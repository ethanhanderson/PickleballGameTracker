//
//  AppNavigationState.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 7/9/25.
//

import Foundation
import GameTrackerCore
import SwiftUI

// MARK: - App Navigation State

@MainActor
@Observable
final class AppNavigationState {
  var navigationPath = NavigationPath()

  // MARK: - Games Tab Navigation Methods

  func navigateToSection(_ section: GameCatalog.CatalogSectionInfo) {
    navigationPath.append(GameSectionDestination.sectionDetail(section.title, section.gameTypes))
    trackSectionNavigation(section.title)
  }

  func navigateToSectionDetail(_ destination: GameSectionDestination) {
    navigationPath.append(destination)
  }

  func navigateToGameDetail(_ gameType: GameType) {
    navigationPath.append(GameSectionDestination.gameDetail(gameType))
    trackGameDetailNavigation(gameType)
  }

  // MARK: - History Tab Navigation Methods

  func navigateToHistoryDetail(gameId: UUID) {
    navigationPath.append(GameHistoryDestination.gameDetail(gameId))
    trackHistoryNavigation(gameId)
  }

  func navigateToGameDetail(game: Game) {
    navigateToHistoryDetail(gameId: game.id)
  }

  func navigateToArchive() {
    navigationPath.append(GameHistoryDestination.archiveList)
    Log.event(.actionTapped, level: .info, message: "history → archive")
  }

  // MARK: - Statistics Tab Navigation Methods

  func navigateToStatDetail(_ destination: StatDetailDestination) {
    navigationPath.append(destination)
    trackStatNavigation(destination)
  }

  // MARK: - Roster Tab Navigation Methods

  func navigateToRosterDetail(_ destination: RosterDestination) {
    navigationPath.append(destination)
    trackRosterNavigation(destination)
  }

  // MARK: - Navigation Stack Management

  func popToRoot() {
    navigationPath = NavigationPath()
    trackNavigationReset()
  }

  func popToGamesHome() {
    navigationPath = NavigationPath()
    trackNavigationReset()
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

  var canGoBack: Bool {
    !navigationPath.isEmpty
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

  func trackHistoryNavigation(_ gameId: UUID) {
    Log.event(
      .actionTapped, level: .info,
      message: "history → completed",
      context: .current(gameId: gameId))
  }

  func trackStatNavigation(_ destination: StatDetailDestination) {
    let destinationName: String
    switch destination {
    case .winRate: destinationName = "winRate"
    case .serveWin: destinationName = "serveWin"
    case .trends: destinationName = "trends"
    case .streaks: destinationName = "streaks"
    }
    Log.event(
      .actionTapped, level: .info,
      message: "statistics → \(destinationName)",
      metadata: ["depth": String(navigationDepth)])
  }

  func trackRosterNavigation(_ destination: RosterDestination) {
    switch destination {
    case .identity(let identity):
      let identityType: String
      switch identity {
      case .player:
        identityType = "player"
      case .team:
        identityType = "team"
      }
      Log.event(
        .actionTapped, level: .info,
        message: "roster → identity",
        metadata: ["type": identityType, "depth": String(navigationDepth)])
    }
  }

  func trackNavigationReset() {
    Log.event(.viewAppear, level: .debug, message: "Navigation reset to root")
  }
}

// MARK: - State Restoration

extension AppNavigationState {
  func saveState() {
    Log.event(
      .appLaunch, level: .debug,
      message: "Navigation state saved",
      metadata: ["depth": String(navigationDepth)])
  }

  func restoreState() {
    Log.event(.appLaunch, level: .debug, message: "Navigation state restored")
  }
}
