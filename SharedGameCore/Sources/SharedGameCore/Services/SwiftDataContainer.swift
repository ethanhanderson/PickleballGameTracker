//
//  SwiftDataContainer.swift
//  SharedGameCore
//
//  Created by Ethan Anderson on 7/9/25.
//

import Foundation
import SwiftData

/// Centralized SwiftData container configuration for the pickleball app
@MainActor
public final class SwiftDataContainer: Sendable {

  public static let shared = SwiftDataContainer()

  private var _modelContainer: ModelContainer?
  private let containerName = "PickleballScoreTracking"

  private init() {}

  /// Get or create the model container
  public var modelContainer: ModelContainer {
    if let container = _modelContainer {
      return container
    }

    let container = createModelContainer()
    _modelContainer = container
    return container
  }

  /// Create a new model container with proper configuration
  private func createModelContainer() -> ModelContainer {
    let schema = Schema([
      Game.self,
      GameSummary.self,
      PlayerProfile.self,
      TeamProfile.self,
      GameTypePreset.self,
    ])

    do {
      // Create the storage URL and ensure directory exists
      let storeURL = try createStoreURL()

      let modelConfiguration = ModelConfiguration(
        "PickleballGames",
        schema: schema,
        url: storeURL,
        cloudKitDatabase: .none  // Local storage only for v0.3
      )

      let container = try ModelContainer(
        for: schema,
        configurations: [modelConfiguration]
      )

      // Configure container for optimal performance
      configureContainer(container)

      Log.event(
        .loadSucceeded, level: .debug, message: "SwiftData store created",
        metadata: ["path": storeURL.path])
      return container
    } catch {
      // If container creation fails, try with a simpler configuration
      Log.error(error, event: .loadFailed, metadata: ["phase": "createModelContainerFallback"])
      return createFallbackContainer()
    }
  }

  /// Create and ensure the store URL directory exists
  private func createStoreURL() throws -> URL {
    // Get the Application Support directory
    let appSupportURL = FileManager.default.urls(
      for: .applicationSupportDirectory,
      in: .userDomainMask
    ).first!

    // Create our app-specific directory
    let storeDirectory = appSupportURL.appendingPathComponent(containerName)

    // Ensure the directory exists
    try FileManager.default.createDirectory(
      at: storeDirectory,
      withIntermediateDirectories: true,
      attributes: nil
    )

    // Return the full store URL
    let storeURL = storeDirectory.appendingPathComponent("PickleballGames.sqlite")

    Log.event(
      .loadSucceeded, level: .debug, message: "SwiftData store directory",
      metadata: ["path": storeDirectory.path])
    return storeURL
  }

  /// Create a fallback container with minimal configuration
  private func createFallbackContainer() -> ModelContainer {
    do {
      // Try with in-memory storage as fallback
      let schema = Schema([Game.self, PlayerProfile.self, TeamProfile.self, GameTypePreset.self])
      let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
      return try ModelContainer(for: schema, configurations: [configuration])
    } catch {
      fatalError("Failed to create SwiftData container: \(error)")
    }
  }

  /// Configure container settings for optimal performance
  private func configureContainer(_ container: ModelContainer) {
    // Enable write-ahead logging for better performance
    let context = container.mainContext

    // Configure context for UI operations
    context.autosaveEnabled = true

    Log.event(.loadSucceeded, level: .debug, message: "SwiftData container configured successfully")
  }

  /// Reset the container (useful for testing or data corruption recovery)
  public func resetContainer() async throws {
    guard let container = _modelContainer else { return }

    // Delete all data
    try container.mainContext.delete(model: Game.self)
    try container.mainContext.save()

    Log.event(.saveSucceeded, level: .info, message: "SwiftData container reset successfully")
  }

  /// Get container statistics for monitoring
  public func getContainerStatistics() async -> ContainerStatistics {
    let context = modelContainer.mainContext

    do {
      let gameCount = try context.fetchCount(FetchDescriptor<Game>())

      return ContainerStatistics(
        gameCount: gameCount,
        lastUpdated: Date()
      )
    } catch {
      Log.error(error, event: .loadFailed, metadata: ["phase": "getContainerStatistics"])
      return ContainerStatistics(lastUpdated: Date())
    }
  }

  /// Check if the container is healthy and responsive
  public func performHealthCheck() async -> Bool {
    do {
      // Try a simple query to test responsiveness
      let context = modelContainer.mainContext
      _ = try context.fetchCount(FetchDescriptor<Game>())
      return true
    } catch {
      Log.error(error, event: .loadFailed, metadata: ["phase": "performHealthCheck"])
      return false
    }
  }

  /// Perform maintenance operations
  public func performMaintenance() async throws {
    let context = modelContainer.mainContext

    // Save any pending changes
    if context.hasChanges {
      try context.save()
    }

    Log.event(.saveSucceeded, level: .info, message: "Container maintenance completed")
  }

  /// Validate the integrity of the SwiftData store and attempt recovery if needed
  public func validateAndRecoverStore() async throws -> Bool {
    do {
      // Perform a simple health check first
      let isHealthy = await performHealthCheck()

      if !isHealthy {
        Log.event(
          .loadFailed, level: .warn, message: "Store health check failed, attempting recovery...")

        // Try to save any pending changes
        let context = modelContainer.mainContext
        if context.hasChanges {
          try context.save()
        }

        // Re-run health check
        let isRecovered = await performHealthCheck()
        if isRecovered {
          Log.event(.saveSucceeded, level: .info, message: "Store recovery successful")
          return true
        } else {
          Log.event(.saveFailed, level: .warn, message: "Store recovery failed")
          return false
        }
      }

      Log.event(.loadSucceeded, level: .info, message: "Store validation passed")
      return true
    } catch {
      Log.error(error, event: .loadFailed, metadata: ["phase": "validateAndRecoverStore"])
      throw error
    }
  }

  /// Get detailed diagnostic information about the container
  public func getDiagnosticInfo() async -> [String: Any] {
    var diagnostics: [String: Any] = [:]

    // Basic container info
    diagnostics["containerName"] = containerName
    diagnostics["hasContainer"] = _modelContainer != nil

    // Store location info
    do {
      let storeURL = try createStoreURL()
      diagnostics["storeURL"] = storeURL.path
      diagnostics["storeExists"] = FileManager.default.fileExists(atPath: storeURL.path)

      // Directory info
      let storeDirectory = storeURL.deletingLastPathComponent()
      diagnostics["directoryExists"] = FileManager.default.fileExists(atPath: storeDirectory.path)

      // File size if exists
      if FileManager.default.fileExists(atPath: storeURL.path) {
        let attributes = try FileManager.default.attributesOfItem(atPath: storeURL.path)
        diagnostics["storeSize"] = attributes[.size] as? Int64 ?? 0
      }
    } catch {
      diagnostics["storeURLError"] = error.localizedDescription
    }

    // Health status
    let isHealthy = await performHealthCheck()
    diagnostics["isHealthy"] = isHealthy

    // Statistics
    let stats = await getContainerStatistics()
    diagnostics["gameCount"] = stats.gameCount
    diagnostics["lastUpdated"] = stats.lastUpdated

    return diagnostics
  }

  /// Create an in-memory model container for previews and testing
  /// This container will not persist data and is isolated from the main app data
  public static func createPreviewContainer() -> ModelContainer {
    let schema = Schema([Game.self, PlayerProfile.self, TeamProfile.self, GameTypePreset.self])

    let modelConfiguration = ModelConfiguration(
      schema: schema,
      isStoredInMemoryOnly: true,  // Key: in-memory only for previews
      allowsSave: true,
      cloudKitDatabase: .none
    )

    do {
      let container = try ModelContainer(
        for: schema,
        configurations: [modelConfiguration]
      )

      Log.event(.loadSucceeded, level: .debug, message: "Created in-memory preview container")
      return container
    } catch {
      fatalError("Failed to create preview container: \(error)")
    }
  }
}

// MARK: - Container Statistics

public struct ContainerStatistics: Sendable {
  public let gameCount: Int
  public let lastUpdated: Date

  public init(
    gameCount: Int = 0,
    lastUpdated: Date
  ) {
    self.gameCount = gameCount
    self.lastUpdated = lastUpdated
  }

  public var totalItems: Int {
    return gameCount
  }
}
