//
//  GameStartConfiguration.swift
//  SharedGameCore
//
//  Standardized configuration used to start a new live game.
//

import Foundation

/// Standardized configuration used to start a new live game.
public struct GameStartConfiguration: Hashable {
  public let gameType: GameType
  public let teamSize: TeamSize
  public let participants: Participants
  public let notes: String?
  /// Optional: when provided, this variation will be used (validated) instead of deriving defaults
  public let variation: GameVariation?

  public init(
    gameType: GameType,
    teamSize: TeamSize,
    participants: Participants,
    notes: String? = nil,
    variation: GameVariation? = nil
  ) {
    self.gameType = gameType
    self.teamSize = teamSize
    self.participants = participants
    self.notes = notes
    self.variation = variation
  }
}

/// Team size for a match. Currently supports singles and doubles.
public enum TeamSize: Int, Sendable, Hashable, Codable {
  case singles = 1
  case doubles = 2

  public var playersPerSide: Int { rawValue }

  public init?(playersPerSide: Int) {
    switch playersPerSide {
    case 1: self = .singles
    case 2: self = .doubles
    default: return nil
    }
  }
}

/// Participants for a match (either players or teams per side)
public struct Participants: Sendable, Hashable {
  public enum Participant: Sendable, Hashable {
    case players([UUID])   // PlayerProfile IDs, ordered selection for side
    case team(UUID)        // TeamProfile ID
  }

  public let side1: Participant
  public let side2: Participant

  public init(side1: Participant, side2: Participant) {
    self.side1 = side1
    self.side2 = side2
  }
}


