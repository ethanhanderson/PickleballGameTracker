import Foundation

@MainActor
public extension LiveSyncCoordinator {
  func publishScoreEvent(
    for game: Game,
    target: LiveScoreTarget,
    assignsServe: Bool,
    timestamp: TimeInterval
  ) async throws {
    let operation: LiveGameDeltaDTO.Operation = assignsServe
      ? .scoreAndSetServe(
        team: target.team,
        playerId: target.playerId,
        playerName: target.playerName
      )
      : .score(
        team: target.team,
        playerId: target.playerId,
        playerName: target.playerName
      )

    try await publish(
      delta: LiveGameDeltaDTO(
        gameId: game.id,
        timestamp: timestamp,
        operation: operation
      )
    )
  }

  func publishScoreAssignment(
    for game: Game,
    target: LiveScoreTarget,
    timestamp: TimeInterval
  ) async throws {
    try await publishScoreEvent(
      for: game,
      target: target,
      assignsServe: true,
      timestamp: timestamp
    )
  }

  func publishScoreDelta(
    for game: Game,
    team: Int,
    playerId: UUID?,
    playerName: String?,
    timestamp: TimeInterval
  ) async throws {
    let target = LiveScoreTarget.resolved(team: team, playerId: playerId, playerName: playerName)
    try await publishScoreEvent(
      for: game,
      target: target,
      assignsServe: false,
      timestamp: timestamp
    )
  }

  func publishDecrementDelta(
    for game: Game,
    team: Int,
    timestamp: TimeInterval
  ) async throws {
    try await publish(
      delta: LiveGameDeltaDTO(
        gameId: game.id,
        timestamp: timestamp,
        operation: .decrement(team: team)
      )
    )
  }

  func publishUndoDelta(
    for game: Game,
    timestamp: TimeInterval
  ) async throws {
    try await publish(
      delta: LiveGameDeltaDTO(
        gameId: game.id,
        timestamp: timestamp,
        operation: .undoLastPoint
      )
    )
  }
}


