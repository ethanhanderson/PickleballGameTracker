//
//  Game+SwiftUI.swift
//  SharedGameCore
//
//  SwiftUI-specific extensions for Game model
//  These extensions contain UI-related computed properties that depend on SwiftUI types
//

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
      
    case .anonymous:
      break
    }
    
    return [
      TeamConfig(teamNumber: 1, teamName: "Team 1"),
      TeamConfig(teamNumber: 2, teamName: "Team 2")
    ]
  }

  /// Convenience property for views without ModelContext
  public var teamsWithLabels: [TeamConfig] {
    // Fallback to default labels
    return [
      TeamConfig(teamNumber: 1, teamName: "Team 1"),
      TeamConfig(teamNumber: 2, teamName: "Team 2")
    ]
  }

  /// Get the accent color for a team using the current roster associations
  public func teamTintColor(for teamNumber: Int, context: ModelContext) -> Color {
    switch participantMode {
    case .teams:
      let team = (teamNumber == 1) ? resolveSide1Team(context: context) : resolveSide2Team(context: context)
      if let team { return team.accentColor }
    case .players:
      let players = (teamNumber == 1) ? resolveSide1Players(context: context) : resolveSide2Players(context: context)
      if let first = players?.first { return first.accentColor }
    case .anonymous:
      break
    }
    // Fallback to game type color if roster cannot be resolved
    return gameType.color
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
