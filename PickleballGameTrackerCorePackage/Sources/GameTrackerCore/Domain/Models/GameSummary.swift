//
//  GameSummary.swift
//  SharedGameCore
//
//  Created by Agent on 8/13/25.
//

import Foundation
import SwiftData

@Model
public final class GameSummary {
  @Attribute(.unique) public var gameId: UUID
  public var gameTypeId: String
  public var completedDate: Date

  // Basic KPIs
  public var winningTeam: Int  // 1 or 2
  public var pointDifferential: Int
  public var duration: TimeInterval
  public var totalRallies: Int

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
