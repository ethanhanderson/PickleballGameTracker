//
//  GroupPairingsEngine.swift
//  GameTrackerCore
//
//  Generates schedules for Group Play sessions:
//  - Random Pairings (partner-rotation for players, or team-vs-team round robin)
//  - Supports singles, doubles, and 2v1 via player-based schedules
//

import Foundation

public struct GroupPairingsEngine: Sendable {
  
  public init() {}
  
  // MARK: - Public API
  
  /// Build a schedule for a random pairings session.
  ///
  /// - Parameters:
  ///   - players: Roster of player IDs
  ///   - playMode: singles / doubles / twoVOne
  ///   - usePartnerRotation: If true, ensures partners rotate (players mode).
  ///   - useTeamRoundRobin: If true, form teams first (external) and schedule team round robin.
  ///     Callers that choose team round robin should pass pre-formed `teams` and leave `players` as empty.
  ///   - teams: Optional list of fixed team IDs (for team round robin)
  /// - Returns: Array of scheduled matches (unsorted relationship; `orderIndex` is filled)
  public func buildRandomSchedule(
    players: [UUID],
    playMode: GroupPlayPlayMode,
    usePartnerRotation: Bool,
    useTeamRoundRobin: Bool,
    teams: [UUID] = []
  ) -> [ScheduledMatch] {
    if useTeamRoundRobin, teams.count >= 2 {
      return scheduleTeamRoundRobin(teams: teams)
    }
    
    switch playMode {
    case .singles:
      return scheduleSinglesPartnerRotation(players: players)
    case .doubles:
      return scheduleDoublesPartnerRotation(players: players)
    case .twoVOne:
      return scheduleTwoVOne(players: players)
    }
  }
  
  // MARK: - Singles (players mode)
  
  /// Schedule singles where players rotate opponents; attempts to cover all pairs.
  private func scheduleSinglesPartnerRotation(players: [UUID]) -> [ScheduledMatch] {
    let uniquePairs = allUniquePairs(of: players)
    var usedPairs: Set<Pair> = []
    var rounds: [[Pair]] = []
    
    // Greedy: build rounds of disjoint pairs until pairs exhausted
    var remaining = uniquePairs
    while !remaining.isEmpty {
      var round: [Pair] = []
      var available: Set<UUID> = Set(players)
      
      // Try to pack as many disjoint pairs into this round as possible
      for pair in remaining {
        if available.contains(pair.a) && available.contains(pair.b) {
          round.append(pair)
          available.remove(pair.a)
          available.remove(pair.b)
        }
      }
      
      // Remove round pairs from remaining
      for p in round {
        usedPairs.insert(p)
      }
      remaining.removeAll { usedPairs.contains($0) }
      
      if round.isEmpty { break }
      rounds.append(round)
    }
    
    // Convert to ScheduledMatch list with order indices
    var matches: [ScheduledMatch] = []
    var idx = 0
    for r in rounds {
      for pair in r {
        let m = ScheduledMatch(
          participantModeRaw: ParticipantMode.players.rawValue,
          side1PlayerIds: [pair.a],
          side2PlayerIds: [pair.b],
          orderIndex: idx
        )
        matches.append(m)
        idx += 1
      }
    }
    return matches
  }
  
  // MARK: - Doubles (players mode, partner rotation)
  
  /// Schedule doubles with partner rotation such that each player partners with many others.
  /// Greedy algorithm over all unique partner pairs; creates disjoint-team rounds.
  private func scheduleDoublesPartnerRotation(players: [UUID]) -> [ScheduledMatch] {
    // Require at least 4 players
    guard players.count >= 4 else { return [] }
    
    // Build all unique partner pairs
    let partnerPairs = allUniquePairs(of: players)
    
    // Track pairs that have already partnered
    var remainingPairs = Set(partnerPairs)
    var matches: [ScheduledMatch] = []
    var orderIndex = 0
    
    // In each iteration, try to form two teams from four distinct players
    // by selecting two disjoint pairs that haven't partnered yet,
    // and choose opponents as the next best available disjoint pair combo.
    while true {
      var usedInThisRound: Set<UUID> = []
      var producedAny = false
      
      // Attempt to pick two disjoint pairs to form one match
      outer: for p1 in remainingPairs {
        if usedInThisRound.contains(p1.a) || usedInThisRound.contains(p1.b) { continue }
        for p2 in remainingPairs {
          if p1 == p2 { continue }
          let disjoint = Set([p1.a, p1.b]).isDisjoint(with: Set([p2.a, p2.b]))
          if disjoint && usedInThisRound.isDisjoint(with: [p1.a, p1.b, p2.a, p2.b]) {
            // We have two disjoint pairs; now find opponents
            // Simple approach: use the same two pairs; assign teams (p1 vs p2)
            let match = ScheduledMatch(
              participantModeRaw: ParticipantMode.players.rawValue,
              side1PlayerIds: [p1.a, p1.b],
              side2PlayerIds: [p2.a, p2.b],
              orderIndex: orderIndex
            )
            matches.append(match)
            orderIndex += 1
            // Mark these pairs as used
            remainingPairs.remove(p1)
            remainingPairs.remove(p2)
            usedInThisRound.formUnion([p1.a, p1.b, p2.a, p2.b])
            producedAny = true
            break outer
          }
        }
      }
      
      if !producedAny { break }
      // Continue until no more disjoint pairs can be formed
    }
    
    return matches
  }
  
  // MARK: - 2v1 (players mode)
  
  /// Schedule 2v1 so that each player takes a turn as the solo player as evenly as possible.
  private func scheduleTwoVOne(players: [UUID]) -> [ScheduledMatch] {
    guard players.count >= 3 else { return [] }
    var matches: [ScheduledMatch] = []
    var orderIndex = 0
    
    // Rotate each player as the solo; partners rotate from remaining
    for (idx, solo) in players.enumerated() {
      let others = players.enumerated().filter { $0.offset != idx }.map { $0.element }
      // Choose two partners for the opposing side; simple rolling window of size 2
      if others.count >= 2 {
        for start in stride(from: 0, to: others.count, by: 2) {
          let group = Array(others[start..<min(start + 2, others.count)])
          if group.count == 2 {
            let match = ScheduledMatch(
              participantModeRaw: ParticipantMode.players.rawValue,
              side1PlayerIds: [solo],
              side2PlayerIds: group,
              orderIndex: orderIndex
            )
            matches.append(match)
            orderIndex += 1
          }
        }
      }
    }
    
    return matches
  }
  
  // MARK: - Teams round robin (teams mode)
  
  /// Schedule round robin between provided teams (by IDs).
  private func scheduleTeamRoundRobin(teams: [UUID]) -> [ScheduledMatch] {
    let pairs = allUniquePairs(of: teams)
    var matches: [ScheduledMatch] = []
    var idx = 0
    for p in pairs {
      let m = ScheduledMatch(
        participantModeRaw: ParticipantMode.teams.rawValue,
        side1TeamId: p.a,
        side2TeamId: p.b,
        orderIndex: idx
      )
      matches.append(m)
      idx += 1
    }
    return matches
  }
  
  // MARK: - Helpers
  
  private struct Pair: Hashable {
    let a: UUID
    let b: UUID
    
    init(_ a: UUID, _ b: UUID) {
      if a.uuidString < b.uuidString {
        self.a = a; self.b = b
      } else {
        self.a = b; self.b = a
      }
    }
  }
  
  private func allUniquePairs(of ids: [UUID]) -> [Pair] {
    guard ids.count >= 2 else { return [] }
    var pairs: [Pair] = []
    for i in 0..<(ids.count - 1) {
      for j in (i + 1)..<ids.count {
        pairs.append(Pair(ids[i], ids[j]))
      }
    }
    return pairs
  }
}


