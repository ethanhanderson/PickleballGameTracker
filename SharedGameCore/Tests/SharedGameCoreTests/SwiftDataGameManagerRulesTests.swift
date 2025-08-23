//
//  SwiftDataGameManagerRulesTests.swift
//  SharedGameCoreTests
//
//  Validates rule enforcement in SwiftDataGameManager (serving + scoring).
//

import Foundation
import Testing

@testable import SharedGameCore

@Suite("SwiftDataGameManager Rule Enforcement")
struct SwiftDataGameManagerRulesTests {

  // Minimal in-memory storage stub
  @MainActor
  final class TestStorage: SwiftDataStorageProtocol {
    private(set) var gamesById: [UUID: Game] = [:]

    func saveGame(_ game: Game) async throws {
      gamesById[game.id] = game
    }

    func loadGames() async throws -> [Game] { Array(gamesById.values) }
    func loadActiveGames() async throws -> [Game] { gamesById.values.filter { !$0.isCompleted } }
    func loadCompletedGames() async throws -> [Game] { gamesById.values.filter { $0.isCompleted } }
    func loadGame(id: UUID) async throws -> Game? { gamesById[id] }

    func updateGame(_ game: Game) async throws { gamesById[game.id] = game }
    func deleteGame(id: UUID) async throws { gamesById.removeValue(forKey: id) }
    func deleteAllGames() async throws { gamesById.removeAll() }

    func searchGames(query: String) async throws -> [Game] { [] }
    func loadGameStatistics() async throws -> GameStatistics { GameStatistics() }
    func performMaintenance() async throws {}
    func getStorageStatistics() async throws -> StorageStatistics { StorageStatistics() }
    func validateGamePersistence(_ game: Game) async throws -> Bool { true }
  }

  @Test("Scoring while paused is rejected")
  @MainActor
  func testCannotScoreWhenPaused() async throws {
    let storage = TestStorage()
    let manager = SwiftDataGameManager(storage: storage)
    let game = Game(gameType: .recreational)
    game.gameState = .paused
    try await storage.saveGame(game)

    await #expect(throws: GameError.cannotScoreWhenPaused) {
      try await manager.scorePoint(for: 1, in: game)
    }
  }

  @Test("Manual server change is rejected during play")
  @MainActor
  func testIllegalServerChangeDuringPlay() async throws {
    let storage = TestStorage()
    let manager = SwiftDataGameManager(storage: storage)
    let game = Game(gameType: .recreational)
    game.gameState = .playing
    try await storage.saveGame(game)

    await #expect(throws: GameError.illegalServerChangeDuringPlay) {
      try await manager.switchServer(in: game)
    }

    await #expect(throws: GameError.illegalServerChangeDuringPlay) {
      try await manager.setServer(to: 2, in: game)
    }
  }

  @Test("Manual serving player change is rejected during play (doubles)")
  @MainActor
  func testIllegalServingPlayerChangeDuringPlay() async throws {
    let storage = TestStorage()
    let manager = SwiftDataGameManager(storage: storage)
    let variation = GameVariation(name: "Doubles", gameType: .recreational, teamSize: 2)
    let game = Game(gameVariation: variation)
    game.gameState = .playing
    try await storage.saveGame(game)

    await #expect(throws: GameError.illegalServingPlayerChangeDuringPlay) {
      try await manager.switchServingPlayer(in: game)
    }
    await #expect(throws: GameError.illegalServingPlayerChangeDuringPlay) {
      try await manager.setServingPlayer(to: 2, in: game)
    }
  }

  @Test("Manual server change is allowed when paused")
  @MainActor
  func testManualServerChangeWhenPaused() async throws {
    let storage = TestStorage()
    let manager = SwiftDataGameManager(storage: storage)
    let game = Game(gameType: .recreational)
    game.gameState = .paused
    try await storage.saveGame(game)

    try await manager.setServer(to: 2, in: game)
    #expect(game.currentServer == 2)
  }
}


