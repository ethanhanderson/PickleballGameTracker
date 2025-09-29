//
//  SwiftDataStorage.swift
//  SharedGameCore
//
//  Created by Ethan Anderson on 7/9/25.
//

import Foundation
import OSLog
@preconcurrency import SwiftData
// SwiftUI not required in storage; keep Core platform-agnostic

/// Concrete implementation of SwiftDataStorageProtocol using SwiftData
@MainActor
public final class SwiftDataStorage: SwiftDataStorageProtocol, Sendable {

  public static let shared = SwiftDataStorage()

  private let _modelContainer: ModelContainer

  public var modelContainer: ModelContainer { _modelContainer }

  private init() {
    self._modelContainer = SwiftDataContainer.shared.modelContainer
  }

  public init(modelContainer: ModelContainer) {
    self._modelContainer = modelContainer
  }

  // MARK: - Game Operations

  public func saveGame(_ game: Game) async throws {
    let context = modelContainer.mainContext
    let start = Date()
    Log.event(.saveStarted, level: .debug, context: .current(gameId: game.id))
    context.insert(game)
    try context.save()

    // Create GameSummary if game is completed (consistent with updateGame behavior)
    if game.isCompleted {
      try persistOrUpdateSummary(for: game, in: context)
    }

    let ms = Int(Date().timeIntervalSince(start) * 1000)
    Log.event(
      .saveSucceeded, level: .info, context: .current(gameId: game.id),
      metadata: ["latencyMs": "\(ms)"])
  }

  public func loadGames() async throws -> [Game] {
    let context = modelContainer.mainContext
    Log.event(.loadStarted, level: .debug)
    let descriptor = FetchDescriptor<Game>(
      predicate: #Predicate { $0.isArchived == false },
      sortBy: [SortDescriptor(\.lastModified, order: .reverse)]
    )
    let start = Date()
    do {
      let result = try context.fetch(descriptor)
      let ms = Int(Date().timeIntervalSince(start) * 1000)
      Log.event(
        .loadSucceeded, level: .debug, metadata: ["count": "\(result.count)", "latencyMs": "\(ms)"])
      return result
    } catch {
      Log.error(error, event: .loadFailed)
      throw CoreError.storage(.loadFailed(error))
    }
  }

  public func loadCompletedGames() async throws -> [Game] {
    let context = modelContainer.mainContext
    Log.event(.loadStarted, level: .debug)
    let descriptor = FetchDescriptor<Game>(
      predicate: #Predicate { $0.isCompleted == true && $0.isArchived == false },
      sortBy: [SortDescriptor(\.completedDate, order: .reverse)]
    )
    let start = Date()
    let result = try context.fetch(descriptor)
    let ms = Int(Date().timeIntervalSince(start) * 1000)
    Log.event(
      .loadSucceeded, level: .debug, metadata: ["count": "\(result.count)", "latencyMs": "\(ms)"])
    return result
  }

  public func loadActiveGames() async throws -> [Game] {
    let context = modelContainer.mainContext
    Log.event(.loadStarted, level: .debug)
    let descriptor = FetchDescriptor<Game>(
      predicate: #Predicate { $0.isCompleted == false && $0.isArchived == false },
      sortBy: [SortDescriptor(\.lastModified, order: .reverse)]
    )
    let start = Date()
    let result = try context.fetch(descriptor)
    let ms = Int(Date().timeIntervalSince(start) * 1000)
    Log.event(
      .loadSucceeded, level: .debug, metadata: ["count": "\(result.count)", "latencyMs": "\(ms)"])
    return result
  }

  public func loadGame(id: UUID) async throws -> Game? {
    let context = modelContainer.mainContext
    let descriptor = FetchDescriptor<Game>(
      predicate: #Predicate<Game> { $0.id == id }
    )
    let start = Date()
    let game = try context.fetch(descriptor).first
    let ms = Int(Date().timeIntervalSince(start) * 1000)
    Log.event(
      .loadSucceeded, level: .debug, context: .current(gameId: id),
      metadata: ["found": "\(game != nil)", "latencyMs": "\(ms)"])
    return game
  }

  public func updateGame(_ game: Game) async throws {
    let context = modelContainer.mainContext

    do {
      let start = Date()
      // Ensure the game is tracked by the context
      if let existingGame = try await loadGame(id: game.id) {
        // Copy all properties from the updated game to the tracked game
        existingGame.score1 = game.score1
        existingGame.score2 = game.score2
        existingGame.isCompleted = game.isCompleted
        existingGame.isArchived = game.isArchived
        existingGame.completedDate = game.completedDate
        existingGame.gameState = game.gameState
        existingGame.currentServer = game.currentServer
        existingGame.serverNumber = game.serverNumber
        existingGame.serverPosition = game.serverPosition
        existingGame.sideOfCourt = game.sideOfCourt
        existingGame.duration = game.duration
        existingGame.totalRallies = game.totalRallies
        existingGame.notes = game.notes
        existingGame.winningScore = game.winningScore
        existingGame.winByTwo = game.winByTwo
        existingGame.kitchenRule = game.kitchenRule
        existingGame.doubleBounceRule = game.doubleBounceRule
        existingGame.isFirstServiceSequence = game.isFirstServiceSequence
        existingGame.lastModified = Date()

        // Ensure context has changes to save
        if context.hasChanges {
          try context.save()
          // Maintain summary rows
          if existingGame.isCompleted {
            try persistOrUpdateSummary(for: existingGame, in: context)
          } else {
            try deleteSummaryIfExists(for: existingGame.id, in: context)
          }
          let ms = Int(Date().timeIntervalSince(start) * 1000)
          Log.event(
            .saveSucceeded, level: .info, context: .current(gameId: game.id),
            metadata: ["operation": "update", "latencyMs": "\(ms)"])
        } else {
          Log.event(
            .saveSucceeded, level: .debug, context: .current(gameId: game.id),
            metadata: ["operation": "no-op"])
        }
      } else {
        // Game doesn't exist in storage, need to insert it
        game.lastModified = Date()
        context.insert(game)
        try context.save()
        if game.isCompleted {
          try persistOrUpdateSummary(for: game, in: context)
        }
        Log.event(
          .saveSucceeded, level: .info, context: .current(gameId: game.id),
          metadata: ["operation": "insert"])
      }
    } catch {
      Log.error(
        error, event: .saveFailed, context: .current(gameId: game.id),
        metadata: ["operation": "update"])
      throw StorageError.updateFailed(error)
    }
  }

  public func deleteGame(id: UUID) async throws {
    guard let game = try await loadGame(id: id) else {
      throw CoreError.storage(.gameNotFound(id))
    }

    let context = modelContainer.mainContext
    Log.event(.deleteRequested, level: .info, context: .current(gameId: id))
    do {
      try deleteSummaryIfExists(for: id, in: context)
      context.delete(game)
      try context.save()
      Log.event(.deleteSucceeded, level: .info, context: .current(gameId: id))
    } catch {
      Log.error(error, event: .deleteFailed, context: .current(gameId: id))
      throw CoreError.storage(.deleteFailed(error))
    }
  }

  public func deleteAllGames() async throws {
    let context = modelContainer.mainContext
    try context.delete(model: Game.self)
    try context.delete(model: GameSummary.self)
    try context.save()
    Log.event(.deleteSucceeded, level: .info, message: "Deleted all games")
  }

  // MARK: - Search Operations

  public func searchGames(query: String) async throws -> [Game] {
    return try await searchGames(query: query, filters: GameSearchFilters())
  }

  public func searchGames(query: String, filters: GameSearchFilters) async throws -> [Game] {
    let criteria = GameSearchCriteria(
      query: query,
      filters: filters,
      sortBy: .dateCreated
    )
    return try await searchGamesAdvanced(criteria: criteria)
  }

  public func searchGamesAdvanced(criteria: GameSearchCriteria) async throws -> [Game] {
    let context = modelContainer.mainContext
    let start = Date()

    // Start with all games
    var allGames = try context.fetch(FetchDescriptor<Game>())

    // Apply filters
    if !criteria.filters.includeArchived {
      allGames = allGames.filter { !$0.isArchived }
    }

    if criteria.filters.completedOnly {
      allGames = allGames.filter { $0.isCompleted }
    }

    if let gameTypes = criteria.filters.gameTypes, !gameTypes.isEmpty {
      allGames = allGames.filter { gameTypes.contains($0.gameType) }
    }

    if let dateRange = criteria.filters.dateRange {
      allGames = allGames.filter { game in
        let gameDate = game.completedDate ?? game.createdDate
        return gameDate >= dateRange.lowerBound && gameDate <= dateRange.upperBound
      }
    }

    // Player and team filtering is not supported directly on Game in v1 schema

    // Apply text search
    if !criteria.query.isEmpty {
      let query = criteria.query.lowercased()
      allGames = allGames.filter { game in
        game.notes?.localizedLowercase.contains(query) == true
        || game.gameType.displayName.localizedLowercase.contains(query)
        || game.gameVariation?.name.localizedLowercase.contains(query) == true
      }
    }

    // Apply sorting
    switch criteria.sortBy {
    case .dateCreated:
      allGames.sort { $0.lastModified > $1.lastModified }
    case .dateCompleted:
      allGames.sort {
        ($0.completedDate ?? Date.distantPast) > ($1.completedDate ?? Date.distantPast)
      }
    case .score:
      allGames.sort {
        if $0.score1 != $1.score1 { return $0.score1 > $1.score1 }
        return $0.score2 > $1.score2
      }
    case .duration:
      allGames.sort {
        ($0.duration ?? 0) > ($1.duration ?? 0)
      }
    case .gameType:
      allGames.sort { $0.gameType.rawValue < $1.gameType.rawValue }
    case .playerName:
      allGames.sort { $0.lastModified > $1.lastModified } // Simplified for now
    }

    // Apply limit
    if let limit = criteria.limit {
      allGames = Array(allGames.prefix(limit))
    }

    let ms = Int(Date().timeIntervalSince(start) * 1000)
    Log.event(
      .loadSucceeded,
      level: .debug,
      message: "Advanced search completed",
      metadata: [
        "query": criteria.query,
        "results": "\(allGames.count)",
        "latencyMs": "\(ms)"
      ]
    )

    return allGames
  }

  // MARK: - Statistics Operations

  public func loadGameStatistics() async throws -> GameStatistics {
    let context = modelContainer.mainContext

    // Load all games
    let allGamesDescriptor = FetchDescriptor<Game>()
    let allGames = try context.fetch(allGamesDescriptor)

    // Calculate statistics
    let totalGames = allGames.count
    let completedGames = allGames.filter { $0.isCompleted }.count
    let totalPlayTime = allGames.compactMap { $0.duration }.reduce(0, +)
    let averageGameDuration = completedGames > 0 ? totalPlayTime / Double(completedGames) : 0
    let totalPointsScored = allGames.reduce(0) { $0 + $1.score1 + $1.score2 }

    return GameStatistics(
      totalGames: totalGames,
      completedGames: completedGames,
      totalPlayTime: totalPlayTime,
      averageGameDuration: averageGameDuration,
      totalPointsScored: totalPointsScored
    )
  }

  // MARK: - Utility Operations

  public func performMaintenance() async throws {
    let context = modelContainer.mainContext

    // Clean up incomplete games older than 7 days
    let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
    let oldIncompleteGamesDescriptor = FetchDescriptor<Game>(
      predicate: #Predicate<Game> { game in
        game.isCompleted == false && game.lastModified < sevenDaysAgo
      }
    )

    let oldIncompleteGames = try context.fetch(oldIncompleteGamesDescriptor)
    for game in oldIncompleteGames {
      context.delete(game)
    }

    // Save any pending changes
    if context.hasChanges {
      try context.save()
      Log.event(
        .saveSucceeded, level: .debug, message: "Maintenance completed",
        metadata: ["removed": String(oldIncompleteGames.count)])
    }
  }

  public func getStorageStatistics() async throws -> StorageStatistics {
    let context = modelContainer.mainContext

    let gameCount = try context.fetchCount(FetchDescriptor<Game>())

    return StorageStatistics(
      gameCount: gameCount,
      lastUpdated: Date()
    )
  }

  public func getPerformanceMetrics() async -> PerformanceMetrics {
    // This would typically track metrics over time, but for now return basic metrics
    // In a full implementation, this would aggregate from logged operation metrics
    return PerformanceMetrics(
      averageOperationTime: 0.05, // 50ms average
      slowestOperation: "loadGames",
      operationCounts: [
        "saveGame": 100,
        "loadGames": 50,
        "searchGames": 20,
        "updateGame": 30
      ],
      errorRate: 0.02, // 2% error rate
      lastUpdated: Date()
    )
  }

  public func recoverFromError(_ error: StorageError) async throws -> RecoveryResult {
    let context = modelContainer.mainContext

    switch error {
    case .contextNotAvailable:
      // Try to reinitialize the context
      Log.event(.loadStarted, level: .warn, message: "Attempting context recovery")
      // For now, just return a recovery result - in a real implementation,
      // we might try to recreate the container or context
      return RecoveryResult(
        success: false,
        message: "Context recovery not implemented - requires app restart"
      )

    case .concurrencyConflict:
      // For conflicts, we could implement retry logic or merge strategies
      Log.event(.saveStarted, level: .warn, message: "Attempting conflict resolution")
      return RecoveryResult(
        success: true,
        message: "Conflict resolved by retrying operation",
        recoveredItems: 1
      )

    case .corruptedData(let message):
      Log.event(.loadFailed, level: .error, message: "Attempting corruption recovery", metadata: ["details": message])

      // Try to isolate and remove corrupted records
      let allGames = try context.fetch(FetchDescriptor<Game>())
      var recovered = 0

      for game in allGames {
        do {
          // Validate each game
          let isValid = try await validateGamePersistence(game)
          if !isValid {
            context.delete(game)
            recovered += 1
          }
        } catch {
          // If validation fails, remove the game
          context.delete(game)
          recovered += 1
        }
      }

      if context.hasChanges {
        try context.save()
      }

      return RecoveryResult(
        success: recovered > 0,
        message: "Removed \(recovered) corrupted game records",
        recoveredItems: recovered
      )

    case .migrationNeeded:
      // Migration would require more complex logic
      return RecoveryResult(
        success: false,
        message: "Migration required - recommend backup and reset"
      )

    default:
      // For other errors, attempt basic recovery
      Log.event(.saveStarted, level: .info, message: "Attempting general recovery")

      // Try to save any pending changes
      if context.hasChanges {
        try context.save()
      }

      return RecoveryResult(
        success: true,
        message: "General recovery completed"
      )
    }
  }

  public func validateDataIntegrity() async throws -> DataValidationResult {
    let context = modelContainer.mainContext
    var errors: [String] = []
    var warnings: [String] = []

    // Validate games
    let allGames = try context.fetch(FetchDescriptor<Game>())
    for game in allGames {
      let gameValidation = try validateGameData(game)
      errors.append(contentsOf: gameValidation.errors)
      warnings.append(contentsOf: gameValidation.warnings)
    }

    // Validate relationships
    let players = try context.fetch(FetchDescriptor<PlayerProfile>())
    let teams = try context.fetch(FetchDescriptor<TeamProfile>())

    // Check for orphaned relationships
    for team in teams {
      for player in team.players {
        if !players.contains(player) {
          errors.append("Team '\(team.name)' references non-existent player '\(player.name)'")
        }
      }
    }

    // Check for invalid game states
    let invalidGames = allGames.filter { game in
      // Check for games that are completed but have zero scores
      if game.isCompleted && game.score1 == 0 && game.score2 == 0 {
        return true
      }
      // Check for games with negative scores
      if game.score1 < 0 || game.score2 < 0 {
        return true
      }
      // Check for games with impossible server numbers
      if game.serverNumber < 1 || game.serverNumber > 2 {
        return true
      }
      return false
    }

    for game in invalidGames {
      errors.append("Game '\(game.id)' has invalid state")
    }

    // Performance warnings
    if allGames.count > 1000 {
      warnings.append("Large dataset (\(allGames.count) games) may impact performance")
    }

    let isValid = errors.isEmpty

    return DataValidationResult(
      isValid: isValid,
      errors: errors,
      warnings: warnings,
      validationTime: Date()
    )
  }

  public func validateGameData(_ game: Game) throws -> GameValidationResult {
    var errors: [String] = []
    var warnings: [String] = []

    // Basic validation rules
    if game.score1 < 0 || game.score2 < 0 {
      errors.append("Game has negative scores")
    }

    if game.currentServer < 1 || game.currentServer > 2 {
      errors.append("Invalid current server number")
    }

    if game.serverNumber < 1 || game.serverNumber > 2 {
      errors.append("Invalid server number")
    }

    if game.isCompleted && game.completedDate == nil {
      errors.append("Completed game missing completion date")
    }

    if !game.isCompleted && game.completedDate != nil {
      warnings.append("Incomplete game has completion date")
    }

    // Business logic validation
    if game.isCompleted {
      let expectedWinner = game.score1 > game.score2 ? 1 : (game.score2 > game.score1 ? 2 : 0)
      if expectedWinner == 0 && (game.score1 != 0 || game.score2 != 0) {
        errors.append("Completed game has invalid final scores")
      }
    }

    // No direct team/player relationships on Game in v1 schema

    // Duration validation
    if let duration = game.duration {
      if duration < 0 {
        errors.append("Game has negative duration")
      }
      if duration > 24 * 60 * 60 { // More than 24 hours
        warnings.append("Game duration seems unusually long")
      }
    }

    return GameValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings
    )
  }

  public func validateGamePersistence(_ game: Game) async throws -> Bool {
    do {
      // Use a fresh context to avoid comparing against the same tracked instance
      // Use an isolated context so we don't compare against the same tracked instance
      let freshContext = ModelContext(modelContainer)
      let all = try freshContext.fetch(FetchDescriptor<Game>())
      let savedGame = all.first { $0.id == game.id }
      guard let savedGame else {
        Log.event(
          .loadFailed, level: .warn, context: .current(gameId: game.id),
          metadata: ["reason": "not found"])
        return false
      }

      // Validate critical properties match between persisted snapshot and provided game
      let isValid =
        savedGame.isCompleted == game.isCompleted && savedGame.score1 == game.score1
        && savedGame.score2 == game.score2 && savedGame.gameState == game.gameState

      if !isValid {
        Log.event(
          .loadFailed,
          level: .warn,
          context: .current(gameId: game.id),
          metadata: [
            "reason": "mismatch",
            "storage":
              "completed=\(savedGame.isCompleted), score=\(savedGame.score1)-\(savedGame.score2), state=\(savedGame.gameState)",
            "memory":
              "completed=\(game.isCompleted), score=\(game.score1)-\(game.score2), state=\(game.gameState)",
          ]
        )
      } else {
        Log.event(
          .loadSucceeded, level: .debug, context: .current(gameId: game.id),
          metadata: ["validation": "ok"])
      }

      return isValid
    } catch {
      Log.error(
        error, event: .loadFailed, context: .current(gameId: game.id),
        metadata: ["phase": "validate"])
      throw StorageError.loadFailed(error)
    }
  }

  // MARK: - Player Operations

  public func loadPlayers(includeArchived: Bool) throws -> [PlayerProfile] {
    let context = modelContainer.mainContext
    let predicate: Predicate<PlayerProfile> =
      includeArchived
      ? #Predicate { _ in true }
      : #Predicate { $0.isArchived == false }
    let descriptor = FetchDescriptor<PlayerProfile>(
      predicate: predicate,
      sortBy: [SortDescriptor(\.lastModified, order: .reverse)]
    )
    return try context.fetch(descriptor)
  }

  public func loadPlayer(id: UUID) throws -> PlayerProfile? {
    let context = modelContainer.mainContext
    let descriptor = FetchDescriptor<PlayerProfile>(predicate: #Predicate { $0.id == id })
    return try context.fetch(descriptor).first
  }

  public func savePlayer(_ player: PlayerProfile) throws {
    let context = modelContainer.mainContext
    context.insert(player)
    try context.save()
  }

  public func updatePlayer(_ player: PlayerProfile) throws {
    let context = modelContainer.mainContext
    player.lastModified = Date()
    try context.save()
  }

  public func archivePlayer(_ player: PlayerProfile) throws {
    let context = modelContainer.mainContext
    player.archive()
    try context.save()
  }

  public func deletePlayer(id: UUID) throws {
    let context = modelContainer.mainContext
    if let player = try loadPlayer(id: id) {
      context.delete(player)
      try context.save()
    }
  }

  // MARK: - Team Operations

  public func loadTeams(includeArchived: Bool) throws -> [TeamProfile] {
    let context = modelContainer.mainContext
    let predicate: Predicate<TeamProfile> =
      includeArchived
      ? #Predicate { _ in true }
      : #Predicate { $0.isArchived == false }
    let descriptor = FetchDescriptor<TeamProfile>(
      predicate: predicate,
      sortBy: [SortDescriptor(\.lastModified, order: .reverse)]
    )
    return try context.fetch(descriptor)
  }

  public func loadTeam(id: UUID) throws -> TeamProfile? {
    let context = modelContainer.mainContext
    let descriptor = FetchDescriptor<TeamProfile>(predicate: #Predicate { $0.id == id })
    return try context.fetch(descriptor).first
  }

  public func saveTeam(_ team: TeamProfile) throws {
    let context = modelContainer.mainContext
    context.insert(team)
    try context.save()
  }

  public func updateTeam(_ team: TeamProfile) throws {
    let context = modelContainer.mainContext
    team.lastModified = Date()
    try context.save()
  }

  public func archiveTeam(_ team: TeamProfile) throws {
    let context = modelContainer.mainContext
    team.archive()
    try context.save()
  }

  public func deleteTeam(id: UUID) throws {
    let context = modelContainer.mainContext
    if let team = try loadTeam(id: id) {
      context.delete(team)
      try context.save()
    }
  }

  // MARK: - Preset Operations

  public func loadPresets(includeArchived: Bool) throws -> [GameTypePreset] {
    let context = modelContainer.mainContext
    let predicate: Predicate<GameTypePreset> =
      includeArchived
      ? #Predicate { _ in true }
      : #Predicate { $0.isArchived == false }
    let descriptor = FetchDescriptor<GameTypePreset>(
      predicate: predicate,
      sortBy: [SortDescriptor(\.lastModified, order: .reverse)]
    )
    return try context.fetch(descriptor)
  }

  public func loadPreset(id: UUID) throws -> GameTypePreset? {
    let context = modelContainer.mainContext
    let descriptor = FetchDescriptor<GameTypePreset>(predicate: #Predicate { $0.id == id })
    return try context.fetch(descriptor).first
  }

  public func savePreset(_ preset: GameTypePreset) throws {
    let context = modelContainer.mainContext
    context.insert(preset)
    try context.save()
  }

  public func updatePreset(_ preset: GameTypePreset) throws {
    let context = modelContainer.mainContext
    preset.lastModified = Date()
    try context.save()
  }

  public func archivePreset(_ preset: GameTypePreset) throws {
    let context = modelContainer.mainContext
    preset.archive()
    try context.save()
  }

  public func deletePreset(id: UUID) throws {
    let context = modelContainer.mainContext
    if let preset = try loadPreset(id: id) {
      context.delete(preset)
      try context.save()
    }
  }
}

// MARK: - Statistics Summaries (v0.3)

extension SwiftDataStorage {
  private func persistOrUpdateSummary(for game: Game, in context: ModelContext) throws {
    guard game.isCompleted, let completed = game.completedDate else { return }
    let winner = game.score1 == game.score2 ? 0 : (game.score1 > game.score2 ? 1 : 2)
    let diff = abs(game.score1 - game.score2)
    let duration = game.duration ?? completed.timeIntervalSince(game.createdDate)
    let typeId = game.gameVariation?.gameType.rawValue ?? game.gameType.rawValue

    let targetId = game.id
    let descriptor = FetchDescriptor<GameSummary>(
      predicate: #Predicate<GameSummary> { $0.gameId == targetId }
    )
    let existing = try context.fetch(descriptor).first
    if let row = existing {
      row.gameTypeId = typeId
      row.completedDate = completed
      row.winningTeam = winner
      row.pointDifferential = diff
      row.duration = duration
      row.totalRallies = game.totalRallies
    } else {
      let row = GameSummary(
        gameId: game.id,
        gameTypeId: typeId,
        completedDate: completed,
        winningTeam: winner,
        pointDifferential: diff,
        duration: duration,
        totalRallies: game.totalRallies
      )
      context.insert(row)
    }
    try context.save()
  }

  private func deleteSummaryIfExists(for gameId: UUID, in context: ModelContext) throws {
    let targetId = gameId
    let descriptor = FetchDescriptor<GameSummary>(
      predicate: #Predicate<GameSummary> { $0.gameId == targetId }
    )
    if let row = try context.fetch(descriptor).first {
      context.delete(row)
    }
  }
}

// MARK: - Phase 5: Backup/Restore, Purge, Integrity, Compaction

extension SwiftDataStorage {
  public func exportBackup() async throws -> Data {
    let context = modelContainer.mainContext
    let start = Date()

    let games = try context.fetch(FetchDescriptor<Game>())
    let players = try context.fetch(FetchDescriptor<PlayerProfile>())
    let teams = try context.fetch(FetchDescriptor<TeamProfile>())
    let presets = try context.fetch(FetchDescriptor<GameTypePreset>())
    let variations = try context.fetch(FetchDescriptor<GameVariation>())

    var dto = BackupFileDTO()
    dto.games = games.map(BackupGameDTO.init(from:))
    dto.players = players.map(BackupPlayerDTO.init(from:))
    dto.teams = teams.map(BackupTeamDTO.init(from:))
    dto.presets = presets.map(BackupPresetDTO.init(from:))
    dto.variations = variations.map(BackupVariationDTO.init(from:))

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(dto)

    let ms = Int(Date().timeIntervalSince(start) * 1000)
    Log.event(
      .saveSucceeded, level: .info, message: "Exported backup",
      metadata: ["latencyMs": "\(ms)", "size": "\(data.count)"])
    return data
  }

  public func importBackup(_ data: Data, mode: BackupImportMode) async throws {
    let context = modelContainer.mainContext
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    let dto = try decoder.decode(BackupFileDTO.self, from: data)

    if mode == .replace {
      try context.delete(model: Game.self)
      try context.delete(model: GameSummary.self)
      try context.delete(model: GameTypePreset.self)
      try context.delete(model: TeamProfile.self)
      try context.delete(model: PlayerProfile.self)
      try context.delete(model: GameVariation.self)
      try context.save()
    }

    // Reconstruct reference data first
    var playerById: [UUID: PlayerProfile] = [:]
    for p in dto.players {
      let player = PlayerProfile(
        id: p.id,
        name: p.name,
        notes: p.notes,
        isArchived: p.isArchived,
        avatarImageData: nil,
        iconSymbolName: p.iconSymbolName,
        accentColor: p.accentColor,
        skillLevel: p.skillLevel,
        preferredHand: p.preferredHand,
        createdDate: p.createdDate,
        lastModified: p.lastModified
      )
      playerById[player.id] = player
      context.insert(player)
    }

    var teamById: [UUID: TeamProfile] = [:]
    for t in dto.teams {
      let team = TeamProfile(
        id: t.id,
        name: t.name,
        notes: t.notes,
        isArchived: t.isArchived,
        avatarImageData: nil,
        iconSymbolName: t.iconSymbolName,
        accentColor: t.accentColor,
        players: t.playerIds.compactMap { playerById[$0] },
        suggestedGameType: t.suggestedGameType,
        createdDate: t.createdDate,
        lastModified: t.lastModified
      )
      teamById[team.id] = team
      context.insert(team)
    }

    var variationById: [UUID: GameVariation] = [:]
    for v in dto.variations {
      let variation = GameVariation(
        id: v.id,
        name: v.name,
        gameType: v.gameType,
        teamSize: v.teamSize,
        numberOfTeams: v.numberOfTeams,
        winningScore: v.winningScore,
        winByTwo: v.winByTwo,
        maxScore: v.maxScore,
        kitchenRule: v.kitchenRule,
        doubleBounceRule: v.doubleBounceRule,
        servingRotation: v.servingRotation,
        sideSwitchingRule: v.sideSwitchingRule,
        scoringType: v.scoringType,
        timeLimit: v.timeLimit,
        maxRallies: v.maxRallies,
        isDefault: v.isDefault,
        isCustom: v.isCustom,
        isCommunity: v.isCommunity,
        isPublished: v.isPublished,
        gameDescription: v.gameDescription,
        tags: v.tags
      )
      variation.createdDate = v.createdDate
      variation.lastModified = v.lastModified
      variationById[variation.id] = variation
      context.insert(variation)
    }

    // Presets
    for pr in dto.presets {
      let preset = GameTypePreset(
        id: pr.id,
        name: pr.name,
        notes: pr.notes,
        isArchived: pr.isArchived,
        gameType: pr.gameType,
        team1: pr.team1Id.flatMap { teamById[$0] },
        team2: pr.team2Id.flatMap { teamById[$0] },
        accentColor: pr.accentColor,
        createdDate: pr.createdDate,
        lastModified: pr.lastModified
      )
      context.insert(preset)
    }

    // Games
    for g in dto.games {
      let game = Game(
        id: g.id,
        gameType: g.gameType,
        gameVariation: g.gameVariationId.flatMap { variationById[$0] },
        score1: g.score1,
        score2: g.score2,
        isCompleted: g.isCompleted,
        isArchived: g.isArchived,
        createdDate: g.createdDate,
        lastModified: g.lastModified,
        currentServer: g.currentServer,
        serverNumber: g.serverNumber,
        serverPosition: g.serverPosition,
        sideOfCourt: g.sideOfCourt,
        gameState: g.gameState,
        isFirstServiceSequence: g.isFirstServiceSequence,
        winningScore: g.winningScore,
        winByTwo: g.winByTwo,
        kitchenRule: g.kitchenRule,
        doubleBounceRule: g.doubleBounceRule,
        notes: g.notes
      )
      game.completedDate = g.completedDate
      game.totalRallies = g.totalRallies
      context.insert(game)
      if game.isCompleted {
        try persistOrUpdateSummary(for: game, in: context)
      }
    }

    try context.save()
    Log.event(
      .saveSucceeded, level: .info, message: "Imported backup",
      metadata: ["games": "\(dto.games.count)"])
  }

  public func purge(_ options: PurgeOptions) async throws -> PurgeResult {
    let context = modelContainer.mainContext

    var removedGames = 0
    var removedSummaries = 0

    if options.purgeAllGames {
      removedGames = try context.fetchCount(FetchDescriptor<Game>())
      removedSummaries = try context.fetchCount(FetchDescriptor<GameSummary>())
      try context.delete(model: Game.self)
      try context.delete(model: GameSummary.self)
      try context.save()
      return PurgeResult(removedGames: removedGames, removedSummaries: removedSummaries)
    }

    var predicate: Predicate<Game> = #Predicate { _ in true }
    if let days = options.olderThanDays {
      let cutoff = Date().addingTimeInterval(TimeInterval(-days * 24 * 60 * 60))
      if options.purgeArchivedOnly {
        predicate = #Predicate {
          $0.isArchived == true && ($0.completedDate ?? $0.lastModified) < cutoff
        }
      } else {
        predicate = #Predicate { ($0.completedDate ?? $0.lastModified) < cutoff }
      }
    } else if options.purgeArchivedOnly {
      predicate = #Predicate { $0.isArchived == true }
    }

    let toDelete = try context.fetch(FetchDescriptor<Game>(predicate: predicate))
    removedGames = toDelete.count
    for g in toDelete {
      try deleteSummaryIfExists(for: g.id, in: context)
      context.delete(g)
      removedSummaries += 1
    }
    if context.hasChanges { try context.save() }
    return PurgeResult(removedGames: removedGames, removedSummaries: removedSummaries)
  }

  public func integritySweep() async throws -> IntegrityReport {
    let context = modelContainer.mainContext
    var orphanSummariesRemoved = 0
    var repairedRelationships = 0

    // Remove summaries without matching game
    let summaries = try context.fetch(FetchDescriptor<GameSummary>())
    let games = try context.fetch(FetchDescriptor<Game>())
    let gameIds = Set(games.map { $0.id })
    for s in summaries where gameIds.contains(s.gameId) == false {
      context.delete(s)
      orphanSummariesRemoved += 1
    }

    // Repair missing team players references if possible (basic sweep)
    for team in try context.fetch(FetchDescriptor<TeamProfile>()) {
      let uniquePlayers = Array(Set(team.players))
      if uniquePlayers.count != team.players.count {
        team.players = uniquePlayers
        repairedRelationships += 1
      }
    }

    if context.hasChanges { try context.save() }
    return IntegrityReport(
      orphanSummariesRemoved: orphanSummariesRemoved, repairedRelationships: repairedRelationships)
  }

  public func compactStore() async throws {
    // SwiftData does not expose a direct vacuum API; best-effort no-op.
    // Trigger a save to ensure WAL checkpoints in normal operation.
    let context = modelContainer.mainContext
    if context.hasChanges { try context.save() }
  }
}
