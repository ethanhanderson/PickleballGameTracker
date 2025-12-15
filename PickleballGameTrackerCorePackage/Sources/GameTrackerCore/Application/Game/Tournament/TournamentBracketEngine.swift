//
//  TournamentBracketEngine.swift
//  GameTrackerCore
//
//  Single-elimination bracket generator with basic seeding and bye handling.
//

import Foundation

public struct TournamentBracketEngine: Sendable {
  
  public init() {}
  
  // MARK: - Public API
  
  /// Generate the first round of a single-elimination bracket for players.
  /// - Parameters:
  ///   - players: Participant player IDs
  ///   - seeded: If true, keep order for standard 1-vs-N seeding. If false, shuffle.
  public func firstRoundForPlayers(players: [UUID], seeded: Bool) -> [ScheduledMatch] {
    return firstRound(entries: players, useTeams: false, seeded: seeded)
  }
  
  /// Generate the first round of a single-elimination bracket for teams.
  /// - Parameters:
  ///   - teams: Team IDs
  ///   - seeded: If true, keep order for standard 1-vs-N seeding. If false, shuffle.
  public func firstRoundForTeams(teams: [UUID], seeded: Bool) -> [ScheduledMatch] {
    return firstRound(entries: teams, useTeams: true, seeded: seeded)
  }
  
  // MARK: - Internal
  
  private func firstRound(entries rawEntries: [UUID], useTeams: Bool, seeded: Bool) -> [ScheduledMatch] {
    guard rawEntries.count >= 2 else { return [] }
    
    var entries: [UUID?] = rawEntries.map { $0 }
    if !seeded {
      entries.shuffle()
    }
    
    // Expand to next power of two by adding explicit bye placeholders (nil)
    let target = nextPowerOfTwo(entries.count)
    let numByes = max(0, target - entries.count)
    if numByes > 0 {
      entries.append(contentsOf: Array(repeating: UUID?.none, count: numByes))
      if !seeded {
        entries.shuffle()
      }
    }
    
    // Pair up sequentially; skip generating a match when a bye is present
    var matches: [ScheduledMatch] = []
    var order = 0
    var i = 0
    while i < entries.count {
      let a = entries[i]
      let b = i + 1 < entries.count ? entries[i + 1] : nil
      
      if let aId = a, let bId = b {
        let match: ScheduledMatch
        if useTeams {
          match = ScheduledMatch(
            participantModeRaw: ParticipantMode.teams.rawValue,
            side1TeamId: aId,
            side2TeamId: bId,
            orderIndex: order
          )
        } else {
          match = ScheduledMatch(
            participantModeRaw: ParticipantMode.players.rawValue,
            side1PlayerIds: [aId],
            side2PlayerIds: [bId],
            orderIndex: order
          )
        }
        matches.append(match)
        order += 1
      }
      
      // Bye: last entry advances; no match needed in first round
      i += 2
    }
    return matches
  }
  
  private func nextPowerOfTwo(_ n: Int) -> Int {
    var x = 1
    while x < n { x <<= 1 }
    return x
  }
}


