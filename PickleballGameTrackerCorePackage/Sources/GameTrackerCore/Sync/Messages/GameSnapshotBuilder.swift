//
//  GameSnapshotBuilder.swift
//  GameTrackerCore
//

import Foundation

public struct GameSnapshotBuilder {
  public static func make(
    from game: Game,
    elapsedTime: TimeInterval,
    isTimerRunning: Bool
  ) -> LiveGameSnapshotDTO {
    return LiveGameSnapshotDTO(
      gameId: game.id,
      elapsedTime: elapsedTime,
      isTimerRunning: isTimerRunning,
      gameType: game.gameType,
      score1: game.score1,
      score2: game.score2,
      currentServer: game.currentServer,
      serverNumber: game.serverNumber,
      serverPosition: game.serverPosition,
      sideOfCourt: game.sideOfCourt,
      gameState: game.gameState,
      isFirstServiceSequence: game.isFirstServiceSequence,
      winningScore: game.winningScore,
      winByTwo: game.winByTwo,
      kitchenRule: game.kitchenRule,
      doubleBounceRule: game.doubleBounceRule,
      sideSwitchingRule: game.sideSwitchingRule,
      servingRotation: game.servingRotation,
      scoringType: game.scoringType,
      timeLimit: game.timeLimit,
      maxRallies: game.maxRallies,
      participantMode: game.participantMode,
      side1PlayerIds: game.side1PlayerIds,
      side2PlayerIds: game.side2PlayerIds,
      side1TeamId: game.side1TeamId,
      side2TeamId: game.side2TeamId
    )
  }
}


