import Foundation

public enum SyncMessageType: String, Codable, Sendable, CaseIterable {
  case activeGameState
  case historyRequest
  case historyBatch
  case ack
}

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

  public init(
    id: UUID,
    gameType: GameType,
    score1: Int,
    score2: Int,
    isCompleted: Bool,
    createdDate: Date,
    completedDate: Date?,
    lastModified: Date,
    duration: TimeInterval?,
    winningScore: Int,
    notes: String?
  ) {
    self.id = id
    self.gameType = gameType
    self.score1 = score1
    self.score2 = score2
    self.isCompleted = isCompleted
    self.createdDate = createdDate
    self.completedDate = completedDate
    self.lastModified = lastModified
    self.duration = duration
    self.winningScore = winningScore
    self.notes = notes
  }
}

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

public struct ActiveGameStateDTO: Codable, Sendable, Identifiable {
  public let id: UUID
  public let gameId: UUID
  public let gameType: GameType
  public let createdDate: Date
  public let score1: Int
  public let score2: Int
  public let isCompleted: Bool
  public let gameState: GameState
  public let currentServer: Int
  public let serverNumber: Int
  public let serverPosition: ServerPosition
  public let sideOfCourt: SideOfCourt
  public let isFirstServiceSequence: Bool
  public let elapsedSeconds: TimeInterval
  public let isTimerRunning: Bool
  public let lastTimerStartTime: Date?
  public let lastEventTimestamp: Date
  public let deviceIdentifier: String
  public let gameVariationId: UUID?
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

// MARK: - DTO Helpers

public extension ActiveGameStateDTO {
  static func from(
    game: Game,
    elapsedSeconds: TimeInterval,
    isTimerRunning: Bool,
    lastTimerStartTime: Date?
  ) -> ActiveGameStateDTO {
    ActiveGameStateDTO(
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
      gameVariationId: game.gameVariation?.id,
      winningScore: game.winningScore,
      winByTwo: game.winByTwo,
      kitchenRule: game.kitchenRule,
      doubleBounceRule: game.doubleBounceRule
    )
  }

  func isMoreRecentThan(_ other: ActiveGameStateDTO) -> Bool {
    // Prefer lastEventTimestamp when available, otherwise compare elapsed time
    if lastEventTimestamp != other.lastEventTimestamp {
      return lastEventTimestamp > other.lastEventTimestamp
    }
    return elapsedSeconds > other.elapsedSeconds
  }
}

public extension HistoryGameDTO {
  init(from game: Game) {
    self.init(
      id: game.id,
      gameType: game.gameType,
      score1: game.score1,
      score2: game.score2,
      isCompleted: game.isCompleted,
      createdDate: game.createdDate,
      completedDate: game.completedDate,
      lastModified: game.lastModified,
      duration: game.duration,
      winningScore: game.winningScore,
      notes: game.notes
    )
  }
}

// MARK: - Sync Errors

public enum SyncError: Error, Sendable, LocalizedError {
  case watchConnectivityNotSupported
  case sessionNotAvailable
  case deviceNotReachable
  case encodingFailed
  case decodingFailed

  public var errorDescription: String? {
    switch self {
    case .watchConnectivityNotSupported:
      return "WatchConnectivity is not supported on this device"
    case .sessionNotAvailable:
      return "Sync session is not available"
    case .deviceNotReachable:
      return "Paired device is not reachable"
    case .encodingFailed:
      return "Failed to encode sync message"
    case .decodingFailed:
      return "Failed to decode sync message"
    }
  }
}


