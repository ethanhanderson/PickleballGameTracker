//
//  LiveGameStateManager.swift
//  SharedGameCore
//
//  Centralized live game state manager replacing ActiveGameStateManager,
//  GameSessionManager, and TimerManager.
//

import Foundation
@preconcurrency import SwiftData
import SwiftUI
import Observation
#if canImport(ActivityKit)
import ActivityKit
#endif

@MainActor
@Observable
public final class LiveGameStateManager: LiveGameCoordinator, Sendable {

  // MARK: - Factories

  public static func production(
    storage: any SwiftDataStorageProtocol = SwiftDataStorage.shared
  ) -> LiveGameStateManager {
    let manager = LiveGameStateManager()
    let gameManager = SwiftDataGameManager(storage: storage)
    manager._gameManager = gameManager
    gameManager.activeGameDelegate = manager._delegateProxy

    return manager
  }

  public static func preview(container: ModelContainer) -> LiveGameStateManager {
    let storage = SwiftDataStorage(modelContainer: container)
    return production(storage: storage)
  }

  // MARK: - Dependencies

  private var _gameManager: SwiftDataGameManager?
  public var gameManager: SwiftDataGameManager? { _gameManager }

  private let timer = TimerManager()
  private let sessionStore = LiveSessionStore.shared
  
  // Weak reference to sync coordinator for checking if another device is tracking
  @ObservationIgnored
  private weak var syncCoordinator: LiveSyncCoordinator?

  // Delegate proxy to keep compiler happy with weak reference on SwiftDataGameManager
  @ObservationIgnored
  private lazy var _delegateProxy: DelegateProxy = DelegateProxy(owner: self)

  // MARK: - State

  public private(set) var currentGame: Game?
  public private(set) var isGameLive: Bool = false
  public private(set) var isGameInitial: Bool = true
  public private(set) var currentServeNumber: Int = 1

  public var hasLiveGame: Bool {
    currentGame != nil && currentGame?.isCompleted == false
  }

  // Sync removed

  // Timer state properties - these need to be stored to trigger UI updates
  public private(set) var isTimerRunning: Bool = false
  public private(set) var elapsedTime: TimeInterval = 0
  public private(set) var formattedElapsedTime: String = "00:00"
  public private(set) var formattedElapsedTimeWithCentiseconds: String = "00:00.00"

  public var isTimerRunningProxy: Bool { timer.isRunning }
  public var elapsedTimeProxy: TimeInterval { timer.elapsedTime }
  public var formattedElapsedTimeProxy: String { timer.formattedElapsedTime }
  public var formattedElapsedTimeWithCentisecondsProxy: String { timer.formattedElapsedTimeWithCentiseconds }

  // MARK: - Derived UI Helpers
  public var currentGameTypeDisplayName: String? { currentGame?.gameType.displayName }
  public var currentScore: String? { currentGame?.formattedScore }
  public var currentGameTypeIcon: String? { currentGame?.gameType.iconName }
  public var currentGameTypeColor: Color? { currentGame?.gameType.color }

  public init() {
    timer.setTimerUpdateCallback { [weak self] in
      Task { @MainActor in
        self?.updateTimerProperties()
      }
    }
  }

  // MARK: - Configuration

  public func configure(gameManager: SwiftDataGameManager) {
    self._gameManager = gameManager
    gameManager.activeGameDelegate = _delegateProxy
  }

  public func configure(syncCoordinator: LiveSyncCoordinator) {
    self.syncCoordinator = syncCoordinator
  }

  // Sync configuration removed

  // MARK: - Lifecycle

  public func setCurrentGame(_ game: Game) async {
    if let existing = currentGame, existing.id != game.id {
      timer.stop()
      timer.reset()
      currentServeNumber = 1
    }
    currentGame = game
    isGameInitial = (game.gameState == .initial)
    isGameLive = (game.gameState == .playing)
    
    if let gm = _gameManager {
      gm.activeGameDelegate = _delegateProxy
    }

    // Persist session for fast resume
    persistSession()
  }
  
  // Sync session initialization removed

  public func clearCurrentGame() {
    currentGame = nil
    isGameLive = false
    isGameInitial = true
    currentServeNumber = 1
    timer.stop()
    timer.reset()
    sessionStore.clear()
  }

  // MARK: - Creation

  /// Create a new game for a `GameType`, set it as current, and return it
  public func createGame(type: GameType) async throws -> Game {
    guard let gm = _gameManager else { throw GameError.noActiveGame }
    let game = try await gm.createGame(type: type)
    await setCurrentGame(game)
    return game
  }

  /// Create a new game with custom rules, set it as current, and return it
  public func createGame(type: GameType, rules: GameRules) async throws -> Game {
    guard let gm = _gameManager else { throw GameError.noActiveGame }
    let game = try await gm.createGame(type: type, rules: rules)
    await setCurrentGame(game)
    return game
  }

  /// Start a game using a fluent builder.
  ///
  /// This is a convenience wrapper around `startNewGame(with:)` that accepts
  /// a `GameStartBuilder` for a more ergonomic API.
  ///
  /// - Parameter builder: The configured game start builder
  /// - Returns: The newly created and started game
  public func start(using builder: GameStartBuilder) async throws -> Game {
    let config = try builder.build()
    return try await startNewGame(with: config)
  }

  /// Start a new game by reusing the most recent completed game's participants and rules.
  ///
  /// This is the "Last Game" quick-start feature. It finds the most recently completed
  /// game of the specified type and creates a new game with:
  /// - Exact same participants (players or teams)
  /// - Same rules and settings (variation)
  /// - Fresh game state (scores reset, new timestamp)
  ///
  /// If no completed game exists or participants are missing, throws an error.
  /// The caller should handle this by presenting the full Setup sheet.
  ///
  /// - Parameter type: The game type to search for
  /// - Returns: The newly created game with reused participants
  /// - Throws: `GameError.noActiveGame` if manager not configured,
  ///           `GameRulesError.invalidConfiguration` if no suitable game found
  public func startLastGame(of type: GameType) async throws -> Game {
    guard let gm = _gameManager else { throw GameError.noActiveGame }
    
    // Find most recent completed game of this type
    guard let lastGame = try await gm.mostRecentCompletedGame(of: type) else {
      throw GameRulesError.invalidConfiguration(
        "No completed \(type.displayName) game found. Please use full setup."
      )
    }
    
    // Determine team size
    guard let teamSize = TeamSize(playersPerSide: lastGame.effectiveTeamSize) else {
      throw GameRulesError.invalidTeamSize(lastGame.effectiveTeamSize)
    }
    
    // Build participants - require exact match, no anonymous fallback
    let participants: Participants
    switch lastGame.participantMode {
    case .players:
      guard !lastGame.side1PlayerIds.isEmpty && !lastGame.side2PlayerIds.isEmpty else {
        throw GameRulesError.invalidConfiguration(
          "Last game has no participants. Please use full setup."
        )
      }
      participants = Participants(
        side1: .players(lastGame.side1PlayerIds),
        side2: .players(lastGame.side2PlayerIds)
      )
      
    case .teams:
      guard let team1Id = lastGame.side1TeamId, let team2Id = lastGame.side2TeamId else {
        throw GameRulesError.invalidConfiguration(
          "Last game has no team participants. Please use full setup."
        )
      }
      participants = Participants(
        side1: .team(team1Id),
        side2: .team(team2Id)
      )
      
    case .anonymous:
      throw GameRulesError.invalidConfiguration(
        "Last game was anonymous. Please use full setup."
      )
    }
    
    // Create rules preserving settings from last game
    let rules = try GameRules.createValidated(
      winningScore: lastGame.winningScore,
      winByTwo: lastGame.winByTwo,
      kitchenRule: lastGame.kitchenRule,
      doubleBounceRule: lastGame.doubleBounceRule,
      servingRotation: lastGame.servingRotation,
      sideSwitchingRule: lastGame.sideSwitchingRule,
      scoringType: lastGame.scoringType,
      timeLimit: lastGame.timeLimit,
      maxRallies: lastGame.maxRallies
    )
    
    // Build configuration and start
    let config = GameStartConfiguration(
      gameType: type,
      teamSize: teamSize,
      participants: participants,
      notes: "Resumed from last game",
      rules: rules
    )
    
    return try await startNewGame(with: config)
  }

  /// Start a new game from a completed game, preserving participants and rules.
  ///
  /// Note: This method now requires exact participants. Use `startLastGame(of:)` for
  /// the public "Last Game" feature, which includes proper error handling.
  public func startGameFromCompleted(_ lastGame: Game) async throws -> Game {
    guard _gameManager != nil else { throw GameError.noActiveGame }

    // Determine team size from the last game
    guard let teamSize = TeamSize(playersPerSide: lastGame.effectiveTeamSize) else {
      throw GameRulesError.invalidTeamSize(lastGame.effectiveTeamSize)
    }

    // Build participants from the last game - require exact match
    let participants: Participants
    switch lastGame.participantMode {
    case .players:
      guard !lastGame.side1PlayerIds.isEmpty && !lastGame.side2PlayerIds.isEmpty else {
        throw GameRulesError.invalidConfiguration("Game has no participants")
      }
      participants = Participants(
        side1: .players(lastGame.side1PlayerIds),
        side2: .players(lastGame.side2PlayerIds)
      )
      
    case .teams:
      guard let team1Id = lastGame.side1TeamId, let team2Id = lastGame.side2TeamId else {
        throw GameRulesError.invalidConfiguration("Game has no team participants")
      }
      participants = Participants(
        side1: .team(team1Id),
        side2: .team(team2Id)
      )
      
    case .anonymous:
      throw GameRulesError.invalidConfiguration("Cannot restart anonymous game")
    }

    // Create rules preserving settings from last game
    let rules = try GameRules.createValidated(
      winningScore: lastGame.winningScore,
      winByTwo: lastGame.winByTwo,
      kitchenRule: lastGame.kitchenRule,
      doubleBounceRule: lastGame.doubleBounceRule,
      servingRotation: lastGame.servingRotation,
      sideSwitchingRule: lastGame.sideSwitchingRule,
      scoringType: lastGame.scoringType,
      timeLimit: lastGame.timeLimit,
      maxRallies: lastGame.maxRallies
    )

    // Build configuration
    let config = GameStartConfiguration(
      gameType: lastGame.gameType,
      teamSize: teamSize,
      participants: participants,
      notes: "Resumed from previous game",
      rules: rules
    )

    return try await startNewGame(with: config)
  }

  /// Start a new game using a standardized configuration contract
  public func startNewGame(with config: GameStartConfiguration) async throws -> Game {
    guard let gm = _gameManager else { throw GameError.noActiveGame }

    // Reset timer for new game
    timer.stop()
    timer.reset()

    // Detect anonymous players flow (no persisted participant IDs)
    let isAnonymousPlayers: Bool = {
      switch (config.participants.side1, config.participants.side2) {
      case (.players(let a), .players(let b)):
        return a.isEmpty && b.isEmpty
      default:
        return false
      }
    }()

    // Validate invariants unless we are using anonymous players fallback
    if !isAnonymousPlayers {
      try validateStartConfiguration(config)
    }

    // Get rules from config or use game type defaults
    let rules = config.rules ?? config.gameType.defaultRules

    // Anonymous players flow: create without a matchup and mark participants as players with empty arrays
    if isAnonymousPlayers {
      let game = try await gm.createGame(type: config.gameType, rules: rules)
      game.notes = config.notes
      game.participantMode = .players
      game.side1PlayerIds = []
      game.side2PlayerIds = []
      try await gm.updateGame(game)
      await setCurrentGame(game)
      return game
    }

    // Build a MatchupSelection from participants for non-anonymous starts
    let matchup: MatchupSelection
    switch (config.participants.side1, config.participants.side2) {
    case (.players(let a), .players(let b)):
      matchup = MatchupSelection(teamSize: config.teamSize.playersPerSide, mode: .players(sideA: a, sideB: b))
    case (.team(let t1), .team(let t2)):
      matchup = MatchupSelection(teamSize: config.teamSize.playersPerSide, mode: .teams(team1Id: t1, team2Id: t2))
    default:
      throw GameRulesError.invalidConfiguration("Participants shape does not match team size")
    }

    // Persist via manager; set as current
    let game = try await gm.createGame(type: config.gameType, rules: rules, matchup: matchup)
    game.notes = config.notes
    await setCurrentGame(game)
    return game
  }

  private func validateStartConfiguration(_ config: GameStartConfiguration) throws(GameRulesError) {
    // Ensure team size supported by game type bounds
    let minSize = config.gameType.minTeamSize
    let maxSize = config.gameType.maxTeamSize
    let size = config.teamSize.playersPerSide
    guard size >= minSize && size <= maxSize else {
      throw GameRulesError.invalidTeamSize(size)
    }

    switch (config.participants.side1, config.participants.side2, config.teamSize) {
    case (.players(let a), .players(let b), .singles):
      guard a.count == 1 && b.count == 1 else {
        throw GameRulesError.invalidConfiguration("Singles requires exactly one player per side")
      }
    case (.players(let a), .players(let b), .doubles):
      guard a.count == 2 && b.count == 2 else {
        throw GameRulesError.invalidConfiguration("Doubles requires exactly two players per side when using players mode")
      }
    case (.team, .team, _):
      break
    default:
      throw GameRulesError.invalidConfiguration("Participants must both be players or both teams and match team size")
    }
  }

  public func toggleGameState() async throws {
    guard let game = currentGame, let gm = _gameManager else { throw GameError.noActiveGame }
    switch game.gameState {
    case .initial: try await startGame()
    case .playing: try await pauseGame()
    case .paused: try await resumeGame()
    case .completed: throw GameError.gameAlreadyCompleted
    case .serving: try await resumeGame()
    }
    // Ensure delegate binding
    gm.activeGameDelegate = _delegateProxy
  }

  public func startGame() async throws {
    guard let game = currentGame, let gm = _gameManager else { throw GameError.noActiveGame }
    
    game.gameState = .playing
    isGameLive = true
    isGameInitial = false
    game.logEvent(.gameResumed, at: elapsedTime)
    try await gm.updateGame(game)
    timer.start()
    updateTimerProperties()
    persistSession()
    
    #if canImport(ActivityKit)
    if #available(iOS 16.1, watchOS 9.1, *) {
      await startLiveActivity(for: game)
    }
    #endif
  }

  public func pauseGame() async throws {
    guard let game = currentGame, let gm = _gameManager else { throw GameError.noActiveGame }
    
    game.gameState = .paused
    isGameLive = false
    game.logEvent(.gamePaused, at: elapsedTime)
    try await gm.updateGame(game)
    timer.pause()
    updateTimerProperties()
    persistSession()
  }

  public func resumeGame() async throws {
    guard let game = currentGame, let gm = _gameManager else { throw GameError.noActiveGame }
    
    game.gameState = .playing
    isGameLive = true
    game.logEvent(.gameResumed, at: elapsedTime)
    try await gm.updateGame(game)
    timer.resume()
    updateTimerProperties()
    persistSession()
  }

  public func completeCurrentGame() async throws {
    guard let game = currentGame, let gm = _gameManager else { throw GameError.noActiveGame }
    try await gm.completeGame(game)
    game.logEvent(.gameCompleted, at: elapsedTime)
    timer.stop()
    
    #if canImport(ActivityKit)
    if #available(iOS 16.1, watchOS 9.1, *) {
      await endLiveActivity()
    }
    #endif
    
    clearCurrentGame()
  }

  // MARK: - Scoring

  public func scorePoint(for team: Int) async throws {
    guard let game = currentGame, let gm = _gameManager else { throw GameError.noActiveGame }
    try await gm.scorePoint(for: team, in: game)
    game.logEvent(.playerScored, at: elapsedTime, teamAffected: team)
    
    #if canImport(ActivityKit)
    if #available(iOS 16.1, watchOS 9.1, *) {
      await updateLiveActivity(for: game)
    }
    #endif
  }

  public func undoLastPoint() async throws {
    guard let game = currentGame, let gm = _gameManager else { throw GameError.noActiveGame }
    try await gm.undoLastPoint(in: game)
    game.logEvent(.scoreUndone, at: elapsedTime)
    
    #if canImport(ActivityKit)
    if #available(iOS 16.1, watchOS 9.1, *) {
      await updateLiveActivity(for: game)
    }
    #endif
  }

  public func decrementScore(for team: Int) async throws {
    guard let game = currentGame, let gm = _gameManager else { throw GameError.noActiveGame }
    try await gm.decrementScore(for: team, in: game)
  }

  public func resetCurrentGame() async throws {
    guard let game = currentGame, let gm = _gameManager else { throw GameError.noActiveGame }
    try await gm.resetGame(game)
    currentServeNumber = 1
    timer.reset()

    // TODO: Send full snapshot after reset
  }

  // MARK: - Serving

  public func switchServer() async throws {
    guard let game = currentGame, let gm = _gameManager else { throw GameError.noActiveGame }
    try await gm.switchServer(in: game)
    currentServeNumber += 1
  }

  public func setServer(to team: Int) async throws {
    guard let game = currentGame, let gm = _gameManager else { throw GameError.noActiveGame }
    try await gm.setServer(to: team, in: game)
  }

  public func switchServingPlayer() async throws {
    guard let game = currentGame, let gm = _gameManager else { throw GameError.noActiveGame }
    try await gm.switchServingPlayer(in: game)
  }

  public func startSecondServeForCurrentTeam() async throws {
    guard let game = currentGame, let gm = _gameManager else { throw GameError.noActiveGame }
    try await gm.startSecondServeForCurrentTeam(in: game)
  }

  public func handleServiceFault() async throws {
    guard let game = currentGame, let gm = _gameManager else { throw GameError.noActiveGame }
    try await gm.handleServiceFault(in: game)
    game.logEvent(.serviceFault, at: elapsedTime, teamAffected: game.currentServer)
  }

  public func handleNonServingTeamTap(on tappedTeam: Int) async throws {
    guard let game = currentGame, let gm = _gameManager else { throw GameError.noActiveGame }
    try await gm.handleNonServingTeamTap(on: tappedTeam, in: game)
  }

  // MARK: - Timer Controls

  public func startTimer() {
    timer.start()
    updateTimerProperties()
  }

  public func pauseTimer() {
    timer.pause()
    updateTimerProperties()
  }

  public func resumeTimer() {
    timer.resume()
    updateTimerProperties()
  }

  public func toggleTimer() {
    timer.toggle()
    updateTimerProperties()
  }

  public func setElapsedTime(_ timeInterval: TimeInterval) {
    timer.setElapsedTime(timeInterval)
    updateTimerProperties()
    persistSession()
  }

  /// Update the underlying timer's tick interval
  public func setTimerUpdateInterval(_ interval: TimeInterval) {
    timer.setUpdateInterval(interval)
    updateTimerProperties()
  }

  // Reset functionality removed; elapsed time can be set explicitly via setElapsedTime(_:)

  // MARK: - Private Timer Updates

  private var lastLiveActivityUpdateTime: TimeInterval = 0
  private let liveActivityUpdateInterval: TimeInterval = 1.0
  
  private func updateTimerProperties() {
    isTimerRunning = timer.isRunning
    elapsedTime = timer.elapsedTime
    let newFormattedTime = timer.formattedElapsedTime
    formattedElapsedTime = newFormattedTime
    formattedElapsedTimeWithCentiseconds = timer.formattedElapsedTimeWithCentiseconds
    
    #if canImport(ActivityKit)
    if #available(iOS 16.1, watchOS 9.1, *) {
      let currentTime = timer.elapsedTime
      let timeSinceLastUpdate = currentTime - lastLiveActivityUpdateTime
      
      if timeSinceLastUpdate >= liveActivityUpdateInterval || lastLiveActivityUpdateTime == 0 {
        Task { @MainActor in
          if let game = currentGame, hasLiveGame {
            await updateLiveActivity(for: game)
            lastLiveActivityUpdateTime = currentTime
          }
        }
      }
    }
    #endif
  }

  // MARK: - Session Persistence
  private func persistSession() {
    guard let game = currentGame, game.isCompleted == false else { return }
    let state = LiveSessionState(
      gameId: game.id,
      elapsedTime: elapsedTime,
      isTimerRunning: isTimerRunning,
      lastModified: Date()
    )
    sessionStore.save(state)
  }

  public func attemptResumeFromSession() async {
    guard let gm = _gameManager else { return }
    guard currentGame == nil else { return }
    
    // First, try to resume from session store if available
    if let state = sessionStore.load() {
      if let game = try? await gm.storage.loadGame(id: state.gameId), game.isCompleted == false {
        await restoreGame(game, elapsedTime: state.elapsedTime, wasTimerRunning: state.isTimerRunning)
        return
      }
    }
    
    // If no session store or session game not found, check database for active games
    await attemptRestoreActiveGameFromDatabase()
  }
  
  private func restoreGame(_ game: Game, elapsedTime: TimeInterval, wasTimerRunning: Bool) async {
    await setCurrentGame(game)
    setElapsedTime(elapsedTime)
    
    if wasTimerRunning && game.gameState == .playing {
      let anotherDeviceTracking = syncCoordinator?.isAnotherDeviceActivelyTracking() ?? false
      if !anotherDeviceTracking {
        timer.resume()
      } else {
        timer.pause()
      }
    } else {
      timer.pause()
    }
    
    #if canImport(ActivityKit)
    if #available(iOS 16.1, watchOS 9.1, *) {
      if game.gameState == .playing || game.gameState == .paused {
        await startLiveActivity(for: game)
      }
    }
    #endif
  }
  
  private func attemptRestoreActiveGameFromDatabase() async {
    guard let gm = _gameManager else { return }
    
    do {
      let activeGames = try await gm.storage.loadActiveGames()
      
      // Prioritize games in .playing state
      let playingGame = activeGames.first { $0.gameState == .playing }
      let gameToRestore = playingGame ?? activeGames.first
      
      guard let game = gameToRestore, !game.isCompleted else { return }
      
      // Estimate elapsed time from game events
      // Events store timestamp as elapsed time when they occurred
      let estimatedElapsedTime: TimeInterval
      if let lastEvent = game.eventsByTimestamp.first {
        // Use the timestamp from the most recent event
        // For paused games, this represents when it was paused
        // For playing games, this is the last recorded elapsed time
        estimatedElapsedTime = lastEvent.timestamp
      } else if let duration = game.duration {
        // Fallback to stored duration if available
        estimatedElapsedTime = duration
      } else {
        // No events or duration: start at 0 for new games
        estimatedElapsedTime = 0
      }
      
      // For paused games, restore without starting timer
      // For playing games, check if another device is tracking
      let shouldStartTimer = game.gameState == .playing
      let anotherDeviceTracking = syncCoordinator?.isAnotherDeviceActivelyTracking() ?? false
      
      await setCurrentGame(game)
      setElapsedTime(estimatedElapsedTime)
      
      if shouldStartTimer && !anotherDeviceTracking {
        timer.resume()
      } else {
        timer.pause()
      }
      
      #if canImport(ActivityKit)
      if #available(iOS 16.1, watchOS 9.1, *) {
        if game.gameState == .playing || game.gameState == .paused {
          await startLiveActivity(for: game)
        }
      }
      #endif
      
      Log.event(
        .loadSucceeded,
        level: .info,
        message: "Active game restored from database",
        metadata: [
          "gameId": "\(game.id)",
          "gameState": "\(game.gameState)",
          "source": "database"
        ]
      )
    } catch {
      Log.error(
        error,
        event: .loadFailed,
        metadata: ["phase": "attemptRestoreActiveGameFromDatabase"]
      )
    }
  }

  /// Persist session state without pausing the game
  /// Used when app goes to background but continues running
  public func persistSessionOnly() async {
    persistSession()
  }

  /// Handle app termination
  /// Pauses the game and persists state if no other device is actively tracking
  public func handleAppWillTerminate() async {
    guard let game = currentGame else { return }
    guard !game.isCompleted else { return }
    
    // Check if another device is actively tracking
    let anotherDeviceTracking = syncCoordinator?.isAnotherDeviceActivelyTracking() ?? false
    
    if !anotherDeviceTracking && isGameLive && game.gameState == .playing {
      // Only pause if we're the only device tracking
      try? await pauseGame()
      persistSession()
    } else {
      // Just persist current state without pausing (another device is tracking)
      persistSession()
    }
  }
  
  // All sync helper and transport-related functions removed

  // MARK: - LiveGameCoordinator

  public func incrementServeNumber() { currentServeNumber += 1 }
  public func triggerServeChangeHaptic() { HapticFeedbackService.shared.serveChange() }
  public func gameStateDidChange(to gameState: GameState) {
    switch gameState {
    case .playing:
      isGameLive = true
      if !timer.isRunning { timer.resume() }
      updateTimerProperties()
      
      #if canImport(ActivityKit)
      if #available(iOS 16.1, watchOS 9.1, *) {
        Task { @MainActor in
          if let game = currentGame {
            await startLiveActivity(for: game)
          }
        }
      }
      #endif
    case .paused:
      isGameLive = false
      if timer.isRunning { timer.pause() }
      updateTimerProperties()
    case .completed:
      isGameLive = false
      timer.stop()
      updateTimerProperties()
    case .initial, .serving:
      updateTimerProperties()
      break
    }
  }
  public func gameDidComplete(_ game: Game) { 
    currentGame = game
    
    #if canImport(ActivityKit)
    if #available(iOS 16.1, watchOS 9.1, *) {
      Task { @MainActor in
        await endLiveActivity()
      }
    }
    #endif
  }
  
  public func gameDidUpdate(_ game: Game) { 
    if currentGame?.id == game.id { 
      currentGame = game
      
      #if canImport(ActivityKit)
      if #available(iOS 16.1, watchOS 9.1, *) {
        Task { @MainActor in
          await updateLiveActivity(for: game)
        }
      }
      #endif
    } 
  }
  
  public func gameDidDelete(_ game: Game) { 
    if currentGame?.id == game.id { 
      #if canImport(ActivityKit)
      if #available(iOS 16.1, watchOS 9.1, *) {
        Task { @MainActor in
          await endLiveActivity()
        }
      }
      #endif
      clearCurrentGame()
    } 
  }
  
  public func validateStateConsistency() -> Bool { timer.validateState() }
  
  // MARK: - Live Activity Management
  
  #if canImport(ActivityKit)
  @available(iOS 16.1, watchOS 9.1, *)
  private func startLiveActivity(for game: Game) async {
    guard let gm = _gameManager else { return }
    guard hasLiveGame else { return }
    let context = gm.storage.modelContainer.mainContext
    
    let timerString = getCurrentTimerString()
    let mostRecentEvent = game.eventsByTimestamp.first
    let eventDescription = mostRecentEvent?.shortDescription
    let eventType = mostRecentEvent?.eventType.rawValue
    let eventTeam = mostRecentEvent?.teamAffected
    
    lastLiveActivityUpdateTime = timer.elapsedTime
    
    do {
      try await LiveActivityManager.shared.startActivity(
        for: game,
        context: context,
        formattedElapsedTime: timerString,
        mostRecentEventDescription: eventDescription,
        mostRecentEventType: eventType,
        mostRecentEventTeamAffected: eventTeam
      )
    } catch {
      Log.error(error, event: .appLaunch, metadata: ["gameId": "\(game.id)", "action": "startLiveActivity"])
    }
  }
  
  @available(iOS 16.1, watchOS 9.1, *)
  private func updateLiveActivity(for game: Game) async {
    guard hasLiveGame else { return }
    
    let timerString = getCurrentTimerString()
    let mostRecentEvent = game.eventsByTimestamp.first
    let eventDescription = mostRecentEvent?.shortDescription
    let eventType = mostRecentEvent?.eventType.rawValue
    let eventTeam = mostRecentEvent?.teamAffected
    
    await LiveActivityManager.shared.updateActivity(
      for: game,
      formattedElapsedTime: timerString,
      mostRecentEventDescription: eventDescription,
      mostRecentEventType: eventType,
      mostRecentEventTeamAffected: eventTeam
    )
  }
  
  private func getCurrentTimerString() -> String {
    let timerValue = timer.formattedElapsedTime
    return timerValue.isEmpty ? "00:00" : timerValue
  }
  
  @available(iOS 16.1, watchOS 9.1, *)
  private func endLiveActivity() async {
    await LiveActivityManager.shared.endActivity()
  }
  #endif

  // MARK: - Internal Delegate Proxy

  private final class DelegateProxy: LiveGameCoordinator, Sendable {
    weak var owner: LiveGameStateManager?
    init(owner: LiveGameStateManager) { self.owner = owner }
    var currentGame: Game? { owner?.currentGame }
    func setCurrentGame(_ game: Game) { 
      Task { @MainActor in
        await owner?.setCurrentGame(game)
      }
    }
    func incrementServeNumber() { owner?.incrementServeNumber() }
    func triggerServeChangeHaptic() { owner?.triggerServeChangeHaptic() }
    func gameStateDidChange(to gameState: GameState) { owner?.gameStateDidChange(to: gameState) }
    func gameDidComplete(_ game: Game) { owner?.gameDidComplete(game) }
    func gameDidUpdate(_ game: Game) { owner?.gameDidUpdate(game) }
    func gameDidDelete(_ game: Game) { owner?.gameDidDelete(game) }
    func validateStateConsistency() -> Bool { owner?.validateStateConsistency() ?? true }
  }
}


