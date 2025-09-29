//
//  LiveGameStateManager.swift
//  SharedGameCore
//
//  Centralized live game state manager replacing ActiveGameStateManager,
//  GameSessionManager, and TimerManager.
//

import Foundation
import SwiftData
import SwiftUI
import Observation

@MainActor
@Observable
public final class LiveGameStateManager: LiveGameCoordinator, Sendable {

  // MARK: - Factories

  public static func production(storage: any SwiftDataStorageProtocol = SwiftDataStorage.shared) -> LiveGameStateManager {
    let manager = LiveGameStateManager()
    let gameManager = SwiftDataGameManager(storage: storage)
    manager._gameManager = gameManager
    gameManager.activeGameDelegate = manager._delegateProxy

    // Configure sync service
    Task {
      await manager.configureSyncService()
    }

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
  private var syncService: ActiveGameSyncService?

  // Delegate proxy to keep compiler happy with weak reference on SwiftDataGameManager
  @ObservationIgnored
  private lazy var _delegateProxy: DelegateProxy = DelegateProxy(owner: self)

  // MARK: - State

  public private(set) var currentGame: Game?
  public private(set) var isGameActive: Bool = false
  public private(set) var isGameInitial: Bool = true
  public private(set) var currentServeNumber: Int = 1

  public var hasActiveGame: Bool {
    currentGame != nil && currentGame?.isCompleted == false
  }

  // Sync toggle used by watchOS to coordinate with iOS device
  public private(set) var isSyncEnabled: Bool = false

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
    // Set up timer callback to update observable properties
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

  /// Configure sync service with callback handlers for active game and history synchronization
  public func configureSyncService() async {
    guard syncService == nil else { return }

    syncService = ActiveGameSyncService.shared

    await syncService?.configure(
      onActiveGameReceived: { [weak self] dto in
        Task { await self?.handleIncomingActiveGameState(dto) }
      },
      onHistoryReceived: { [weak self] games in
        Task { await self?.handleIncomingGameHistory(games) }
      },
      onHistoryRequested: { [weak self] in
        Task { await self?.handleHistoryRequest() }
      }
    )
  }

  // MARK: - Lifecycle

  public func setCurrentGame(_ game: Game) {
    // If switching games, clean up timer state
    if let existing = currentGame, existing.id != game.id {
      timer.stop()
      currentServeNumber = 1
    }
    currentGame = game
    isGameInitial = (game.gameState == .initial)
    isGameActive = (game.gameState == .playing)
  }

  public func clearCurrentGame() {
    currentGame = nil
    isGameActive = false
    isGameInitial = true
    currentServeNumber = 1
    timer.stop()
  }

  // MARK: - Creation

  /// Create a new game for a `GameType`, set it as current, and return it
  public func createGame(type: GameType) async throws -> Game {
    guard let gm = _gameManager else { throw GameError.noActiveGame }
    let game = try await gm.createGame(type: type)
    setCurrentGame(game)
    return game
  }

  /// Create a new game for a `GameVariation`, set it as current, and return it
  public func createGame(variation: GameVariation) async throws -> Game {
    guard let gm = _gameManager else { throw GameError.noActiveGame }
    let game = try await gm.createGame(variation: variation)
    setCurrentGame(game)
    return game
  }

  /// Start a new game using a standardized configuration contract
  public func startNewGame(with config: GameStartConfiguration) async throws -> Game {
    guard let gm = _gameManager else { throw GameError.noActiveGame }

    // Validate invariants
    try validateStartConfiguration(config)

    // Derive or validate variation
    let variation: GameVariation
    if let provided = config.variation {
      // Ensure provided variation matches the requested type/team size
      guard provided.gameType == config.gameType else {
        throw GameVariationError.invalidConfiguration("Variation gameType mismatch")
      }
      guard provided.teamSize == config.teamSize.playersPerSide else {
        throw GameVariationError.invalidTeamSize(provided.teamSize)
      }
      variation = provided
    } else {
      // Create a minimal validated variation from the game type and team size
      let displayName: String
      switch (config.participants.side1, config.participants.side2) {
      case (.players(let a), .players(let b)):
        let aName = a.first.map { _ in "Side A" } ?? "Side A"
        let bName = b.first.map { _ in "Side B" } ?? "Side B"
        displayName = "\(aName) vs \(bName)"
      case (.team, .team):
        displayName = "Teams Match"
      default:
        displayName = "\(config.gameType.displayName) Game"
      }

      variation = try GameVariation.createValidated(
        name: displayName,
        gameType: config.gameType,
        teamSize: config.teamSize.playersPerSide,
        winningScore: config.gameType.defaultWinningScore,
        winByTwo: config.gameType.defaultWinByTwo,
        kitchenRule: config.gameType.defaultKitchenRule,
        doubleBounceRule: config.gameType.defaultDoubleBounceRule,
        servingRotation: .standard,
        sideSwitchingRule: config.gameType.defaultSideSwitchingRule,
        isCustom: true
      )
    }

    // Build a MatchupSelection from participants
    let matchup: MatchupSelection
    switch (config.participants.side1, config.participants.side2) {
    case (.players(let a), .players(let b)):
      matchup = MatchupSelection(teamSize: config.teamSize.playersPerSide, mode: .players(sideA: a, sideB: b))
    case (.team(let t1), .team(let t2)):
      matchup = MatchupSelection(teamSize: config.teamSize.playersPerSide, mode: .teams(team1Id: t1, team2Id: t2))
    default:
      throw GameVariationError.invalidConfiguration("Participants shape does not match team size")
    }

    // Persist via manager; set as current
    let game = try await gm.createGame(variation: variation, matchup: matchup)
    game.notes = config.notes
    setCurrentGame(game)
    return game
  }

  private func validateStartConfiguration(_ config: GameStartConfiguration) throws(GameVariationError) {
    // Ensure team size supported by game type bounds
    let minSize = config.gameType.minTeamSize
    let maxSize = config.gameType.maxTeamSize
    let size = config.teamSize.playersPerSide
    guard size >= minSize && size <= maxSize else {
      throw GameVariationError.invalidTeamSize(size)
    }

    switch (config.participants.side1, config.participants.side2, config.teamSize) {
    case (.players(let a), .players(let b), .singles):
      guard a.count == 1 && b.count == 1 else {
        throw GameVariationError.invalidConfiguration("Singles requires exactly one player per side")
      }
    case (.team, .team, .doubles):
      // Team entities represent multiples; allow any team size permitted by type
      break
    case (.players(let a), .players(let b), .doubles):
      // Allow specifying two players per side as ad-hoc doubles
      guard a.count == 2 && b.count == 2 else {
        throw GameVariationError.invalidConfiguration("Doubles requires exactly two players per side when using players mode")
      }
    default:
      throw GameVariationError.invalidConfiguration("Participants must both be players or both teams and match team size")
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
    isGameActive = true
    isGameInitial = false
    game.logEvent(.gameResumed, at: elapsedTime)
    try await gm.updateGame(game)
    timer.start()
  }

  public func pauseGame() async throws {
    guard let game = currentGame, let gm = _gameManager else { throw GameError.noActiveGame }
    game.gameState = .paused
    isGameActive = false
    game.logEvent(.gamePaused, at: elapsedTime)
    try await gm.updateGame(game)
    timer.pause()
  }

  public func resumeGame() async throws {
    guard let game = currentGame, let gm = _gameManager else { throw GameError.noActiveGame }
    game.gameState = .playing
    isGameActive = true
    game.logEvent(.gameResumed, at: elapsedTime)
    try await gm.updateGame(game)
    timer.resume()
  }

  public func completeCurrentGame() async throws {
    guard let game = currentGame, let gm = _gameManager else { throw GameError.noActiveGame }
    try await gm.completeGame(game)
    game.logEvent(.gameCompleted, at: elapsedTime)
    timer.stop()
  }

  // MARK: - Scoring

  public func scorePoint(for team: Int) async throws {
    guard let game = currentGame, let gm = _gameManager else { throw GameError.noActiveGame }
    try await gm.scorePoint(for: team, in: game)
    game.logEvent(.playerScored, at: elapsedTime, teamAffected: team)

    // Send updated game state to paired device
    await sendCurrentGameState()
  }

  public func undoLastPoint() async throws {
    guard let game = currentGame, let gm = _gameManager else { throw GameError.noActiveGame }
    try await gm.undoLastPoint(in: game)
    game.logEvent(.scoreUndone, at: elapsedTime)

    // Send updated game state to paired device
    await sendCurrentGameState()
  }

  public func decrementScore(for team: Int) async throws {
    guard let game = currentGame, let gm = _gameManager else { throw GameError.noActiveGame }
    try await gm.decrementScore(for: team, in: game)

    // Send updated game state to paired device
    await sendCurrentGameState()
  }

  public func resetCurrentGame() async throws {
    guard let game = currentGame, let gm = _gameManager else { throw GameError.noActiveGame }
    try await gm.resetGame(game)
    currentServeNumber = 1
    timer.reset()

    // Send updated game state to paired device
    await sendCurrentGameState()
  }

  // MARK: - Serving

  public func switchServer() async throws {
    guard let game = currentGame, let gm = _gameManager else { throw GameError.noActiveGame }
    try await gm.switchServer(in: game)
    currentServeNumber += 1

    // Send updated game state to paired device
    await sendCurrentGameState()
  }

  public func setServer(to team: Int) async throws {
    guard let game = currentGame, let gm = _gameManager else { throw GameError.noActiveGame }
    try await gm.setServer(to: team, in: game)

    // Send updated game state to paired device
    await sendCurrentGameState()
  }

  public func switchServingPlayer() async throws {
    guard let game = currentGame, let gm = _gameManager else { throw GameError.noActiveGame }
    try await gm.switchServingPlayer(in: game)

    // Send updated game state to paired device
    await sendCurrentGameState()
  }

  public func startSecondServeForCurrentTeam() async throws {
    guard let game = currentGame, let gm = _gameManager else { throw GameError.noActiveGame }
    try await gm.startSecondServeForCurrentTeam(in: game)

    // Send updated game state to paired device
    await sendCurrentGameState()
  }

  public func handleServiceFault() async throws {
    guard let game = currentGame, let gm = _gameManager else { throw GameError.noActiveGame }
    try await gm.handleServiceFault(in: game)
    game.logEvent(.serviceFault, at: elapsedTime, teamAffected: game.currentServer)

    // Send updated game state to paired device
    await sendCurrentGameState()
  }

  public func handleNonServingTeamTap(on tappedTeam: Int) async throws {
    guard let game = currentGame, let gm = _gameManager else { throw GameError.noActiveGame }
    try await gm.handleNonServingTeamTap(on: tappedTeam, in: game)

    // Send updated game state to paired device
    await sendCurrentGameState()
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

  public func resetTimer() {
    timer.reset()
    updateTimerProperties()
  }

  public func setElapsedTime(_ timeInterval: TimeInterval) {
    timer.setElapsedTime(timeInterval)
    updateTimerProperties()
  }

  public func resetElapsedTime() {
    timer.reset()
    updateTimerProperties()
  }

  // MARK: - Private Timer Updates

  private func updateTimerProperties() {
    isTimerRunning = timer.isRunning
    elapsedTime = timer.elapsedTime
    formattedElapsedTime = timer.formattedElapsedTime
    formattedElapsedTimeWithCentiseconds = timer.formattedElapsedTimeWithCentiseconds
  }

  // MARK: - Sync Control

  public func setSyncEnabled(_ enabled: Bool) {
    isSyncEnabled = enabled
    Task { @MainActor in
      syncService?.setSyncEnabled(enabled)
    }
  }

  // MARK: - Sync Message Handlers

  /// Handle incoming active game state from paired device
  @MainActor
  private func handleIncomingActiveGameState(_ dto: ActiveGameStateDTO) async {
    // Only process if we don't have an active game or this is a more recent state
    guard let currentGame = currentGame else {
      // We don't have an active game, so we can't sync with this state
      return
    }

    // Check if this DTO is for the same game and is more recent
    guard dto.gameId == currentGame.id && dto.isMoreRecentThan(ActiveGameStateDTO.from(
      game: currentGame,
      elapsedSeconds: elapsedTime,
      isTimerRunning: isTimerRunning,
      lastTimerStartTime: timer.lastTimerStartTime
    )) else {
      return
    }

    // Update our game state to match the incoming state
    updateGameFromDTO(dto)
  }

  /// Handle incoming game history from paired device
  @MainActor
  private func handleIncomingGameHistory(_ games: [HistoryGameDTO]) async {
    // This would typically involve storing/updating games in the database
    // For now, we'll just log that we received history
    Log.event(.syncSucceeded, level: .debug, message: "Received game history sync", metadata: ["count": String(games.count)])
  }

  /// Handle history request from paired device
  @MainActor
  private func handleHistoryRequest() async {
    // Send recent completed games to the paired device
    guard let gm = _gameManager else { return }

    do {
      let completedGames = try await gm.storage.loadCompletedGames()
      let historyDTOs = completedGames.prefix(20).map { HistoryGameDTO(from: $0) }
      try await syncService?.sendGameHistory(Array(historyDTOs))
    } catch {
      Log.error(error, event: .syncFailed, context: .current(gameId: currentGame?.id))
    }
  }

  /// Update current game state from DTO
  @MainActor
  private func updateGameFromDTO(_ dto: ActiveGameStateDTO) {
    guard let currentGame = currentGame, currentGame.id == dto.gameId else { return }

    // Update game state to match DTO
    currentGame.score1 = dto.score1
    currentGame.score2 = dto.score2
    currentGame.gameState = dto.gameState
    currentGame.currentServer = dto.currentServer
    currentGame.serverNumber = dto.serverNumber
    currentGame.serverPosition = dto.serverPosition
    currentGame.sideOfCourt = dto.sideOfCourt
    currentGame.isFirstServiceSequence = dto.isFirstServiceSequence
    currentGame.lastModified = Date()

    // Update timer state
    timer.setElapsedTime(dto.elapsedSeconds)
    if dto.isTimerRunning && !timer.isRunning {
      timer.start()
    } else if !dto.isTimerRunning && timer.isRunning {
      timer.pause()
    }

    // Update our observable properties
    updateTimerProperties()

    // Update UI state
    isGameActive = (dto.gameState == .playing)
    isGameInitial = (dto.gameState == .initial)

    Log.event(.syncSucceeded, level: .debug, message: "Updated game from sync", context: .current(gameId: dto.gameId))
  }

  /// Send current game state to paired device
  @MainActor
  private func sendCurrentGameState() async {
    guard let currentGame = currentGame,
          let syncService = syncService,
          isSyncEnabled else { return }

    let dto = ActiveGameStateDTO.from(
      game: currentGame,
      elapsedSeconds: elapsedTime,
      isTimerRunning: isTimerRunning,
      lastTimerStartTime: timer.lastTimerStartTime
    )

    do {
      try await syncService.sendActiveGameState(dto)
    } catch {
      Log.error(error, event: .syncFailed, context: .current(gameId: currentGame.id))
    }
  }

  // MARK: - LiveGameCoordinator

  public func incrementServeNumber() { currentServeNumber += 1 }
  public func triggerServeChangeHaptic() { HapticFeedbackService.shared.serveChange() }
  public func gameStateDidChange(to gameState: GameState) {
    switch gameState {
    case .playing:
      isGameActive = true
      if !timer.isRunning { timer.start() }
      updateTimerProperties()
    case .paused:
      isGameActive = false
      if timer.isRunning { timer.pause() }
      updateTimerProperties()
    case .completed:
      isGameActive = false
      timer.stop()
      updateTimerProperties()
    case .initial, .serving:
      updateTimerProperties()
      break
    }
  }
  public func gameDidComplete(_ game: Game) { currentGame = game }
  public func gameDidUpdate(_ game: Game) { if currentGame?.id == game.id { currentGame = game } }
  public func gameDidDelete(_ game: Game) { if currentGame?.id == game.id { clearCurrentGame() } }
  public func validateStateConsistency() -> Bool { timer.validateState() }

  // MARK: - Internal Delegate Proxy

  private final class DelegateProxy: LiveGameCoordinator, Sendable {
    weak var owner: LiveGameStateManager?
    init(owner: LiveGameStateManager) { self.owner = owner }
    var currentGame: Game? { owner?.currentGame }
    func setCurrentGame(_ game: Game) { owner?.setCurrentGame(game) }
    func incrementServeNumber() { owner?.incrementServeNumber() }
    func triggerServeChangeHaptic() { owner?.triggerServeChangeHaptic() }
    func gameStateDidChange(to gameState: GameState) { owner?.gameStateDidChange(to: gameState) }
    func gameDidComplete(_ game: Game) { owner?.gameDidComplete(game) }
    func gameDidUpdate(_ game: Game) { owner?.gameDidUpdate(game) }
    func gameDidDelete(_ game: Game) { owner?.gameDidDelete(game) }
    func validateStateConsistency() -> Bool { owner?.validateStateConsistency() ?? true }
  }
}


