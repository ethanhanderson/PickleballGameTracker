//
//  SyncTypes.swift
//  SharedGameCore
//
//  Created by Ethan Anderson on 7/9/25.
//

import Foundation

#if os(iOS)
  import UIKit
#elseif os(watchOS)
  import WatchKit
#endif

// MARK: - Sync Message Types

/// Types of messages that can be sent between devices
public enum SyncMessageType: String, Codable, Sendable, CaseIterable {
  case activeGameState = "activeGameState"
  case historyRequest = "historyRequest"
  case historyBatch = "historyBatch"
  case ack = "ack"
}

/// Simplified game data for history synchronization
public struct HistoryGameDTO: Codable, Sendable, Identifiable {
  public let id: UUID
  public let gameType: GameType
  public let score1: Int
  public let score2: Int
  public let isCompleted: Bool
  public let createdDate: Date
  public let completedDate: Date?
  public let lastModified: Date
  public let duration: TimeInterval?
  public let winningScore: Int
  public let notes: String?

  public init(from game: Game) {
    self.id = game.id
    self.gameType = game.gameType
    self.score1 = game.score1
    self.score2 = game.score2
    self.isCompleted = game.isCompleted
    self.createdDate = game.createdDate
    self.completedDate = game.completedDate
    self.lastModified = game.lastModified
    self.duration = game.duration
    self.winningScore = game.winningScore
    self.notes = game.notes
  }
}

/// Container for all sync messages between devices
public enum SyncMessage: Codable, Sendable {
  case activeGameState(ActiveGameStateDTO)
  case historyRequest
  case historyBatch([HistoryGameDTO])
  case ack

  public var type: SyncMessageType {
    switch self {
    case .activeGameState: return .activeGameState
    case .historyRequest: return .historyRequest
    case .historyBatch: return .historyBatch
    case .ack: return .ack
    }
  }
}

// MARK: - Active Game State DTO

/// Data Transfer Object for active game state synchronization
public struct ActiveGameStateDTO: Codable, Sendable, Identifiable {
  public let id: UUID

  // Core Game Identity
  public let gameId: UUID
  public let gameType: GameType
  public let createdDate: Date

  // Game Scores and State
  public let score1: Int
  public let score2: Int
  public let isCompleted: Bool
  public let gameState: GameState

  // Serving Information
  public let currentServer: Int
  public let serverNumber: Int
  public let serverPosition: ServerPosition
  public let sideOfCourt: SideOfCourt
  public let isFirstServiceSequence: Bool

  // Timer State
  public let elapsedSeconds: TimeInterval
  public let isTimerRunning: Bool
  public let lastTimerStartTime: Date?

  // Synchronization Metadata
  public let lastEventTimestamp: Date
  public let deviceIdentifier: String

  // Optional Game Variation
  public let gameVariationId: UUID?

  // Core Rules Snapshot (ensures identical behavior across devices even without variation model)
  public let winningScore: Int
  public let winByTwo: Bool
  public let kitchenRule: Bool
  public let doubleBounceRule: Bool

  public init(
    id: UUID = UUID(),
    gameId: UUID,
    gameType: GameType,
    createdDate: Date,
    score1: Int,
    score2: Int,
    isCompleted: Bool,
    gameState: GameState,
    currentServer: Int,
    serverNumber: Int,
    serverPosition: ServerPosition,
    sideOfCourt: SideOfCourt,
    isFirstServiceSequence: Bool,
    elapsedSeconds: TimeInterval,
    isTimerRunning: Bool,
    lastTimerStartTime: Date?,
    lastEventTimestamp: Date = Date(),
    deviceIdentifier: String? = nil,
    gameVariationId: UUID? = nil,
    winningScore: Int,
    winByTwo: Bool,
    kitchenRule: Bool,
    doubleBounceRule: Bool
  ) {
    self.id = id
    self.gameId = gameId
    self.gameType = gameType
    self.createdDate = createdDate
    self.score1 = score1
    self.score2 = score2
    self.isCompleted = isCompleted
    self.gameState = gameState
    self.currentServer = currentServer
    self.serverNumber = serverNumber
    self.serverPosition = serverPosition
    self.sideOfCourt = sideOfCourt
    self.isFirstServiceSequence = isFirstServiceSequence
    self.elapsedSeconds = elapsedSeconds
    self.isTimerRunning = isTimerRunning
    self.lastTimerStartTime = lastTimerStartTime
    self.lastEventTimestamp = lastEventTimestamp
    self.deviceIdentifier = deviceIdentifier ?? "device-\(UUID().uuidString.prefix(8))"
    self.gameVariationId = gameVariationId
    self.winningScore = winningScore
    self.winByTwo = winByTwo
    self.kitchenRule = kitchenRule
    self.doubleBounceRule = doubleBounceRule
  }

}

// MARK: - Extensions

extension ActiveGameStateDTO {
  /// Create DTO from a Game and timer state
  public static func from(
    game: Game,
    elapsedSeconds: TimeInterval,
    isTimerRunning: Bool,
    lastTimerStartTime: Date?,
    deviceIdentifier: String? = nil
  ) -> ActiveGameStateDTO {
    return ActiveGameStateDTO(
      gameId: game.id,
      gameType: game.gameType,
      createdDate: game.createdDate,
      score1: game.score1,
      score2: game.score2,
      isCompleted: game.isCompleted,
      gameState: game.gameState,
      currentServer: game.currentServer,
      serverNumber: game.serverNumber,
      serverPosition: game.serverPosition,
      sideOfCourt: game.sideOfCourt,
      isFirstServiceSequence: game.isFirstServiceSequence,
      elapsedSeconds: elapsedSeconds,
      isTimerRunning: isTimerRunning,
      lastTimerStartTime: lastTimerStartTime,
      lastEventTimestamp: Date(),
      deviceIdentifier: deviceIdentifier ?? "device-\(UUID().uuidString.prefix(8))",
      gameVariationId: game.gameVariation?.id,
      winningScore: game.winningScore,
      winByTwo: game.winByTwo,
      kitchenRule: game.kitchenRule,
      doubleBounceRule: game.doubleBounceRule
    )
  }

  /// Check if this DTO represents a more recent state than another
  public func isMoreRecentThan(_ other: ActiveGameStateDTO) -> Bool {
    return lastEventTimestamp > other.lastEventTimestamp
  }

  /// Calculate timer drift between this state and local timer
  public func timerDriftFrom(localElapsed: TimeInterval) -> TimeInterval {
    return abs(elapsedSeconds - localElapsed)
  }

  /// Whether the timer drift is significant enough to require correction
  public func hasSignificantTimerDrift(
    from localElapsed: TimeInterval, threshold: TimeInterval = 1.0
  ) -> Bool {
    return timerDriftFrom(localElapsed: localElapsed) > threshold
  }
}

// MARK: - Sync Errors

/// Errors that can occur during synchronization
public enum SyncError: Error, LocalizedError, Sendable {
  case watchConnectivityNotSupported
  case sessionNotAvailable
  case deviceNotReachable
  case messageEncodingFailed(any Error)
  case messageDecodingFailed(any Error)
  case invalidMessageFormat
  case syncDisabled
  case timerDriftTooLarge(TimeInterval)
  case gameStateMismatch

  public var errorDescription: String? {
    switch self {
    case .watchConnectivityNotSupported:
      return "WatchConnectivity is not supported on this device"
    case .sessionNotAvailable:
      return "WatchConnectivity session is not available"
    case .deviceNotReachable:
      return "The paired device is not reachable"
    case .messageEncodingFailed(let error):
      return "Failed to encode sync message: \(error.localizedDescription)"
    case .messageDecodingFailed(let error):
      return "Failed to decode sync message: \(error.localizedDescription)"
    case .invalidMessageFormat:
      return "Received message has invalid format"
    case .syncDisabled:
      return "Synchronization is currently disabled"
    case .timerDriftTooLarge(let drift):
      return "Timer drift is too large to automatically correct: \(String(format: "%.1f", drift))s"
    case .gameStateMismatch:
      return "Game state mismatch between devices"
    }
  }
}
