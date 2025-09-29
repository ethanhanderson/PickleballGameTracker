//
//  MatchupSelection.swift
//  SharedGameCore
//
//  Created by Assistant on 9/3/25.
//

import Foundation

/// Lightweight, non-persisted value describing how a game should be started
/// with either ad-hoc players or existing teams. Used as input to game creation.
public struct MatchupSelection: Sendable, Hashable {
  public enum Mode: Sendable, Hashable {
    case players(sideA: [UUID], sideB: [UUID])  // PlayerProfile IDs
    case teams(team1Id: UUID, team2Id: UUID)    // TeamProfile IDs
  }

  /// Number of players per side (1 for singles, 2 for doubles, etc.)
  public let teamSize: Int
  public let mode: Mode

  public init(teamSize: Int, mode: Mode) {
    self.teamSize = teamSize
    self.mode = mode
  }
}


