//  WatchGameCatalogView.swift
//  Pickleball Score Tracking Watch App
//
//  Created by Ethan Anderson on 7/9/25.
//

import CorePackage
import SwiftData
import SwiftUI

public struct WatchGameCatalogView: View {
  @Environment(\.modelContext) private var modelContext

  private let gameTypes = GameType.allCases
  @State private var currentGameTypeIndex = 0
  @State private var gameManager = SwiftDataGameManager()
  @State private var isCreatingGame = false
  @State private var activeGameStateManager = ActiveGameStateManager.shared

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
                DesignSystem.Colors.gameType(gameType).gradient,
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
                .foregroundColor(.white)
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
                .foregroundColor(.white)
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
                  .foregroundColor(.white)
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
      .navigationTint()
      .task {
        // Configure shared active game manager with SwiftData context and manager
        if activeGameStateManager.gameManager == nil {
          activeGameStateManager.configure(with: modelContext, gameManager: gameManager)
        }
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
  WatchGameCatalogView()
    .modelContainer(
      try! PreviewGameData.createPreviewContainer(with: [
        PreviewGameData.midGame
      ]))
}
