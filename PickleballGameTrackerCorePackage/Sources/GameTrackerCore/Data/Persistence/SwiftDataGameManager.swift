import Foundation
import SwiftData

/// Primary business logic service for pickleball games
/// Handles all game operations, rules validation, and data persistence
/// 
/// Views should use @Query for data access, and this manager for operations only.
@MainActor
@Observable
public final class SwiftDataGameManager: Sendable {

  public let storage: any SwiftDataStorageProtocol
  

  // Delegate reference for active game coordination
  public weak var activeGameDelegate: (any LiveGameCoordinator)?

  public init(storage: any SwiftDataStorageProtocol = SwiftDataStorage.shared) {
    self.storage = storage
  }

  // Resolve a Game to the storage container's live context
  private func resolveTrackedGame(_ game: Game) async -> Game {
    if let tracked = try? await storage.loadGame(id: game.id) {
      return tracked
    }
    return game
  }

  // MARK: - Game Queries

  /// Find the most recent completed game of the specified type.
  ///
  /// Used for "Last Game" quick-start feature to reuse participants and rules.
  ///
  /// - Parameter type: The game type to search for
  /// - Returns: The most recently completed game, or nil if none found
  public func mostRecentCompletedGame(of type: GameType) async throws -> Game? {
    let completedGames = try await storage.loadCompletedGames()
    
    let matchingGames = completedGames
      .filter { $0.gameType == type }
      .sorted { ($0.completedDate ?? $0.createdDate) > ($1.completedDate ?? $1.createdDate) }
    
    return matchingGames.first
  }

  // MARK: - Game Creation

  /// Create a new game with the specified type
  public func createGame(type: GameType) async throws -> Game {
    let newGame = Game(gameType: type)
    try await storage.saveGame(newGame)

    Log.event(
      .saveSucceeded,
      level: .info,
      message: "Game created",
      context: .current(gameId: newGame.id),
      metadata: ["type": type.displayName]
    )
    return newGame
  }

  /// Create a new game with custom rules
  public func createGame(type: GameType, rules: GameRules) async throws -> Game {
    let newGame = Game(gameType: type, rules: rules)
    try await storage.saveGame(newGame)

    Log.event(
      .saveSucceeded,
      level: .info,
      message: "Game created with custom rules",
      context: .current(gameId: newGame.id),
      metadata: ["type": type.displayName]
    )
    return newGame
  }

  /// Create a new game with custom rules and a matchup selection (players or teams)
  public func createGame(
    type: GameType,
    rules: GameRules,
    matchup: MatchupSelection
  ) async throws -> Game {
    let newGame = Game(
      gameType: type,
      rules: rules,
      winningScore: rules.winningScore,
      winByTwo: rules.winByTwo,
      kitchenRule: rules.kitchenRule,
      doubleBounceRule: rules.doubleBounceRule,
      sideSwitchingRule: rules.sideSwitchingRule,
      servingRotation: rules.servingRotation,
      scoringType: rules.scoringType,
      timeLimit: rules.timeLimit,
      maxRallies: rules.maxRallies
    )

    // Store participant data from matchup
    switch matchup.mode {
    case .players(let sideA, let sideB):
      newGame.participantMode = .players
      newGame.side1PlayerIds = sideA
      newGame.side2PlayerIds = sideB
    case .teams(let team1Id, let team2Id):
      newGame.participantMode = .teams
      newGame.side1TeamId = team1Id
      newGame.side2TeamId = team2Id
    }

    // Snapshot the effective team size at creation so future logic does not rely
    // on transformable enum decoding or guesses from participant arrays.
    // This avoids mismatches when resuming the "Last Game" quick start.
    newGame.teamSize = matchup.teamSize

    try await storage.saveGame(newGame)

    Log.event(
      .saveSucceeded,
      level: .info,
      message: "Game created with matchup",
      context: .current(gameId: newGame.id),
      metadata: ["type": type.displayName, "teamSize": String(matchup.teamSize)]
    )
    return newGame
  }

  // MARK: - Game Operations

  /// Score a point for the specified team in the given game
  public func scorePoint(for team: Int, in game: Game) async throws {
    let game = await resolveTrackedGame(game)
    guard !game.isCompleted else { throw GameError.gameAlreadyCompleted }
    guard team == 1 || team == 2 else { throw GameError.invalidTeam }
    // Enforce: scoring only allowed when actively playing
    guard game.gameState == .playing else { throw GameError.cannotScoreWhenPaused }

    let previousServer = game.currentServer
    let previousSide = game.sideOfCourt
    let wasCompleted = game.isCompleted

    // Apply business logic through the Game model (updates server/position/side per rules)
    if team == 1 { game.scorePoint1() } else { game.scorePoint2() }

    // Serve sequence tracking
    if previousServer != game.currentServer { activeGameDelegate?.incrementServeNumber() }
    // Detect side switching for logging/haptics (only when game is playing)
    if previousSide != game.sideOfCourt {
      Log.event(.sidesSwitched, level: .info, context: .current(gameId: game.id))
      // Game state is already validated as .playing above, so haptic will trigger
      activeGameDelegate?.triggerServeChangeHaptic()
    }

    let didComplete = !wasCompleted && game.isCompleted
    try await updateGame(game)
    if didComplete {
      do {
        let isValid = try await storage.validateGamePersistence(game)
        if !isValid {
          Log.event(
            .saveFailed, level: .warn, context: .current(gameId: game.id),
            metadata: ["phase": "autoCompleteValidationFailed"])
          try await updateGame(game)
        }
      } catch {
        Log.error(
          error, event: .saveFailed, context: .current(gameId: game.id),
          metadata: ["phase": "autoCompleteValidation"])
      }
      activeGameDelegate?.gameStateDidChange(to: .completed)
      activeGameDelegate?.gameDidComplete(game)
      Log.event(
        .gameCompleted, level: .info, context: .current(gameId: game.id),
        metadata: ["finalScore": game.formattedScore])
    } else {
      activeGameDelegate?.gameDidUpdate(game)
    }
    Log.event(
      .scoreIncrement, level: .info, context: .current(gameId: game.id),
      metadata: ["team": "\(team)", "score": game.formattedScore])
  }

  /// Score a point for the specified team and log a playerScored event
  /// This method combines scoring with event logging and ensures both are persisted immediately
  public func scorePointAndLogEvent(
    for team: Int,
    in game: Game,
    at timestamp: TimeInterval,
    customDescription: String? = nil
  ) async throws {
    let game = await resolveTrackedGame(game)
    try await scorePoint(for: team, in: game)
    game.logEvent(.playerScored, at: timestamp, teamAffected: team, description: customDescription)
    try await updateGame(game)
  }

  /// Undo the last point in the given game
  public func undoLastPoint(in game: Game) async throws {
    let game = await resolveTrackedGame(game)
    guard game.totalRallies > 0 else {
      throw GameError.noPointsToUndo
    }

    // Apply business logic through the Game model
    game.undoLastPoint()

    // Persist changes
    try await updateGame(game)

    // Notify delegate if this affects the active game
    activeGameDelegate?.gameDidUpdate(game)

    Log.event(
      .actionTapped,
      level: .info,
      message: "Undo last point",
      context: .current(gameId: game.id),
      metadata: ["score": game.formattedScore]
    )
  }

  /// Decrement score for a specific team without changing serving team
  public func decrementScore(for team: Int, in game: Game) async throws {
    let game = await resolveTrackedGame(game)
    guard !game.isCompleted else { throw GameError.gameAlreadyCompleted }
    guard team == 1 || team == 2 else { throw GameError.invalidTeam }
    // Enforce: score adjustment only allowed when actively playing
    guard game.gameState == .playing else { throw GameError.cannotScoreWhenPaused }

    // Check if team has points to decrement
    let currentScore = team == 1 ? game.score1 : game.score2
    guard currentScore > 0 else { throw GameError.noPointsToUndo }

    // Store current serving/side state to preserve on decrement
    let currentServer = game.currentServer
    let currentServerNumber = game.serverNumber
    let currentServerPosition = game.serverPosition
    let currentSideOfCourt = game.sideOfCourt

    // Decrement the specific team's score
    if team == 1 {
      game.score1 = max(0, game.score1 - 1)
    } else {
      game.score2 = max(0, game.score2 - 1)
    }

    // Preserve serving state
    game.currentServer = currentServer
    game.serverNumber = currentServerNumber
    game.serverPosition = currentServerPosition
    game.sideOfCourt = currentSideOfCourt

    // Update other game properties
    game.totalRallies = max(0, game.totalRallies - 1)
    game.lastModified = Date()

    // Reset completion state if needed
    game.isCompleted = false
    game.completedDate = nil

    try await updateGame(game)
    activeGameDelegate?.gameDidUpdate(game)

    Log.event(
      .scoreDecrement, level: .info, context: .current(gameId: game.id),
      metadata: ["team": "\(team)", "score": game.formattedScore])
  }

  /// Change the game state to paused
  public func pauseGame(_ game: Game) async throws {
    let game = await resolveTrackedGame(game)
    guard !game.isCompleted else {
      throw GameError.gameAlreadyCompleted
    }

    game.pauseGame()
    try await updateGame(game)

    // Notify delegate about state change
    activeGameDelegate?.gameStateDidChange(to: .paused)

    Log.event(.gamePaused, level: .info, context: .current(gameId: game.id))
  }

  /// Change the game state to playing
  public func resumeGame(_ game: Game) async throws {
    let game = await resolveTrackedGame(game)
    guard !game.isCompleted else {
      throw GameError.gameAlreadyCompleted
    }

    game.resumeGame()
    try await updateGame(game)

    // Notify delegate about state change (Fixed: was .serving, should be .playing)
    activeGameDelegate?.gameStateDidChange(to: .playing)

    Log.event(.gameResumed, level: .info, context: .current(gameId: game.id))
  }

  /// Complete the specified game
  /// If the game is unused (less than 5 minutes, no scores, no meaningful events),
  /// it will be deleted instead of saved.
  public func completeGame(_ game: Game, elapsedTime: TimeInterval? = nil) async throws {
    let game = await resolveTrackedGame(game)
    guard !game.isCompleted else {
      throw GameError.gameAlreadyCompleted
    }

    // Capture game ID before any operations that might delete/detach the object
    let gameId = game.id

    // Check if game is unused and should be deleted instead of saved
    if let elapsedTime = elapsedTime, game.isUnused(elapsedTime: elapsedTime) {
      Log.event(
        .deleteRequested, level: .info, context: .current(gameId: gameId),
        metadata: ["reason": "unusedGame", "elapsedTime": "\(elapsedTime)"])
      
      try await deleteGame(game)
      
      Log.event(
        .deleteSucceeded, level: .info, context: .current(gameId: gameId),
        metadata: ["reason": "unusedGame"])
      return
    }

    game.completeGame()

    do {
      try await updateGame(game)

      // Validate that the completion was properly saved
      let isValid = try await storage.validateGamePersistence(game)
      if !isValid {
        Log.event(
          .saveFailed, level: .warn, context: .current(gameId: game.id),
          metadata: ["phase": "completionValidation"])
      }
    } catch {
      Log.error(
        error, event: .saveFailed, context: .current(gameId: game.id),
        metadata: ["action": "completeGame"])
      throw error
    }

    // Notify delegate if this was the active game
    activeGameDelegate?.gameStateDidChange(to: .completed)
    activeGameDelegate?.gameDidComplete(game)

    Log.event(
      .gameCompleted, level: .info, context: .current(gameId: game.id),
      metadata: ["finalScore": game.formattedScore])
  }

  /// Reset the specified game to initial state
  public func resetGame(_ game: Game) async throws {
    let game = await resolveTrackedGame(game)
    game.resetGame()
    try await updateGame(game)

    // Notify delegate about reset
    activeGameDelegate?.gameDidUpdate(game)

    Log.event(
      .actionTapped, level: .info, message: "Game reset", context: .current(gameId: game.id))
  }

  /// Update an existing game in storage
  public func updateGame(_ game: Game) async throws {
    let game = await resolveTrackedGame(game)
    do {
      game.lastModified = Date()
      try await storage.updateGame(game)

      // Validate state consistency for active games
      if game.id == activeGameDelegate?.currentGame?.id {
        Task { @MainActor in
          _ = activeGameDelegate?.validateStateConsistency()
        }
      }
    } catch {
      Log.error(
        error, event: .saveFailed, context: .current(gameId: game.id),
        metadata: ["action": "updateGame"])
      throw error
    }
  }

  /// Delete a game from storage
  public func deleteGame(_ game: Game) async throws {
    let game = await resolveTrackedGame(game)
    // Capture game ID and check if it's the active game BEFORE deletion
    // to avoid accessing detached object properties
    let gameId = game.id
    let isActiveGame = activeGameDelegate?.currentGame?.id == gameId
    
    try await storage.deleteGame(id: gameId)

    // Notify delegate if this was the active game
    // CRITICAL: game object is now detached from context after deletion.
    // Any access to properties (even indirectly) will trigger fault resolution errors.
    // The delegate method gameDidDelete is designed to not access properties,
    // but we must ensure no SwiftData operations happen on the detached object.
    if isActiveGame {
      // Call delegate on main actor
      // The game parameter is passed for protocol compliance but must not be accessed
      await MainActor.run {
        activeGameDelegate?.gameDidDelete(game)
      }
    }

    Log.event(.deleteSucceeded, level: .info, context: .current(gameId: gameId))
  }

  // MARK: - Statistics

  public func getGameStatistics() async throws -> GameStatistics {
    return try await storage.loadGameStatistics()
  }

  // MARK: - Archive / Restore

  /// Archive a completed game. Archived games are hidden from default queries.
  public func archiveGame(_ game: Game) async throws {
    guard game.isCompleted else { throw GameError.invalidOperation }
    game.isArchived = true
    game.lastModified = Date()
    try await updateGame(game)
    Log.event(
      .actionTapped, level: .info, message: "Game archived", context: .current(gameId: game.id))
  }

  /// Restore a previously archived game
  public func restoreGame(_ game: Game) async throws {
    game.isArchived = false
    game.lastModified = Date()
    try await updateGame(game)
    Log.event(
      .actionTapped, level: .info, message: "Game restored", context: .current(gameId: game.id))
  }

  /// Scan for and recover any games with completion issues
  public func validateAndRecoverGameData() async throws -> Int {
    Log.event(.loadStarted, level: .info, message: "validateAndRecover: start")
    var recoveredCount = 0

    // Load all games from storage
    let allGames = try await storage.loadGames()

    for game in allGames {
      do {
        // Check if game should be completed based on score but isn't marked as completed
        if !game.isCompleted && game.shouldComplete {
          Log.event(
            .saveStarted, level: .info, context: .current(gameId: game.id),
            metadata: ["reason": "autoCompleteOnRecover", "score": game.formattedScore])

          // Auto-complete the game
          game.completeGame()
          try await updateGame(game)
          recoveredCount += 1
        }

        // Validate that completed games have proper completion data
        if game.isCompleted {
          if game.completedDate == nil {
            Log.event(
              .saveStarted, level: .warn, context: .current(gameId: game.id),
              metadata: ["reason": "missingCompletedDate"])
            game.completedDate = game.lastModified
            try await updateGame(game)
            recoveredCount += 1
          }

          if game.gameState != .completed {
            Log.event(
              .saveStarted, level: .warn, context: .current(gameId: game.id),
              metadata: ["reason": "incorrectCompletedState"])
            game.gameState = .completed
            try await updateGame(game)
            recoveredCount += 1
          }
        }

        // Validate persistence for critical games
        let isValid = try await storage.validateGamePersistence(game)
        if !isValid {
          Log.event(
            .saveStarted, level: .warn, context: .current(gameId: game.id),
            metadata: ["reason": "persistenceMismatch"])
          try await updateGame(game)
          recoveredCount += 1
        }

      } catch {
        Log.error(
          error, event: .saveFailed, context: .current(gameId: game.id),
          metadata: ["phase": "validateAndRecover"])
        // Continue with other games
      }
    }

    Log.event(
      .loadSucceeded, level: .info, message: "validateAndRecover: done",
      metadata: ["recovered": String(recoveredCount)])
    return recoveredCount
  }

  // MARK: - Server Management

  /// Manually switch the serving team in the given game
  public func switchServer(in game: Game) async throws {
    let game = await resolveTrackedGame(game)
    guard !game.isCompleted else { throw GameError.gameAlreadyCompleted }
    // Enforce: serving team can only be changed during active play
    guard game.gameState == .playing else { throw GameError.cannotChangeServeWhenNotPlaying }

    let previousServer = game.currentServer
    let newServer = previousServer == 1 ? 2 : 1

    game.currentServer = newServer
    if game.effectiveTeamSize > 1 {
      // Reset to first server on side-out and enforce parity for doubles
      game.serverNumber = 1
      let teamScore = (newServer == 1) ? game.score1 : game.score2
      game.serverPosition = (teamScore % 2 == 0) ? .right : .left
    } else {
      // Singles: keep position; ensure serving player is 1 for consistency
      game.serverNumber = 1
    }

    try await updateGame(game)

    if previousServer != game.currentServer { activeGameDelegate?.incrementServeNumber() }
    activeGameDelegate?.triggerServeChangeHaptic()
    activeGameDelegate?.gameDidUpdate(game)

    Log.event(
      .serverSwitched, level: .info, context: .current(gameId: game.id),
      metadata: ["from": "T\(previousServer)", "to": "T\(game.currentServer)"])
  }

  /// Manually set the serving team in the given game (only during active play)
  public func setServer(to team: Int, in game: Game) async throws {
    let game = await resolveTrackedGame(game)
    guard !game.isCompleted else { throw GameError.gameAlreadyCompleted }
    guard team == 1 || team == 2 else { throw GameError.invalidTeam }
    // Enforce: serving team can only be changed during active play
    guard game.gameState == .playing else { throw GameError.cannotChangeServeWhenNotPlaying }

    let previousServer = game.currentServer
    game.currentServer = team
    if game.effectiveTeamSize > 1 {
      if previousServer != team { game.serverNumber = 1 }
      let teamScore = (team == 1) ? game.score1 : game.score2
      game.serverPosition = (teamScore % 2 == 0) ? .right : .left
    } else {
      game.serverNumber = 1
      // Keep position for singles
    }

    try await updateGame(game)

    if previousServer != game.currentServer { activeGameDelegate?.incrementServeNumber() }
    activeGameDelegate?.triggerServeChangeHaptic()
    activeGameDelegate?.gameDidUpdate(game)

    Log.event(
      .serverSwitched, level: .info, context: .current(gameId: game.id),
      metadata: ["from": "T\(previousServer)", "to": "T\(team)", "action": "setServer"])
  }

  /// Switch the serving player within the current serving team (for doubles)
  public func switchServingPlayer(in game: Game) async throws {
    let game = await resolveTrackedGame(game)
    guard !game.isCompleted else {
      throw GameError.gameAlreadyCompleted
    }

    guard game.effectiveTeamSize > 1 else {
      throw GameError.invalidOperation
    }
    // Enforce: manual serving player change only when game not actively playing
    guard game.gameState != .playing else { throw GameError.illegalServingPlayerChangeDuringPlay }

    // Apply business logic through the Game model
    game.switchServingPlayer()

    // Persist changes
    try await updateGame(game)

    // Notify delegate if this affects the active game
    activeGameDelegate?.gameDidUpdate(game)

    Log.event(
      .serverSwitched, level: .info, context: .current(gameId: game.id),
      metadata: [
        "server": "T\(game.currentServer)P\(game.serverNumber)", "action": "switchServingPlayer",
      ])
  }

  /// Handle a service fault by advancing the serve according to game rules
  public func handleServiceFault(in game: Game) async throws {
    let game = await resolveTrackedGame(game)
    guard !game.isCompleted else {
      throw GameError.gameAlreadyCompleted
    }

    // Apply business logic through the Game model
    game.handleServiceFault()

    // Persist changes
    try await updateGame(game)

    // Serve sequence tracking and haptics
    activeGameDelegate?.triggerServeChangeHaptic()

    Log.event(
      .serverSwitched, level: .info, context: .current(gameId: game.id),
      metadata: ["server": "T\(game.currentServer)", "serverNumber": "\(game.serverNumber)"])
  }

  /// Set the serving player within the current serving team
  public func setServingPlayer(to player: Int, in game: Game) async throws {
    let game = await resolveTrackedGame(game)
    guard !game.isCompleted else {
      throw GameError.gameAlreadyCompleted
    }

    guard player == 1 || player == 2 else {
      throw GameError.invalidPlayer
    }

    guard game.effectiveTeamSize > 1 else {
      throw GameError.invalidOperation
    }
    // Enforce: manual serving player change only when game not actively playing
    guard game.gameState != .playing else { throw GameError.illegalServingPlayerChangeDuringPlay }

    // Apply business logic through the Game model
    game.setServingPlayer(to: player)

    // Persist changes
    try await updateGame(game)

    // Notify delegate if this affects the active game
    activeGameDelegate?.gameDidUpdate(game)

    Log.event(
      .serverSwitched, level: .info, context: .current(gameId: game.id),
      metadata: ["server": "T\(game.currentServer)P\(player)", "action": "setServingPlayer"])
  }

  /// Start the second serve for the current team during active play (doubles only).
  /// This is permitted convenience behavior to advance from first to second server
  /// without logging a specific fault event from the quick actions.
  public func startSecondServeForCurrentTeam(in game: Game) async throws {
    let game = await resolveTrackedGame(game)
    guard !game.isCompleted else { throw GameError.gameAlreadyCompleted }
    guard game.effectiveTeamSize > 1 else { throw GameError.invalidOperation }
    // Only allow during active play
    guard game.gameState == .playing else { throw GameError.cannotScoreWhenPaused }

    // Only transition from first to second server during active play
    guard game.serverNumber == 1 else {
      throw GameError.invalidOperation
    }

    // Advance to partner per doubles rules (equivalent to a service fault on first server)
    try await handleServiceFault(in: game)

    // Persist changes
    try await updateGame(game)

    // Notify delegate for active game coordination (no serve-number increment; same team)
    activeGameDelegate?.gameDidUpdate(game)
    activeGameDelegate?.triggerServeChangeHaptic()

    Log.event(
      .serverSwitched,
      level: .info,
      message: "Second serve started for current team",
      context: .current(gameId: game.id),
      metadata: [
        "team": "T\(game.currentServer)",
        "serverNumber": "\(game.serverNumber)",
        "phase": "secondServeManual"
      ]
    )
  }

  /// Handle tap on the non-serving team's score card during active play.
  /// - Behavior:
  ///   - Singles: switches serve to tapped team (no scoring), resets to first server
  ///   - Doubles: advances serve as a fault: first → second, or side-out to other team
  public func handleNonServingTeamTap(on tappedTeam: Int, in game: Game) async throws {
    let game = await resolveTrackedGame(game)
    guard !game.isCompleted else { throw GameError.gameAlreadyCompleted }
    guard tappedTeam == 1 || tappedTeam == 2 else { throw GameError.invalidTeam }
    guard game.gameState == .playing else { throw GameError.cannotScoreWhenPaused }
    // Only when tapping the non-serving team
    guard game.currentServer != tappedTeam else { return }

    let previousServer = game.currentServer
    let previousServerNumber = game.serverNumber

    if game.effectiveTeamSize == 1 {
      // Singles: explicit exception allowed during play (bypass setServer validation)
      game.currentServer = tappedTeam
      game.serverNumber = 1
      // Preserve serverPosition; no side change occurs from this manual adjustment
    } else {
      // Doubles: treat as service fault advance
      try await handleServiceFault(in: game)
    }

    try await updateGame(game)

    // Serve sequence tracking and haptics
    if previousServer != game.currentServer { activeGameDelegate?.incrementServeNumber() }
    activeGameDelegate?.triggerServeChangeHaptic()

    Log.event(
      .serverSwitched,
      level: .info,
      message: "Serve advanced via non-serving team tap",
      context: .current(gameId: game.id),
      metadata: [
        "from": "T\(previousServer)P\(previousServerNumber)",
        "to": "T\(game.currentServer)P\(game.serverNumber)"
      ]
    )
  }
}

// MARK: - Game Errors

public enum GameError: Error, LocalizedError, Sendable {
  case noActiveGame
  case gameAlreadyCompleted
  case invalidTeam
  case invalidPlayer
  case invalidOperation
  case noPointsToUndo
  case gameNotFound
  case cannotScoreWhenPaused
  case cannotChangeServeWhenNotPlaying
  case illegalServerChangeDuringPlay
  case illegalServingPlayerChangeDuringPlay
  case notSessionParticipant
  case invalidEventPayload

  public var errorDescription: String? {
    switch self {
    case .noActiveGame:
      return "No active game available"
    case .gameAlreadyCompleted:
      return "Game is already completed"
    case .invalidTeam:
      return "Invalid team number (must be 1 or 2)"
    case .invalidPlayer:
      return "Invalid player number (must be 1 or 2)"
    case .invalidOperation:
      return "Invalid operation for current game configuration"
    case .noPointsToUndo:
      return "No points to undo"
    case .gameNotFound:
      return "Game not found"
    case .cannotScoreWhenPaused:
      return "You can't change the score while the game is paused. Resume the game first."
    case .cannotChangeServeWhenNotPlaying:
      return "Serving team can only be changed during active play."
    case .illegalServerChangeDuringPlay:
      return "Server can't be changed during active play. Pause the game to adjust serving."
    case .illegalServingPlayerChangeDuringPlay:
      return "Serving player can't be changed during active play. Pause the game to adjust."
    case .notSessionParticipant:
      return "Only session participants can perform this action"
    case .invalidEventPayload:
      return "Invalid event payload"
    }
  }
}
