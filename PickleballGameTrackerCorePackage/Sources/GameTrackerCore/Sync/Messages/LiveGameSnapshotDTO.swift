//
//  LiveGameSnapshotDTO.swift
//  GameTrackerCore
//

import Foundation

// Full-state snapshot of a live game for bootstrap/resync.
public struct LiveGameSnapshotDTO: Codable, Sendable, Identifiable {
  public let id: UUID
  public let gameId: UUID

  // Timer snapshot
  public let elapsedTime: TimeInterval
  public let isTimerRunning: Bool

  // Core state
  public let gameType: GameType
  public let score1: Int
  public let score2: Int
  public let currentServer: Int
  public let serverNumber: Int
  public let serverPosition: ServerPosition
  public let sideOfCourt: SideOfCourt
  public let gameState: GameState
  public let isFirstServiceSequence: Bool

  // Rules
  public let winningScore: Int
  public let winByTwo: Bool
  public let kitchenRule: Bool
  public let doubleBounceRule: Bool
  public let sideSwitchingRule: SideSwitchingRule
  public let servingRotation: ServingRotation
  public let scoringType: ScoringType
  public let timeLimit: TimeInterval?
  public let maxRallies: Int?

  // Participants
  public let participantMode: ParticipantMode
  public let side1PlayerIds: [UUID]
  public let side2PlayerIds: [UUID]
  public let side1TeamId: UUID?
  public let side2TeamId: UUID?

  public init(
    id: UUID = UUID(),
    gameId: UUID,
    elapsedTime: TimeInterval,
    isTimerRunning: Bool,
    gameType: GameType,
    score1: Int,
    score2: Int,
    currentServer: Int,
    serverNumber: Int,
    serverPosition: ServerPosition,
    sideOfCourt: SideOfCourt,
    gameState: GameState,
    isFirstServiceSequence: Bool,
    winningScore: Int,
    winByTwo: Bool,
    kitchenRule: Bool,
    doubleBounceRule: Bool,
    sideSwitchingRule: SideSwitchingRule,
    servingRotation: ServingRotation,
    scoringType: ScoringType,
    timeLimit: TimeInterval?,
    maxRallies: Int?,
    participantMode: ParticipantMode,
    side1PlayerIds: [UUID],
    side2PlayerIds: [UUID],
    side1TeamId: UUID?,
    side2TeamId: UUID?
  ) {
    self.id = id
    self.gameId = gameId
    self.elapsedTime = elapsedTime
    self.isTimerRunning = isTimerRunning
    self.gameType = gameType
    self.score1 = score1
    self.score2 = score2
    self.currentServer = currentServer
    self.serverNumber = serverNumber
    self.serverPosition = serverPosition
    self.sideOfCourt = sideOfCourt
    self.gameState = gameState
    self.isFirstServiceSequence = isFirstServiceSequence
    self.winningScore = winningScore
    self.winByTwo = winByTwo
    self.kitchenRule = kitchenRule
    self.doubleBounceRule = doubleBounceRule
    self.sideSwitchingRule = sideSwitchingRule
    self.servingRotation = servingRotation
    self.scoringType = scoringType
    self.timeLimit = timeLimit
    self.maxRallies = maxRallies
    self.participantMode = participantMode
    self.side1PlayerIds = side1PlayerIds
    self.side2PlayerIds = side2PlayerIds
    self.side1TeamId = side1TeamId
    self.side2TeamId = side2TeamId
  }
}


