import Foundation
import GameTrackerCore

@MainActor
enum LiveGameStartSync {
  /// Mirror a newly started game from the local device to the companion device.
  /// This helper is intended to be called on the iPhone side immediately after
  /// a game is created and set as the current live game.
  static func syncGameStart(
    source: String,
    game: Game,
    liveManager: LiveGameStateManager,
    syncCoordinator: LiveSyncCoordinator
  ) async {
    let gameId = game.id

    // Build a canonical start configuration from the persisted game.
    let config = makeStartConfiguration(from: game)

    do {
      // Publish roster snapshot first so the companion has all participants.
      if let gm = liveManager.gameManager,
         let storage = gm.storage as? SwiftDataStorage {
        let rosterBuilder = RosterSnapshotBuilder(storage: storage)
        if let roster = try? rosterBuilder.build(includeArchived: false, includeGuests: true) {
          try await syncCoordinator.publishRoster(roster)
        }
      }

      // Publish start configuration (with explicit gameId) so the companion
      // can create or align its local game record.
      try await syncCoordinator.publishStart(config)

      // Immediately publish a full snapshot so a companion that comes online
      // after the initial start request can still join the in-progress game.
      if let current = liveManager.currentGame, current.id == game.id {
        let snapshot = GameSnapshotBuilder.make(
          from: current,
          elapsedTime: liveManager.elapsedTime,
          isTimerRunning: liveManager.isTimerRunning
        )
        try await syncCoordinator.publish(snapshot: snapshot)
      }

      Log.event(
        .saveSucceeded,
        level: .info,
        message: "sync.start.mirrored",
        context: .current(gameId: gameId),
        metadata: [
          "source": source,
          "gameType": game.gameType.rawValue
        ]
      )
    } catch {
      Log.error(
        error,
        event: .saveFailed,
        context: .current(gameId: gameId),
        metadata: [
          "phase": "LiveGameStartSync.syncGameStart",
          "source": source,
          "gameType": game.gameType.rawValue
        ]
      )
    }
  }

  private static func makeStartConfiguration(from game: Game) -> GameStartConfiguration {
    let teamSize = TeamSize(playersPerSide: game.effectiveTeamSize) ?? .doubles

    let participants: Participants = {
      switch game.participantMode {
      case .players:
        return Participants(
          side1: .players(game.side1PlayerIds),
          side2: .players(game.side2PlayerIds)
        )
      case .teams:
        return Participants(
          side1: .team(game.side1TeamId!),
          side2: .team(game.side2TeamId!)
        )
      }
    }()

    let rules = try? GameRules.createValidated(
      winningScore: game.winningScore,
      winByTwo: game.winByTwo,
      kitchenRule: game.kitchenRule,
      doubleBounceRule: game.doubleBounceRule,
      servingRotation: game.servingRotation,
      sideSwitchingRule: game.sideSwitchingRule,
      scoringType: game.scoringType,
      timeLimit: game.timeLimit,
      maxRallies: game.maxRallies
    )

    return GameStartConfiguration(
      gameId: game.id,
      gameType: game.gameType,
      teamSize: teamSize,
      participants: participants,
      notes: game.notes,
      rules: rules
    )
  }
}


