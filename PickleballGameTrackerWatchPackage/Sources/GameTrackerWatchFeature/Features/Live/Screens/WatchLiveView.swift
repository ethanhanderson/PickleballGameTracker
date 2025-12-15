//
//  WatchLiveView.swift
//  Pickleball Score Tracking Watch App
//
//  Created by Ethan Anderson on 7/9/25.
//

import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct WatchLiveView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss
  @Environment(SwiftDataGameManager.self) private var gameManager
  @Environment(LiveGameStateManager.self) private var liveGameStateManager
  @Environment(LiveSyncCoordinator.self) private var syncCoordinator
  @Environment(\.isLuminanceReduced) private var isLuminanceReduced
  @Environment(WorkoutManager.self) private var workoutManager
  @Environment(ExtendedRuntimeManager.self) private var extendedRuntimeManager
  @Environment(\.scenePhase) private var scenePhase

  let initialGame: Game
  private let gameIdSnapshot: UUID
  private let gameTypeSnapshot: GameType
  @State private var showingCompleteAlert = false
  @State private var selectedTab: String = "controls"
  @State private var isToggling = false
  @State private var showingSettings = false
  @State private var showingWorkoutSheet = false
  @State private var hasEndedGame = false
  @State private var didStartLiveSession = false
  @State private var isWorkoutSetupInFlight = false

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
    guard let current = liveGameStateManager.currentGame else { return nil }
    if current.isDetachedFromContext { return nil }
    return current
  }

  private var fallbackMessaging: (icon: String, message: String, showSpinner: Bool, color: Color) {
    if hasEndedGame {
      return ("flag.checkered", "Game no longer available", false, .green)
    } else {
      return ("arrow.triangle.2.circlepath", "Syncing live game…", true, .blue)
    }
  }

  init(game: Game, onCompleted: (() -> Void)? = nil) {
    self.initialGame = game
    self.gameIdSnapshot = game.id
    self.gameTypeSnapshot = game.gameType
    self.onCompleted = onCompleted
  }

  var body: some View {
    Group {
      if let game = game {
        TabView(selection: $selectedTab) {
          Tab(value: "controls") {
            controlsTab(for: game)
          }

          Tab(value: "score") {
            scoreTab(for: game)
          }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedTab)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .onAppear {
          didStartLiveSession = true
        }
        .alert("End Game", isPresented: $showingCompleteAlert) {
          Button("End", role: .destructive) {
            Task { @MainActor in
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
        .sheet(isPresented: $showingWorkoutSheet) {
          WorkoutInfoSheetView()
        }
        .onChange(of: liveGameStateManager.currentGame?.gameState) { _, newState in
          guard let state = newState else { return }
          Task { @MainActor in
            let anotherDevice = syncCoordinator.isAnotherDeviceActivelyTracking()
            switch state {
            case .playing:
              if anotherDevice {
                await teardownWorkoutIfNeeded()
                extendedRuntimeManager.stopSessionIfNeeded()
              } else if workoutManager.isAuthorized, let activeGame = liveGameStateManager.currentGame {
                extendedRuntimeManager.stopSessionIfNeeded()
                await ensureWorkoutRunning(for: activeGame)
              } else {
                extendedRuntimeManager.startFrontmostSessionIfNeeded()
              }
              await switchToScoreTabAfterResume()
            case .paused:
              pauseWorkoutIfNeeded()
              extendedRuntimeManager.stopSessionIfNeeded()
            case .completed:
              await teardownWorkoutIfNeeded()
              extendedRuntimeManager.stopSessionIfNeeded()
            case .initial, .serving:
              break
            }
          }
        }
      } else {
        if hasEndedGame || didStartLiveSession {
          let fallback = fallbackMessaging
          WatchMessageView(
            icon: fallback.icon,
            message: fallback.message,
            showSpinner: fallback.showSpinner,
            color: fallback.color
          )
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          ProgressView("Loading game...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
      }
    }
    .task {
      liveGameStateManager.configure(gameManager: gameManager)
      
      if liveGameStateManager.currentGame == nil {
        await liveGameStateManager.setCurrentGame(initialGame)
      }
      guard let activeGame = liveGameStateManager.currentGame else {
        hasEndedGame = true
        Task { @MainActor in
          dismiss()
        }
        return
      }
      didStartLiveSession = true
      syncCoordinator.setLiveViewForeground(scenePhase == .active)
      Log.event(
        .viewAppear,
        level: .debug,
        message: "WatchLiveView task configured",
        context: .current(gameId: activeGame.id),
        metadata: [
          "initialGame.type": initialGame.gameType.rawValue,
          "currentGame.type": activeGame.gameType.rawValue
        ]
      )

      // Configure timer tick based on AOD state
      liveGameStateManager.setTimerUpdateInterval(isLuminanceReduced ? 1.0 : 0.01)

      Log.event(
        .viewAppear,
        level: .debug,
        message: "Watch live view ready for sync",
        context: .current(gameId: initialGame.id)
      )

      // Prepare HealthKit workout in background (do not start yet)
      let prepared = await authorizeAndPrepareWorkout(for: activeGame)
      if prepared {
        extendedRuntimeManager.stopSessionIfNeeded()
      }
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
    .onChange(of: liveGameStateManager.currentGame?.id) { _, newId in
      guard didStartLiveSession else { return }
      if newId == nil {
        handleLiveGameRemoval()
      }
    }
    .onChange(of: liveGameStateManager.currentGame?.isDetachedFromContext ?? false) { _, isDetached in
      guard didStartLiveSession else { return }
      if isDetached {
        handleLiveGameRemoval()
      }
    }
    .onChange(of: scenePhase) { _, phase in
      syncCoordinator.setLiveViewForeground(phase == .active)
    }
  }

  // MARK: - Extracted Tabs

  @ViewBuilder
  private func controlsTab(for game: Game) -> some View {
    NavigationStack {
      GameControlsView(
        game: game,
        isGamePaused: !liveGameStateManager.isGameLive,
        isGameInitial: liveGameStateManager.isGameInitial,
        isToggling: isToggling,
        showingCompleteAlert: $showingCompleteAlert,
        showingSettings: $showingSettings,
        onToggleGame: toggleGame,
        onOpenWorkout: { showingWorkoutSheet = true }
      )
    }
  }

  @ViewBuilder
  private func scoreTab(for game: Game) -> some View {
    NavigationStack {
      VStack(spacing: DesignSystem.Spacing.md) {
        WatchGameTimerCard(
          game: game,
          liveGameStateManager: liveGameStateManager,
          isLuminanceReduced: isLuminanceReduced
        )

        gameTypeSpecificScoreControls(for: game)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .padding(.top, DesignSystem.Spacing.sm)
      .onAppear {
        Log.event(
          .viewAppear,
          level: .debug,
          message: "Rendering \(game.gameType.displayName) score tab on Watch",
          context: .current(gameId: game.id),
          metadata: [
            "watch.liveView.gameType": game.gameType.rawValue,
            "liveManager.currentGameType": liveGameStateManager.currentGame?.gameType.rawValue ?? "nil"
          ]
        )
      }
    }
  }

  @ViewBuilder
  private func gameTypeSpecificScoreControls(for game: Game) -> some View {
    switch game.gameType {
    case .cutthroat:
      ScrollView(.vertical) {
        PlayerListControlsView(
          game: game,
          liveGameStateManager: liveGameStateManager,
          isGamePaused: !liveGameStateManager.isGameLive,
          onHapticFeedback: triggerScoreControlsHaptic
        )
        .frame(maxWidth: .infinity, alignment: .top)
        .padding(.bottom, DesignSystem.Spacing.lg)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      
    case .recreational, .tournament, .training, .social, .custom, .groupPlay:
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

  private func triggerScoreControlsHaptic() {
    scoreControlsTrigger.toggle()
  }

  private func handleLiveGameRemoval() {
    guard didStartLiveSession else { return }
    if hasEndedGame { return }
    hasEndedGame = true
    syncCoordinator.setLiveViewForeground(false)

    Task { @MainActor in
      await teardownWorkoutIfNeeded()
      extendedRuntimeManager.stopSessionIfNeeded()
      onCompleted?()
      dismiss()
    }
  }

  @MainActor
  private func switchToScoreTabAfterResume(delay: Duration? = nil) async {
    if let delay {
      try? await Task.sleep(for: delay)
    }

    guard selectedTab != "score" else { return }

    withAnimation(.easeInOut(duration: 0.4)) {
      selectedTab = "score"
    }

    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(200))
      directionUpTrigger.toggle()
    }
  }

  // MARK: - Actions

  private func scorePoint(for team: Int) {
    guard let game = game, !game.safeIsCompleted else {
      return
    }

    let timestamp = liveGameStateManager.elapsedTime
    let isGamePlaying = liveGameStateManager.isGameLive

    // Only trigger haptic feedback when game is actively playing
    if isGamePlaying {
      scoreClickTrigger.toggle()
    }

    Task { @MainActor in
      do {
        try await liveGameStateManager.scorePoint(for: team, at: timestamp)

        // Only trigger success haptic when game is actively playing
        if isGamePlaying {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            scoreSuccessTrigger.toggle()
          }
        }

        if game.safeIsCompleted {
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
      let target = LiveScoreTarget.side(team)
      try? await syncCoordinator.publishScoreEvent(
        for: game,
        target: target,
        assignsServe: false,
        timestamp: timestamp
      )
    }
  }

  private func decrementScore(for team: Int) {
    guard let game = game, !game.safeIsCompleted else {
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

    Task { @MainActor in
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
      try? await syncCoordinator.publishDecrementDelta(
        for: game,
        team: team,
        timestamp: timestamp
      )
    }
  }

  private func setServer(to team: Int) {
    guard let game = game, !game.safeIsCompleted else {
      return
    }

    let timestamp = liveGameStateManager.elapsedTime

    Task { @MainActor in
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

    if game.safeIsCompleted {
      let gameId = game.id
      Task { @MainActor in
        await handleGameCompletion(gameId: gameId)
      }
      return
    }

    Task { @MainActor in
      isToggling = true
      toggleClickTrigger.toggle()

      try? await liveGameStateManager.toggleGameState()

      if liveGameStateManager.isGameLive {
        await switchToScoreTabAfterResume(delay: .milliseconds(150))
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
      hasEndedGame = true
      await MainActor.run {
        onCompleted?()
        dismiss()
      }
      Log.event(
        .gameCompleted,
        level: .info,
        context: .current(gameId: gameId),
        metadata: ["platform": "watchOS", "source": "explicitEnd", "elapsed": "\(elapsed)"]
      )
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
    hasEndedGame = true
    await MainActor.run {
      liveGameStateManager.clearCurrentGame()
      onCompleted?()
      dismiss()
    }
    Log.event(
      .gameCompleted,
      level: .info,
      context: .current(gameId: gameId),
      metadata: ["platform": "watchOS", "source": "autoComplete"]
    )
  }

  // MARK: - Workout Helpers

  @MainActor
  private func authorizeAndPrepareWorkout(for game: Game) async -> Bool {
    await workoutManager.requestAuthorizationIfNeeded()
    guard workoutManager.isAuthorized else { return false }
    if !workoutManager.isPrepared {
      await workoutManager.prepare(for: game.gameType)
    }
    return workoutManager.isPrepared
  }

  @MainActor
  private func ensureWorkoutRunning(for game: Game) async {
    guard !isWorkoutSetupInFlight else { return }
    isWorkoutSetupInFlight = true
    defer { isWorkoutSetupInFlight = false }
    guard await authorizeAndPrepareWorkout(for: game) else { return }
    extendedRuntimeManager.stopSessionIfNeeded()
    await workoutManager.start()
  }

  @MainActor
  private func pauseWorkoutIfNeeded() {
    guard workoutManager.sessionState == .running else { return }
    workoutManager.pause()
  }

  @MainActor
  private func teardownWorkoutIfNeeded() async {
    if workoutManager.sessionState != .notStarted {
      await workoutManager.endAndSave()
    }
    extendedRuntimeManager.stopSessionIfNeeded()
  }
}

// MARK: - Previews

#Preview {
  let setup = PreviewContainers.standardSetup()
  let syncCoordinator = LiveSyncCoordinator(service: NoopSyncService())
  // Randomized preview across types, team formats, and participants
  let possibleTypes = Array(GameType.allCases)
  let chosenType = possibleTypes.randomElement()
  let preferTeamSize: Int? = [nil, 1, 2].randomElement() ?? nil
  let nearEndOffset = Int.random(in: 0...4)
  let cutthroatPlayers: Int? = (chosenType == .cutthroat) ? Int.random(in: 3...6) : nil
  let customSizes: (Int, Int)? = (chosenType == .custom) ? (Int.random(in: 1...2), Int.random(in: 1...2)) : nil

  let game = PreviewContainers.exampleGame(
    in: setup.container,
    type: chosenType,
    preferTeamSize: preferTeamSize,
    desiredState: .playing,
    showWonGame: false,
    nearEndOffset: nearEndOffset,
    cutthroatPlayers: cutthroatPlayers,
    customSideSizes: customSizes,
    randomizeParticipants: true
  )
  let workoutManager = WorkoutManager()

  WatchLiveView(game: game)
    .modelContainer(setup.container)
    .environment(setup.liveGameManager)
    .environment(setup.gameManager)
    .environment(syncCoordinator)
    .environment(workoutManager)
}

#Preview("Singles Game") {
  let setup = PreviewContainers.standardSetup()
  let syncCoordinator = LiveSyncCoordinator(service: NoopSyncService())
  let game = PreviewContainers.exampleGame(
    in: setup.container,
    type: nil,
    preferTeamSize: 1,
    desiredState: .playing,
    randomizeParticipants: true
  )
  let workoutManager = WorkoutManager()

  WatchLiveView(game: game)
    .modelContainer(setup.container)
    .environment(setup.liveGameManager)
    .environment(setup.gameManager)
    .environment(syncCoordinator)
    .environment(workoutManager)
}

#Preview("Doubles Game") {
  let setup = PreviewContainers.standardSetup()
  let syncCoordinator = LiveSyncCoordinator(service: NoopSyncService())
  let game = PreviewContainers.exampleGame(
    in: setup.container,
    type: nil,
    preferTeamSize: 2,
    desiredState: .playing,
    randomizeParticipants: true
  )
  let workoutManager = WorkoutManager()

  WatchLiveView(game: game)
    .modelContainer(setup.container)
    .environment(setup.liveGameManager)
    .environment(setup.gameManager)
    .environment(syncCoordinator)
    .environment(workoutManager)
}

#Preview("Cutthroat Game") {
  let setup = PreviewContainers.standardSetup()
  let syncCoordinator = LiveSyncCoordinator(service: NoopSyncService())
  let game = PreviewContainers.exampleGame(in: setup.container, type: .cutthroat)
  let workoutManager = WorkoutManager()

  WatchLiveView(game: game)
    .modelContainer(setup.container)
    .environment(setup.liveGameManager)
    .environment(setup.gameManager)
    .environment(syncCoordinator)
    .environment(workoutManager)
}
