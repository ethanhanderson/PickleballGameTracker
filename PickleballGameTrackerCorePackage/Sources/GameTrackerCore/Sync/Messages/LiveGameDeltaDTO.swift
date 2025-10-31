//
//  LiveGameDeltaDTO.swift
//  GameTrackerCore
//

import Foundation

// Idempotent, append-only event describing a single user action or state transition.
public struct LiveGameDeltaDTO: Codable, Sendable, Identifiable {
  public enum Operation: Codable, Sendable {
    case score(team: Int)
    case undoLastPoint
    case decrement(team: Int)
    case setGameState(GameState)
    case switchServer
    case setServer(team: Int)
    case switchServingPlayer
    case startSecondServe
    case serviceFault
    case nonServingTeamTap(team: Int)
    case reset
    case setElapsedTime(elapsed: TimeInterval, isRunning: Bool)
  }

  public let id: UUID
  public let gameId: UUID
  public let createdAt: Date
  public let timestamp: TimeInterval  // Live timer when applied
  public let operation: Operation

  public init(
    id: UUID = UUID(),
    gameId: UUID,
    createdAt: Date = Date(),
    timestamp: TimeInterval,
    operation: Operation
  ) {
    self.id = id
    self.gameId = gameId
    self.createdAt = createdAt
    self.timestamp = timestamp
    self.operation = operation
  }
}


