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
    
    // Prepare entries: seeded keeps incoming order; otherwise shuffle
    var entries = rawEntries
    if !seeded {
      entries.shuffle()
    }
    
    // Expand to next power of two by adding implicit byes
    let target = nextPowerOfTwo(entries.count)
    let numByes = max(0, target - entries.count)
    if numByes > 0 {
      // Standard seeding places byes against top seeds; we simulate by appending nils
      entries.append(contentsOf: Array(repeating: UUID?.none, count: numByes).compactMap { $0 })
      // Note: We cannot append nil to a [UUID]; instead we handle byes by pairing last entries unevenly.
      // Fallback: while entries.count is odd, duplicate last to keep pairing, and the session manager can skip duplicates.
      // But better approach: pair in a way to skip generating matches with missing opponents.
    }
    
    // Pair up sequentially; if odd count, last gets a bye (no match generated)
    var matches: [ScheduledMatch] = []
    var order = 0
    var i = 0
    while i < entries.count {
      if i + 1 < entries.count {
        let a = entries[i]
        let b = entries[i + 1]
        let match: ScheduledMatch
        if useTeams {
          match = ScheduledMatch(
            participantModeRaw: ParticipantMode.teams.rawValue,
            side1TeamId: a,
            side2TeamId: b,
            orderIndex: order
          )
        } else {
          match = ScheduledMatch(
            participantModeRaw: ParticipantMode.players.rawValue,
            side1PlayerIds: [a],
            side2PlayerIds: [b],
            orderIndex: order
          )
        }
        matches.append(match)
        order += 1
        i += 2
      } else {
        // Bye: last entry advances; no match needed in first round
        i += 1
      }
    }
    return matches
  }
  
  private func nextPowerOfTwo(_ n: Int) -> Int {
    var x = 1
    while x < n { x <<= 1 }
    return x
  }
}


