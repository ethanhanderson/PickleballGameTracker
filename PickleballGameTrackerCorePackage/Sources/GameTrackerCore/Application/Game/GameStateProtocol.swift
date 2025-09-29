//
//  GameStateProtocol.swift
//  SharedGameCore
//
//  Created by Ethan Anderson on 7/9/25.
//

import Foundation
import SwiftData

/// Protocol defining the core interface for game state management
@MainActor
public protocol GameStateProtocol: AnyObject {

  // MARK: - Game State Properties

  /// The currently active game, if any
  var currentGame: Game? { get }

  /// Whether there is an active (non-completed) game
  var hasActiveGame: Bool { get }

  /// Whether the game is currently in playing state
  var isGameActive: Bool { get }

  /// Whether the game is in initial state (never started)
  var isGameInitial: Bool { get }

  // MARK: - Timer State Properties

  /// The elapsed time since the game started
  var elapsedTime: TimeInterval { get }

  /// Whether the game timer is currently running
  var isTimerRunning: Bool { get }

  /// Current serve number (increments each time serving team changes)
  var currentServeNumber: Int { get }

  // MARK: - UI State Properties

  /// Text for the game control button
  var gameControlButtonText: String { get }

  /// Icon for the game control button
  var gameControlButtonIcon: String { get }

  /// Combined game and timer status for UI display
  var gameAndTimerStatus: String { get }

  /// Whether the timer can be started manually
  var canStartTimer: Bool { get }

  /// Whether the timer can be paused manually
  var canPauseTimer: Bool { get }

  /// Text for the timer control button
  var timerButtonText: String { get }

  // MARK: - Formatted Time Properties

  /// Formatted elapsed time string (hours:minutes:seconds when hours > 0, otherwise minutes:seconds)
  var formattedElapsedTime: String { get }

  /// Formatted elapsed time string with centiseconds
  var formattedElapsedTimeWithCentiseconds: String { get }

  // MARK: - Game Control Methods

  /// Toggle between game states (start → pause → resume)
  func toggleGameState() async throws

  /// Start the current game and automatically start the timer
  func startGame() async throws

  /// Pause the current game (stops timer automatically)
  func pauseGame() async throws

  /// Resume the current game (starts timer automatically)
  func resumeGame() async throws

  /// Complete the current active game
  func completeCurrentGame() async throws

  /// Clear the current game (used when user dismisses a completed game)
  func clearCurrentGame()

  // MARK: - Scoring Methods

  /// Score a point for the specified team
  func scorePoint(for team: Int) async throws

  /// Undo the last point
  func undoLastPoint() async throws

  /// Reset the current game to initial state
  func resetCurrentGame() async throws

  // MARK: - Server Management

  /// Switch the serving team
  func switchServer() async throws

  /// Set the serving team manually
  func setServer(to team: Int) async throws

  /// Switch the serving player within the current serving team (for doubles)
  func switchServingPlayer() async throws

  // MARK: - Timer Control Methods

  /// Start the timer (for external control)
  func startTimer()

  /// Stop the timer completely (for external control)
  func stopTimer()

  /// Toggle timer state (for timer-only control, independent of game state)
  func toggleTimer()

  // MARK: - Configuration Methods

  /// Configure the state manager with a model context and optional game manager
  func configure(with modelContext: ModelContext, gameManager: SwiftDataGameManager?, enableSync: Bool)

  /// Set the current game and prepare timer state
  func setCurrentGame(_ game: Game)
}

/// Extension to provide default implementations for computed properties that can be derived from other state
extension GameStateProtocol {

  /// Whether there is an active (non-completed) game
  public var hasActiveGame: Bool {
    currentGame != nil && currentGame?.isCompleted == false
  }

  /// Whether the game can be started
  public var canStartGame: Bool {
    hasActiveGame && !isGameActive
  }

  /// Whether the game can be paused
  public var canPauseGame: Bool {
    hasActiveGame && isGameActive
  }

  /// Whether the game can be resumed
  public var canResumeGame: Bool {
    hasActiveGame && !isGameActive && !isGameInitial
  }
}
