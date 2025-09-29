import GameTrackerCore
//
//  WatchActiveGameView.swift
//  Pickleball Score Tracking Watch App
//
//  Created by Ethan Anderson on 7/9/25.
//

import SwiftData
import SwiftUI

struct WatchActiveGameView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss
  @Environment(SwiftDataGameManager.self) private var gameManager
  @Environment(LiveGameStateManager.self) private var activeGameStateManager

  @Bindable var game: Game
  @State private var showingCompleteAlert = false
  @State private var selectedTab: String = "controls"
  @State private var isToggling = false
  @State private var isResetting = false
  @State private var resetTrigger = false
  @State private var playPauseTrigger = false
  @State private var pulseAnimation = false
  @State private var showingSettings = false

  // Haptic feedback triggers
  @State private var scoreClickTrigger = false
  @State private var scoreSuccessTrigger = false
  @State private var scoreFailureTrigger = false
  @State private var decrementClickTrigger = false
  @State private var toggleClickTrigger = false
  @State private var directionUpTrigger = false
  @State private var completeSuccessTrigger = false
  @State private var completeFailureTrigger = false
  @State private var completionSuccessTrigger = false
  @State private var scoreControlsTrigger = false

  let onCompleted: (() -> Void)?

  init(game: Game, onCompleted: (() -> Void)? = nil) {
    self.game = game
    self.onCompleted = onCompleted
  }

  var body: some View {
    TabView(selection: $selectedTab) {
      Tab("Game Controls", systemImage: "", value: "controls") {
        NavigationStack {
          GameControlsView(
            game: game,
            isGamePaused: !activeGameStateManager.isGameActive,
            isGameInitial: activeGameStateManager.isGameInitial,
            isToggling: isToggling,
            showingCompleteAlert: $showingCompleteAlert,
            showingSettings: $showingSettings,
            onToggleGame: toggleGame
          )
          .navigationTitle(game.gameType.displayName)
          .toolbarTitleDisplayMode(.inline)
        }
      }

      Tab("Score Controls", systemImage: "", value: "score") {
        NavigationStack {
          ScoreControlsView(
            game: game,
            activeGameStateManager: activeGameStateManager,
            onScorePoint: scorePoint,
            onDecrementScore: decrementScore,
            onToggleTimer: toggleTimer,
            onResetTimer: resetTimer,
            onHapticFeedback: triggerScoreControlsHaptic,
            isResetting: isResetting,
            isToggling: isToggling,
            pulseAnimation: pulseAnimation,
            resetTrigger: resetTrigger,
            playPauseTrigger: playPauseTrigger
          )
        }
      }
    }
    .animation(.easeInOut(duration: 0.3), value: selectedTab)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(0)
    .background(.black)
    .alert("End Game", isPresented: $showingCompleteAlert) {
      Button("End", role: .destructive) {
        Task {
          await completeGame()
        }
      }
      Button("Go back", role: .cancel) {}
    } message: {
      Text("Are you sure you want to complete this game?")
    }
    .sheet(isPresented: $showingSettings) {
      WatchActiveGameSettingsView(
        game: game,
        gameManager: gameManager,
        activeGameStateManager: activeGameStateManager
      )
    }
    // Ensure we react if game becomes completed by any path (auto-complete, sync, end button)
    .onChange(of: game.isCompleted) { _, isCompleted in
      if isCompleted {
        Task { await handleGameCompletion() }
      }
    }
    .task {
      // Configure the activeGameStateManager for this watch session
      activeGameStateManager.configure(gameManager: gameManager)
      // Ensure device sync is enabled so phone-created games sync to watch and vice versa
      activeGameStateManager.setSyncEnabled(true)
      activeGameStateManager.setCurrentGame(game)

      // Keep games in initial state - user must explicitly start
      Log.event(
        .viewAppear,
        level: .debug,
        message: "Watch game loaded initial state"
      )
    }
    .sensoryFeedback(.impact(weight: .light), trigger: scoreClickTrigger)
    .sensoryFeedback(.success, trigger: scoreSuccessTrigger)
    .sensoryFeedback(.error, trigger: scoreFailureTrigger)
    .sensoryFeedback(.impact(weight: .light), trigger: decrementClickTrigger)
    .sensoryFeedback(.impact(weight: .light), trigger: toggleClickTrigger)
    .sensoryFeedback(.impact(weight: .light), trigger: directionUpTrigger)
    .sensoryFeedback(.success, trigger: completeSuccessTrigger)
    .sensoryFeedback(.error, trigger: completeFailureTrigger)
    .sensoryFeedback(.success, trigger: completionSuccessTrigger)
    .sensoryFeedback(.impact(weight: .light), trigger: scoreControlsTrigger)
  }

  // MARK: - Timer Actions

  private func toggleTimer() {
    guard !isToggling && !isResetting else { return }

    Task { @MainActor in
      isToggling = true

      // Trigger play/pause button bounce effect
      playPauseTrigger.toggle()

      // Use the activeGameStateManager's timer toggle method
      activeGameStateManager.toggleTimer()

      // Brief delay to ensure toggle operation completes
      try? await Task.sleep(for: .milliseconds(100))

      isToggling = false
    }
  }

  private func triggerScoreControlsHaptic() {
    scoreControlsTrigger.toggle()
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

      // Reset timer values using activeGameStateManager
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

  // MARK: - Actions

  private func scorePoint(for team: Int) {
    guard !game.isCompleted && activeGameStateManager.isGameActive else {
      return
    }

    // Trigger initial click feedback
    scoreClickTrigger.toggle()

    Task {
      do {
        // Use activeGameStateManager to score points
        try await activeGameStateManager.scorePoint(for: team)

        // Add subtle haptic feedback for success
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          scoreSuccessTrigger.toggle()
        }

        // Handle game completion
        if game.isCompleted {
          await handleGameCompletion()
        }
      } catch {
        Log.error(
          error,
          event: .scoreIncrement,
          context: .current(gameId: game.id),
          metadata: ["platform": "watchOS"]
        )
        scoreFailureTrigger.toggle()
      }
    }
  }

  private func decrementScore(for team: Int) {
    guard !game.isCompleted && activeGameStateManager.isGameActive else {
      return
    }

    // Only allow decrementing if score is greater than 0
    let currentScore = team == 1 ? game.score1 : game.score2
    guard currentScore > 0 else { return }

    // Trigger initial click feedback
    decrementClickTrigger.toggle()

    Task {
      do {
        try await gameManager.decrementScore(for: team, in: game)
        // Provide haptic feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          // Additional click feedback handled by trigger
        }
      } catch {
        Log.error(
          error,
          event: .scoreDecrement,
          context: .current(gameId: game.id),
          metadata: ["platform": "watchOS"]
        )
        scoreFailureTrigger.toggle()
      }
    }
  }

  private func toggleGame() {
    guard !isToggling && !isResetting else { return }

    // Handle completed game - clear from state manager and dismiss the view
    if game.isCompleted {
      Task {
        await handleGameCompletion()
      }
      return
    }

    Task { @MainActor in
      isToggling = true
      toggleClickTrigger.toggle()

      // Single, atomic operation using state manager
      try? await activeGameStateManager.toggleGameState()

      // Animate tab switch when game is started/resumed
      if activeGameStateManager.isGameActive {
        // Brief delay to let the button state update visually first
        try? await Task.sleep(for: .milliseconds(150))

        // Smooth animated transition to score tab
        withAnimation(.easeInOut(duration: 0.4)) {
          selectedTab = "score"
        }

        // Additional subtle haptic feedback for the tab switch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
          directionUpTrigger.toggle()
        }
      }

      try? await Task.sleep(for: .milliseconds(100))
      isToggling = false
    }
  }

  private func completeGame() async {
    do {
      try await activeGameStateManager.completeCurrentGame()
      completeSuccessTrigger.toggle()

      // Handle game completion UX (central state persists/syncs)
      await handleGameCompletion()
    } catch {
      Log.error(
        error,
        event: .gameCompleted,
        context: .current(gameId: game.id),
        metadata: ["platform": "watchOS"]
      )
      completeFailureTrigger.toggle()
    }
  }

  // MARK: - Game Completion Handler

  private func handleGameCompletion() async {
    // Idempotency: only proceed when completed
    guard game.isCompleted else { return }

    // Brief completion haptic
    completionSuccessTrigger.toggle()

    // Shorter delay for snappy UX
    try? await Task.sleep(for: .milliseconds(800))

    await MainActor.run {
      onCompleted?()
      dismiss()
    }

    Log.event(
      .gameCompleted,
      level: .info,
      context: .current(gameId: game.id),
      metadata: ["platform": "watchOS"]
    )
  }
}

// MARK: - Previews

#Preview("Active Singles Game") {
  let container = PreviewDataSeeder.container()
  WatchActiveGameView(game: PreviewGameData.midGame)
    .modelContainer(container)
    .environment(LiveGameStateManager.preview(container: container))
}

#Preview("Completed Game") {
  let container = PreviewDataSeeder.container()
  WatchActiveGameView(game: PreviewGameData.completedGame)
    .modelContainer(container)
    .environment(LiveGameStateManager.preview(container: container))
}
