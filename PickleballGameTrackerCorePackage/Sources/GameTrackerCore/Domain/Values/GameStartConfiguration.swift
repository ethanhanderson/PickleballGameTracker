//
//  GameStartConfiguration.swift
//  SharedGameCore
//
//  Standardized configuration used to start a new live game.
//

import Foundation

/// Standardized configuration used to start a new live game.
public struct GameStartConfiguration: Hashable, Codable {
  public let gameId: UUID?
  public let gameType: GameType
  public let teamSize: TeamSize
  public let participants: Participants
  public let notes: String?
  /// Optional: when provided, these rules will be used instead of game type defaults
  public let rules: GameRules?

  public init(
    gameId: UUID? = nil,
    gameType: GameType,
    teamSize: TeamSize,
    participants: Participants,
    notes: String? = nil,
    rules: GameRules? = nil
  ) {
    self.gameId = gameId
    self.gameType = gameType
    self.teamSize = teamSize
    self.participants = participants
    self.notes = notes
    self.rules = rules
  }
}

// Allow use across concurrency domains; GameRules is not Sendable, but we only
// pass this through main-actor handlers, and rules are encoded as value fields.
extension GameStartConfiguration: @unchecked Sendable {}

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
public struct Participants: Sendable, Hashable, Codable {
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

// Manual Codable for Participants.Participant (enum with associated values)
extension Participants.Participant: Codable {
  private enum CodingKeys: String, CodingKey { case kind, players, team }
  private enum Kind: String, Codable { case players, team }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let kind = try container.decode(Kind.self, forKey: .kind)
    switch kind {
    case .players:
      let ids = try container.decode([UUID].self, forKey: .players)
      self = .players(ids)
    case .team:
      let id = try container.decode(UUID.self, forKey: .team)
      self = .team(id)
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .players(let ids):
      try container.encode(Kind.players, forKey: .kind)
      try container.encode(ids, forKey: .players)
    case .team(let id):
      try container.encode(Kind.team, forKey: .kind)
      try container.encode(id, forKey: .team)
    }
  }
}

// Custom Codable to encode/decode GameRules as a value payload, avoiding direct
// Codable conformance on the SwiftData model class.
extension GameStartConfiguration {
  private enum CodingKeys: String, CodingKey { case gameId, gameType, teamSize, participants, notes, rules }

  private struct RulesPayload: Codable, Sendable, Hashable {
    let winningScore: Int
    let winByTwo: Bool
    let maxScore: Int?
    let kitchenRule: Bool
    let doubleBounceRule: Bool
    let servingRotation: ServingRotation
    let sideSwitchingRule: SideSwitchingRule
    let scoringType: ScoringType
    let timeLimit: TimeInterval?
    let maxRallies: Int?
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.gameId = try container.decodeIfPresent(UUID.self, forKey: .gameId)
    self.gameType = try container.decode(GameType.self, forKey: .gameType)
    self.teamSize = try container.decode(TeamSize.self, forKey: .teamSize)
    self.participants = try container.decode(Participants.self, forKey: .participants)
    self.notes = try container.decodeIfPresent(String.self, forKey: .notes)
    if let payload = try container.decodeIfPresent(RulesPayload.self, forKey: .rules) {
      // Construct a GameRules instance from value payload
      self.rules = GameRules(
        winningScore: payload.winningScore,
        winByTwo: payload.winByTwo,
        maxScore: payload.maxScore,
        kitchenRule: payload.kitchenRule,
        doubleBounceRule: payload.doubleBounceRule,
        servingRotation: payload.servingRotation,
        sideSwitchingRule: payload.sideSwitchingRule,
        scoringType: payload.scoringType,
        timeLimit: payload.timeLimit,
        maxRallies: payload.maxRallies
      )
    } else {
      self.rules = nil
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(gameId, forKey: .gameId)
    try container.encode(gameType, forKey: .gameType)
    try container.encode(teamSize, forKey: .teamSize)
    try container.encode(participants, forKey: .participants)
    try container.encodeIfPresent(notes, forKey: .notes)
    if let rules = rules {
      let payload = RulesPayload(
        winningScore: rules.winningScore,
        winByTwo: rules.winByTwo,
        maxScore: rules.maxScore,
        kitchenRule: rules.kitchenRule,
        doubleBounceRule: rules.doubleBounceRule,
        servingRotation: rules.servingRotation,
        sideSwitchingRule: rules.sideSwitchingRule,
        scoringType: rules.scoringType,
        timeLimit: rules.timeLimit,
        maxRallies: rules.maxRallies
      )
      try container.encode(payload, forKey: .rules)
    }
  }
}


