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

  // MARK: - Statistics Operations

  func loadGameStatistics() async throws -> GameStatistics

  // MARK: - Utility Operations

  func performMaintenance() async throws
  func getStorageStatistics() async throws -> StorageStatistics
  func validateGamePersistence(_ game: Game) async throws -> Bool

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

// MARK: - Storage Errors

public enum StorageError: Error, LocalizedError {
  case gameNotFound(UUID)
  case contextNotAvailable
  case saveFailed(any Error)
  case loadFailed(any Error)
  case deleteFailed(any Error)
  case objectNotTracked(UUID)
  case updateFailed(any Error)

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
    }
  }
}
