//
//  SwiftDataStorageProtocol.swift
//  SharedGameCore
//
//  Created by Ethan Anderson on 7/9/25.
//

import Foundation
import SwiftData

/// Protocol defining the interface for SwiftData storage operations
@MainActor
public protocol SwiftDataStorageProtocol {
  var modelContainer: ModelContainer { get }

  // MARK: - Game Operations

  func saveGame(_ game: Game) async throws
  func loadGames() async throws -> [Game]
  func loadActiveGames() async throws -> [Game]
  func loadCompletedGames() async throws -> [Game]
  func loadGame(id: UUID) async throws -> Game?
  func updateGame(_ game: Game) async throws
  func deleteGame(id: UUID) async throws
  func deleteAllGames() async throws

  // MARK: - Search Operations

  func searchGames(query: String) async throws -> [Game]
  func searchGames(query: String, filters: GameSearchFilters) async throws -> [Game]
  func searchGamesAdvanced(criteria: GameSearchCriteria) async throws -> [Game]

  // MARK: - Statistics Operations

  func loadGameStatistics() async throws -> GameStatistics

  // MARK: - Utility Operations

  func performMaintenance() async throws
  func getStorageStatistics() async throws -> StorageStatistics
  func validateGamePersistence(_ game: Game) async throws -> Bool
  func getPerformanceMetrics() async -> PerformanceMetrics
  func recoverFromError(_ error: StorageError) async throws -> RecoveryResult
  func validateDataIntegrity() async throws -> DataValidationResult
  func validateGameData(_ game: Game) throws -> GameValidationResult

  // MARK: - Backup & Maintenance (Phase 5)

  func exportBackup() async throws -> Data
  func importBackup(_ data: Data, mode: BackupImportMode) async throws
  func purge(_ options: PurgeOptions) async throws -> PurgeResult
  func integritySweep() async throws -> IntegrityReport
  func compactStore() async throws

  // MARK: - Player Operations

  func loadPlayers(includeArchived: Bool) throws -> [PlayerProfile]
  func loadPlayer(id: UUID) throws -> PlayerProfile?
  func savePlayer(_ player: PlayerProfile) throws
  func updatePlayer(_ player: PlayerProfile) throws
  func archivePlayer(_ player: PlayerProfile) throws
  func deletePlayer(id: UUID) throws

  // MARK: - Team Operations

  func loadTeams(includeArchived: Bool) throws -> [TeamProfile]
  func loadTeam(id: UUID) throws -> TeamProfile?
  func saveTeam(_ team: TeamProfile) throws
  func updateTeam(_ team: TeamProfile) throws
  func archiveTeam(_ team: TeamProfile) throws
  func deleteTeam(id: UUID) throws

  // MARK: - Preset Operations

  func loadPresets(includeArchived: Bool) throws -> [GameTypePreset]
  func loadPreset(id: UUID) throws -> GameTypePreset?
  func savePreset(_ preset: GameTypePreset) throws
  func updatePreset(_ preset: GameTypePreset) throws
  func archivePreset(_ preset: GameTypePreset) throws
  func deletePreset(id: UUID) throws
}

// MARK: - Enhanced Search Types

public struct GameSearchFilters: Sendable {
  public let gameTypes: Set<GameType>?
  public let dateRange: ClosedRange<Date>?
  public let completedOnly: Bool
  public let includeArchived: Bool
  public let playerIds: Set<UUID>?
  public let teamIds: Set<UUID>?

  public init(
    gameTypes: Set<GameType>? = nil,
    dateRange: ClosedRange<Date>? = nil,
    completedOnly: Bool = false,
    includeArchived: Bool = false,
    playerIds: Set<UUID>? = nil,
    teamIds: Set<UUID>? = nil
  ) {
    self.gameTypes = gameTypes
    self.dateRange = dateRange
    self.completedOnly = completedOnly
    self.includeArchived = includeArchived
    self.playerIds = playerIds
    self.teamIds = teamIds
  }
}

public struct GameSearchCriteria: Sendable {
  public let query: String
  public let filters: GameSearchFilters
  public let sortBy: GameSortOption
  public let limit: Int?

  public init(
    query: String,
    filters: GameSearchFilters = GameSearchFilters(),
    sortBy: GameSortOption = .dateCreated,
    limit: Int? = nil
  ) {
    self.query = query
    self.filters = filters
    self.sortBy = sortBy
    self.limit = limit
  }
}

public enum GameSortOption: Sendable {
  case dateCreated
  case dateCompleted
  case score
  case duration
  case gameType
  case playerName

  var sortDescriptors: [SortDescriptor<Game>] {
    switch self {
    case .dateCreated:
      return [SortDescriptor<Game>(\.lastModified, order: .reverse)]
    case .dateCompleted:
      return [SortDescriptor<Game>(\.completedDate, order: .reverse)]
    case .score:
      return [
        SortDescriptor<Game>(\.score1, order: .reverse),
        SortDescriptor<Game>(\.score2, order: .reverse)
      ]
    case .duration:
      return [SortDescriptor<Game>(\.duration, order: .reverse)]
    case .gameType:
      // Sort by game type raw value since enum sorting may not be supported
      return []
    case .playerName:
      return [SortDescriptor<Game>(\.lastModified, order: .reverse)] // Placeholder - would need more complex sorting
    }
  }
}

// MARK: - Supporting Types

public struct GameStatistics: Sendable {
  public let totalGames: Int
  public let completedGames: Int
  public let totalPlayTime: TimeInterval
  public let averageGameDuration: TimeInterval
  public let totalPointsScored: Int

  public init(
    totalGames: Int = 0,
    completedGames: Int = 0,
    totalPlayTime: TimeInterval = 0,
    averageGameDuration: TimeInterval = 0,
    totalPointsScored: Int = 0
  ) {
    self.totalGames = totalGames
    self.completedGames = completedGames
    self.totalPlayTime = totalPlayTime
    self.averageGameDuration = averageGameDuration
    self.totalPointsScored = totalPointsScored
  }
}

public struct StorageStatistics: Sendable {
  public let gameCount: Int
  public let lastUpdated: Date

  public init(
    gameCount: Int = 0,
    lastUpdated: Date = Date()
  ) {
    self.gameCount = gameCount
    self.lastUpdated = lastUpdated
  }
}

public struct PerformanceMetrics: Sendable {
  public let averageOperationTime: TimeInterval
  public let slowestOperation: String
  public let operationCounts: [String: Int]
  public let errorRate: Double
  public let lastUpdated: Date

  public init(
    averageOperationTime: TimeInterval = 0,
    slowestOperation: String = "",
    operationCounts: [String: Int] = [:],
    errorRate: Double = 0,
    lastUpdated: Date = Date()
  ) {
    self.averageOperationTime = averageOperationTime
    self.slowestOperation = slowestOperation
    self.operationCounts = operationCounts
    self.errorRate = errorRate
    self.lastUpdated = lastUpdated
  }
}

// MARK: - Storage Errors

public enum StorageError: Error, LocalizedError, Sendable {
  case gameNotFound(UUID)
  case contextNotAvailable
  case saveFailed(any Error)
  case loadFailed(any Error)
  case deleteFailed(any Error)
  case objectNotTracked(UUID)
  case updateFailed(any Error)
  case validationFailed(String)
  case constraintViolation(String)
  case migrationNeeded
  case corruptedData(String)
  case quotaExceeded
  case networkUnavailable
  case timeout
  case concurrencyConflict

  public var errorDescription: String? {
    switch self {
    case .gameNotFound(let id):
      return "Game with ID \(id) not found"
    case .contextNotAvailable:
      return "SwiftData context is not available"
    case .saveFailed(let error):
      return "Failed to save: \(error.localizedDescription)"
    case .loadFailed(let error):
      return "Failed to load: \(error.localizedDescription)"
    case .deleteFailed(let error):
      return "Failed to delete: \(error.localizedDescription)"
    case .objectNotTracked(let id):
      return "Game object with ID \(id) is not tracked by SwiftData context"
    case .updateFailed(let error):
      return "Failed to update: \(error.localizedDescription)"
    case .validationFailed(let message):
      return "Validation failed: \(message)"
    case .constraintViolation(let message):
      return "Constraint violation: \(message)"
    case .migrationNeeded:
      return "Database migration is required"
    case .corruptedData(let message):
      return "Data corruption detected: \(message)"
    case .quotaExceeded:
      return "Storage quota exceeded"
    case .networkUnavailable:
      return "Network connection unavailable"
    case .timeout:
      return "Operation timed out"
    case .concurrencyConflict:
      return "Concurrent modification conflict"
    }
  }

  public var recoverySuggestion: String? {
    switch self {
    case .migrationNeeded:
      return "Reset the app data and restore from backup"
    case .corruptedData:
      return "Restore from a recent backup"
    case .quotaExceeded:
      return "Free up space or purge old data"
    case .concurrencyConflict:
      return "Retry the operation"
    case .timeout:
      return "Check your connection and try again"
    case .networkUnavailable:
      return "Check your internet connection"
    default:
      return "Try again or contact support if the issue persists"
    }
  }
}

public struct RecoveryResult: Sendable {
  public let success: Bool
  public let message: String
  public let recoveredItems: Int

  public init(success: Bool, message: String, recoveredItems: Int = 0) {
    self.success = success
    self.message = message
    self.recoveredItems = recoveredItems
  }
}

public struct DataValidationResult: Sendable {
  public let isValid: Bool
  public let errors: [String]
  public let warnings: [String]
  public let validationTime: Date

  public init(
    isValid: Bool = true,
    errors: [String] = [],
    warnings: [String] = [],
    validationTime: Date = Date()
  ) {
    self.isValid = isValid
    self.errors = errors
    self.warnings = warnings
    self.validationTime = validationTime
  }
}

public struct GameValidationResult: Sendable {
  public let isValid: Bool
  public let errors: [String]
  public let warnings: [String]

  public init(isValid: Bool = true, errors: [String] = [], warnings: [String] = []) {
    self.isValid = isValid
    self.errors = errors
    self.warnings = warnings
  }
}

// MARK: - Backup & Maintenance Types

public struct PurgeOptions: Sendable {
  public var purgeAllGames: Bool
  public var purgeArchivedOnly: Bool
  public var olderThanDays: Int?

  public init(
    purgeAllGames: Bool = false, purgeArchivedOnly: Bool = false, olderThanDays: Int? = nil
  ) {
    self.purgeAllGames = purgeAllGames
    self.purgeArchivedOnly = purgeArchivedOnly
    self.olderThanDays = olderThanDays
  }
}

public struct PurgeResult: Sendable {
  public let removedGames: Int
  public let removedSummaries: Int

  public init(removedGames: Int = 0, removedSummaries: Int = 0) {
    self.removedGames = removedGames
    self.removedSummaries = removedSummaries
  }
}

public struct IntegrityReport: Sendable {
  public let orphanSummariesRemoved: Int
  public let repairedRelationships: Int

  public init(orphanSummariesRemoved: Int = 0, repairedRelationships: Int = 0) {
    self.orphanSummariesRemoved = orphanSummariesRemoved
    self.repairedRelationships = repairedRelationships
  }
}
