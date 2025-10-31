//
//  GameType.swift
//  SharedGameCore
//
//  Created by Ethan Anderson on 7/9/25.
//

import Foundation

public enum GameType: String, CaseIterable, Codable, Hashable, Sendable {
  case recreational = "recreational"
  case tournament = "tournament"
  case training = "training"
  case social = "social"
  case custom = "custom"

  public var displayName: String {
    switch self {
    case .recreational:
      return "Recreational"
    case .tournament:
      return "Tournament"
    case .training:
      return "Training"
    case .social:
      return "Social"
    case .custom:
      return "Custom"
    }
  }

  public var description: String {
    switch self {
    case .recreational:
      return "Casual pickleball games for fun and fitness"
    case .tournament:
      return "Official competitive format games"
    case .training:
      return "Short practice games to improve your skills"
    case .social:
      return "Fun variations and group play formats"
    case .custom:
      return "Create your own rules and game format"
    }
  }

  // MARK: - Visual Display Properties

  public var iconName: String {
    switch self {
    case .recreational: return "figure.pickleball"
    case .tournament: return "trophy.fill"
    case .training: return "figure.strengthtraining.traditional"
    case .social: return "person.3.fill"
    case .custom: return "slider.horizontal.3"
    }
  }


  public var difficultyFillProgress: Double {
    switch self {
    case .recreational: return 0.5  // Beginner-Friendly
    case .tournament: return 0.85  // Competitive
    case .training: return 0.25  // Practice
    case .social: return 0.6  // Variable
    case .custom: return 1.0  // Variable (max to indicate complexity)
    }
  }

  public var playerCountText: String {
    switch self {
    case .recreational: return "2-4 Players"
    case .tournament: return "2-4 Players"
    case .training: return "2-4 Players"
    case .social: return "2-6 Players"
    case .custom: return "1-6 Players"
    }
  }

  public var estimatedTimeText: String {
    switch self {
    case .recreational: return "15-25 min"
    case .tournament: return "20-45 min"
    case .training: return "8-15 min"
    case .social: return "10-30 min"
    case .custom: return "5-60 min"
    }
  }

  public var difficultyText: String {
    switch self {
    case .recreational: return "Beginner-Friendly"
    case .tournament: return "Competitive"
    case .training: return "Practice"
    case .social: return "Variable"
    case .custom: return "Variable"
    }
  }

  public var difficultyLabel: String {
    difficultyText
  }

  public var playerCountValue: String {
    switch self {
    case .recreational: return "2-4"
    case .tournament: return "2-4"
    case .training: return "2-4"
    case .social: return "2-6"
    case .custom: return "1-6"
    }
  }

  public var estimatedTimeValue: String {
    switch self {
    case .recreational: return "15-25"
    case .tournament: return "20-45"
    case .training: return "8-15"
    case .social: return "10-30"
    case .custom: return "5-60"
    }
  }

  public var timeUnitLabel: String {
    switch self {
    case .recreational, .tournament, .training, .social, .custom:
      return "Minutes"
    }
  }

  // Default scoring settings (kept for backward compatibility)
  public var defaultWinningScore: Int {
    switch self {
    case .recreational: return 11
    case .tournament: return 11  // Can be customized to 15/21
    case .training: return 7
    case .social: return 11
    case .custom: return 11  // Default, but customizable
    }
  }

  public var defaultWinByTwo: Bool {
    switch self {
    case .recreational: return true
    case .tournament: return true
    case .training: return false  // Faster completion for practice
    case .social: return true
    case .custom: return true  // Default, but customizable
    }
  }

  // All game types follow official pickleball rules (kept for backward compatibility)
  public var defaultKitchenRule: Bool {
    switch self {
    case .recreational, .tournament, .training, .social, .custom:
      return true  // No exceptions - all use official rules
    }
  }

  public var defaultDoubleBounceRule: Bool {
    switch self {
    case .recreational, .tournament, .training, .social, .custom:
      return true  // No exceptions - all use official rules
    }
  }

  public var defaultSideSwitchingRule: SideSwitchingRule {
    switch self {
    case .recreational: return .never
    case .tournament: return .at6Points
    case .training: return .never  // In-game logic handles switching for training
    case .social: return .never  // In-game logic handles switching for social
    case .custom: return .never  // Default to never; user variations can override
    }
  }
  
  /// Returns the default GameRules for this game type
  /// Note: This creates a new GameRules instance each time. For persisted rules, use GameRules.createDefaultRules(for:)
  public var defaultRules: GameRules {
    return GameRules.createDefaultRules(for: self)
  }

  // Team configuration
  public var supportsTeamCustomization: Bool {
    switch self {
    case .recreational: return true  // 1-4 players per team
    case .tournament: return true  // 1-4 players per team
    case .training: return true  // 1-4 players per team
    case .social: return true  // 1-6 players per team for group formats
    case .custom: return true  // Full customization
    }
  }

  public var defaultTeamSize: Int {
    switch self {
    case .recreational: return 1  // Default to singles for v0.3 tests; variations can override
    case .tournament: return 2  // Doubles for competitive
    case .training: return 2  // Practice doubles most common
    case .social: return 2  // Doubles for social play
    case .custom: return 2  // Default, but customizable
    }
  }

  public var minTeamSize: Int {
    switch self {
    case .recreational: return 1
    case .tournament: return 1
    case .training: return 1
    case .social: return 1
    case .custom: return 1
    }
  }

  public var maxTeamSize: Int {
    switch self {
    case .recreational: return 2  // Singles and doubles only
    case .tournament: return 4  // Full range
    case .training: return 4  // Full range
    case .social: return 6  // Extended for group formats
    case .custom: return 6  // Extended for testing
    }
  }

  // Player labels based on team size
  public func playerLabel1(teamSize: Int = 0) -> String {
    let effectiveTeamSize = teamSize > 0 ? teamSize : defaultTeamSize
    return effectiveTeamSize == 1 ? "Player 1" : "Team 1"
  }

  public func playerLabel2(teamSize: Int = 0) -> String {
    let effectiveTeamSize = teamSize > 0 ? teamSize : defaultTeamSize
    return effectiveTeamSize == 1 ? "Player 2" : "Team 2"
  }

  public func shortPlayerLabel1(teamSize: Int = 0) -> String {
    let effectiveTeamSize = teamSize > 0 ? teamSize : defaultTeamSize
    return effectiveTeamSize == 1 ? "P1" : "T1"
  }

  public func shortPlayerLabel2(teamSize: Int = 0) -> String {
    let effectiveTeamSize = teamSize > 0 ? teamSize : defaultTeamSize
    return effectiveTeamSize == 1 ? "P2" : "T2"
  }

  // Legacy computed properties for backward compatibility
  public var playerLabel1: String {
    return playerLabel1(teamSize: 0)
  }

  public var playerLabel2: String {
    return playerLabel2(teamSize: 0)
  }

  public var shortPlayerLabel1: String {
    return shortPlayerLabel1(teamSize: 0)
  }

  public var shortPlayerLabel2: String {
    return shortPlayerLabel2(teamSize: 0)
  }

  // Testing value - provides different edge cases
  public var testingScenario: String {
    switch self {
    case .recreational:
      return "Standard rules, common recreational scoring patterns"
    case .tournament:
      return "Competitive rules, extended games, tournament scenarios"
    case .training:
      return "Quick completion, skill development focus"
    case .social:
      return "Group formats, social variations, flexible rules"
    case .custom:
      return "Edge cases, boundary testing, rule combinations"
    }
  }
}

// MARK: - Centralized Game Type Collections

extension GameType {
  /// All game types for comprehensive testing
  public static let allTypes: [GameType] = GameType.allCases

  /// Beginner-friendly game types
  public static let beginnerTypes: [GameType] = [.training, .recreational]

  /// Competitive game types
  public static let competitiveTypes: [GameType] = [.tournament]

  /// Social/group game types
  public static let socialTypes: [GameType] = [.social, .recreational]

  /// Quick start game types for immediate play
  public static let quickStartTypes: [GameType] = [.training, .recreational]

  /// Customizable game types
  public static let customizableTypes: [GameType] = [.recreational, .tournament, .social, .custom]

  /// Testing/development game types
  public static let testingTypes: [GameType] = [.training, .custom]

  /// Most commonly used game types
  public static let recommendedTypes: [GameType] = [.recreational, .training]

  /// Subset appropriate for quick-start on watchOS
  public static let watchSupportedCases: [GameType] = [.recreational, .training]
}

// MARK: - Game State Enums

public enum ServerPosition: String, CaseIterable, Codable, Sendable {
  case left = "left"
  case right = "right"

  public var displayName: String {
    switch self {
    case .left:
      return "Left"
    case .right:
      return "Right"
    }
  }
}

public enum SideOfCourt: String, CaseIterable, Codable, Sendable {
  case side1 = "side1"
  case side2 = "side2"

  public var displayName: String {
    switch self {
    case .side1:
      return "Side 1"
    case .side2:
      return "Side 2"
    }
  }
}

public enum GameState: String, CaseIterable, Codable, Sendable {
  case initial = "initial"
  case serving = "serving"
  case playing = "playing"
  case completed = "completed"
  case paused = "paused"

  public var displayName: String {
    switch self {
    case .initial:
      return "Not Started"
    case .serving:
      return "Serving"
    case .playing:
      return "Playing"
    case .completed:
      return "Completed"
    case .paused:
      return "Paused"
    }
  }

  /// Color associated with each game state for UI theming
  public var stateColor: GameStateColor {
    switch self {
    case .initial:
      return .readyToStart
    case .serving:
      return .attention
    case .playing:
      return .active
    case .completed:
      return .success
    case .paused:
      return .inactive
    }
  }
}

// MARK: - Game State Colors

/// Colors specifically designed for different game states
public enum GameStateColor: String, CaseIterable, Codable, Sendable {
  case readyToStart = "readyToStart"  // Blue - ready to begin
  case attention = "attention"        // Orange - attention needed
  case active = "active"              // Green - currently active
  case success = "success"            // Green - completed successfully
  case inactive = "inactive"          // Gray - paused/inactive


  public var displayName: String {
    switch self {
    case .readyToStart:
      return "Ready to Start"
    case .attention:
      return "Attention"
    case .active:
      return "Active"
    case .success:
      return "Success"
    case .inactive:
      return "Inactive"
    }
  }
}
