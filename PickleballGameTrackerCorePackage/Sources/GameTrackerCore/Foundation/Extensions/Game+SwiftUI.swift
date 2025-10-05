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
    // Try to resolve from stored participant data
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
    
    // Fallback: parse from variation name (for legacy games)
    if let name = gameVariation?.name {
      let parts = name.split(separator: " vs ")
      if parts.count == 2 {
        let a = String(parts[0]).trimmingCharacters(in: .whitespacesAndNewlines)
        let b = String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
        if !a.isEmpty && !b.isEmpty {
          return [
            TeamConfig(teamNumber: 1, teamName: a),
            TeamConfig(teamNumber: 2, teamName: b)
          ]
        }
      }
    }
    
    // Final fallback
    return [
      TeamConfig(teamNumber: 1, teamName: "Team 1"),
      TeamConfig(teamNumber: 2, teamName: "Team 2")
    ]
  }

  /// Convenience property for views without ModelContext (uses parsing fallback)
  public var teamsWithLabels: [TeamConfig] {
    // Legacy behavior - parse from variation name
    if let name = gameVariation?.name {
      let parts = name.split(separator: " vs ")
      if parts.count == 2 {
        let a = String(parts[0]).trimmingCharacters(in: .whitespacesAndNewlines)
        let b = String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
        if !a.isEmpty && !b.isEmpty {
          return [
            TeamConfig(teamNumber: 1, teamName: a),
            TeamConfig(teamNumber: 2, teamName: b)
          ]
        }
      }
    }
    return [
      TeamConfig(teamNumber: 1, teamName: "Team 1"),
      TeamConfig(teamNumber: 2, teamName: "Team 2")
    ]
  }

  /// Get the tint color for a team
  public func teamTintColor(for teamNumber: Int) -> Color {
    let defaultColor = Color.green
    return defaultColor
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
  /// The tint color for the player's icon
  public var iconTintColorValue: Color? {
    if isGuest {
      return .green
    }
    return accentColor
  }

  /// The accent color for the player
  public var accentColor: Color? {
    get {
      guard let stored = accentColorStored else { return nil }
      return Color(.sRGB,
                   red: Double(stored.red),
                   green: Double(stored.green),
                   blue: Double(stored.blue),
                   opacity: Double(stored.alpha))
    }
    set {
      if let c = newValue {
        // Convert to sRGB components via UIColor bridging
        #if canImport(UIKit)
        let ui = UIColor(c)
        if let cg = ui.cgColor.converted(to: CGColorSpace(name: CGColorSpace.sRGB)!, intent: .defaultIntent, options: nil),
           let comps = cg.components, comps.count >= 3 {
          let a = comps.count >= 4 ? comps[3] : 1
          accentColorStored = StoredRGBAColor(
            red: Float(comps[0]),
            green: Float(comps[1]),
            blue: Float(comps[2]),
            alpha: Float(a)
          )
        }
        #endif
      } else {
        accentColorStored = nil
      }
    }
  }

  /// A default color for the player based on their skill level
  public var defaultColor: Color {
    if isGuest {
      return .green
    }
    switch skillLevel {
    case .beginner:
      return .green
    case .intermediate:
      return .blue
    case .advanced:
      return .orange
    case .expert:
      return .red
    case .unknown:
      return .gray
    }
  }

  /// The primary color to use for the player (custom tint color or default)
  public var primaryColor: Color {
    iconTintColorValue ?? defaultColor
  }
}

// MARK: - TeamProfile SwiftUI Extensions

extension TeamProfile {
  /// The tint color for the team's icon
  public var iconTintColorValue: Color? {
    accentColor
  }

  /// The accent color for the team
  public var accentColor: Color? {
    get {
      guard let stored = accentColorStored else { return nil }
      return Color(.sRGB,
                   red: Double(stored.red),
                   green: Double(stored.green),
                   blue: Double(stored.blue),
                   opacity: Double(stored.alpha))
    }
    set {
      if let c = newValue {
        #if canImport(UIKit)
        let ui = UIColor(c)
        if let cg = ui.cgColor.converted(to: CGColorSpace(name: CGColorSpace.sRGB)!, intent: .defaultIntent, options: nil),
           let comps = cg.components, comps.count >= 3 {
          let a = comps.count >= 4 ? comps[3] : 1
          accentColorStored = StoredRGBAColor(
            red: Float(comps[0]),
            green: Float(comps[1]),
            blue: Float(comps[2]),
            alpha: Float(a)
          )
        }
        #endif
      } else {
        accentColorStored = nil
      }
    }
  }

  /// A default color for the team
  public var defaultColor: Color {
    .green
  }

  /// The primary color to use for the team (custom tint color or default)
  public var primaryColor: Color {
    iconTintColorValue ?? defaultColor
  }
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
