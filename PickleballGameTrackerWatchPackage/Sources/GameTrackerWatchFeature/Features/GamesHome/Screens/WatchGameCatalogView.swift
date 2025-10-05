import GameTrackerCore
//  WatchGameCatalogView.swift
//  Pickleball Score Tracking Watch App
//
//  Created by Ethan Anderson on 7/9/25.
//

import SwiftData
import SwiftUI

public struct WatchGameCatalogView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(LiveGameStateManager.self) private var activeGameStateManager
  @Environment(SwiftDataGameManager.self) private var gameManager

  private let gameTypes = GameType.allCases
  @State private var currentGameTypeIndex = 0
  @State private var isCreatingGame = false

  private var currentGameType: GameType {
    gameTypes[currentGameTypeIndex]
  }

  public init() {}

  public var body: some View {
    if let activeGame = activeGameStateManager.currentGame {
      WatchActiveGameView(
        game: activeGame,
        onCompleted: {
          // Ensure shared state is cleared so we return to the catalog
          activeGameStateManager.clearCurrentGame()
        }
      )
      // When leaving the active game for any reason, ensure catalog can reappear
      .onDisappear {
        if activeGameStateManager.currentGame?.isCompleted == true {
          activeGameStateManager.clearCurrentGame()
        }
      }
    } else {
      NavigationStack {
        TabView(selection: $currentGameTypeIndex) {
          ForEach(Array(gameTypes.enumerated()), id: \.element) {
            index,
            gameType in
            GameTypeCard(gameType: gameType)
              .containerBackground(
                gameType.color.gradient,
                for: .tabView
              )
              .tag(index)
          }
        }
        .tabViewStyle(.verticalPage)
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            Button {
              // TODO: Implement stats navigation
              Log.event(
                .actionTapped, level: .debug, message: "Statistics tapped",
                metadata: ["platform": "watchOS"])
            } label: {
              Image(systemName: "chart.bar.fill")
                .foregroundStyle(.white)
            }
          }

          ToolbarItem(placement: .topBarTrailing) {
            Button {
              // TODO: Implement history navigation
              Log.event(
                .actionTapped, level: .debug, message: "History tapped",
                metadata: ["platform": "watchOS"])
            } label: {
              Image(systemName: "clock")
                .foregroundStyle(.white)
            }
          }

          ToolbarItemGroup(placement: .bottomBar) {
            Button {
              // TODO: Implement starting a game variation
            } label: {
              Image(systemName: "list.bullet")
            }

            Button {
              startNewGame()
            } label: {
              if isCreatingGame {
                ProgressView()
                  .progressViewStyle(
                    CircularProgressViewStyle(tint: .white)
                  )
                  .scaleEffect(0.8)
              } else {
                Image(systemName: "play.fill")
                  .foregroundStyle(.white)
              }
            }
            .controlSize(.large)
            .tint(currentGameType.color.opacity(0.6))
            .disabled(isCreatingGame)

            Button {
              // TODO: Implement
            } label: {
              Image(systemName: "gearshape.fill")
            }
          }
        }
      }
      .task {
        // Configure shared active game manager with SwiftData context and manager
        if activeGameStateManager.gameManager == nil { activeGameStateManager.configure(gameManager: gameManager) }
        // Ensure device sync is enabled so iPhone sees watch-created games
        activeGameStateManager.setSyncEnabled(true)
      }
      .onChange(of: activeGameStateManager.currentGame) { _, newValue in
        // Reactively present active game when it becomes available (e.g., from phone)
        if newValue != nil {
          // No-op: body will switch to WatchActiveGameView automatically
        }
      }
    }
  }

  // MARK: - Actions

  private func startNewGame() {
    guard !isCreatingGame else { return }

    isCreatingGame = true

    Task {
      do {
        let newGame = try await gameManager.createGame(
          type: currentGameType
        )

        await MainActor.run {
          // Set via shared state manager so both devices stay in sync
          activeGameStateManager.setCurrentGame(newGame)
          isCreatingGame = false
        }

        Log.event(
          .gameResumed, level: .info, message: "Started game on watch",
          context: .current(gameId: newGame.id), metadata: ["gameType": currentGameType.displayName]
        )
      } catch {
        await MainActor.run {
          isCreatingGame = false
        }
        Log.error(
          error, event: .saveFailed, metadata: ["platform": "watchOS", "action": "startNewGame"])
      }
    }
  }
}

// GameTypeCard extracted to Components/GameTypeCard.swift

// MARK: - Previews

#Preview("Game Catalog") {
  let container = PreviewContainers.standard()
  let (gameManager, liveGameManager) = PreviewContainers.managers(for: container)
  
  WatchGameCatalogView()
    .modelContainer(container)
    .environment(liveGameManager)
    .environment(gameManager)
}
