//
//  SwiftDataStorage.swift
//  SharedGameCore
//
//  Created by Ethan Anderson on 7/9/25.
//

import Foundation
@preconcurrency import SwiftData

/// Concrete implementation of SwiftDataStorageProtocol using SwiftData
@MainActor
public final class SwiftDataStorage: SwiftDataStorageProtocol {

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
    // Persist summary if completed
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
    let result = try context.fetch(descriptor)
    let ms = Int(Date().timeIntervalSince(start) * 1000)
    Log.event(
      .loadSucceeded, level: .debug, metadata: ["count": "\(result.count)", "latencyMs": "\(ms)"])
    return result
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
      throw StorageError.gameNotFound(id)
    }

    let context = modelContainer.mainContext
    Log.event(.deleteRequested, level: .info, context: .current(gameId: id))
    try deleteSummaryIfExists(for: id, in: context)
    context.delete(game)
    try context.save()
    Log.event(.deleteSucceeded, level: .info, context: .current(gameId: id))
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
    let context = modelContainer.mainContext
    let descriptor = FetchDescriptor<Game>(
      predicate: #Predicate<Game> { game in
        game.isArchived == false && game.notes?.localizedStandardContains(query) == true
      },
      sortBy: [SortDescriptor(\.lastModified, order: .reverse)]
    )
    return try context.fetch(descriptor)
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
