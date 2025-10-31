//
//  HistorySummariesDTO.swift
//  GameTrackerCore
//

import Foundation

public struct HistorySummaryDTO: Codable, Sendable, Identifiable {
  public var id: UUID { gameId }
  public let gameId: UUID
  public let gameTypeId: String
  public let completedDate: Date
  public let winningTeam: Int
  public let pointDifferential: Int
  public let duration: TimeInterval
  public let totalRallies: Int

  public init(
    gameId: UUID,
    gameTypeId: String,
    completedDate: Date,
    winningTeam: Int,
    pointDifferential: Int,
    duration: TimeInterval,
    totalRallies: Int
  ) {
    self.gameId = gameId
    self.gameTypeId = gameTypeId
    self.completedDate = completedDate
    self.winningTeam = winningTeam
    self.pointDifferential = pointDifferential
    self.duration = duration
    self.totalRallies = totalRallies
  }
}

public struct HistorySummariesDTO: Codable, Sendable {
  public let summaries: [HistorySummaryDTO]
  public let generatedAt: Date

  public init(summaries: [HistorySummaryDTO], generatedAt: Date = Date()) {
    self.summaries = summaries
    self.generatedAt = generatedAt
  }
}


