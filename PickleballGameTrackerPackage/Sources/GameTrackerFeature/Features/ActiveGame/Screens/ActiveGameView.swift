//
//  ActiveGameView.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 7/9/25.
//

import CorePackage
import SwiftData
import SwiftUI

@MainActor
struct ActiveGameView: View {
  @Bindable var game: Game
  let gameManager: SwiftDataGameManager
  @Environment(ActiveGameStateManager.self) private var activeGameStateManager
  let onDismiss: (() -> Void)?

  @State private var isResetting: Bool = false
  @State private var isToggling: Bool = false
  @State private var pulseAnimation: Bool = false
  @State private var resetTrigger: Bool = false
  @State private var playPauseTrigger: Bool = false

  // Removed: @State private var isGameActive: Bool = false
  // Now using: activeGameStateManager.isGameActive

  var body: some View {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
      TimerCard(
        game: game,
        formattedElapsedTime: activeGameStateManager
          .formattedElapsedTimeWithCentiseconds,
        isTimerPaused: !activeGameStateManager.isTimerRunning,
        isGameActive: activeGameStateManager.isGameActive,
        isResetting: isResetting,
        isToggling: isToggling,
        pulseAnimation: pulseAnimation,
        resetTrigger: resetTrigger,
        playPauseTrigger: playPauseTrigger,
        onResetTimer: resetTimer,
        onToggleTimer: toggleTimer
      )

      ServeBezel(
        game: game,
        currentServeNumber: activeGameStateManager.currentServeNumber
      )
      .padding(.horizontal, DesignSystem.Spacing.lg)

      // Team Score Cards
      VStack(spacing: DesignSystem.Spacing.md) {
        TeamScoreCard(
          game: game,
          teamNumber: 1,
          teamName: "Team 1",
          gameManager: gameManager,
          isGameActive: activeGameStateManager.isGameActive
        )

        TeamScoreCard(
          game: game,
          teamNumber: 2,
          teamName: "Team 2",
          gameManager: gameManager,
          isGameActive: activeGameStateManager.isGameActive
        )
      }
      .padding(.horizontal, DesignSystem.Spacing.lg)
      .frame(maxHeight: .infinity)

      // Game Control Button
      GameControlButton(
        game: game,
        isGamePaused: !activeGameStateManager.isGameActive,
        isGameInitial: activeGameStateManager.isGameInitial,
        isToggling: isToggling,
        isResetting: isResetting,
        onToggleGame: toggleGame
      )
      .padding(.bottom, DesignSystem.Spacing.lg)
      .accessibilityIdentifier("ActiveGameView.toggleGameButton")
    }
    .padding(.top, DesignSystem.Spacing.lg)
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity,
      alignment: .topLeading
    )
    .task {
      // Ensure the game is set as the current game in state manager
      activeGameStateManager.setCurrentGame(game)
      // State manager automatically initializes game control state
      // Games start in initial/paused state by default - user must press "Start Game" button
    }
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .principal) {
        HStack(spacing: DesignSystem.Spacing.sm) {
          Image(systemName: game.gameType.iconName)
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(DesignSystem.Colors.gameType(game.gameType).gradient)
            .shadow(
              color: DesignSystem.Colors.gameType(game.gameType).opacity(0.3),
              radius: 2,
              x: 0,
              y: 1
            )

          Text(game.gameType.displayName)
            .font(DesignSystem.Typography.title3)
            .fontWeight(.semibold)
            .foregroundColor(DesignSystem.Colors.textPrimary)
        }
      }

      ActiveGameToolbar(
        game: game, gameManager: gameManager, activeGameStateManager: activeGameStateManager)
    }
  }

  // MARK: - Timer Actions

  private func toggleTimer() {
    guard !isToggling && !isResetting else { return }

    Task { @MainActor in
      isToggling = true

      // Trigger play/pause button bounce effect
      playPauseTrigger.toggle()

      // Use the dedicated timer toggle method
      activeGameStateManager.toggleTimer()

      // Brief delay to ensure toggle operation completes
      try? await Task.sleep(for: .milliseconds(100))

      isToggling = false
    }
  }

  private func resetTimer() {
    guard !isResetting && !isToggling else { return }

    Task { @MainActor in
      // Preserve the current game and timer state
      let wasGameActive = activeGameStateManager.isGameActive

      isResetting = true

      // If game is active, pause it to stop timer cleanly
      if wasGameActive {
        try? await activeGameStateManager.pauseGame()
      }

      // Trigger UI animations
      resetTrigger.toggle()
      pulseAnimation = true

      // Reset timer values
      activeGameStateManager.resetElapsedTime()
      game.createdDate = Date()

      // Delay to clearly show the reset
      try? await Task.sleep(for: .milliseconds(250))

      // Restore previous state
      pulseAnimation = false
      isResetting = false

      if wasGameActive {
        try? await activeGameStateManager.resumeGame()
        // Timer will auto-resume if it was running before
      }
    }
  }

  // MARK: - Game Control Functions

  private func toggleGame() {
    guard !isToggling && !isResetting else { return }

    // Handle completed game - clear from state manager and dismiss the view
    if game.isCompleted {
      activeGameStateManager.clearCurrentGame()
      onDismiss?()
      return
    }

    Task { @MainActor in
      isToggling = true

      // Single, atomic operation using state manager
      try? await activeGameStateManager.toggleGameState()

      try? await Task.sleep(for: .milliseconds(100))
      isToggling = false
    }
  }
}

// MARK: - Previews

#Preview("Paused — Early Game") {
  NavigationStack {
    ActiveGameView(
      game: PreviewGameData.earlyGame,
      gameManager: SwiftDataGameManager(),
      onDismiss: nil
    )
  }
}

#Preview("Close Game") {
  NavigationStack {
    ActiveGameView(
      game: PreviewGameData.closeGame,
      gameManager: SwiftDataGameManager(),
      onDismiss: nil
    )
  }
}

#Preview("Initial Game") {
  NavigationStack {
    ActiveGameView(
      game: PreviewGameData.midGame,
      gameManager: SwiftDataGameManager(),
      onDismiss: nil
    )
  }
}

#Preview("Completed Game") {
  NavigationStack {
    ActiveGameView(
      game: PreviewGameData.completedGame,
      gameManager: SwiftDataGameManager(),
      onDismiss: nil
    )
  }
}
