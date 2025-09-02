//
//  NavigationDestinationFactory.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 7/9/25.
//

import CorePackage
import SwiftData
import SwiftUI

// MARK: - Navigation Destination Factory

struct NavigationDestinationFactory {

  // MARK: - GameSectionDestination Routing

  @MainActor @ViewBuilder
  static func createDestination(
    for destination: GameSectionDestination,
    modelContext: ModelContext,
    navigationState: AppNavigationState
  ) -> some View {
    switch destination {
    case .quickStart, .allGames, .recommended, .beginnerFriendly, .advancedPlay, .testing,
      .customizable:
      GameSectionDetailView(
        destination: destination,
        modelContext: modelContext,
        navigationState: navigationState
      )
      .task { @MainActor in
        Log.event(
          .viewAppear, level: .debug, message: "Open section detail",
          metadata: ["title": destination.title])
        navigationState.trackSectionNavigation(destination.title)
      }
    case .gameDetail(let gameType):
      createGameDetailView(
        gameType: gameType,
        modelContext: modelContext,
        navigationState: navigationState
      )
    case .sectionDetail(let title, let gameTypes):
      GameSectionDetailView(
        sectionTitle: title,
        gameTypes: gameTypes,
        modelContext: modelContext,
        navigationState: navigationState
      )
      .task { @MainActor in
        Log.event(
          .viewAppear, level: .debug, message: "Open custom section detail",
          metadata: ["title": title])
        navigationState.trackSectionNavigation(title)
      }
    }
  }

  // MARK: - GameType Routing

  @ViewBuilder
  static func createGameDetailView(
    gameType: GameType,
    modelContext: ModelContext,
    navigationState: AppNavigationState
  ) -> some View {
    GameDetailDestinationView(gameType: gameType, navigationState: navigationState)
  }

}

// MARK: - Wrapped Destination View (uses Environment for DI)

@MainActor
private struct GameDetailDestinationView: View {
  @Environment(SwiftDataGameManager.self) private var gameManager
  @Environment(ActiveGameStateManager.self) private var activeGameStateManager

  let gameType: GameType
  @Bindable var navigationState: AppNavigationState

  var body: some View {
    GameDetailView(
      gameType: gameType,
      onStartGame: { variation in
        Task {
          do {
            let newGame = try await gameManager.createGame(variation: variation)
            activeGameStateManager.setCurrentGame(newGame)
            Log.event(
              .viewAppear,
              level: .info,
              message: "New game created and set current (paused)",
              context: .current(gameId: newGame.id),
              metadata: ["source": "Navigation", "gameId": newGame.id.uuidString]
            )
          } catch {
            Log.error(error, event: .saveFailed, metadata: ["action": "createAndStartGame"])
          }
        }
      }
    )
    .onAppear {
      Log.event(
        .viewAppear, level: .debug, message: "Open game detail",
        metadata: ["gameType": gameType.displayName])
      navigationState.trackGameDetailNavigation(gameType)
    }
  }
}
