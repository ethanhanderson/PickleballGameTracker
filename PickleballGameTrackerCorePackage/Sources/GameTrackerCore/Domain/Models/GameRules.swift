//
//  GameRules.swift
//  SharedGameCore
//
//  Created by Ethan Anderson on 10/18/25.
//

import Foundation
import SwiftData

@Model
public final class GameRules {
  @Attribute(.unique) public var id: UUID
  
  // Scoring Rules
  public var winningScore: Int
  public var winByTwo: Bool
  public var maxScore: Int?
  
  // Game Rules
  public var kitchenRule: Bool
  public var doubleBounceRule: Bool
  public var servingRotation: ServingRotation
  public var sideSwitchingRule: SideSwitchingRule
  public var scoringType: ScoringType
  
  // Game Format
  public var timeLimit: TimeInterval?
  public var maxRallies: Int?
  
  // Metadata
  public var createdDate: Date
  public var lastModified: Date
  
  public init(
    id: UUID = UUID(),
    winningScore: Int = 11,
    winByTwo: Bool = true,
    maxScore: Int? = nil,
    kitchenRule: Bool = true,
    doubleBounceRule: Bool = true,
    servingRotation: ServingRotation = .standard,
    sideSwitchingRule: SideSwitchingRule = .at6Points,
    scoringType: ScoringType = .sideOut,
    timeLimit: TimeInterval? = nil,
    maxRallies: Int? = nil
  ) {
    self.id = id
    self.winningScore = winningScore
    self.winByTwo = winByTwo
    self.maxScore = maxScore
    self.kitchenRule = kitchenRule
    self.doubleBounceRule = doubleBounceRule
    self.servingRotation = servingRotation
    self.sideSwitchingRule = sideSwitchingRule
    self.scoringType = scoringType
    self.timeLimit = timeLimit
    self.maxRallies = maxRallies
    self.createdDate = Date()
    self.lastModified = Date()
  }
}

// MARK: - GameRules Enums

public enum ScoringType: String, CaseIterable, Codable, Sendable {
  case sideOut = "sideOut"
  case rally = "rally"

  public var displayName: String {
    switch self {
    case .sideOut: return "Side-Out Scoring"
    case .rally: return "Rally Scoring"
    }
  }

  public var description: String {
    switch self {
    case .sideOut: return "Points only scored by serving team (traditional)"
    case .rally: return "Point scored after every rally (modern)"
    }
  }
}

public enum ServingRotation: String, CaseIterable, Codable, Sendable {
  case standard = "standard"
  case alternating = "alternating"
  case doubleServe = "doubleServe"
  case singleServe = "singleServe"

  public var displayName: String {
    switch self {
    case .standard:
      return "Standard Rotation"
    case .alternating:
      return "Alternating Serve"
    case .doubleServe:
      return "Double Serve"
    case .singleServe:
      return "Single Serve"
    }
  }

  public var description: String {
    switch self {
    case .standard:
      return "Standard pickleball serving rotation"
    case .alternating:
      return "Players alternate serving each point"
    case .doubleServe:
      return "Each player/team serves twice before switching"
    case .singleServe:
      return "Each player/team serves once before switching"
    }
  }
}

public enum SideSwitchingRule: String, CaseIterable, Codable, Sendable {
  case never = "never"
  case at6Points = "at6Points"
  case atHalfway = "atHalfway"
  case everyPoint = "everyPoint"
  case afterEachGame = "afterEachGame"

  public var displayName: String {
    switch self {
    case .never:
      return "Never Switch"
    case .at6Points:
      return "Switch at 6 Points"
    case .atHalfway:
      return "Switch at Halfway"
    case .everyPoint:
      return "Switch Every Point"
    case .afterEachGame:
      return "Switch After Game"
    }
  }

  public var description: String {
    switch self {
    case .never:
      return "Teams stay on the same side for entire game"
    case .at6Points:
      return "Teams switch sides when combined score reaches 6 points"
    case .atHalfway:
      return "Teams switch sides at halfway point of winning score"
    case .everyPoint:
      return "Teams switch sides after every point"
    case .afterEachGame:
      return "Teams switch sides after each completed game"
    }
  }

  public func shouldSwitchSides(currentScore1: Int, currentScore2: Int, winningScore: Int) -> Bool {
    switch self {
    case .never:
      return false
    case .at6Points:
      return (currentScore1 + currentScore2) == 6
    case .atHalfway:
      let halfway = winningScore / 2
      return (currentScore1 + currentScore2) == halfway
    case .everyPoint:
      return true
    case .afterEachGame:
      return false
    }
  }
}

// MARK: - GameRules Extensions

extension GameRules {
  public var formattedTimeLimit: String? {
    guard let timeLimit = timeLimit else { return nil }

    let hours = Int(timeLimit) / 3600
    let minutes = Int(timeLimit) % 3600 / 60
    let seconds = Int(timeLimit) % 60

    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    } else if minutes > 0 {
      return String(format: "%d:%02d", minutes, seconds)
    } else {
      return "\(seconds)s"
    }
  }

  public func copy() -> GameRules {
    return GameRules(
      winningScore: winningScore,
      winByTwo: winByTwo,
      maxScore: maxScore,
      kitchenRule: kitchenRule,
      doubleBounceRule: doubleBounceRule,
      servingRotation: servingRotation,
      sideSwitchingRule: sideSwitchingRule,
      scoringType: scoringType,
      timeLimit: timeLimit,
      maxRallies: maxRallies
    )
  }
}

// MARK: - Error Types

public enum GameRulesError: Error, LocalizedError, Sendable {
  case invalidWinningScore(Int)
  case invalidTeamSize(Int)
  case invalidConfiguration(String)
  case invalidTimeLimit(TimeInterval)
  case invalidMaxRallies(Int)

  public var errorDescription: String? {
    switch self {
    case .invalidWinningScore(let score):
      return "Invalid winning score: \(score). Score must be between 1 and 50."
    case .invalidTeamSize(let size):
      return "Invalid team size: \(size). Team size must be between 1 and 6."
    case .invalidConfiguration(let message):
      return "Invalid game configuration: \(message)"
    case .invalidTimeLimit(let limit):
      return "Invalid time limit: \(limit) seconds. Time limit must be between 60 seconds and 2 hours."
    case .invalidMaxRallies(let rallies):
      return "Invalid max rallies: \(rallies). Max rallies must be between 1 and 1000."
    }
  }

  public var recoverySuggestion: String? {
    switch self {
    case .invalidWinningScore:
      return "Choose a winning score between 1 and 50 points."
    case .invalidTeamSize:
      return "Choose a team size between 1 and 6 players."
    case .invalidConfiguration:
      return "Please check your game settings and try again."
    case .invalidTimeLimit:
      return "Set a time limit between 1 minute and 2 hours."
    case .invalidMaxRallies:
      return "Set max rallies between 1 and 1000."
    }
  }
}

// MARK: - Validation

extension GameRules {
  public func validate() throws(GameRulesError) {
    guard winningScore > 0 && winningScore <= 50 else {
      throw GameRulesError.invalidWinningScore(winningScore)
    }

    if let timeLimit = timeLimit {
      guard timeLimit >= 60 && timeLimit <= 7200 else {
        throw GameRulesError.invalidTimeLimit(timeLimit)
      }
    }

    if let maxRallies = maxRallies {
      guard maxRallies >= 1 && maxRallies <= 1000 else {
        throw GameRulesError.invalidMaxRallies(maxRallies)
      }
    }

    if winByTwo && winningScore <= 1 {
      throw GameRulesError.invalidConfiguration(
        "Win-by-two rule requires winning score of at least 2")
    }
  }

  public static func createValidated(
    winningScore: Int = 11,
    winByTwo: Bool = true,
    maxScore: Int? = nil,
    kitchenRule: Bool = true,
    doubleBounceRule: Bool = true,
    servingRotation: ServingRotation = .standard,
    sideSwitchingRule: SideSwitchingRule = .at6Points,
    scoringType: ScoringType = .sideOut,
    timeLimit: TimeInterval? = nil,
    maxRallies: Int? = nil
  ) throws(GameRulesError) -> GameRules {
    let rules = GameRules(
      winningScore: winningScore,
      winByTwo: winByTwo,
      maxScore: maxScore,
      kitchenRule: kitchenRule,
      doubleBounceRule: doubleBounceRule,
      servingRotation: servingRotation,
      sideSwitchingRule: sideSwitchingRule,
      scoringType: scoringType,
      timeLimit: timeLimit,
      maxRallies: maxRallies
    )

    try rules.validate()
    return rules
  }
}

// MARK: - Default Rules Factory

extension GameRules {
  public static func createDefaultRules(for gameType: GameType) -> GameRules {
    return GameRules(
      winningScore: gameType.defaultWinningScore,
      winByTwo: gameType.defaultWinByTwo,
      maxScore: nil,
      kitchenRule: gameType.defaultKitchenRule,
      doubleBounceRule: gameType.defaultDoubleBounceRule,
      servingRotation: .standard,
      sideSwitchingRule: gameType.defaultSideSwitchingRule,
      scoringType: .sideOut,
      timeLimit: nil,
      maxRallies: nil
    )
  }
}

