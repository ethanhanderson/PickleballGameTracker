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
  
  @ObservationIgnored
  private weak var syncCoordinator: LiveSyncCoordinator?

  @ObservationIgnored
  private lazy var _delegateProxy: DelegateProxy = DelegateProxy(owner: self)

  // MARK: - State

  public private(set) var currentGame: Game?
  public private(set) var currentGameTypeSnapshot: GameType?
  public private(set) var isGameLive: Bool = false
  public private(set) var isGameInitial: Bool = true
  public private(set) var currentServeNumber: Int = 1
  private var isCompletingGame: Bool = false

  public var hasLiveGame: Bool {
    currentGame != nil && currentGame?.isCompleted == false
  }

  /// Check if the current game will be deleted (not saved) when ended
  public var willDeleteCurrentGameOnCompletion: Bool {
    guard let game = currentGame else { return false }
    return game.isUnused(elapsedTime: elapsedTime)
  }

  public private(set) var isTimerRunning: Bool = false
  public private(set) var elapsedTime: TimeInterval = 0
  public private(set) var formattedElapsedTime: String = "00:00"
  public private(set) var formattedElapsedTimeWithCentiseconds: String = "00:00.00"

  public var isTimerRunningProxy: Bool { timer.isRunning }
  public var elapsedTimeProxy: TimeInterval { timer.elapsedTime }
  public var formattedElapsedTimeProxy: String { timer.formattedElapsedTime }
  public var formattedElapsedTimeWithCentisecondsProxy: String { timer.formattedElapsedTimeWithCentiseconds }

  // MARK: - Derived UI Helpers
  public var currentGameTypeDisplayName: String? { currentGameTypeSnapshot?.displayName }
  public var currentScore: String? { currentGame?.formattedScore }
  public var currentGameTypeIcon: String? { currentGameTypeSnapshot?.iconName }
  public var currentGameTypeColor: Color? { currentGameTypeSnapshot?.color }

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

  // MARK: - Lifecycle

  public func setCurrentGame(_ game: Game) async {
    let resolved: Game
    if let gm = _gameManager, let reloaded = try? await gm.storage.loadGame(id: game.id) {
      resolved = reloaded
    } else {
      resolved = game
    }

    if let existing = currentGame, existing.id != resolved.id {
      timer.stop()
      timer.reset()
      currentServeNumber = 1
      updateTimerProperties()
    }
    currentGame = resolved
    currentGameTypeSnapshot = resolved.gameType
    isGameInitial = (resolved.gameState == .initial)
    isGameLive = (resolved.gameState == .playing)
    
    if let gm = _gameManager {
      gm.activeGameDelegate = _delegateProxy
    }

    persistSession()
    updateTimerProperties()
  }

  public func clearCurrentGame() {
    currentGame = nil
    currentGameTypeSnapshot = nil
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
    
    guard let lastGame = try await gm.mostRecentCompletedGame(of: type) else {
      throw GameRulesError.invalidConfiguration(
        "No completed \(type.displayName) game found. Please use full setup."
      )
    }
    
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
      
    
    }
    
    let teamSizeValue: Int = {
      switch (participants.side1, participants.side2) {
      case (.players(let a), .players(let b)):
        return min(a.count, b.count)
      case (.team, .team):
        let snapshot = lastGame.teamSize
        return snapshot > 0 ? snapshot : type.defaultTeamSize
      default:
        return type.defaultTeamSize
      }
    }()
    guard let teamSize = TeamSize(playersPerSide: teamSizeValue) else {
      throw GameRulesError.invalidTeamSize(teamSizeValue)
    }
    
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
      
    
    }

    let teamSizeValue: Int = {
      switch (participants.side1, participants.side2) {
      case (.players(let a), .players(let b)):
        return min(a.count, b.count)
      case (.team, .team):
        let snapshot = lastGame.teamSize
        return snapshot > 0 ? snapshot : lastGame.gameType.defaultTeamSize
      default:
        return lastGame.gameType.defaultTeamSize
      }
    }()
    guard let teamSize = TeamSize(playersPerSide: teamSizeValue) else {
      throw GameRulesError.invalidTeamSize(teamSizeValue)
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

    timer.stop()
    timer.reset()
    updateTimerProperties()

    try validateStartConfiguration(config)

    let rules = config.rules ?? config.gameType.defaultRules

    let matchup: MatchupSelection
    switch (config.participants.side1, config.participants.side2) {
    case (.players(let a), .players(let b)):
      matchup = MatchupSelection(teamSize: config.teamSize.playersPerSide, mode: .players(sideA: a, sideB: b))
    case (.team(let t1), .team(let t2)):
      matchup = MatchupSelection(teamSize: config.teamSize.playersPerSide, mode: .teams(team1Id: t1, team2Id: t2))
    default:
      throw GameRulesError.invalidConfiguration("Participants shape does not match team size")
    }

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
    
    try await gm.pauseGame(game)
    game.logEvent(.gamePaused, at: elapsedTime)
    try await gm.updateGame(game)
    updateTimerProperties()
    persistSession()
  }

  public func resumeGame() async throws {
    guard let game = currentGame, let gm = _gameManager else { throw GameError.noActiveGame }
    
    try await gm.resumeGame(game)
    game.logEvent(.gameResumed, at: elapsedTime)
    try await gm.updateGame(game)
    updateTimerProperties()
    persistSession()
  }

  public func completeCurrentGame() async throws {
    guard !isCompletingGame else { return }
    isCompletingGame = true
    defer { isCompletingGame = false }

    guard let game = currentGame, let gm = _gameManager else { throw GameError.noActiveGame }
    if game.isCompleted {
      clearCurrentGame()
      #if canImport(ActivityKit)
      if #available(iOS 16.1, watchOS 9.1, *) {
        await endLiveActivity()
      }
      #endif
      return
    }
    
    let willBeDeleted = game.isUnused(elapsedTime: elapsedTime)
    
    if !willBeDeleted {
      game.logEvent(.gameCompleted, at: elapsedTime)
    }
    
    let wasRunning = timer.isRunning
    timer.stop()
    
    do {
      try await gm.completeGame(game, elapsedTime: elapsedTime)
    } catch {
      if wasRunning { timer.resume() }
      updateTimerProperties()
      throw error
    }
    
    clearCurrentGame()
    
    #if canImport(ActivityKit)
    if #available(iOS 16.1, watchOS 9.1, *) {
      await endLiveActivity()
    }
    #endif
  }

  // MARK: - Scoring

  public func scorePoint(for team: Int) async throws {
    guard let game = currentGame, let gm = _gameManager else { throw GameError.noActiveGame }
    try await gm.scorePointAndLogEvent(for: team, in: game, at: elapsedTime)
    
    #if canImport(ActivityKit)
    if #available(iOS 16.1, watchOS 9.1, *) {
      await updateLiveActivity(for: game)
    }
    #endif
  }

  /// Score a point using an explicit timestamp captured by the caller.
  /// This ensures the same timestamp is used for both local persistence and outbound sync.
  public func scorePoint(for team: Int, at timestamp: TimeInterval) async throws {
    guard let game = currentGame, let gm = _gameManager else { throw GameError.noActiveGame }
    try await gm.scorePointAndLogEvent(for: team, in: game, at: timestamp)
    
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
    let faultTeam = game.currentServer
    try await gm.handleServiceFault(in: game)
    game.logEvent(.serviceFault, at: elapsedTime, teamAffected: faultTeam)
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
    
    if let state = sessionStore.load() {
      if let game = try? await gm.storage.loadGame(id: state.gameId), game.isCompleted == false {
        await restoreGame(game, elapsedTime: state.elapsedTime, wasTimerRunning: state.isTimerRunning)
        return
      }
    }
    
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
      
      let playingGame = activeGames.first { $0.gameState == .playing }
      let gameToRestore = playingGame ?? activeGames.first
      
      guard let game = gameToRestore, !game.isCompleted else { return }
      
      let estimatedElapsedTime: TimeInterval
      if let lastEvent = game.eventsByTimestamp.first {
        estimatedElapsedTime = lastEvent.timestamp
      } else if let duration = game.duration {
        estimatedElapsedTime = duration
      } else {
        estimatedElapsedTime = 0
      }
      
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

  public func persistSessionOnly() async {
    persistSession()
  }

  public func handleAppWillTerminate() async {
    guard let game = currentGame else { return }
    guard !game.isCompleted else { return }
    
    let anotherDeviceTracking = syncCoordinator?.isAnotherDeviceActivelyTracking() ?? false
    
    if !anotherDeviceTracking && isGameLive && game.gameState == .playing {
      try? await pauseGame()
      persistSession()
    } else {
      persistSession()
    }
  }

  // MARK: - LiveGameCoordinator

  public func incrementServeNumber() { currentServeNumber += 1 }
  public func triggerServeChangeHaptic() {
    HapticFeedbackService.shared.serveChange(isGamePlaying: isGameLive)
  }
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
    Task { @MainActor in
      await setCurrentGame(game)
    }
    
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
      Task { @MainActor in
        await setCurrentGame(game)
      }
      
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
    clearCurrentGame()
    
    #if canImport(ActivityKit)
    if #available(iOS 16.1, watchOS 9.1, *) {
      Task { @MainActor in
        await endLiveActivity()
      }
    }
    #endif
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


