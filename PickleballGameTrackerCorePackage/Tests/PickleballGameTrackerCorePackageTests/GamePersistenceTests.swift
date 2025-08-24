//
//  GamePersistenceTests.swift
//  SharedGameCore
//
//  Created by Ethan Anderson on 7/9/25.
//

import SwiftData
import Testing

@testable import SharedGameCore

@Suite("Game Persistence and Storage")
struct GamePersistenceTests {

  // MARK: - Game Completion Persistence

  @Test("Game completion persists to storage correctly")
  @MainActor
  func testGameCompletionPersistence() async throws {
    let container = SwiftDataContainer.shared
    let context = container.modelContainer.mainContext

    // Clear existing games
    try context.delete(model: Game.self)
    try context.save()

    let manager = SwiftDataGameManager()

    // Create and complete a game
    let game = try await manager.createGame(type: .recreational)

    // Drive scoring until completion
    while !game.isCompleted {
      try await manager.scorePoint(for: 1, in: game)
    }

    // Verify auto-completion
    #expect(game.isCompleted == true)
    #expect(game.gameState == .completed)
    #expect(game.completedDate != nil)

    // Verify persistence
    let savedGame = try await manager.storage.loadGame(id: game.id)
    #expect(savedGame != nil)
    #expect(savedGame?.isCompleted == true)
    #expect(savedGame?.gameState == .completed)

    // Verify in completed games list
    let completedGames = try await manager.storage.loadCompletedGames()
    #expect(completedGames.contains { $0.id == game.id })
  }

  @Test("Manual game completion persists correctly")
  @MainActor
  func testManualGameCompletionPersistence() async throws {
    let container = SwiftDataContainer.shared
    let context = container.modelContainer.mainContext

    // Clear existing games
    try context.delete(model: Game.self)
    try context.save()

    let manager = SwiftDataGameManager()

    // Create game with partial score
    let game = try await manager.createGame(type: .recreational)
    // Move to playing so manager scoring is allowed
    try await manager.resumeGame(game)
    try await manager.scorePoint(for: 1, in: game)
    try await manager.scorePoint(for: 2, in: game)

    #expect(game.isCompleted == false)

    // Manually complete
    try await manager.completeGame(game)

    // Verify completion and persistence
    #expect(game.isCompleted == true)
    #expect(game.gameState == .completed)

    let savedGame = try await manager.storage.loadGame(id: game.id)
    #expect(savedGame?.isCompleted == true)
  }

  // MARK: - Storage Validation

  @Test("Storage validation detects persistence issues")
  @MainActor
  func testStorageValidation() async throws {
    let container = SwiftDataContainer.shared
    let context = container.modelContainer.mainContext

    // Clear existing games
    try context.delete(model: Game.self)
    try context.save()

    let storage = SwiftDataStorage.shared

    // Create and save game
    let game = Game(gameType: .recreational, score1: 5, score2: 3)
    try await storage.saveGame(game)

    // Validate persistence
    let isValid = try await storage.validateGamePersistence(game)
    #expect(isValid == true)

    // Modify game in memory without saving
    game.score1 = 10

    // Validation should detect mismatch
    let isValidAfterChange = try await storage.validateGamePersistence(game)
    #expect(isValidAfterChange == false)
  }

  @Test("Update method handles missing games correctly")
  @MainActor
  func testUpdateGameHandlesMissingGames() async throws {
    let container = SwiftDataContainer.shared
    let context = container.modelContainer.mainContext

    // Clear existing games
    try context.delete(model: Game.self)
    try context.save()

    let storage = SwiftDataStorage.shared

    // Create game without saving first
    let game = Game(gameType: .recreational, score1: 5, score2: 3)

    // Update should handle missing game by inserting it
    try await storage.updateGame(game)

    // Verify it was inserted
    let savedGame = try await storage.loadGame(id: game.id)
    #expect(savedGame != nil)
    #expect(savedGame?.score1 == 5)
    #expect(savedGame?.score2 == 3)
  }

  // MARK: - Data Recovery

  @Test("Data recovery fixes completion issues")
  @MainActor
  func testDataRecoveryMethod() async throws {
    let container = SwiftDataContainer.shared
    let context = container.modelContainer.mainContext

    // Clear existing games
    try context.delete(model: Game.self)
    try context.save()

    let manager = SwiftDataGameManager()

    // Create game that should be completed but isn't marked as such
    let game = Game(gameType: .recreational, score1: 11, score2: 8)
    game.isCompleted = false  // Incorrectly not marked
    game.gameState = .playing

    try await manager.storage.saveGame(game)

    // Run recovery
    let recoveredCount = try await manager.validateAndRecoverGameData()

    // Should have recovered the game
    #expect(recoveredCount > 0)

    // Verify proper completion state
    let recoveredGame = try await manager.storage.loadGame(id: game.id)
    #expect(recoveredGame?.isCompleted == true)
    #expect(recoveredGame?.gameState == .completed)
    #expect(recoveredGame?.completedDate != nil)
  }

  // MARK: - Storage Error Handling

  @Test("Storage error handling improvements")
  @MainActor
  func testStorageErrorHandling() async throws {
    let storage = SwiftDataStorage.shared

    // Test updating a game that doesn't exist in storage
    let orphanGame = Game(gameType: .recreational, score1: 5, score2: 3)

    // Should work with fix (inserts missing game)
    try await storage.updateGame(orphanGame)

    // Verify insertion
    let savedGame = try await storage.loadGame(id: orphanGame.id)
    #expect(savedGame != nil)
    #expect(savedGame?.score1 == 5)
    #expect(savedGame?.score2 == 3)
  }

  @Test("Game manager auto-completion persistence")
  @MainActor
  func testGameManagerAutoCompletion() async throws {
    let container = SwiftDataContainer.shared
    let context = container.modelContainer.mainContext

    // Clear existing games
    try context.delete(model: Game.self)
    try context.save()

    let manager = SwiftDataGameManager()

    // Create game and score to near completion
    let game = try await manager.createGame(type: .recreational)

    // Score to 10-9
    for _ in 1...10 {
      try await manager.scorePoint(for: 1, in: game)
    }
    for _ in 1...9 {
      try await manager.scorePoint(for: 2, in: game)
    }

    #expect(game.isCompleted == false)

    // Score winning point (should auto-complete)
    try await manager.scorePoint(for: 1, in: game)

    // Verify auto-completion and persistence
    #expect(game.isCompleted == true)
    #expect(game.gameState == .completed)
    #expect(game.completedDate != nil)
    #expect(game.score1 == 11)
    #expect(game.score2 == 9)

    // Verify saved to storage
    let savedGame = try await manager.storage.loadGame(id: game.id)
    #expect(savedGame?.isCompleted == true)
    #expect(savedGame?.gameState == .completed)
  }
}
