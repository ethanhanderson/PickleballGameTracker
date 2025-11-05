import GameTrackerCore
//
//  WatchLiveView.swift
//  Pickleball Score Tracking Watch App
//
//  Created by Ethan Anderson on 7/9/25.
//

import SwiftData
import SwiftUI

struct WatchLiveView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss
  @Environment(SwiftDataGameManager.self) private var gameManager
  @Environment(LiveGameStateManager.self) private var liveGameStateManager
  @Environment(LiveSyncCoordinator.self) private var syncCoordinator
  @Environment(\.isLuminanceReduced) private var isLuminanceReduced

  let initialGame: Game
  @State private var showingCompleteAlert = false
  @State private var selectedTab: String = "controls"
  @State private var isToggling = false
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
  
  private var game: Game? {
    liveGameStateManager.currentGame
  }

  init(game: Game, onCompleted: (() -> Void)? = nil) {
    self.initialGame = game
    self.onCompleted = onCompleted
  }

  var body: some View {
    Group {
      if let game = game {
        TabView(selection: $selectedTab) {
          Tab(value: "controls") {
            NavigationStack {
              GameControlsView(
                game: game,
                isGamePaused: !liveGameStateManager.isGameLive,
                isGameInitial: liveGameStateManager.isGameInitial,
                isToggling: isToggling,
                showingCompleteAlert: $showingCompleteAlert,
                showingSettings: $showingSettings,
                onToggleGame: toggleGame
              )
            }
          }

          Tab(value: "score") {
            NavigationStack {
              ScoreControlsView(
                game: game,
                liveGameStateManager: liveGameStateManager,
                onScorePoint: scorePoint,
                onDecrementScore: decrementScore,
                onSetServer: setServer,
                onHapticFeedback: triggerScoreControlsHaptic
              )
            }
          }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedTab)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .alert("End Game", isPresented: $showingCompleteAlert) {
          Button("End", role: .destructive) {
            Task {
              await completeGame()
            }
          }
          Button("Cancel", role: .cancel) {}
        } message: {
          if liveGameStateManager.willDeleteCurrentGameOnCompletion {
            Text("End this game? It will not be saved since no scores or events have been logged.")
          } else {
            Text("End this game? It will be saved to your history and included in your statistics.")
          }
        }
        .sheet(isPresented: $showingSettings) {
          WatchLiveSettingsView(
            game: game,
            gameManager: gameManager,
            liveGameStateManager: liveGameStateManager
          )
        }
        .onChange(of: liveGameStateManager.currentGame?.id) { _, newId in
          // If the current game is cleared externally, dismiss safely
          if newId == nil {
            Task { @MainActor in
              dismiss()
            }
          }
        }
      } else {
        ProgressView("Loading game...")
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .task {
      liveGameStateManager.configure(gameManager: gameManager)
      
      if liveGameStateManager.currentGame == nil {
        await liveGameStateManager.setCurrentGame(initialGame)
      }

      // Configure timer tick based on AOD state
      liveGameStateManager.setTimerUpdateInterval(isLuminanceReduced ? 1.0 : 0.01)

      Log.event(
        .viewAppear,
        level: .debug,
        message: "Watch live view ready for sync",
        context: .current(gameId: initialGame.id)
      )
    }
    .onChange(of: isLuminanceReduced) { _, reduced in
      liveGameStateManager.setTimerUpdateInterval(reduced ? 1.0 : 0.01)
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

  private func triggerScoreControlsHaptic() {
    scoreControlsTrigger.toggle()
  }

  // MARK: - Actions

  private func scorePoint(for team: Int) {
    guard let game = game, !game.isCompleted else {
      return
    }

    let timestamp = liveGameStateManager.elapsedTime
    let isGamePlaying = liveGameStateManager.isGameLive

    // Only trigger haptic feedback when game is actively playing
    if isGamePlaying {
      scoreClickTrigger.toggle()
    }

    Task {
      do {
        try await liveGameStateManager.scorePoint(for: team, at: timestamp)

        // Only trigger success haptic when game is actively playing
        if isGamePlaying {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            scoreSuccessTrigger.toggle()
          }
        }

        if game.isCompleted {
          let gameId = game.id
          await handleGameCompletion(gameId: gameId)
        }
      } catch {
        Log.error(
          error,
          event: .scoreIncrement,
          context: .current(gameId: game.id),
          metadata: ["platform": "watchOS"]
        )
        // Only trigger error haptic when game is actively playing
        if isGamePlaying {
          scoreFailureTrigger.toggle()
        }
      }
    }
    Task { @MainActor in
      guard let game = self.game else { return }
      try? await syncCoordinator.publish(delta: LiveGameDeltaDTO(
        gameId: game.id,
        timestamp: timestamp,
        operation: .score(team: team)
      ))
    }
  }

  private func decrementScore(for team: Int) {
    guard let game = game, !game.isCompleted else {
      return
    }

    let timestamp = liveGameStateManager.elapsedTime
    let isGamePlaying = liveGameStateManager.isGameLive

    let currentScore = team == 1 ? game.score1 : game.score2
    guard currentScore > 0 else { return }

    // Only trigger haptic feedback when game is actively playing
    if isGamePlaying {
      decrementClickTrigger.toggle()
    }

    Task {
      do {
        try await liveGameStateManager.decrementScore(for: team)
      } catch {
        Log.error(
          error,
          event: .scoreDecrement,
          context: .current(gameId: game.id),
          metadata: ["platform": "watchOS"]
        )
        // Only trigger error haptic when game is actively playing
        if isGamePlaying {
          scoreFailureTrigger.toggle()
        }
      }
    }
    Task { @MainActor in
      guard let game = self.game else { return }
      try? await syncCoordinator.publish(delta: LiveGameDeltaDTO(
        gameId: game.id,
        timestamp: timestamp,
        operation: .decrement(team: team)
      ))
    }
  }

  private func setServer(to team: Int) {
    guard let game = game, !game.isCompleted else {
      return
    }

    let timestamp = liveGameStateManager.elapsedTime

    Task {
      do {
        try await liveGameStateManager.setServer(to: team)
      } catch {
        Log.error(
          error,
          event: .serverSwitched,
          context: .current(gameId: game.id),
          metadata: ["platform": "watchOS", "team": "\(team)"]
        )
      }
    }
    Task { @MainActor in
      guard let game = self.game else { return }
      try? await syncCoordinator.publish(delta: LiveGameDeltaDTO(
        gameId: game.id,
        timestamp: timestamp,
        operation: .setServer(team: team)
      ))
    }
  }

  private func toggleGame() {
    guard let game = game, !isToggling else { return }

    if game.isCompleted {
      let gameId = game.id
      Task {
        await handleGameCompletion(gameId: gameId)
      }
      return
    }

    Task { @MainActor in
      isToggling = true
      toggleClickTrigger.toggle()

      try? await liveGameStateManager.toggleGameState()

      if liveGameStateManager.isGameLive {
        try? await Task.sleep(for: .milliseconds(150))

        withAnimation(.easeInOut(duration: 0.4)) {
          selectedTab = "score"
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
          directionUpTrigger.toggle()
        }
      }

      try? await Task.sleep(for: .milliseconds(100))
      // Publish lifecycle change so paired device updates game state (and coordinator adjusts timer)
      try? await syncCoordinator.publish(delta: LiveGameDeltaDTO(
        gameId: game.id,
        timestamp: liveGameStateManager.elapsedTime,
        operation: .setGameState(game.gameState)
      ))

      // Also publish current timer state to keep elapsed/run state tight
      try? await syncCoordinator.publish(delta: LiveGameDeltaDTO(
        gameId: game.id,
        timestamp: liveGameStateManager.elapsedTime,
        operation: .setElapsedTime(
          elapsed: liveGameStateManager.elapsedTime,
          isRunning: liveGameStateManager.isTimerRunning
        )
      ))
      isToggling = false
    }
  }

  private func completeGame() async {
    guard let game = game else { return }

    let gameId = game.id
    let elapsed = liveGameStateManager.elapsedTime

    do {
      try await liveGameStateManager.completeCurrentGame()
      completeSuccessTrigger.toggle()

      // Immediately clear and dismiss to avoid rendering stale objects
      await MainActor.run {
        onCompleted?()
        dismiss()
      }
      // Publish completion so the paired device ends the live game
      Task { @MainActor in
        try? await syncCoordinator.publish(delta: LiveGameDeltaDTO(
          gameId: gameId,
          timestamp: elapsed,
          operation: .setGameState(.completed)
        ))
      }
    } catch {
      Log.error(
        error,
        event: .gameCompleted,
        context: .current(gameId: gameId),
        metadata: ["platform": "watchOS"]
      )
      completeFailureTrigger.toggle()
    }
  }

  private func handleGameCompletion(gameId: UUID) async {
    // Retained for external triggers; now performs immediate dismiss
    await MainActor.run {
      onCompleted?()
      dismiss()
    }
    Log.event(
      .gameCompleted,
      level: .info,
      context: .current(gameId: gameId),
      metadata: ["platform": "watchOS"]
    )
  }
}

// MARK: - Previews

#Preview {
  let setup = PreviewContainers.liveGameSetup()
  let ctx = setup.container.mainContext
  let fetched = (try? ctx.fetch(FetchDescriptor<Game>())) ?? []
  let game = fetched.first(where: { $0.gameState == .playing })
    ?? fetched.first
    ?? { preconditionFailure("Preview requires at least one game") }()

  WatchLiveView(game: game)
    .modelContainer(setup.container)
    .environment(setup.liveGameManager)
    .environment(setup.gameManager)
}

#Preview("Singles Game") {
  let setup = PreviewContainers.liveGameSetup()
  let ctx = setup.container.mainContext
  let fetched = (try? ctx.fetch(FetchDescriptor<Game>())) ?? []
  let game = fetched.first(where: { $0.effectiveTeamSize == 1 && !$0.isCompleted })
    ?? fetched.first(where: { !$0.isCompleted })
    ?? fetched.first
    ?? { preconditionFailure("Preview requires at least one game") }()

  WatchLiveView(game: game)
    .modelContainer(setup.container)
    .environment(setup.liveGameManager)
    .environment(setup.gameManager)
}

#Preview("Doubles Game") {
  let setup = PreviewContainers.liveGameSetup()
  let ctx = setup.container.mainContext
  let fetched = (try? ctx.fetch(FetchDescriptor<Game>())) ?? []
  let game = fetched.first(where: { $0.effectiveTeamSize > 1 && !$0.isCompleted })
    ?? fetched.first(where: { !$0.isCompleted })
    ?? fetched.first
    ?? { preconditionFailure("Preview requires at least one game") }()

  WatchLiveView(game: game)
    .modelContainer(setup.container)
    .environment(setup.liveGameManager)
    .environment(setup.gameManager)
}
