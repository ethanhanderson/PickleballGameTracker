//
//  ActiveGameStateManager.swift
//  SharedGameCore
//
//  Created by Ethan Anderson on 7/9/25.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
public final class ActiveGameStateManager: Sendable {

  // MARK: - Singleton

  public static let shared = ActiveGameStateManager()

  // MARK: - Published Properties

  /// The currently active game
  public private(set) var currentGame: Game?

  /// The elapsed time since the game started
  public private(set) var elapsedTime: TimeInterval = 0

  /// Whether the game timer is currently running
  public private(set) var isTimerRunning: Bool = false

  /// Whether there is an active game
  public var hasActiveGame: Bool {
    currentGame != nil && currentGame?.isCompleted == false
  }

  /// Whether the game is currently active (playing state)
  public private(set) var isGameActive: Bool = false

  /// Whether the game is in initial state (never started)
  public private(set) var isGameInitial: Bool = true

  /// Current serve number (increments each time serving team changes)
  public private(set) var currentServeNumber: Int = 1

  // MARK: - Dependencies

  /// Business logic manager for delegating game operations
  public var gameManager: SwiftDataGameManager?

  /// Sync service for cross-device synchronization
  private var syncService: ActiveGameSyncService?

  /// Pending remote game for conflict resolution
  private var pendingRemoteGame: ActiveGameStateDTO?

  /// Flag to prevent sync loops during remote updates
  private var isProcessingRemoteUpdate = false

  /// Haptic feedback service for local actions only
  private var hapticService: HapticFeedbackService {
    HapticFeedbackService.shared
  }

  /// Formatted elapsed time string (hours:minutes:seconds when hours > 0, otherwise minutes:seconds)
  public var formattedElapsedTime: String {
    let totalSeconds = Int(elapsedTime)
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    let seconds = totalSeconds % 60

    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    } else {
      return String(format: "%02d:%02d", minutes, seconds)
    }
  }

  /// Formatted elapsed time string with centiseconds (hours:minutes:seconds.centiseconds when hours > 0, otherwise minutes:seconds.centiseconds)
  public var formattedElapsedTimeWithCentiseconds: String {
    let totalSeconds = Int(elapsedTime)
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    let seconds = totalSeconds % 60
    let centiseconds = Int((elapsedTime.truncatingRemainder(dividingBy: 1)) * 100)

    if hours > 0 {
      return String(format: "%d:%02d:%02d.%02d", hours, minutes, seconds, centiseconds)
    } else {
      return String(format: "%02d:%02d.%02d", minutes, seconds, centiseconds)
    }
  }

  // MARK: - Private Properties

  private var gameTimer: Timer?
  private var gameStartTime: Date?
  private var pausedTime: TimeInterval = 0
  private var lastPauseTime: Date?
  private var modelContext: ModelContext?

  // MARK: - Inactivity Tracking

  /// Timer for checking inactivity periods
  private var inactivityTimer: Timer?

  /// Last time there was game activity (score, undo, etc.)
  private var lastActivityTime: Date?

  /// Whether inactivity checking is enabled
  public var isInactivityTrackingEnabled: Bool = true

  // MARK: - UI State Properties

  /// Text for the game control button
  public var gameControlButtonText: String {
    if isGameInitial { return "Start Game" }
    return isGameActive ? "Pause Game" : "Resume Game"
  }

  /// Icon for the game control button
  public var gameControlButtonIcon: String {
    if isGameInitial { return "play.fill" }
    return isGameActive ? "pause.fill" : "play.fill"
  }

  /// Combined game and timer status for UI display
  public var gameAndTimerStatus: String {
    guard hasActiveGame else { return "No active game" }

    let gameStatus = isGameActive ? "Playing" : "Paused"
    let timerStatus = isTimerRunning ? "Running" : "Stopped"

    return "\(gameStatus) • Timer \(timerStatus)"
  }

  /// Whether the timer can be started manually
  public var canStartTimer: Bool {
    hasActiveGame && !isTimerRunning && currentGame?.gameState == .playing
  }

  /// Whether the timer can be paused manually
  public var canPauseTimer: Bool {
    hasActiveGame && isTimerRunning
  }

  /// Text for the timer control button
  public var timerButtonText: String {
    if !hasActiveGame { return "No Game" }

    guard currentGame?.gameState == .playing else {
      return "Game Not Playing"
    }

    return isTimerRunning ? "Pause Timer" : "Start Timer"
  }

  // MARK: - Inactivity Timeout Constants

  /// Time after which the timer stops due to inactivity (2 minutes)
  private let timerInactivityTimeout: TimeInterval = 120

  /// Time after which the entire game pauses due to inactivity (10 minutes)
  private let gameInactivityTimeout: TimeInterval = 600

  // MARK: - Initialization

  nonisolated public init() {}

  // MARK: - Public Methods

  /// Configure the state manager with a model context and game manager
  public func configure(
    with modelContext: ModelContext, gameManager: SwiftDataGameManager? = nil,
    enableSync: Bool = true
  ) {
    self.modelContext = modelContext

    // Set up the game manager relationship
    if let gameManager = gameManager {
      self.gameManager = gameManager
      gameManager.activeGameDelegate = self
    }

    // Set up sync service if enabled
    if enableSync {
      configureSyncService()
    }

    loadActiveGame()
  }

  /// Start a new active game (timer/session management only)
  public func startGame(_ game: Game) {
    // Complete any existing active game first
    if let existingGame = currentGame, !existingGame.isCompleted {
      Task {
        try? await gameManager?.completeGame(existingGame)
      }
    }

    // Set the new active game
    currentGame = game
    gameStartTime = Date()
    elapsedTime = 0

    // Ensure game starts in paused state with timer stopped
    stopTimerInternal()

    // Trigger haptic feedback for local game start
    if !isProcessingRemoteUpdate {
      hapticService.gameStart()
    }

    // Sync the new game to paired device
    syncCurrentGameState()

    Log.event(
      .gameResumed,
      level: .info,
      message: "Active game set (paused)",
      context: .current(gameId: game.id),
      metadata: ["gameType": game.gameType.rawValue]
    )
  }

  /// Complete the current active game (delegates to game manager)
  public func completeCurrentGame() async throws {
    guard let game = currentGame,
      let gameManager = gameManager
    else { return }

    try await gameManager.completeGame(game)
  }

  /// Clear the current game (used when user dismisses a completed game)
  public func clearCurrentGame() {
    currentGame = nil
    stopTimer()
    elapsedTime = 0
    gameStartTime = nil
    stopInactivityTracking()
    resetServeNumber()

    Log.event(
      .actionTapped,
      level: .info,
      message: "Current game cleared from state manager"
    )
  }

  // MARK: - Game State Control (with Automatic Timer Management)

  /// Toggle between game states (start/pause/resume)
  public func toggleGameState() async throws {
    guard currentGame != nil else { throw GameError.noActiveGame }

    if isGameInitial {
      try await startGame()
    } else if isGameActive {
      try await pauseGame()
    } else {
      try await resumeGame()
    }
  }

  /// Start the game (automatically starts timer)
  public func startGame() async throws {
    guard let game = currentGame else { throw GameError.noActiveGame }

    // Atomic state change
    isGameActive = true
    isGameInitial = false
    game.gameState = .playing

    // Persist to storage
    try await gameManager?.updateGame(game)

    // Handle timer state change
    gameStateDidChange(to: .playing)

    // Automatically start timer when game starts
    if !isTimerRunning {
      startTimerInternal()
      Log.event(.actionTapped, level: .debug, message: "Timer auto-started with game")
    }

    Log.event(
      .gameResumed, level: .info, message: "Game started", context: .current(gameId: game.id))
  }

  /// Pause the game (automatically stops timer)
  public func pauseGame() async throws {
    guard let game = currentGame else { throw GameError.noActiveGame }

    // Automatically stop timer when game pauses
    let wasTimerRunning = isTimerRunning
    if wasTimerRunning {
      lastPauseTime = Date()  // Track pause time for resume
      stopTimerInternal()
      Log.event(.actionTapped, level: .debug, message: "Timer auto-stopped with game pause")
    }

    // Update game state
    isGameActive = false
    game.gameState = .paused

    try await gameManager?.updateGame(game)
    gameStateDidChange(to: .paused)

    Log.event(.gamePaused, level: .info, message: "Game paused", context: .current(gameId: game.id))
  }

  /// Resume the game (automatically resumes timer)
  public func resumeGame() async throws {
    guard let game = currentGame else { throw GameError.noActiveGame }

    isGameActive = true
    game.gameState = .playing

    try await gameManager?.updateGame(game)
    gameStateDidChange(to: .playing)

    // Automatically resume timer when game resumes
    if !isTimerRunning {
      // Add the pause duration to total paused time
      if let pauseStart = lastPauseTime {
        pausedTime += Date().timeIntervalSince(pauseStart)
        lastPauseTime = nil
      }

      startTimerInternal()
      Log.event(.actionTapped, level: .debug, message: "Timer auto-resumed with game")
    }

    Log.event(
      .gameResumed, level: .info, message: "Game resumed", context: .current(gameId: game.id))
  }

  // MARK: - Business Operation Delegation

  /// Score a point for the specified team (delegates to game manager)
  public func scorePoint(for team: Int) async throws {
    guard let game = currentGame,
      let gameManager = gameManager
    else {
      throw GameError.noActiveGame
    }

    try await gameManager.scorePoint(for: team, in: game)
    // Activity tracking is reset in gameDidUpdate delegate method
  }

  /// Undo the last point (delegates to game manager)
  public func undoLastPoint() async throws {
    guard let game = currentGame,
      let gameManager = gameManager
    else {
      throw GameError.noActiveGame
    }

    try await gameManager.undoLastPoint(in: game)
    // Activity tracking is reset in gameDidUpdate delegate method
  }

  /// Reset the current game (delegates to game manager)
  public func resetCurrentGame() async throws {
    guard let game = currentGame,
      let gameManager = gameManager
    else {
      throw GameError.noActiveGame
    }

    try await gameManager.resetGame(game)
    resetElapsedTime()
    resetServeNumber()
    // Activity tracking is reset in gameDidUpdate delegate method
  }

  /// Pause the current game timer (old method - replaced by pauseGame() async)
  public func pauseTimer() {
    guard hasActiveGame && isTimerRunning else { return }
    lastPauseTime = Date()
    stopTimerInternal()
  }

  /// Resume the current game timer (old method - replaced by resumeGame() async)
  public func resumeTimer() {
    guard hasActiveGame && !isTimerRunning else { return }

    // Timer should only run when game is in .playing state
    guard currentGame?.gameState == .playing else {
      Log.event(
        .actionTapped,
        level: .warn,
        message: "Timer not started; expected .playing",
        metadata: ["state": currentGame?.gameState.rawValue ?? "unknown"]
      )
      return
    }

    // Add the pause duration to total paused time
    if let pauseStart = lastPauseTime {
      pausedTime += Date().timeIntervalSince(pauseStart)
      lastPauseTime = nil
    }

    startTimerInternal()
    Log.event(.actionTapped, level: .debug, message: "Game timer resumed (state .playing)")
  }

  /// Reset the elapsed time (useful for game restarts)
  public func resetElapsedTime() {
    elapsedTime = 0
    pausedTime = 0
    lastPauseTime = nil
    gameStartTime = Date()
  }

  /// Increment the serve number when serving team changes
  public func incrementServeNumber() {
    currentServeNumber += 1
    Log.event(.serverSwitched, level: .debug, metadata: ["serveNumber": "\(currentServeNumber)"])
  }

  /// Reset the serve number to 1 (for new games or game resets)
  public func resetServeNumber() {
    currentServeNumber = 1
    Log.event(.serverSwitched, level: .debug, message: "Serve number reset to 1")
  }

  /// Start the timer (for external control)
  public func startTimer() {
    guard hasActiveGame && !isTimerRunning else { return }

    // If the game isn't playing yet, transition to playing when starting the timer
    if currentGame?.gameState != .playing {
      currentGame?.gameState = .playing
      isGameActive = true
      isGameInitial = false
      if let game = currentGame {
        Task { @MainActor in
          try? await self.gameManager?.updateGame(game)
        }
      }
    }

    // Handle pause tracking - if we're resuming from a timer-only pause
    if let lastPause = lastPauseTime {
      let pauseDuration = Date().timeIntervalSince(lastPause)
      pausedTime += pauseDuration
      lastPauseTime = nil
      Log.event(
        .actionTapped,
        level: .debug,
        message: "Timer resumed",
        metadata: ["pauseDuration": String(format: "%.2f", pauseDuration)]
      )
    } else if gameStartTime == nil {
      gameStartTime = Date()
    }

    startTimerInternal()

    // Trigger haptic feedback for local timer start
    if !isProcessingRemoteUpdate {
      hapticService.timerToggle()
    }

    Log.event(.actionTapped, level: .debug, message: "Timer started")
  }

  /// Stop the timer completely (for external control)
  public func stopTimer() {
    stopTimerInternal()
    pausedTime = 0
    lastPauseTime = nil

    // Trigger haptic feedback for local timer stop
    if !isProcessingRemoteUpdate {
      hapticService.timerToggle()
    }
  }

  /// Toggle timer state (for timer-only control, independent of game state)
  public func toggleTimer() {
    // Reset activity when user manually controls timer
    resetActivityTracking()

    if isTimerRunning {
      pauseTimerOnly()  // Stop just the timer, preserve game state
    } else {
      // Timer can only start if game is in playing state
      guard currentGame?.gameState == .playing else {
        Log.event(
          .actionTapped,
          level: .warn,
          message: "Timer cannot start (toggle); game not .playing",
          metadata: ["state": currentGame?.gameState.rawValue ?? "unknown"]
        )
        return
      }
      startTimer()
    }
  }

  /// Pause just the timer without affecting game state
  public func pauseTimerOnly() {
    guard isTimerRunning else { return }

    // Record the pause time to track how long timer was paused
    lastPauseTime = Date()

    // Stop the timer but preserve game state
    stopTimerInternal()
    Log.event(
      .actionTapped,
      level: .debug,
      message: "Timer paused - game state unchanged",
      metadata: ["state": currentGame?.gameState.rawValue ?? "unknown"]
    )
  }

  /// Set the current game and prepare timer state
  public func setCurrentGame(_ game: Game) {
    // If this is already the current game, preserve timer state
    if currentGame?.id == game.id {
      // Just update the reference in case the game object changed
      let oldState = currentGame?.gameState
      currentGame = game

      // Update game control state if state changed
      if oldState != game.gameState {
        isGameActive = (game.gameState == .playing)
        isGameInitial = (game.gameState == .initial)
      }

      Log.event(
        .gameResumed,
        level: .debug,
        message: "Current game refreshed",
        context: .current(gameId: game.id),
        metadata: ["timerRunning": String(isTimerRunning)]
      )
      return
    }

    // Setting a new game - reset everything
    currentGame = game
    // Do not derive elapsed from createdDate; timer should be 0 until started
    gameStartTime = nil

    // Initialize game control state
    isGameActive = (game.gameState == .playing)
    isGameInitial = (game.gameState == .initial)

    // Reset pause tracking for this game session
    pausedTime = 0
    lastPauseTime = nil

    // Elapsed time starts at 0 until the timer is started
    elapsedTime = 0

    // Reset serve number for new game
    resetServeNumber()

    // New games start with timer paused - user must explicitly start
    stopTimerInternal()

    // Sync the new game to paired device
    syncCurrentGameState()

    Log.event(
      .gamePaused,
      level: .debug,
      message: "New game set - timer paused",
      context: .current(gameId: game.id),
      metadata: [
        "state": game.gameState.rawValue,
        "isGameActive": String(isGameActive),
        "isGameInitial": String(isGameInitial),
      ]
    )
  }

  /// Called when game state changes - handles timer stop based on state
  public func gameStateDidChange(to newState: GameState) {
    guard hasActiveGame else { return }

    // Update UI state to match game state
    isGameActive = (newState == .playing)
    isGameInitial = (newState == .initial)

    switch newState {
    case .playing:
      // Don't auto-start timer here - handled by game control methods
      resetActivityTracking()
      Log.event(.gameResumed, level: .debug, message: "state -> playing")

    case .initial, .serving, .completed:
      // Force stop timer for these states
      if isTimerRunning {
        stopTimerInternal()
        Log.event(
          .gamePaused, level: .debug, message: "Timer force-stopped due to state",
          metadata: ["state": newState.rawValue])
      }
      stopInactivityTracking()

    case .paused:
      // Don't auto-stop timer here - handled by pauseGame() method
      stopInactivityTracking()
      Log.event(.gamePaused, level: .debug, message: "state -> paused")
    }
  }

  // MARK: - Inactivity Management

  /// Reset the activity tracking (call this when any game activity occurs)
  private func resetActivityTracking() {
    guard isInactivityTrackingEnabled && hasActiveGame else { return }

    lastActivityTime = Date()

    // Only start inactivity tracking if timer is running
    if isTimerRunning {
      startInactivityTracking()
    }

    Log.event(.actionTapped, level: .debug, message: "Inactivity timer reset")
  }

  /// Start the inactivity tracking timer
  private func startInactivityTracking() {
    guard isInactivityTrackingEnabled && hasActiveGame && isTimerRunning else { return }

    stopInactivityTracking()  // Stop any existing timer

    inactivityTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      Task { @MainActor in
        self?.checkForInactivity()
      }
    }
  }

  /// Stop the inactivity tracking timer
  private func stopInactivityTracking() {
    inactivityTimer?.invalidate()
    inactivityTimer = nil
  }

  /// Check if the game has been inactive and take appropriate action
  private func checkForInactivity() {
    guard let lastActivity = lastActivityTime,
      hasActiveGame
    else {
      // Stop tracking if conditions are no longer met
      stopInactivityTracking()
      return
    }

    let inactiveTime = Date().timeIntervalSince(lastActivity)

    // First threshold: Stop just the timer (2 minutes)
    if inactiveTime >= timerInactivityTimeout && inactiveTime < gameInactivityTimeout {
      if isTimerRunning {
        pauseTimerOnly()  // Manual timer pause, game stays active
        Log.event(
          .actionTapped,
          level: .debug,
          message: "Timer auto-paused due to inactivity",
          metadata: ["inactiveSeconds": String(Int(inactiveTime))]
        )
      }
    }
    // Second threshold: Pause the entire game (10 minutes)
    else if inactiveTime >= gameInactivityTimeout {
      if currentGame?.gameState == .playing {
        Task { @MainActor in
          try? await pauseGame()  // This will auto-stop timer too
        }
        Log.event(
          .gamePaused,
          level: .info,
          message: "Game auto-paused due to extended inactivity",
          metadata: ["inactiveSeconds": String(Int(inactiveTime))]
        )
      }
    }
  }

  // MARK: - Private Methods

  private func loadActiveGame() {
    guard let modelContext = modelContext else { return }

    do {
      let descriptor = FetchDescriptor<Game>(
        predicate: #Predicate<Game> { game in
          game.isCompleted == false
        },
        sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
      )

      let activeGames = try modelContext.fetch(descriptor)

      if let activeGame = activeGames.first {
        currentGame = activeGame

        // Initialize game control state
        isGameActive = (activeGame.gameState == .playing)
        isGameInitial = (activeGame.gameState == .initial)

        // Calculate elapsed time since game creation
        let startTime = activeGame.createdDate
        gameStartTime = startTime
        elapsedTime = Date().timeIntervalSince(startTime)

        // Reset pause tracking for loaded game
        pausedTime = 0
        lastPauseTime = nil

        // Always load games in paused state - timer should only start when explicitly requested by user
        stopTimerInternal()
        Log.event(
          .loadSucceeded,
          level: .debug,
          message: "Loaded active game: Timer paused",
          context: .current(gameId: activeGame.id),
          metadata: [
            "state": activeGame.gameState.rawValue,
            "isGameActive": String(isGameActive),
            "isGameInitial": String(isGameInitial),
          ]
        )
      }
    } catch {
      Log.error(error, event: .loadFailed)
    }
  }

  private func startTimerInternal() {
    // Safety: Timer must only run when a game is active and in .playing state
    guard hasActiveGame, currentGame?.gameState == .playing else {
      return
    }

    stopTimerInternal()  // Ensure no duplicate timers

    gameTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
      Task { @MainActor in
        self?.updateElapsedTime()
      }
    }
    isTimerRunning = true

    // Start inactivity tracking when timer starts
    resetActivityTracking()

    // Sync timer state change (unless processing remote update)
    if !isProcessingRemoteUpdate {
      syncCurrentGameState()
    }
  }

  private func stopTimerInternal() {
    gameTimer?.invalidate()
    gameTimer = nil
    isTimerRunning = false

    // Stop inactivity tracking when timer stops
    stopInactivityTracking()

    // Sync timer state change (unless processing remote update)
    if !isProcessingRemoteUpdate {
      syncCurrentGameState()
    }
  }

  private func updateElapsedTime() {
    // Only update if timer is intended to run and game is in playing state
    guard let startTime = gameStartTime, hasActiveGame, currentGame?.gameState == .playing else {
      return
    }
    let totalRealTime = Date().timeIntervalSince(startTime)
    elapsedTime = totalRealTime - pausedTime
  }

  /// Set the timer baseline to a specific elapsed time and running state.
  /// This adjusts internal `gameStartTime`, `pausedTime`, and `lastPauseTime`
  /// so subsequent ticks continue from the provided elapsed time.
  private func setTimerBaseline(
    elapsedSeconds: TimeInterval,
    isRunning: Bool,
    lastStartTime: Date?
  ) {
    let now = Date()

    // Stop existing timer to avoid double scheduling during baseline updates
    stopTimerInternal()

    // Establish a baseline that yields the given elapsedSeconds
    // on the next `updateElapsedTime` tick.
    if let start = lastStartTime, isRunning {
      // Prefer explicit start time if provided and running
      gameStartTime = start
    } else {
      // Derive start time from desired elapsed
      gameStartTime = now.addingTimeInterval(-elapsedSeconds)
    }

    // When paused, we keep a pause anchor so resuming excludes the paused duration
    if isRunning {
      pausedTime = 0
      lastPauseTime = nil
      elapsedTime = elapsedSeconds
      startTimerInternal()
    } else {
      pausedTime = 0
      lastPauseTime = now
      elapsedTime = elapsedSeconds
      // Keep timer stopped
    }
  }

  // MARK: - Delegate Methods (called by SwiftDataGameManager)

  /// Called when a game is updated through the game manager
  public func gameDidUpdate(_ game: Game) {
    // Update our reference if this is the current game
    if currentGame?.id == game.id {
      currentGame = game
      // Reset activity tracking on any game update (score changes, etc.)
      resetActivityTracking()
      // Sync the updated state to paired device
      syncCurrentGameState()
    }
  }

  /// Called when a game is completed through the game manager
  public func gameDidComplete(_ game: Game) {
    // Keep the current game available for display but stop timer and tracking
    if currentGame?.id == game.id {
      // DON'T clear currentGame - keep it for the completed state UI
      stopTimer()
      // DON'T reset elapsedTime - keep final time for display
      stopInactivityTracking()

      // Trigger haptic feedback for local game completion
      if !isProcessingRemoteUpdate {
        hapticService.gameComplete()
      }

      // Sync the completed game state
      syncCurrentGameState()

      Log.event(.gameCompleted, level: .info, context: .current(gameId: game.id))
    }
  }

  /// Called when a game is deleted through the game manager
  public func gameDidDelete(_ game: Game) {
    // Clear current game if this was the active game
    if currentGame?.id == game.id {
      currentGame = nil
      stopTimer()
      elapsedTime = 0
      gameStartTime = nil
      stopInactivityTracking()
    }
  }

  // MARK: - Cleanup

  /// Call this method when the app is about to terminate (optional cleanup)
  public func cleanup() {
    stopTimer()
    stopInactivityTracking()
    Task { @MainActor in
      syncService?.setSyncEnabled(false)
    }
  }

  // MARK: - Inactivity Configuration

  /// Enable or disable inactivity tracking
  public func setInactivityTrackingEnabled(_ enabled: Bool) {
    isInactivityTrackingEnabled = enabled

    if !enabled {
      stopInactivityTracking()
    } else if isTimerRunning {
      resetActivityTracking()
    }

    Log.event(
      .settingsChanged,
      level: .info,
      message: "Inactivity tracking updated",
      metadata: ["enabled": String(enabled)]
    )
  }

  /// Get the current timer inactivity timeout (read-only)
  public var timerInactivityTimeoutSeconds: TimeInterval {
    timerInactivityTimeout
  }

  /// Get the current game inactivity timeout (read-only)
  public var gameInactivityTimeoutSeconds: TimeInterval {
    gameInactivityTimeout
  }

  /// Get the time since last activity (returns nil if no activity tracked)
  public var timeSinceLastActivity: TimeInterval? {
    guard let lastActivity = lastActivityTime else { return nil }
    return Date().timeIntervalSince(lastActivity)
  }

  /// Get a user-friendly status message about inactivity tracking
  public var inactivityStatusMessage: String? {
    guard isInactivityTrackingEnabled,
      hasActiveGame,
      isTimerRunning,
      let timeSinceActivity = timeSinceLastActivity
    else {
      return nil
    }

    let remainingTimerTime = timerInactivityTimeout - timeSinceActivity
    let remainingGameTime = gameInactivityTimeout - timeSinceActivity

    if timeSinceActivity >= gameInactivityTimeout {
      return "Game will auto-pause due to inactivity"
    } else if timeSinceActivity >= timerInactivityTimeout {
      return "Timer will auto-pause in \(Int(remainingGameTime))s"
    } else if remainingTimerTime <= 10 {
      return "Timer will auto-pause in \(Int(remainingTimerTime))s"
    }

    return nil
  }

  // MARK: - Sync Configuration

  /// Configure cross-device synchronization
  private func configureSyncService() {
    syncService = ActiveGameSyncService.shared

    Task {
      await syncService?.configure(
        onActiveGameReceived: { [weak self] dto in
          Task { @MainActor in
            await self?.handleReceivedActiveGameState(dto)
          }
        },
        onHistoryReceived: { [weak self] games in
          Task { @MainActor in
            await self?.handleReceivedGameHistory(games)
          }
        },
        onHistoryRequested: { [weak self] in
          Task { @MainActor in
            await self?.handleHistoryRequest()
          }
        }
      )

      await MainActor.run {
        syncService?.setSyncEnabled(true)
        // Kickstart a reachability ping by sending a minimal history request on boot
        // This helps establish connectivity on some OS versions where reachability
        // callback lags behind activation.
        Task.detached { [weak self] in
          try? await Task.sleep(for: .milliseconds(250))
          do {
            try await self?.syncService?.requestGameHistory()
          } catch {
            // Ignore; this is best-effort to wake up connectivity
          }
        }
      }
    }
  }

  /// Handle received active game state from paired device
  private func handleReceivedActiveGameState(_ dto: ActiveGameStateDTO) async {
    guard let currentGame = currentGame else {
      // No active game - create one from received state
      await createGameFromRemoteState(dto)
      return
    }

    // Check if this is the same game
    if currentGame.id == dto.gameId {
      // Same game - merge state if remote is more recent
      await mergeRemoteGameState(dto, into: currentGame)
    } else {
      // Different game - decide whether to switch
      await handleDifferentActiveGame(dto)
    }
  }

  /// Handle received game history from paired device
  private func handleReceivedGameHistory(_ games: [HistoryGameDTO]) async {
    guard let modelContext = modelContext else {
      Log.event(.loadFailed, level: .warn, message: "No model context available for history sync")
      return
    }

    var newGamesCount = 0
    var updatedGamesCount = 0

    for gameDTO in games {
      // Check if game already exists
      let descriptor = FetchDescriptor<Game>(
        predicate: #Predicate<Game> { $0.id == gameDTO.id }
      )

      do {
        let existingGames = try modelContext.fetch(descriptor)

        if let existingGame = existingGames.first {
          // Update if remote is newer
          if gameDTO.lastModified > existingGame.lastModified {
            updateGameFromDTO(existingGame, with: gameDTO)
            updatedGamesCount += 1
          }
        } else {
          // Create new game from DTO
          let newGame = createGameFromDTO(gameDTO)
          modelContext.insert(newGame)
          newGamesCount += 1
        }
      } catch {
        Log.error(
          error, event: .loadFailed,
          metadata: ["phase": "processHistoryGame", "gameId": gameDTO.id.uuidString])
      }
    }

    // Save all changes
    do {
      try modelContext.save()
      Log.event(
        .syncSucceeded,
        level: .info,
        message: "History sync complete",
        metadata: ["new": String(newGamesCount), "updated": String(updatedGamesCount)]
      )
    } catch {
      Log.error(error, event: .saveFailed, metadata: ["phase": "saveHistorySync"])
    }
  }

  /// Create a new game from remote state
  private func createGameFromRemoteState(_ dto: ActiveGameStateDTO) async {
    guard let modelContext = modelContext else {
      Log.event(
        .saveFailed, level: .warn,
        message: "Cannot create game from remote state - missing dependencies")
      return
    }

    // Create game from DTO (preserve createdDate and core rule fields)
    let newGame = Game(
      id: dto.gameId,
      gameType: dto.gameType,
      score1: dto.score1,
      score2: dto.score2,
      isCompleted: dto.isCompleted,
      createdDate: dto.createdDate,
      lastModified: dto.lastEventTimestamp,
      currentServer: dto.currentServer,
      serverNumber: dto.serverNumber,
      serverPosition: dto.serverPosition,
      sideOfCourt: dto.sideOfCourt,
      gameState: dto.gameState,
      isFirstServiceSequence: dto.isFirstServiceSequence,
      winningScore: dto.winningScore,
      winByTwo: dto.winByTwo,
      kitchenRule: dto.kitchenRule,
      doubleBounceRule: dto.doubleBounceRule
    )

    // Attach variation if present and found
    if let variationId = dto.gameVariationId {
      let descriptor = FetchDescriptor<GameVariation>(
        predicate: #Predicate<GameVariation> { $0.id == variationId }
      )
      if let variation = try? modelContext.fetch(descriptor).first {
        newGame.gameVariation = variation
      }
    }

    // Insert and save the game
    do {
      modelContext.insert(newGame)
      try modelContext.save()

      // Set as current game and update timer state
      currentGame = newGame
      elapsedTime = dto.elapsedSeconds

      // Set flag to prevent sync loops during remote setup
      isProcessingRemoteUpdate = true
      defer { isProcessingRemoteUpdate = false }

      // Apply completion/timer state (without triggering sync)
      if dto.isTimerRunning {
        gameStartTime = dto.lastTimerStartTime ?? Date()
        startTimerInternal()
      } else {
        stopTimerInternal()
      }

      if dto.isCompleted {
        // Ensure completed metadata is present locally
        newGame.completedDate = dto.lastEventTimestamp
        newGame.duration = dto.elapsedSeconds
        // Stop timer and mark UI state
        stopTimer()
        isGameActive = false
        isGameInitial = false
      }

      Log.event(
        .syncSucceeded, level: .info, message: "Created and adopted game from remote",
        metadata: ["gameId": dto.gameId.uuidString])

    } catch {
      Log.error(error, event: .saveFailed, metadata: ["phase": "createGameFromRemoteState"])
    }
  }

  /// Merge remote game state with local game
  private func mergeRemoteGameState(_ dto: ActiveGameStateDTO, into game: Game) async {
    // Only update if remote state is more recent
    let localTimestamp = game.lastModified

    if dto.lastEventTimestamp > localTimestamp {
      // Set flag to prevent sync loops
      isProcessingRemoteUpdate = true
      defer { isProcessingRemoteUpdate = false }

      // Update game state
      game.score1 = dto.score1
      game.score2 = dto.score2
      game.isCompleted = dto.isCompleted
      game.gameState = dto.gameState
      game.currentServer = dto.currentServer
      game.serverNumber = dto.serverNumber
      game.serverPosition = dto.serverPosition
      game.sideOfCourt = dto.sideOfCourt
      game.isFirstServiceSequence = dto.isFirstServiceSequence
      game.winningScore = dto.winningScore
      game.winByTwo = dto.winByTwo
      game.kitchenRule = dto.kitchenRule
      game.doubleBounceRule = dto.doubleBounceRule
      game.lastModified = dto.lastEventTimestamp

      // If remote completed the game, ensure completion metadata is persisted locally as well
      if dto.isCompleted {
        game.completedDate = dto.lastEventTimestamp
        game.duration = dto.elapsedSeconds
      }

      // Attach variation if present
      if let context = modelContext, let variationId = dto.gameVariationId {
        let descriptor = FetchDescriptor<GameVariation>(
          predicate: #Predicate<GameVariation> { $0.id == variationId }
        )
        if let variation = try? context.fetch(descriptor).first {
          game.gameVariation = variation
        }
      }

      // Handle timer state
      await handleRemoteTimerState(dto)

      // Save changes
      try? await gameManager?.updateGame(game)

      Log.event(.syncSucceeded, level: .debug, message: "Merged remote game state - silent update")
    }
  }

  /// Handle different active game from remote
  private func handleDifferentActiveGame(_ dto: ActiveGameStateDTO) async {
    // Store the pending remote game for later user decision
    pendingRemoteGame = dto

    // Notify that there's a game conflict (this could trigger UI)
    let localId = currentGame?.id.uuidString
    let remoteId = dto.gameId.uuidString
    Log.event(
      .syncStarted,
      level: .warn,
      message: "Game conflict",
      metadata: [
        "local": localId.map { String($0.prefix(8)) } ?? "none",
        "remote": String(remoteId.prefix(8)),
      ]
    )

    // For now, auto-resolve based on which game is more recent
    let localTimestamp = currentGame?.lastModified ?? .distantPast

    if dto.lastEventTimestamp > localTimestamp {
      Log.event(.syncStarted, level: .info, message: "Auto-adopting more recent remote game")
      await adoptRemoteGame(dto)
    } else {
      Log.event(.syncStarted, level: .info, message: "Keeping local game (more recent)")
      // Optionally send our game state to override remote
      syncCurrentGameState()
    }
  }

  /// Handle remote timer state and correct drift
  private func handleRemoteTimerState(_ dto: ActiveGameStateDTO) async {
    let drifted = dto.hasSignificantTimerDrift(from: elapsedTime)
    let runningChanged = dto.isTimerRunning != isTimerRunning

    if drifted || runningChanged {
      #if os(iOS)
        if runningChanged {
          // Honor remote pause/resume command, but anchor to phone's current elapsed value.
          let localElapsed = elapsedTime
          Log.event(
            .syncStarted,
            level: .debug,
            message: "(iOS authoritative) Applying remote run-state",
            metadata: [
              "elapsed": String(format: "%.2f", localElapsed),
              "running": String(dto.isTimerRunning),
            ]
          )

          let wasProcessing = isProcessingRemoteUpdate
          isProcessingRemoteUpdate = true
          setTimerBaseline(
            elapsedSeconds: localElapsed,
            isRunning: dto.isTimerRunning,
            lastStartTime: nil
          )
          isProcessingRemoteUpdate = wasProcessing

          // Broadcast authoritative baseline to watch
          syncCurrentGameState()
        } else if drifted {
          // Only drift (no state change): just re-broadcast our baseline for watch to align
          Log.event(
            .syncStarted, level: .debug,
            message: "(iOS authoritative) Drift detected; re-broadcasting local baseline")
          syncCurrentGameState()
        }
      #else
        // On watchOS, adopt the phone's timer baseline so the watch stays in sync with the phone.
        Log.event(
          .syncStarted,
          level: .debug,
          message: "⌚ Applying phone timer baseline",
          metadata: [
            "elapsed": String(format: "%.2f", dto.elapsedSeconds),
            "running": String(dto.isTimerRunning),
          ]
        )

        // Ensure baseline update does not re-sync immediately
        let wasProcessing = isProcessingRemoteUpdate
        isProcessingRemoteUpdate = true
        setTimerBaseline(
          elapsedSeconds: dto.elapsedSeconds,
          isRunning: dto.isTimerRunning,
          lastStartTime: dto.lastTimerStartTime
        )
        isProcessingRemoteUpdate = wasProcessing
      #endif
    }
  }

  /// Send current game state to paired device
  private func syncCurrentGameState() {
    guard let game = currentGame,
      let syncService = syncService
    else { return }

    Task {
      do {
        let dto = ActiveGameStateDTO.from(
          game: game,
          elapsedSeconds: elapsedTime,
          isTimerRunning: isTimerRunning,
          lastTimerStartTime: gameStartTime
        )

        try await syncService.sendActiveGameState(dto)
      } catch {
        Log.error(error, event: .syncFailed, context: .current(gameId: game.id))
      }
    }
  }

  /// Enable or disable sync functionality
  public func setSyncEnabled(_ enabled: Bool) {
    Task { @MainActor in
      syncService?.setSyncEnabled(enabled)
    }
  }

  /// Get current sync state for UI display
  public var syncState: ActiveGameSyncService.SyncState {
    get async {
      return syncService?.syncState ?? .disconnected
    }
  }

  /// Handle history request from paired device
  private func handleHistoryRequest() async {
    guard let modelContext = modelContext,
      let syncService = syncService
    else {
      Log.event(
        .syncFailed, level: .warn, message: "Cannot handle history request - missing dependencies")
      return
    }

    do {
      // Fetch completed games for sharing
      let descriptor = FetchDescriptor<Game>(
        predicate: #Predicate<Game> { $0.isCompleted == true },
        sortBy: [SortDescriptor(\.completedDate, order: .reverse)]
      )

      let completedGames = try modelContext.fetch(descriptor)

      // Convert to DTOs
      let gameDTOs = completedGames.map { HistoryGameDTO(from: $0) }

      // Send in batches to avoid message size limits
      let batchSize = 20
      for batch in gameDTOs.chunked(into: batchSize) {
        try await syncService.sendGameHistory(Array(batch))
      }

      Log.event(
        .syncSucceeded,
        level: .info,
        message: "Sent games to paired device",
        metadata: ["count": String(gameDTOs.count)]
      )

    } catch {
      Log.error(error, event: .syncFailed, metadata: ["phase": "handleHistoryRequest"])
    }
  }

  /// Update existing game from DTO
  private func updateGameFromDTO(_ game: Game, with dto: HistoryGameDTO) {
    game.score1 = dto.score1
    game.score2 = dto.score2
    game.isCompleted = dto.isCompleted
    game.completedDate = dto.completedDate
    game.lastModified = dto.lastModified
    game.duration = dto.duration
    game.winningScore = dto.winningScore
    game.notes = dto.notes
  }

  /// Create new game from DTO
  private func createGameFromDTO(_ dto: HistoryGameDTO) -> Game {
    let game = Game(
      id: dto.id,
      gameType: dto.gameType,
      score1: dto.score1,
      score2: dto.score2,
      isCompleted: dto.isCompleted,
      createdDate: dto.createdDate,
      lastModified: dto.lastModified
    )

    game.completedDate = dto.completedDate
    game.duration = dto.duration
    game.winningScore = dto.winningScore
    game.notes = dto.notes

    return game
  }

  /// Request game history from paired device (typically watch → phone)
  public func requestGameHistory() async {
    guard let syncService = syncService else {
      Log.event(.syncFailed, level: .warn, message: "Sync service not available")
      return
    }

    do {
      try await syncService.requestGameHistory()
      Log.event(.syncStarted, level: .info, message: "Requested game history from paired device")
    } catch {
      Log.error(error, event: .syncFailed, metadata: ["phase": "requestGameHistory"])
    }
  }

  /// Adopt a remote game, completing the current one if necessary
  private func adoptRemoteGame(_ dto: ActiveGameStateDTO) async {
    // Complete current game if it exists and isn't completed
    if let currentGame = currentGame, !currentGame.isCompleted {
      do {
        try await gameManager?.completeGame(currentGame)
        Log.event(
          .saveSucceeded, level: .info, message: "Completed local game to adopt remote game")
      } catch {
        Log.error(error, event: .saveFailed, metadata: ["phase": "adoptRemote_completeCurrent"])
      }
    }

    // Clear pending remote game
    pendingRemoteGame = nil

    // Check if remote game already exists locally
    guard let modelContext = modelContext else {
      Log.event(.saveFailed, level: .warn, message: "No model context for adopting remote game")
      return
    }

    let descriptor = FetchDescriptor<Game>(
      predicate: #Predicate<Game> { $0.id == dto.gameId }
    )

    do {
      let existingGames = try modelContext.fetch(descriptor)

      if let existingGame = existingGames.first {
        // Game exists - merge state and set as current
        await mergeRemoteGameState(dto, into: existingGame)
        currentGame = existingGame
        Log.event(
          .syncSucceeded, level: .info, message: "Adopted existing remote game",
          metadata: ["gameId": dto.gameId.uuidString])
      } else {
        // Game doesn't exist - create it
        await createGameFromRemoteState(dto)
        Log.event(
          .syncSucceeded, level: .info, message: "Created and adopted new remote game",
          metadata: ["gameId": dto.gameId.uuidString])
      }
    } catch {
      Log.error(error, event: .syncFailed, metadata: ["phase": "adoptRemote_fetchAndAdopt"])
    }
  }

  /// Get information about pending remote game conflict
  public var hasPendingGameConflict: Bool {
    pendingRemoteGame != nil
  }

  /// Get pending remote game information
  public var pendingRemoteGameInfo: (gameId: UUID, gameType: GameType, lastModified: Date)? {
    guard let pending = pendingRemoteGame else { return nil }
    return (pending.gameId, pending.gameType, pending.lastEventTimestamp)
  }

  /// Manually adopt the pending remote game
  public func adoptPendingRemoteGame() async {
    guard let pending = pendingRemoteGame else { return }
    await adoptRemoteGame(pending)
  }

  /// Reject the pending remote game and keep local game
  public func rejectPendingRemoteGame() {
    pendingRemoteGame = nil
    // Send our current game state to override remote
    syncCurrentGameState()
    Log.event(.syncStarted, level: .info, message: "Rejected remote game, keeping local game")
  }

  /// Enable or disable haptic feedback for local actions
  public func setHapticsEnabled(_ enabled: Bool) {
    hapticService.isEnabled = enabled
  }

  /// Get current haptic feedback status
  public var isHapticsEnabled: Bool {
    hapticService.isEnabled
  }

  /// Trigger haptic feedback for external scoring actions
  public func triggerScoreHaptic() {
    if !isProcessingRemoteUpdate {
      hapticService.scoreAction()
    }
  }

  /// Trigger haptic feedback for external serve change actions
  public func triggerServeChangeHaptic() {
    if !isProcessingRemoteUpdate {
      hapticService.serveChange()
    }
  }

  /// Start a new game from this device, syncing to paired device
  public func startNewSyncedGame(gameType: GameType, gameVariation: GameVariation? = nil)
    async throws
  {
    guard let gameManager = gameManager else {
      throw GameError.noActiveGame
    }

    // Create the new game through the game manager
    let newGame: Game
    if let gameVariation = gameVariation {
      newGame = try await gameManager.createGame(variation: gameVariation)
    } else {
      newGame = try await gameManager.createGame(type: gameType)
    }

    // Set as current game (this will trigger sync)
    setCurrentGame(newGame)

    Log.event(
      .syncStarted, level: .info, message: "Started new synced game",
      metadata: ["type": gameType.displayName])
  }

  /// Replace the current game with a new one, completing the old game if necessary
  public func replaceCurrentGame(with newGameType: GameType, gameVariation: GameVariation? = nil)
    async throws
  {
    // Complete the current game if it exists and isn't already completed
    if let currentGame = currentGame, !currentGame.isCompleted {
      try await completeCurrentGame()
    }

    // Start the new game
    try await startNewSyncedGame(gameType: newGameType, gameVariation: gameVariation)

    Log.event(
      .syncStarted, level: .info, message: "Replaced current game",
      metadata: ["type": newGameType.displayName])
  }
}

// MARK: - Game State Helpers

extension ActiveGameStateManager {

  /// Quick access to current game score
  public var currentScore: String? {
    guard let game = currentGame else { return nil }
    return "\(game.score1) - \(game.score2)"
  }

  /// Quick access to current game type display name
  public var currentGameTypeDisplayName: String? {
    currentGame?.gameType.displayName
  }

  /// Quick access to current game type color
  public var currentGameTypeColor: Color? {
    guard let type = currentGame?.gameType else { return nil }
    return DesignSystem.Colors.gameType(type)
  }

  /// Quick access to current game type icon name
  public var currentGameTypeIcon: String? {
    currentGame?.gameType.iconName
  }

  /// Whether the current game is close to completion
  public var isGameCloseToCompletion: Bool {
    guard let game = currentGame else { return false }
    let maxScore = max(game.score1, game.score2)
    return maxScore >= game.winningScore - 2
  }

  // MARK: - State Validation

  /// Validate consistency between timer state, game state, and UI state
  public func validateStateConsistency() -> Bool {
    guard let game = currentGame else { return true }

    // Timer should only run when game is playing
    let timerStateValid = !isTimerRunning || game.gameState == .playing

    // UI state should match game state
    let gameActiveValid = isGameActive == (game.gameState == .playing)
    let gameInitialValid = isGameInitial == (game.gameState == .initial)

    if !timerStateValid {
      Log.event(
        .actionTapped,
        level: .warn,
        message: "Timer state inconsistency",
        metadata: ["state": game.gameState.rawValue]
      )
    }

    if !gameActiveValid {
      Log.event(
        .actionTapped,
        level: .warn,
        message: "UI state inconsistency (isGameActive)",
        metadata: ["isGameActive": String(isGameActive), "state": game.gameState.rawValue]
      )
    }

    if !gameInitialValid {
      Log.event(
        .actionTapped,
        level: .warn,
        message: "UI state inconsistency (isGameInitial)",
        metadata: ["isGameInitial": String(isGameInitial), "state": game.gameState.rawValue]
      )
    }

    return timerStateValid && gameActiveValid && gameInitialValid
  }
}
