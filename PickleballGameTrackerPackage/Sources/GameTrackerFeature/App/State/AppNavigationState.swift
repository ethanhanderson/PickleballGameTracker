//
//  AppNavigationState.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 7/9/25.
//

import Foundation
import PickleballGameTrackerCorePackage
import SwiftUI

// MARK: - App Navigation State

@MainActor
@Observable
final class AppNavigationState {
  var navigationPath = NavigationPath()

  // MARK: - Games Tab Navigation Methods

  func navigateToSection(_ section: GameCatalog.GameSection) {
    navigationPath.append(GameSectionDestination.sectionDetail(section.title, section.gameTypes))
  }

  func navigateToSectionDetail(_ destination: GameSectionDestination) {
    navigationPath.append(destination)
  }

  func navigateToGameDetail(_ gameType: GameType) {
    navigationPath.append(GameSectionDestination.gameDetail(gameType))
  }

  // MARK: - History Tab Navigation Methods

  func navigateToGameDetail(game: Game) {
    navigationPath.append(GameHistoryDestination.gameDetail(game))
  }

  // MARK: - Navigation Stack Management

  func popToRoot() {
    navigationPath = NavigationPath()
  }

  func popToGamesHome() {
    // Remove all navigation items to go back to the root (games home)
    navigationPath = NavigationPath()
  }

  func popLast() {
    if !navigationPath.isEmpty {
      navigationPath.removeLast()
    }
  }

  // MARK: - Navigation State Query

  var isAtRoot: Bool {
    navigationPath.isEmpty
  }

  var navigationDepth: Int {
    navigationPath.count
  }

  // MARK: - Navigation Analytics

  func trackGameDetailNavigation(_ gameType: GameType) {
    Log.event(
      .viewAppear, level: .debug, message: "Game opened",
      metadata: ["gameType": gameType.displayName, "depth": String(navigationDepth)])
  }

  func trackSectionNavigation(_ sectionTitle: String) {
    Log.event(
      .viewAppear, level: .debug, message: "Section opened",
      metadata: ["title": sectionTitle, "depth": String(navigationDepth)])
  }

  func trackNavigationReset() {
    Log.event(.viewAppear, level: .debug, message: "Navigation reset to root")
  }
}
