//
//  ActiveGameToolbar.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 7/9/25.
//

import SharedGameCore
import SwiftUI

struct ActiveGameToolbar: ToolbarContent {
  let game: Game
  let gameManager: SwiftDataGameManager
  let activeGameStateManager: ActiveGameStateManager

  @Environment(\.dismiss) private var dismiss
  @State private var showEndGameConfirmation = false

  var body: some ToolbarContent {
    ToolbarItemGroup {
      Button {
        // TODO: Show game info
      } label: {
        Image(systemName: "info")
          .foregroundStyle(.primary)
      }

      Button {
        // TODO: Show event log
      } label: {
        Image(systemName: "list.bullet.rectangle.portrait")
          .foregroundStyle(.primary)
      }

      Menu {
        Section("Display Options") {
          Button {
            // TODO: Toggle timer visibility
          } label: {
            Label("Show Timer", systemImage: "timer")
          }

          Button {
            // TODO: Toggle score controls
          } label: {
            Label("Show Score Controls", systemImage: "numbers.rectangle")
          }

          Button {
            // TODO: Toggle serving indicator
          } label: {
            Label("Show Serving Indicator", systemImage: "tennis.racket")
          }
        }

        Section("Layout") {
          Button {
            // TODO: Switch to compact view
          } label: {
            Label("Compact View", systemImage: "rectangle.compress.vertical")
          }

          Button {
            // TODO: Switch to expanded view
          } label: {
            Label("Expanded View", systemImage: "rectangle.expand.vertical")
          }
        }

        Section("Game Settings") {
          Button {
            // TODO: Edit game rules
          } label: {
            Label("Game Rules", systemImage: "list.clipboard")
          }

          Button {
            // TODO: Sound settings
          } label: {
            Label("Sound Effects", systemImage: "speaker.wave.2")
          }

          Button {
            // TODO: Haptic feedback settings
          } label: {
            Label("Haptic Feedback", systemImage: "iphone.radiowaves.left.and.right")
          }
        }

        Section("Serving Control") {
          Button {
            switchServer()
          } label: {
            Label("Switch Server", systemImage: "arrow.2.squarepath")
          }
          .disabled(game.isCompleted || game.gameState == .playing)

          Button {
            setServerToTeam1()
          } label: {
            Label("Team 1 Serves", systemImage: "1.circle")
          }
          .disabled(game.isCompleted || game.currentServer == 1 || game.gameState == .playing)

          Button {
            setServerToTeam2()
          } label: {
            Label("Team 2 Serves", systemImage: "2.circle")
          }
          .disabled(game.isCompleted || game.currentServer == 2 || game.gameState == .playing)
        }

        Section("Game Actions") {
          Button(role: .destructive) {
            showEndGameConfirmation = true
          } label: {
            Label("End Game", systemImage: "flag.checkered")
          }
        }
      } label: {
        Image(systemName: "ellipsis")
          .foregroundStyle(.primary)
      }
      .confirmationDialog(
        "End Game",
        isPresented: $showEndGameConfirmation,
        titleVisibility: .visible
      ) {
        Button("End Game", role: .destructive) {
          endGame()
        }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text("Are you sure you want to end this game? This cannot be undone.")
      }
    }
  }

  // MARK: - Actions

  private func endGame() {
    Task { @MainActor in
      do {
        // Complete centrally so it syncs to watch and persists in both histories
        try await activeGameStateManager.completeCurrentGame()
        // Dismiss the active game view sheet
        dismiss()
      } catch {
        Log.error(
          error, event: .saveFailed, context: .current(gameId: game.id),
          metadata: ["action": "endGame"])
      }
    }
  }

  // MARK: - Server Control Actions

  private func switchServer() {
    Task { @MainActor in
      do {
        try await gameManager.switchServer(in: game)
      } catch {
        Log.error(
          error, event: .serverSwitched, context: .current(gameId: game.id),
          metadata: ["action": "switchServer"])
      }
    }
  }

  private func setServerToTeam1() {
    Task { @MainActor in
      do {
        try await gameManager.setServer(to: 1, in: game)
      } catch {
        Log.error(
          error, event: .serverSwitched, context: .current(gameId: game.id),
          metadata: ["action": "setServer", "team": "1"])
      }
    }
  }

  private func setServerToTeam2() {
    Task { @MainActor in
      do {
        try await gameManager.setServer(to: 2, in: game)
      } catch {
        Log.error(
          error, event: .serverSwitched, context: .current(gameId: game.id),
          metadata: ["action": "setServer", "team": "2"])
      }
    }
  }
}

// MARK: - Preview

#Preview("Toolbar Demo") {
  NavigationStack {
    VStack {
      Text("Preview Content")
        .padding()
    }
    .toolbar {
      ActiveGameToolbar(
        game: PreviewGameData.midGame,
        gameManager: PreviewGameData.gameManager,
        activeGameStateManager: ActiveGameStateManager.shared
      )
    }
    .navigationTitle("Active Game")
    .navigationBarTitleDisplayMode(.inline)
  }
}
