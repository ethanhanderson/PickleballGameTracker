//
//  ActiveGameStateManagerTests.swift
//  SharedGameCore
//
//  Created by Ethan Anderson on 7/9/25.
//

import Foundation
import SwiftData
import Testing

@testable import SharedGameCore

@Suite("Active Game State Manager")
struct ActiveGameStateManagerTests {

  // MARK: - Basic State Management

  @Test("Initial state is correct")
  @MainActor
  func testInitialState() async throws {
    let stateManager = ActiveGameStateManager()

    #expect(stateManager.currentGame == nil)
    #expect(stateManager.hasActiveGame == false)
    #expect(stateManager.isTimerRunning == false)
    #expect(stateManager.elapsedTime == 0)
    #expect(stateManager.isGameInitial == true)
  }

  @Test("Starting a game updates state")
  @MainActor
  func testStartGame() async throws {
    let stateManager = ActiveGameStateManager()
    let game = Game(gameType: .recreational)

    stateManager.startGame(game)

    #expect(stateManager.currentGame?.id == game.id)
    #expect(stateManager.hasActiveGame == true)
    #expect(stateManager.isGameInitial == true)  // Game not yet started
  }

  @Test("Clearing current game resets state")
  @MainActor
  func testClearCurrentGame() async throws {
    let stateManager = ActiveGameStateManager()
    let game = Game(gameType: .recreational)

    stateManager.startGame(game)
    #expect(stateManager.currentGame != nil)

    stateManager.clearCurrentGame()
    #expect(stateManager.currentGame == nil)
    #expect(stateManager.hasActiveGame == false)
    #expect(stateManager.elapsedTime == 0)
  }

  // MARK: - Timer Management

  @Test("Timer controls work correctly")
  @MainActor
  func testTimerControls() async throws {
    let stateManager = ActiveGameStateManager()
    let game = Game(gameType: .recreational)

    stateManager.startGame(game)
    #expect(stateManager.isTimerRunning == false)

    // Test that timer can be controlled
    stateManager.startTimer()
    #expect(stateManager.isTimerRunning == true)

    stateManager.stopTimer()
    #expect(stateManager.isTimerRunning == false)
  }

  @Test("Elapsed time formatting")
  @MainActor
  func testElapsedTimeFormatting() async throws {
    let stateManager = ActiveGameStateManager()

    // Test initial time format
    #expect(stateManager.formattedElapsedTime == "00:00")

    // Test with some elapsed time (need to set internal elapsed time)
    // This test verifies the formatting logic works
    let formattedTime = stateManager.formattedElapsedTime
    #expect(formattedTime.contains(":"))
  }

  // MARK: - Inactivity Tracking

  @Test("Inactivity tracking can be disabled and enabled")
  @MainActor
  func testInactivityTrackingToggle() async throws {
    let stateManager = ActiveGameStateManager()

    #expect(stateManager.isInactivityTrackingEnabled == true)

    stateManager.setInactivityTrackingEnabled(false)
    #expect(stateManager.isInactivityTrackingEnabled == false)

    stateManager.setInactivityTrackingEnabled(true)
    #expect(stateManager.isInactivityTrackingEnabled == true)
  }

  @Test("Game state changes update manager state")
  @MainActor
  func testGameStateChanges() async throws {
    let stateManager = ActiveGameStateManager()
    let game = Game(gameType: .recreational)

    stateManager.startGame(game)

    // Test initial state
    #expect(stateManager.isGameInitial == true)
    #expect(stateManager.isGameActive == false)

    // Simulate state change
    stateManager.gameStateDidChange(to: .playing)
    #expect(stateManager.isGameActive == true)
    #expect(stateManager.isGameInitial == false)

    // Test paused state
    stateManager.gameStateDidChange(to: .paused)
    #expect(stateManager.isGameActive == false)
  }

  // MARK: - Game Control

  @Test("Game can be started and controlled")
  @MainActor
  func testGameControl() async throws {
    let stateManager = ActiveGameStateManager()
    let game = Game(gameType: .recreational)

    stateManager.startGame(game)

    // Test that game can transition to playing state
    try await stateManager.startGame()
    #expect(stateManager.isGameActive == true)
    #expect(stateManager.currentGame?.gameState == .playing)
  }

  @Test("Completed games are handled properly")
  @MainActor
  func testCompletedGameHandling() async throws {
    let stateManager = ActiveGameStateManager()
    let game = Game(gameType: .recreational, score1: 11, score2: 9)

    stateManager.startGame(game)
    game.completeGame()

    // Simulate completion through delegate
    stateManager.gameDidComplete(game)

    #expect(game.isCompleted == true)
    #expect(game.gameState == .completed)
    #expect(stateManager.isTimerRunning == false)
  }

  // MARK: - Error Handling

  @Test("Invalid operations are handled gracefully")
  @MainActor
  func testInvalidOperationHandling() async throws {
    let stateManager = ActiveGameStateManager()

    // Operating without a game should not crash
    #expect(stateManager.hasActiveGame == false)

    // Clear when no game should not crash
    stateManager.clearCurrentGame()
    #expect(stateManager.currentGame == nil)
  }

  @Test("State manager can be configured")
  @MainActor
  func testConfiguration() async throws {
    let stateManager = ActiveGameStateManager()

    // Configuration should not crash
    let container = try ModelContainer(for: Game.self)
    let context = ModelContext(container)
    stateManager.configure(with: context)

    // Manager should still be in valid state
    #expect(stateManager.currentGame == nil)
  }
}
