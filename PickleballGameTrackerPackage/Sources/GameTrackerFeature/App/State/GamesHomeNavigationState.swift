//
//  GamesHomeNavigationState.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 7/9/25.
//

import Foundation
import PickleballGameTrackerCorePackage
import SwiftUI

// MARK: - Games Home Navigation State

@MainActor
@Observable
final class GamesHomeNavigationState {
  var navigationPath = NavigationPath()

  // MARK: - Navigation Methods

  func navigateToSection(_ section: GameCatalog.GameSection) {
    navigationPath.append(GameSectionDestination.sectionDetail(section.title, section.gameTypes))
  }

  func navigateToGameDetail(_ gameType: GameType) {
    // Clear the navigation stack and navigate directly to game detail
    // This ensures we only have: Games Home -> Game Detail (no intermediate views)
    clearAndNavigateToGameDetail(gameType)
  }

  // MARK: - Navigation Stack Management

  private func clearAndNavigateToGameDetail(_ gameType: GameType) {
    navigationPath = NavigationPath()
    navigationPath.append(GameSectionDestination.gameDetail(gameType))
  }

  func popToRoot() {
    navigationPath = NavigationPath()
  }

  func popLast() {
    if !navigationPath.isEmpty {
      navigationPath.removeLast()
    }
  }

  // MARK: - Navigation State Query

  var currentDepth: Int {
    navigationPath.count
  }

  var isAtRoot: Bool {
    navigationPath.isEmpty
  }

  var canGoBack: Bool {
    !navigationPath.isEmpty
  }

  // MARK: - Navigation Analytics

  func trackSectionNavigation(_ section: GameCatalog.GameSection) {
    NavigationAnalytics.trackSectionNavigation(section)
  }

  func trackGameDetailNavigation(_ gameType: GameType) {
    NavigationAnalytics.trackGameDetailNavigation(gameType)
  }
}

// MARK: - Navigation State Persistence

extension GamesHomeNavigationState {
  private static let navigationStateKey = "GamesHomeNavigationState"

  func saveNavigationState() {
    // Save current navigation path for restoration
    // Note: This is a placeholder for future implementation
    // NavigationPath doesn't directly support serialization
    Log.event(
      .appLaunch, level: .debug, message: "Navigation state saved",
      metadata: ["depth": String(currentDepth)])
  }

  func restoreNavigationState() {
    // Restore saved navigation path
    // Note: This is a placeholder for future implementation
    Log.event(.appLaunch, level: .debug, message: "Navigation state restored")
  }
}

// MARK: - Navigation Analytics

struct NavigationAnalytics {
  static func trackSectionNavigation(_ section: GameCatalog.GameSection) {
    Log.event(
      .viewAppear, level: .debug, message: "Section opened", metadata: ["title": section.title])
  }

  static func trackGameDetailNavigation(_ gameType: GameType) {
    Log.event(
      .viewAppear, level: .debug, message: "Game opened",
      metadata: ["gameType": gameType.displayName])
  }
}
