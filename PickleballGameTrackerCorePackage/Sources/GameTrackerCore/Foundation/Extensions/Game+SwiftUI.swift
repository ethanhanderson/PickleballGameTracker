import SwiftUI
import SwiftData
import CoreGraphics
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Game SwiftUI Extensions

extension Game {
  /// Configuration for each team to support dynamic UI rendering
  public struct TeamConfig: Identifiable {
    public var id: Int { teamNumber }
    public let teamNumber: Int
    public let teamName: String
  }

  /// Array of team configurations for dynamic UI rendering
  /// Requires ModelContext to resolve participant names from roster
  public func teamsWithLabels(context: ModelContext) -> [TeamConfig] {
    // When the model is detached (e.g., deleted or view dismissed), avoid fault resolution
    guard !isDetachedFromContext else { return [] }

    switch participantMode {
    case .players:
      if let side1Players = resolveSide1Players(context: context),
         let side2Players = resolveSide2Players(context: context) {
        let side1Name = side1Players.map { $0.name }.joined(separator: " & ")
        let side2Name = side2Players.map { $0.name }.joined(separator: " & ")
        return [
          TeamConfig(teamNumber: 1, teamName: side1Name),
          TeamConfig(teamNumber: 2, teamName: side2Name)
        ]
      }
      
    case .teams:
      if let team1 = resolveSide1Team(context: context),
         let team2 = resolveSide2Team(context: context) {
        return [
          TeamConfig(teamNumber: 1, teamName: team1.name),
          TeamConfig(teamNumber: 2, teamName: team2.name)
        ]
      }
    }
    // If participants cannot be resolved, prefer an empty array over crashing
    return []
  }

  /// Convenience property for views without ModelContext
  public var teamsWithLabels: [TeamConfig] {
    // No context available — return an empty list to avoid accidental crashes
    []
  }

  /// Get the accent color for a team using the current roster associations
  public func teamTintColor(for teamNumber: Int, context: ModelContext) -> Color {
    // When the model is detached (e.g., deleted or view dismissed), avoid fault resolution
    guard !isDetachedFromContext else { return .accentColor }

    switch participantMode {
    case .teams:
      let team = (teamNumber == 1) ? resolveSide1Team(context: context) : resolveSide2Team(context: context)
      if let team { return team.accentColor }
    case .players:
      let players = (teamNumber == 1) ? resolveSide1Players(context: context) : resolveSide2Players(context: context)
      if let first = players?.first { return first.accentColor }
    }
    // Fallback gracefully if a tint cannot be resolved
    return .accentColor
  }
}

// MARK: - Game State Helpers

extension Game {
  /// Get primary game events for UI display
  public var primaryGameEvents: [GameEventType] {
    [
      .serviceFault,
      .ballOutOfBounds,
      .kitchenViolation,
      .ballHitNet,
      .doubleBounce,
      .ballInKitchenOnServe,
    ]
  }

  /// Get the score for a specific team
  public func score(for teamNumber: Int) -> Int {
    teamNumber == 1 ? score1 : score2
  }

  /// Check if a team is at match point
  public func isAtMatchPoint(for teamNumber: Int) -> Bool {
    isAtMatchPoint(team: teamNumber)
  }

  /// Check if a team is currently serving
  public func isServing(teamNumber: Int) -> Bool {
    currentServer == teamNumber
  }

  /// Check if a team is the winning team (only valid when game is completed)
  public func isWinningTeam(teamNumber: Int) -> Bool {
    guard isCompleted else { return false }
    return (teamNumber == 1 && score1 > score2)
        || (teamNumber == 2 && score2 > score1)
  }

  /// Check if serving indicator should be visible for a team
  public func shouldShowServingIndicator(for teamNumber: Int) -> Bool {
    isServing(teamNumber: teamNumber) && !isCompleted
  }
}

// MARK: - Safe Accessors for Detached Models

extension Game {
  /// True when this `Game` instance is no longer attached to a `ModelContext`.
  /// UI should avoid touching SwiftData-backed properties when detached.
  public var isDetachedFromContext: Bool { modelContext == nil }

  /// Safe accessor for `gameState` that avoids fault resolution on detached objects.
  /// Falls back to `.completed` so UI disables live-only affordances while dismissing.
  public var safeGameState: GameState { isDetachedFromContext ? .completed : gameState }

  /// Safe accessor for `isCompleted` that treats detached objects as completed.
  public var safeIsCompleted: Bool { isDetachedFromContext ? true : isCompleted }
}

// MARK: - PlayerProfile SwiftUI Extensions

extension PlayerProfile {
  /// Non-optional accent color derived from stored RGBA
  public var accentColor: Color {
    accentColorStored.swiftUIColor
  }

  /// For UI usages expecting a primary color, use accentColor
  public var primaryColor: Color { accentColor }
}

// MARK: - TeamProfile SwiftUI Extensions

extension TeamProfile {
  /// Non-optional accent color derived from stored RGBA
  public var accentColor: Color {
    accentColorStored.swiftUIColor
  }

  /// For UI usages expecting a primary color, use accentColor
  public var primaryColor: Color { accentColor }
}

// MARK: - GameType SwiftUI Extensions

extension GameType {
  /// Color associated with the game type
  public var color: Color {
    switch self {
    case .recreational:
      return .green
    case .tournament:
      return .blue
    case .training:
      return .orange
    case .social:
      return .purple
    case .custom:
      return .gray
    }
  }
}

// MARK: - GameTypePreset SwiftUI Extensions

extension GameTypePreset {
  /// Color associated with the preset
  public var color: Color {
    if let stored = accentColorStored {
      return Color(
        .sRGB,
        red: Double(stored.red),
        green: Double(stored.green),
        blue: Double(stored.blue),
        opacity: Double(stored.alpha)
      )
    }
    return gameType.color
  }

  /// Primary color for the preset
  public var primaryColor: Color {
    color
  }
}
