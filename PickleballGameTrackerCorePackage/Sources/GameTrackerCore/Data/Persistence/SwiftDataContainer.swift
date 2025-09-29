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
  private var didUseFallbackInMemory: Bool = false
  private var containerName: String {
    #if os(watchOS)
      return "PickleballScoreTracking.watchOS"
    #else
      return "PickleballScoreTracking.iOS"
    #endif
  }

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
    do {
      // Create the storage URL and ensure directory exists
      let storeURL = try createStoreURL()

      let schema = Schema([
        Game.self, GameVariation.self, GameSummary.self, PlayerProfile.self, TeamProfile.self,
        GameTypePreset.self, GameEvent.self,
      ])
      let configuration = ModelConfiguration(
        url: storeURL,
        cloudKitDatabase: .none
      )

      let container = try ModelContainer(
        for: schema,
        configurations: [configuration]
      )

      // Configure container for optimal performance
      configureContainer(container)

      // First-run seeding: if no variations exist, insert defaults
      do {
        let context = container.mainContext
        let variationCount = try context.fetchCount(FetchDescriptor<GameVariation>())
        if variationCount == 0 {
          SwiftDataSeeding.seedDefaultVariations(into: context)
          try context.save()
          Log.event(
            .saveSucceeded,
            level: .info,
            message: "Seeded default game variations on first run"
          )
        }
      } catch {
        Log.error(error, event: .saveFailed, metadata: ["phase": "firstRunSeed"])
      }

      // Apply iOS file protection after files are created
      #if os(iOS)
        applyFileProtection(at: storeURL)
      #endif

      Log.event(
        .loadSucceeded, level: .debug, message: "SwiftData store created",
        metadata: [
          "path": storeURL.path
        ])
      didUseFallbackInMemory = false
      return container
    } catch {
      // If container creation fails, try with a simpler configuration
      Log.error(error, event: .loadFailed, metadata: ["phase": "createModelContainerFallback"])
      didUseFallbackInMemory = true
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

    // Smoke assert that the directory path resolves under Application Support
    assert(
      storeURL.path.contains("Application Support"),
      "SwiftData store URL must be under Application Support directory")

    Log.event(
      .loadSucceeded, level: .debug, message: "SwiftData store directory",
      metadata: ["path": storeDirectory.path])
    return storeURL
  }

  /// Create a fallback container with minimal configuration
  private func createFallbackContainer() -> ModelContainer {
    do {
      // Try with in-memory storage as fallback
      let schema = Schema([
        Game.self, GameVariation.self, GameSummary.self, PlayerProfile.self, TeamProfile.self,
        GameTypePreset.self, GameEvent.self,
      ])
      let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
      return try ModelContainer(
        for: schema,
        configurations: [configuration]
      )
    } catch {
      fatalError("Failed to create SwiftData container: \(error)")
    }
  }

  /// Configure container settings for optimal performance
  private func configureContainer(_ container: ModelContainer) {
    let context = container.mainContext
    context.autosaveEnabled = true

    Log.event(
      .loadSucceeded, level: .debug, message: "SwiftData container configured successfully")
  }

  /// Reset the container (useful for testing or data corruption recovery)
  public func resetContainer() async throws {
    guard let container = _modelContainer else { return }

    // Delete all data
    try container.mainContext.delete(model: Game.self)
    try container.mainContext.save()

    Log.event(.saveSucceeded, level: .info, message: "SwiftData container reset successfully")
  }

  /// Whether the app is currently using an in-memory fallback container due to an initialization failure
  public var isUsingFallbackInMemory: Bool { didUseFallbackInMemory }

  /// Delete the on-disk SwiftData store files (sqlite, -wal, -shm) and clear the live container reference.
  /// Call this after user confirmation, then instruct user to relaunch the app so a fresh container is injected at startup.
  public func resetStoreFiles() throws {
    let fm = FileManager.default
    let storeURL = try createStoreURL()
    let candidates: [URL] = [
      storeURL,
      storeURL.appendingPathExtension("-wal"),
      storeURL.appendingPathExtension("-shm"),
    ]

    var removed: [String] = []
    var failed: [String] = []

    for url in candidates {
      if fm.fileExists(atPath: url.path) {
        do {
          try fm.removeItem(at: url)
          removed.append(url.lastPathComponent)
        } catch {
          failed.append("\(url.lastPathComponent): \(error.localizedDescription)")
        }
      }
    }

    // Clear the active container; a new one will be created on next access (after relaunch)
    _modelContainer = nil
    didUseFallbackInMemory = false

    Log.event(
      .saveSucceeded,
      level: .info,
      message: "SwiftData store files reset",
      metadata: [
        "removed": removed.joined(separator: ","),
        "failed": failed.joined(separator: ","),
        "path": storeURL.deletingLastPathComponent().path,
      ]
    )

    if failed.isEmpty == false {
      throw PersistenceError.storeResetFailed(
        "Failed to remove some store files: \(failed.joined(separator: "; "))"
      )
    }
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
          .loadFailed,
          level: .warn,
          message: "Store health check failed, attempting recovery...",
          metadata: [
            "usingFallback": String(isUsingFallbackInMemory)
          ])

        // Try to save any pending changes
        let context = modelContainer.mainContext
        if context.hasChanges {
          try context.save()
        }

        // Re-run health check
        let isRecovered = await performHealthCheck()
        if isRecovered {
          Log.event(
            .saveSucceeded,
            level: .info,
            message: "Store recovery successful",
            metadata: ["usingFallback": String(isUsingFallbackInMemory)]
          )
          return true
        } else {
          Log.event(
            .saveFailed,
            level: .warn,
            message: "Store recovery failed",
            metadata: ["usingFallback": String(isUsingFallbackInMemory)]
          )
          return false
        }
      }

      Log.event(
        .loadSucceeded,
        level: .info,
        message: "Store validation passed",
        metadata: [
          "usingFallback": String(isUsingFallbackInMemory)
        ])
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
  public static func createPreviewContainer(seed: ((ModelContext) throws -> Void)? = nil)
    -> ModelContainer
  {
    let schema = Schema([
      Game.self, GameVariation.self, GameSummary.self, PlayerProfile.self, TeamProfile.self,
      GameTypePreset.self, GameEvent.self,
    ])
    let configuration = ModelConfiguration(
      isStoredInMemoryOnly: true,
      allowsSave: true,
      cloudKitDatabase: .none
    )

    do {
      let container = try ModelContainer(
        for: schema,
        configurations: [configuration]
      )

      // Preview determinism: disable autosave; we'll save explicitly after seeding
      container.mainContext.autosaveEnabled = false

      if let seed {
        try seed(container.mainContext)
        try container.mainContext.save()
      }

      Log.event(.loadSucceeded, level: .debug, message: "Created in-memory preview container")
      return container
    } catch {
      fatalError("Failed to create preview container: \(error)")
    }
  }

  /// Get the store file URL for debugging/inspection purposes
  public func getStoreFileURL() throws -> URL {
    try createStoreURL()
  }

  /// Check if store files exist on disk
  public func storeFilesExist() -> Bool {
    do {
      let storeURL = try createStoreURL()
      return FileManager.default.fileExists(atPath: storeURL.path)
    } catch {
      Log.error(error, event: .loadFailed, metadata: ["phase": "storeFilesExist"])
      return false
    }
  }

  /// Get store file size in bytes (0 if file doesn't exist)
  public func getStoreFileSize() -> Int64 {
    do {
      let storeURL = try createStoreURL()
      let attributes = try FileManager.default.attributesOfItem(atPath: storeURL.path)
      return attributes[.size] as? Int64 ?? 0
    } catch {
      Log.error(error, event: .loadFailed, metadata: ["phase": "getStoreFileSize"])
      return 0
    }
  }
}

#if os(iOS)
  import UIKit
  extension SwiftDataContainer {
    fileprivate func applyFileProtection(at sqliteURL: URL) {
      let fm = FileManager.default
      let protection: [FileAttributeKey: Any] = [
        .protectionKey: FileProtectionType.completeUntilFirstUserAuthentication
      ]

      // Protect directory
      let dir = sqliteURL.deletingLastPathComponent()
      try? fm.setAttributes(protection, ofItemAtPath: dir.path)

      // Protect main sqlite and sidecar files if present
      let candidates = [
        sqliteURL,
        sqliteURL.appendingPathExtension("-wal"),
        sqliteURL.appendingPathExtension("-shm"),
      ]
      for url in candidates {
        if fm.fileExists(atPath: url.path) {
          try? fm.setAttributes(protection, ofItemAtPath: url.path)
        }
      }
    }
  }
#endif

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

// MARK: - Persistence Error Types

public enum PersistenceError: LocalizedError, Sendable {
  case storeResetFailed(String)

  public nonisolated var errorDescription: String? {
    switch self {
    case .storeResetFailed(let message):
      return "Data Reset Failed: \(message)"
    }
  }
}
