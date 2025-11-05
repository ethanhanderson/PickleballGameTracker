//
//  SwiftDataGameManagerTests.swift
//  GameTrackerCoreTests
//

import Testing
@testable import GameTrackerCore

@Suite("SwiftDataGameManager Tests")
struct SwiftDataGameManagerTests {
  
  @Test("scorePointAndLogEvent increments score and logs event with persistence")
  @MainActor
  func scorePointAndLogEventCombinesScoringAndEventLogging() async throws {
    let storage = MockSwiftDataStorage()
    let manager = SwiftDataGameManager(storage: storage)
    
    let game = Game(gameType: .recreational)
    game.gameState = .playing
    game.score1 = 5
    game.score2 = 3
    
    try await storage.saveGame(game)
    
    let timestamp: TimeInterval = 12.34
    let customDescription = "Player 1 scored"
    
    try await manager.scorePointAndLogEvent(
      for: 1,
      in: game,
      at: timestamp,
      customDescription: customDescription
    )
    
    #expect(game.score1 == 6)
    #expect(game.score2 == 3)
    
    let lastEvent = game.events.last
    #require(lastEvent != nil)
    #expect(lastEvent?.eventType == .playerScored)
    #expect(lastEvent?.timestamp == timestamp)
    #expect(lastEvent?.teamAffected == 1)
    #expect(lastEvent?.customDescription == customDescription)
    
    let updatedGame = try await storage.loadGame(id: game.id)
    #require(updatedGame != nil)
    #expect(updatedGame?.score1 == 6)
    #expect(updatedGame?.events.last?.eventType == .playerScored)
  }
  
  @Test("scorePointAndLogEvent works without custom description")
  @MainActor
  func scorePointAndLogEventWithoutCustomDescription() async throws {
    let storage = MockSwiftDataStorage()
    let manager = SwiftDataGameManager(storage: storage)
    
    let game = Game(gameType: .recreational)
    game.gameState = .playing
    game.score1 = 0
    game.score2 = 0
    
    try await storage.saveGame(game)
    
    try await manager.scorePointAndLogEvent(
      for: 2,
      in: game,
      at: 45.67
    )
    
    #expect(game.score2 == 1)
    
    let lastEvent = game.events.last
    #require(lastEvent != nil)
    #expect(lastEvent?.eventType == .playerScored)
    #expect(lastEvent?.teamAffected == 2)
    #expect(lastEvent?.customDescription == nil)
  }

  @Test("completeCurrentGame deletes unused game and clears current reference")
  @MainActor
  func completeCurrentGameDeletesUnusedGame() async throws {
    let storage = MockSwiftDataStorage()
    let manager = SwiftDataGameManager(storage: storage)
    let liveManager = LiveGameStateManager()
    liveManager.configure(gameManager: manager)

    let game = try await manager.createGame(type: .recreational)
    await liveManager.setCurrentGame(game)

    // Sanity check: unused games should be flagged for deletion on completion
    #expect(liveManager.willDeleteCurrentGameOnCompletion)

    try await liveManager.completeCurrentGame()

    #expect(liveManager.currentGame == nil)
    #expect(storage.deletedGameIds.contains(game.id))
    #expect(try await storage.loadGame(id: game.id) == nil)
  }
}

// MARK: - Mock Storage

@MainActor
final class MockSwiftDataStorage: SwiftDataStorageProtocol {
  private var games: [UUID: Game] = [:]
  private(set) var deletedGameIds: [UUID] = []
  
  var modelContainer: ModelContainer {
    fatalError("Not implemented for mock")
  }
  
  func saveGame(_ game: Game) async throws {
    games[game.id] = game
  }
  
  func updateGame(_ game: Game) async throws {
    games[game.id] = game
  }
  
  func loadGame(id: UUID) async throws -> Game? {
    return games[id]
  }
  
  func loadGames() async throws -> [Game] {
    Array(games.values)
  }
  
  func loadActiveGames() async throws -> [Game] {
    Array(games.values.filter { !$0.isCompleted })
  }
  
  func loadCompletedGames() async throws -> [Game] {
    Array(games.values.filter { $0.isCompleted })
  }
  
  func deleteGame(id: UUID) async throws {
    games.removeValue(forKey: id)
    deletedGameIds.append(id)
  }
  
  func deleteAllGames() async throws {
    games.removeAll()
  }
  
  func searchGames(query: String) async throws -> [Game] {
    []
  }
  
  func searchGames(query: String, filters: GameSearchFilters) async throws -> [Game] {
    []
  }
  
  func searchGamesAdvanced(criteria: GameSearchCriteria) async throws -> [Game] {
    []
  }
  
  func loadGameStatistics() async throws -> GameStatistics {
    GameStatistics()
  }
  
  func performMaintenance() async throws {
  }
  
  func getStorageStatistics() async throws -> StorageStatistics {
    StorageStatistics()
  }
  
  func validateGamePersistence(_ game: Game) async throws -> Bool {
    return games[game.id] != nil
  }
  
  func getPerformanceMetrics() async -> PerformanceMetrics {
    PerformanceMetrics()
  }
  
  func recoverFromError(_ error: StorageError) async throws -> RecoveryResult {
    RecoveryResult(success: true, message: "")
  }
  
  func validateDataIntegrity() async throws -> DataValidationResult {
    DataValidationResult()
  }
  
  func validateGameData(_ game: Game) throws -> GameValidationResult {
    GameValidationResult()
  }
  
  func exportBackup() async throws -> Data {
    Data()
  }
  
  func importBackup(_ data: Data, mode: BackupImportMode) async throws {
  }
  
  func purge(_ options: PurgeOptions) async throws -> PurgeResult {
    PurgeResult()
  }
  
  func integritySweep() async throws -> IntegrityReport {
    IntegrityReport()
  }
  
  func compactStore() async throws {
  }
  
  func loadPlayers(includeArchived: Bool) throws -> [PlayerProfile] {
    []
  }
  
  func loadPlayer(id: UUID) throws -> PlayerProfile? {
    return nil
  }
  
  func savePlayer(_ player: PlayerProfile) throws {
  }
  
  func updatePlayer(_ player: PlayerProfile) throws {
  }
  
  func archivePlayer(_ player: PlayerProfile) throws {
  }
  
  func deletePlayer(id: UUID) throws {
  }
  
  func loadTeams(includeArchived: Bool) throws -> [TeamProfile] {
    []
  }
  
  func loadTeam(id: UUID) throws -> TeamProfile? {
    return nil
  }
  
  func saveTeam(_ team: TeamProfile) throws {
  }
  
  func updateTeam(_ team: TeamProfile) throws {
  }
  
  func archiveTeam(_ team: TeamProfile) throws {
  }
  
  func deleteTeam(id: UUID) throws {
  }
  
  func loadPresets(includeArchived: Bool) throws -> [GameTypePreset] {
    []
  }
  
  func loadPreset(id: UUID) throws -> GameTypePreset? {
    return nil
  }
  
  func savePreset(_ preset: GameTypePreset) throws {
  }
  
  func updatePreset(_ preset: GameTypePreset) throws {
  }
  
  func archivePreset(_ preset: GameTypePreset) throws {
  }
  
  func deletePreset(id: UUID) throws {
  }
}

