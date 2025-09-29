//
//  GameVariation.swift
//  SharedGameCore
//
//  Created by Ethan Anderson on 7/9/25.
//

import Foundation
import SwiftData

@Model
public final class GameVariation {
  @Attribute(.unique) public var id: UUID
  public var name: String
  public var gameType: GameType

  // Team Configuration
  public var teamSize: Int
  public var numberOfTeams: Int

  // Scoring Rules
  public var winningScore: Int
  public var winByTwo: Bool
  public var maxScore: Int?  // Optional maximum score ceiling

  // Game Rules
  public var kitchenRule: Bool
  public var doubleBounceRule: Bool
  public var servingRotation: ServingRotation
  public var sideSwitchingRule: SideSwitchingRule
  public var scoringType: ScoringType

  // Game Format
  public var timeLimit: TimeInterval?  // Optional time limit in seconds
  public var maxRallies: Int?  // Optional maximum rallies

  // Customization Status
  public var isDefault: Bool
  public var isCustom: Bool
  public var isCommunity: Bool
  public var isPublished: Bool

  // Metadata
  public var createdDate: Date
  public var lastModified: Date
  public var gameDescription: String?
  public var tags: [String]

  public init(
    id: UUID = UUID(),
    name: String,
    gameType: GameType,
    teamSize: Int? = nil,
    numberOfTeams: Int = 2,
    winningScore: Int = 11,
    winByTwo: Bool = true,
    maxScore: Int? = nil,
    kitchenRule: Bool = true,
    doubleBounceRule: Bool = true,
    servingRotation: ServingRotation = .standard,
    sideSwitchingRule: SideSwitchingRule = .at6Points,
    scoringType: ScoringType = .sideOut,
    timeLimit: TimeInterval? = nil,
    maxRallies: Int? = nil,
    isDefault: Bool = false,
    isCustom: Bool = false,
    isCommunity: Bool = false,
    isPublished: Bool = false,
    gameDescription: String? = nil,
    tags: [String] = []
  ) {
    self.id = id
    self.name = name
    self.gameType = gameType
    self.teamSize = teamSize ?? gameType.defaultTeamSize
    self.numberOfTeams = numberOfTeams
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
    self.isDefault = isDefault
    self.isCustom = isCustom
    self.isCommunity = isCommunity
    self.isPublished = isPublished
    self.createdDate = Date()
    self.lastModified = Date()
    self.gameDescription = gameDescription
    self.tags = tags
  }
}

// MARK: - Game Variation Enums

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
      // Official pickleball rule: switch when combined score equals 6
      return (currentScore1 + currentScore2) == 6
    case .atHalfway:
      let halfway = winningScore / 2
      return (currentScore1 + currentScore2) == halfway
    case .everyPoint:
      // Toggle sides after every rally
      return true
    case .afterEachGame:
      return false  // Handled separately for completed games
    }
  }
}

// MARK: - GameVariation Extensions

extension GameVariation {
  /// Get formatted time limit string
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

  /// Get player labels based on team size
  public var playerLabel1: String {
    return gameType.playerLabel1(teamSize: teamSize)
  }

  public var playerLabel2: String {
    return gameType.playerLabel2(teamSize: teamSize)
  }

  /// Check if this variation is compatible with a game type
  public func isCompatible(with gameType: GameType) -> Bool {
    return self.gameType == gameType || gameType.supportsTeamCustomization
  }

  /// Create a copy of this variation
  public func copy() -> GameVariation {
    return GameVariation(
      name: "\(name) Copy",
      gameType: gameType,
      teamSize: teamSize,
      numberOfTeams: numberOfTeams,
      winningScore: winningScore,
      winByTwo: winByTwo,
      maxScore: maxScore,
      kitchenRule: kitchenRule,
      doubleBounceRule: doubleBounceRule,
      servingRotation: servingRotation,
      sideSwitchingRule: sideSwitchingRule,
      scoringType: scoringType,
      timeLimit: timeLimit,
      maxRallies: maxRallies,
      isDefault: false,
      isCustom: true,
      isCommunity: false,
      isPublished: false,
      gameDescription: gameDescription,
      tags: tags
    )
  }
}

// MARK: - Default Game Variations

extension GameVariation {
  /// Create default variations for each game type
  public static func createDefaultVariations() -> [GameVariation] {
    return [
      // Recreational variations
      GameVariation(
        name: "Casual Doubles",
        gameType: .recreational,
        teamSize: 2,
        winningScore: 11,
        winByTwo: true,
        kitchenRule: true,
        doubleBounceRule: true,
        sideSwitchingRule: .never,
        scoringType: .sideOut,
        isDefault: true,
        gameDescription: "Classic doubles pickleball for recreational play"
      ),
      GameVariation(
        name: "Casual Singles",
        gameType: .recreational,
        teamSize: 1,
        winningScore: 11,
        winByTwo: true,
        kitchenRule: true,
        doubleBounceRule: true,
        sideSwitchingRule: .never,
        scoringType: .sideOut,
        isDefault: true,
        gameDescription: "Singles pickleball for recreational play"
      ),
      GameVariation(
        name: "Rally Scoring Doubles",
        gameType: .recreational,
        teamSize: 2,
        winningScore: 15,
        winByTwo: true,
        kitchenRule: true,
        doubleBounceRule: true,
        sideSwitchingRule: .never,
        scoringType: .rally,
        isDefault: true,
        gameDescription: "Modern rally scoring format"
      ),

      // Tournament variations
      GameVariation(
        name: "Tournament Doubles",
        gameType: .tournament,
        teamSize: 2,
        winningScore: 11,
        winByTwo: true,
        kitchenRule: true,
        doubleBounceRule: true,
        sideSwitchingRule: .never,
        scoringType: .sideOut,
        isDefault: true,
        gameDescription: "Official tournament doubles format"
      ),
      GameVariation(
        name: "Tournament Singles",
        gameType: .tournament,
        teamSize: 1,
        winningScore: 11,
        winByTwo: true,
        kitchenRule: true,
        doubleBounceRule: true,
        sideSwitchingRule: .never,
        scoringType: .sideOut,
        isDefault: true,
        gameDescription: "Official tournament singles format"
      ),
      GameVariation(
        name: "Championship Format",
        gameType: .tournament,
        teamSize: 2,
        winningScore: 15,
        winByTwo: true,
        kitchenRule: true,
        doubleBounceRule: true,
        sideSwitchingRule: .never,
        scoringType: .sideOut,
        isDefault: true,
        gameDescription: "Extended tournament format to 15 points"
      ),
      GameVariation(
        name: "Pro Tournament",
        gameType: .tournament,
        teamSize: 2,
        winningScore: 21,
        winByTwo: true,
        kitchenRule: true,
        doubleBounceRule: true,
        sideSwitchingRule: .never,
        scoringType: .sideOut,
        isDefault: true,
        gameDescription: "Professional tournament format to 21 points"
      ),

      // Training variations
      GameVariation(
        name: "Quick Doubles Practice",
        gameType: .training,
        teamSize: 2,
        winningScore: 7,
        winByTwo: false,
        kitchenRule: true,
        doubleBounceRule: true,
        sideSwitchingRule: .never,
        scoringType: .sideOut,
        isDefault: true,
        gameDescription: "Fast practice games for skill development"
      ),
      GameVariation(
        name: "Singles Drill",
        gameType: .training,
        teamSize: 1,
        winningScore: 7,
        winByTwo: false,
        kitchenRule: true,
        doubleBounceRule: true,
        sideSwitchingRule: .never,
        scoringType: .sideOut,
        isDefault: true,
        gameDescription: "Singles practice for conditioning and strategy"
      ),
      GameVariation(
        name: "Rally Training",
        gameType: .training,
        teamSize: 2,
        winningScore: 7,
        winByTwo: false,
        kitchenRule: true,
        doubleBounceRule: true,
        sideSwitchingRule: .never,
        scoringType: .rally,
        isDefault: true,
        gameDescription: "Rally scoring practice to first to 7"
      ),
      GameVariation(
        name: "Serving Practice",
        gameType: .training,
        teamSize: 2,
        winningScore: 5,
        winByTwo: false,
        kitchenRule: true,
        doubleBounceRule: true,
        servingRotation: .singleServe,
        sideSwitchingRule: .never,
        scoringType: .sideOut,
        isDefault: true,
        gameDescription: "Focus on serving skills and rotation"
      ),

      // Social variations
      GameVariation(
        name: "Social Doubles",
        gameType: .social,
        teamSize: 2,
        winningScore: 11,
        winByTwo: true,
        kitchenRule: true,
        doubleBounceRule: true,
        sideSwitchingRule: .never,
        scoringType: .sideOut,
        isDefault: true,
        gameDescription: "Relaxed doubles play for social gatherings"
      ),
      GameVariation(
        name: "Mixed Doubles",
        gameType: .social,
        teamSize: 2,
        winningScore: 11,
        winByTwo: true,
        kitchenRule: true,
        doubleBounceRule: true,
        sideSwitchingRule: .never,
        scoringType: .sideOut,
        isDefault: true,
        gameDescription: "Mixed gender doubles play"
      ),
      GameVariation(
        name: "Skinny Singles",
        gameType: .social,
        teamSize: 1,
        winningScore: 11,
        winByTwo: true,
        kitchenRule: true,
        doubleBounceRule: true,
        sideSwitchingRule: .never,
        scoringType: .sideOut,
        isDefault: true,
        gameDescription: "Half-court singles for close games"
      ),
      GameVariation(
        name: "Round Robin Format",
        gameType: .social,
        teamSize: 2,
        winningScore: 9,
        winByTwo: false,
        kitchenRule: true,
        doubleBounceRule: true,
        sideSwitchingRule: .never,
        scoringType: .sideOut,
        timeLimit: 900,  // 15 minutes
        isDefault: true,
        gameDescription: "Timed format perfect for group rotation"
      ),

      // Custom baseline variation
      GameVariation(
        name: "Custom Game",
        gameType: .custom,
        teamSize: 2,
        winningScore: 11,
        winByTwo: true,
        kitchenRule: true,
        doubleBounceRule: true,
        sideSwitchingRule: .at6Points,
        scoringType: .sideOut,
        isDefault: true,
        gameDescription: "Fully customizable game rules and scoring"
      ),
    ]
  }
}

// MARK: - Error Types

public enum GameVariationError: Error, LocalizedError, Sendable {
  case invalidWinningScore(Int)
  case invalidTeamSize(Int)
  case invalidConfiguration(String)
  case missingGameType
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
    case .missingGameType:
      return "Game type is required for creating a game variation."
    case .invalidTimeLimit(let limit):
      return
        "Invalid time limit: \(limit) seconds. Time limit must be between 60 seconds and 2 hours."
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
    case .missingGameType:
      return "Select a valid game type before creating the variation."
    case .invalidTimeLimit:
      return "Set a time limit between 1 minute and 2 hours."
    case .invalidMaxRallies:
      return "Set max rallies between 1 and 1000."
    }
  }
}

// MARK: - Validation

extension GameVariation {
  /// Validates the game variation configuration
  public func validate() throws(GameVariationError) {
    // Validate winning score
    guard winningScore > 0 && winningScore <= 50 else {
      throw GameVariationError.invalidWinningScore(winningScore)
    }

    // Validate team size
    guard teamSize >= 1 && teamSize <= 6 else {
      throw GameVariationError.invalidTeamSize(teamSize)
    }

    // Validate time limit if set
    if let timeLimit = timeLimit {
      guard timeLimit >= 60 && timeLimit <= 7200 else {  // 1 minute to 2 hours
        throw GameVariationError.invalidTimeLimit(timeLimit)
      }
    }

    // Validate max rallies if set
    if let maxRallies = maxRallies {
      guard maxRallies >= 1 && maxRallies <= 1000 else {
        throw GameVariationError.invalidMaxRallies(maxRallies)
      }
    }

    // Validate logical consistency
    if winByTwo && winningScore <= 1 {
      throw GameVariationError.invalidConfiguration(
        "Win-by-two rule requires winning score of at least 2")
    }
  }

  /// Creates a validated game variation
  public static func createValidated(
    name: String,
    gameType: GameType,
    teamSize: Int? = nil,
    winningScore: Int = 11,
    winByTwo: Bool = true,
    kitchenRule: Bool = true,
    doubleBounceRule: Bool = true,
    servingRotation: ServingRotation = .standard,
    sideSwitchingRule: SideSwitchingRule = .at6Points,
    scoringType: ScoringType = .sideOut,
    timeLimit: TimeInterval? = nil,
    maxRallies: Int? = nil,
    isCustom: Bool = false
  ) throws(GameVariationError) -> GameVariation {

    let variation = GameVariation(
      name: name,
      gameType: gameType,
      teamSize: teamSize ?? gameType.defaultTeamSize,
      winningScore: winningScore,
      winByTwo: winByTwo,
      kitchenRule: kitchenRule,
      doubleBounceRule: doubleBounceRule,
      servingRotation: servingRotation,
      sideSwitchingRule: sideSwitchingRule,
      scoringType: scoringType,
      timeLimit: timeLimit,
      maxRallies: maxRallies,
      isCustom: isCustom
    )

    try variation.validate()
    return variation
  }
}
