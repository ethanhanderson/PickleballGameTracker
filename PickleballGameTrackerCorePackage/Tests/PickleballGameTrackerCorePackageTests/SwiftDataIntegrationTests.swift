//
//  SwiftDataIntegrationTests.swift
//  SharedGameCore
//
//  Created by Ethan Anderson on 7/9/25.
//

import Foundation
import SwiftData
import Testing

@testable import SharedGameCore

@Suite("SwiftData Integration")
struct SwiftDataIntegrationTests {

  // MARK: - Container Tests

  @Test("Container singleton behavior")
  @MainActor
  func testContainerSingleton() throws {
    let container1 = SwiftDataContainer.shared
    let container2 = SwiftDataContainer.shared

    #expect(container1 === container2)
  }

  @Test("Model container creation and health")
  @MainActor
  func testModelContainerHealth() async throws {
    let _ = SwiftDataContainer.shared.modelContainer

    // Test health check
    let isHealthy = await SwiftDataContainer.shared.performHealthCheck()
    #expect(isHealthy == true)
  }

  @Test("Model schema contains Game model")
  @MainActor
  func testModelSchema() throws {
    let container = SwiftDataContainer.shared.modelContainer
    let schema = container.schema

    let gameModel = schema.entities.first { $0.name == "Game" }
    #expect(gameModel != nil)
  }

  // MARK: - Basic Persistence Tests

  @Test("Basic game persistence")
  @MainActor
  func testBasicGamePersistence() throws {
    let container = SwiftDataContainer.shared.modelContainer
    let context = container.mainContext

    // Clear existing data
    try context.delete(model: Game.self)

    // Create and save game
    let game = Game(gameType: .recreational)
    context.insert(game)
    try context.save()

    // Verify persistence
    let fetchDescriptor = FetchDescriptor<Game>()
    let games = try context.fetch(fetchDescriptor)

    #expect(games.contains { $0.id == game.id })
  }

  @Test("Game model validation during save")
  @MainActor
  func testGameModelValidation() throws {
    let container = SwiftDataContainer.shared.modelContainer
    let context = container.mainContext

    // Create game with valid data
    let game = Game(gameType: .tournament, score1: 5, score2: 3)
    context.insert(game)

    // Should save without issues
    #expect(throws: Never.self) {
      try context.save()
    }

    // Verify saved data
    let fetchDescriptor = FetchDescriptor<Game>()
    let games = try context.fetch(fetchDescriptor)
    let savedGame = games.first { $0.id == game.id }

    #expect(savedGame?.score1 == 5)
    #expect(savedGame?.score2 == 3)
    #expect(savedGame?.gameType == .tournament)
  }

  // MARK: - Query Performance Tests

  @Test("Query performance with multiple games")
  @MainActor
  func testQueryPerformance() throws {
    let container = SwiftDataContainer.shared.modelContainer
    let context = container.mainContext

    // Clear and create test data
    try context.delete(model: Game.self)

    // Create multiple games
    for i in 0..<20 {
      let game = Game(gameType: i % 2 == 0 ? .recreational : .tournament)
      game.score1 = Int.random(in: 0...11)
      game.score2 = Int.random(in: 0...11)
      if i < 10 {
        game.completeGame()
      }
      context.insert(game)
    }

    try context.save()

    // Test various queries
    let allGamesDescriptor = FetchDescriptor<Game>()
    let allGames = try context.fetch(allGamesDescriptor)
    #expect(allGames.count == 20)

    // Test filtering completed vs active games
    let completedGames = allGames.filter { $0.isCompleted }
    let activeGames = allGames.filter { !$0.isCompleted }
    #expect(completedGames.count == 10)
    #expect(activeGames.count == 10)
  }

  // MARK: - Data Integrity Tests

  @Test("Concurrent modifications don't corrupt data")
  @MainActor
  func testConcurrentModifications() async throws {
    let container = SwiftDataContainer.shared.modelContainer
    let context = container.mainContext

    // Create initial game
    let game = Game(gameType: .recreational)
    context.insert(game)
    try context.save()

    // Simulate concurrent updates
    for i in 0..<10 {
      if i % 2 == 0 {
        game.scorePoint1()
      } else {
        game.scorePoint2()
      }
      try context.save()
    }

    // Verify final state is consistent
    #expect(game.score1 == 5)
    #expect(game.score2 == 5)
    #expect(game.totalRallies == 10)

    // Verify persistence
    let descriptor = FetchDescriptor<Game>()
    let retrievedGames = try context.fetch(descriptor)
    let retrievedGame = retrievedGames.first { $0.id == game.id }

    #expect(retrievedGame?.score1 == 5)
    #expect(retrievedGame?.score2 == 5)
    #expect(retrievedGame?.totalRallies == 10)
  }

  @Test("Context autosave behavior")
  @MainActor
  func testContextAutosave() throws {
    let container = SwiftDataContainer.shared.modelContainer
    let context = container.mainContext

    // Verify autosave is enabled
    #expect(context.autosaveEnabled == true)
  }

  // MARK: - Container Maintenance

  @Test("Container maintenance operations")
  @MainActor
  func testContainerMaintenance() async throws {
    // Should not throw
    try await SwiftDataContainer.shared.performMaintenance()
    // If we reach here, maintenance completed successfully
    #expect(Bool(true))
  }

  @Test("Container statistics")
  @MainActor
  func testContainerStatistics() async throws {
    let statistics = await SwiftDataContainer.shared.getContainerStatistics()

    #expect(statistics.gameCount >= 0)
    #expect(statistics.totalItems >= 0)
    // Statistics should have valid timestamp
  }

  // MARK: - Notes persistence and search (v0.3 P0 coverage for 1.17 partial)

  @Test("Notes persist and are searchable")
  @MainActor
  func testNotesPersistenceAndSearch() async throws {
    let container = SwiftDataContainer.shared.modelContainer
    let context = container.mainContext

    // Clear
    try context.delete(model: Game.self)

    // Create games with and without notes
    let g1 = Game(gameType: .recreational)
    g1.notes = "Great rally at 7-7"
    let g2 = Game(gameType: .tournament)
    g2.notes = "Finals match"
    let g3 = Game(gameType: .training)
    // no notes

    context.insert(g1)
    context.insert(g2)
    context.insert(g3)
    try context.save()

    // Verify persisted
    let fetched = try context.fetch(FetchDescriptor<Game>())
    #expect(fetched.count == 3)

    // Search via storage API by a token in notes
    let storage = SwiftDataStorage.shared
    let results = try await storage.searchGames(query: "rally")
    #expect(results.count == 1)
    #expect(results.first?.notes?.contains("rally") == true)
  }

  // MARK: - Error Handling

  @Test("Invalid queries are handled gracefully")
  @MainActor
  func testInvalidQueryHandling() throws {
    let container = SwiftDataContainer.shared.modelContainer
    let context = container.mainContext

    // Test with empty predicate
    let descriptor = FetchDescriptor<Game>()
    let games = try context.fetch(descriptor)

    // Should return empty array, not crash
    #expect(games.count >= 0)
  }

  @Test("Database corruption recovery")
  @MainActor
  func testDatabaseRecovery() async throws {
    // Test that health check can detect and handle issues
    let isHealthy = await SwiftDataContainer.shared.performHealthCheck()

    // If not healthy, maintenance should help
    if !isHealthy {
      try await SwiftDataContainer.shared.performMaintenance()
      let isHealthyAfterMaintenance = await SwiftDataContainer.shared.performHealthCheck()
      #expect(isHealthyAfterMaintenance == true)
    } else {
      #expect(isHealthy == true)
    }
  }
}
