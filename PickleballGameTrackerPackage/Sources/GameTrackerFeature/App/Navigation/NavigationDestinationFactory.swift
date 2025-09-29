//
//  NavigationDestinationFactory.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 7/9/25.
//

import GameTrackerCore
import SwiftData
import SwiftUI

// MARK: - Navigation Destination Factory

struct NavigationDestinationFactory {

  // MARK: - GameSectionDestination Routing

  @MainActor @ViewBuilder
  static func createDestination(
    for destination: GameSectionDestination,
    navigationState: AppNavigationState
  ) -> some View {
    switch destination {
    case .quickStart, .allGames, .recommended, .beginnerFriendly, .advancedPlay, .testing,
      .customizable:
      CatalogSectionDetailView(destination: destination, navigationState: navigationState)
        .task { @MainActor in
          Log.event(
            .viewAppear, level: .debug, message: "Open section detail",
            metadata: ["title": destination.title])
          navigationState.trackSectionNavigation(destination.title)
        }
    case .gameDetail(let gameType):
      createGameDetailView(
        gameType: gameType,
        navigationState: navigationState
      )
    case .sectionDetail:
      CatalogSectionDetailView(destination: destination, navigationState: navigationState)
        .task { @MainActor in
          Log.event(
            .viewAppear, level: .debug, message: "Open custom section detail",
            metadata: ["title": destination.title])
          navigationState.trackSectionNavigation(destination.title)
        }
    }
  }

  // MARK: - GameType Routing

  @ViewBuilder
  static func createGameDetailView(
    gameType: GameType,
    navigationState: AppNavigationState
  ) -> some View {
    GameDetailDestinationView(gameType: gameType, navigationState: navigationState)
  }

}

// MARK: - Wrapped Destination View (uses Environment for DI)

@MainActor
private struct GameDetailDestinationView: View {
  @Environment(SwiftDataGameManager.self) private var gameManager
  @Environment(LiveGameStateManager.self) private var activeGameStateManager

  let gameType: GameType
  @Bindable var navigationState: AppNavigationState

  var body: some View {
    GameDetailView(
      gameType: gameType,
      onStartGame: { variation, matchup in
        Task {
          do {
            let config = GameStartConfiguration(
              gameType: gameType,
              teamSize: TeamSize(playersPerSide: matchup.teamSize) ?? .doubles,
              participants: {
                switch matchup.mode {
                case .players(let a, let b):
                  return Participants(side1: .players(a), side2: .players(b))
                case .teams(let t1, let t2):
                  return Participants(side1: .team(t1), side2: .team(t2))
                }
              }(),
              notes: nil,
              variation: variation
            )
            _ = try await activeGameStateManager.startNewGame(with: config)
            Log.event(
              .viewAppear,
              level: .info,
              message: "New game created via LiveGameStateManager",
              metadata: ["source": "Navigation"]
            )
          } catch {
            Log.error(error, event: .saveFailed, metadata: ["action": "startNewGame"])
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
