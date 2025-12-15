//
//  GroupPlaySessionManager.swift
//  GameTrackerCore
//
//  Orchestrates Group Play sessions: creation, scheduling, progression, standings.
//

import Foundation
import Observation
import SwiftData

@MainActor
@Observable
public final class GroupPlaySessionManager {
  
  // MARK: - Dependencies
  
  private let modelContext: ModelContext
  private let pairingsEngine = GroupPairingsEngine()
  private let bracketEngine = TournamentBracketEngine()
  
  // MARK: - State
  
  public private(set) var activeSession: GroupPlaySession?
  
  public init(modelContext: ModelContext) {
    self.modelContext = modelContext
  }
  
  // MARK: - Session Lifecycle
  
  @discardableResult
  public func createSession(
    rosterPlayerIds: [UUID],
    format: GroupPlayFormat,
    playMode: GroupPlayPlayMode,
    isPartnerRotation: Bool,
    isTeamRoundRobin: Bool,
    isSeeded: Bool,
    fixedTeamIds: [UUID] = [],
    teamsForRoundRobin: [UUID] = []
  ) -> GroupPlaySession {
    // Build schedule
    let schedule: [ScheduledMatch]
    switch format {
    case .randomPairings:
      schedule = pairingsEngine.buildRandomSchedule(
        players: rosterPlayerIds,
        playMode: playMode,
        usePartnerRotation: isPartnerRotation,
        useTeamRoundRobin: isTeamRoundRobin,
        teams: teamsForRoundRobin
      )
      
    case .tournamentBracket:
      switch playMode {
      case .singles:
        schedule = bracketEngine.firstRoundForPlayers(players: rosterPlayerIds, seeded: isSeeded)
      case .doubles:
        // Expect teamsForRoundRobin or fixedTeamIds carry the entries
        let teamEntries = !teamsForRoundRobin.isEmpty ? teamsForRoundRobin : fixedTeamIds
        schedule = bracketEngine.firstRoundForTeams(teams: teamEntries, seeded: isSeeded)
      case .twoVOne:
        // Treat as singles entries for bracket purposes (solo players compete)
        schedule = bracketEngine.firstRoundForPlayers(players: rosterPlayerIds, seeded: isSeeded)
      }
    }
    
    let session = GroupPlaySession(
      formatRaw: format.rawValue,
      playModeRaw: playMode.rawValue,
      isPartnerRotation: isPartnerRotation,
      isTeamRoundRobin: isTeamRoundRobin,
      isSeeded: isSeeded,
      rosterPlayerIds: rosterPlayerIds,
      fixedTeamIds: fixedTeamIds,
      schedule: schedule,
      currentIndex: 0,
      linkedGameIds: []
    )
    
    // Establish backreferences
    for m in session.schedule {
      m.session = session
    }
    
    modelContext.insert(session)
    activeSession = session
    return session
  }
  
  public func setActiveSession(_ session: GroupPlaySession?) {
    activeSession = session
  }
  
  // MARK: - Progression
  
  public func nextMatch(in session: GroupPlaySession? = nil) -> ScheduledMatch? {
    let s = session ?? activeSession
    guard let s else { return nil }
    guard s.currentIndex >= 0, s.currentIndex < s.schedule.count else { return nil }
    let m = s.schedule[s.currentIndex]
    if m.status == .completed {
      // find next scheduled
      return s.schedule.first(where: { $0.status == .scheduled })
    }
    return m
  }
  
  public func markMatchInProgress(_ match: ScheduledMatch, gameId: UUID) {
    match.linkedGameId = gameId
    match.setStatus(.inProgress)
    match.session?.setStatus(.inProgress)
    persist()
  }
  
  public func markMatchCompleted(_ match: ScheduledMatch) {
    match.setStatus(.completed)
    if let s = match.session {
      s.advanceIndex()
      if s.schedule.allSatisfy({ $0.status == .completed }) {
        s.setStatus(.completed)
      }
    }
    persist()
  }
  
  // MARK: - Build GameStartConfiguration from ScheduledMatch
  
  public func participantsForMatch(_ match: ScheduledMatch) -> Participants? {
    switch match.participantMode {
    case .players:
      // Validate sides
      guard !match.side1PlayerIds.isEmpty && !match.side2PlayerIds.isEmpty else { return nil }
      return Participants(side1: .players(match.side1PlayerIds), side2: .players(match.side2PlayerIds))
    case .teams:
      guard let t1 = match.side1TeamId, let t2 = match.side2TeamId else { return nil }
      return Participants(side1: .team(t1), side2: .team(t2))
    }
  }
  
  public func buildStartConfiguration(
    for match: ScheduledMatch,
    rules: GameRules? = nil
  ) -> GameStartConfiguration? {
    guard let session = match.session else { return nil }
    guard let participants = participantsForMatch(match) else { return nil }
    
    // Determine effective team size from session play mode
    let teamSize: TeamSize
    switch session.playMode {
    case .singles: teamSize = .singles
    case .doubles, .twoVOne: teamSize = .doubles
    }
    
    return GameStartConfiguration(
      gameType: .groupPlay,
      teamSize: teamSize,
      participants: participants,
      notes: "Group session match",
      rules: rules
    )
  }
  
  // MARK: - Standings
  
  /// Update standings using a completed game's result.
  public func recordResult(from game: Game, for match: ScheduledMatch) {
    guard let session = match.session else { return }
    let (winners, losers, pf, pa) = summarize(game: game)
    
    func bump(entryId: UUID, win: Bool, pointsFor: Int, pointsAgainst: Int) {
      if let existing = session.standings.first(where: { $0.entryId == entryId }) {
        existing.wins += win ? 1 : 0
        existing.losses += win ? 0 : 1
        existing.pointsFor += pointsFor
        existing.pointsAgainst += pointsAgainst
      } else {
        let entry = GroupStandingEntry(
          entryId: entryId,
          wins: win ? 1 : 0,
          losses: win ? 0 : 1,
          pointsFor: pointsFor,
          pointsAgainst: pointsAgainst
        )
        session.standings.append(entry)
      }
    }
    
    switch match.participantMode {
    case .players:
      for id in winners { bump(entryId: id, win: true, pointsFor: pf, pointsAgainst: pa) }
      for id in losers { bump(entryId: id, win: false, pointsFor: pa, pointsAgainst: pf) }
    case .teams:
      if let t1 = match.side1TeamId, let t2 = match.side2TeamId {
        let winningTeamFirstSide = game.score1 > game.score2
        let winnerTeamId = winningTeamFirstSide ? t1 : t2
        let loserTeamId = winningTeamFirstSide ? t2 : t1
        bump(entryId: winnerTeamId, win: true, pointsFor: max(game.score1, game.score2), pointsAgainst: min(game.score1, game.score2))
        bump(entryId: loserTeamId, win: false, pointsFor: min(game.score1, game.score2), pointsAgainst: max(game.score1, game.score2))
      }
    }
    
    markMatchCompleted(match)
  }
  
  private func summarize(game: Game) -> (winners: [UUID], losers: [UUID], pointsFor: Int, pointsAgainst: Int) {
    let firstWon = game.score1 > game.score2
    let winners = firstWon ? game.side1PlayerIds : game.side2PlayerIds
    let losers = firstWon ? game.side2PlayerIds : game.side1PlayerIds
    let pf = max(game.score1, game.score2)
    let pa = min(game.score1, game.score2)
    return (winners, losers, pf, pa)
  }
  
  // MARK: - Persistence
  
  private func persist() {
    do { try modelContext.save() } catch { /* SwiftData save failures are handled by callers */ }
  }
}


