//
//  LiveSyncCoordinator.swift
//  GameTrackerCore
//

import Foundation
import Observation

@MainActor
@Observable
public final class LiveSyncCoordinator {
  private var service: any SyncService
  private weak var liveManager: LiveGameStateManager?
  private weak var gameManager: SwiftDataGameManager?
  private var storage: (any SwiftDataStorageProtocol)?
  // Timer sync: pulse sender leadership and LWW timestamp tracking
  private var isTimerPulseLeader: Bool = false
  private var timerPulseTask: Task<Void, Never>? = nil
  private var lastTimerSetReceivedAt: Date = .distantPast
  private let timerPulseInterval: TimeInterval = 1.0       // 1 Hz pulses
  private let timerDriftThreshold: TimeInterval = 0.25     // snap if > 250ms off
  
  // Server sync: LWW timestamp tracking for conflict resolution
  private var lastServerSetReceivedAt: Date = .distantPast
  private var lastServerValueReceived: Int? = nil

  public init(service: any SyncService) {
    self.service = service

    // Wire default inbound handlers to dispatch on main actor
    self.service.onReceiveLiveSnapshot = { [weak self] snapshot in
      Task { @MainActor in
        await self?.handle(snapshot: snapshot)
      }
    }
    self.service.onReceiveLiveDelta = { [weak self] delta in
      Task { @MainActor in
        await self?.handle(delta: delta)
      }
    }

    // Default roster handler: import into local store (merge)
    self.service.onReceiveRosterSnapshot = { [weak self] roster in
      Task { @MainActor in
        await self?.handle(roster: roster)
      }
    }

    // Start configuration handler: start a new local game mirroring setup
    self.service.onReceiveStartConfiguration = { [weak self] config in
      Task { @MainActor in
        await self?.handle(startConfig: config)
      }
    }

    // Reachability: when transport becomes reachable and no current game, request status
    self.service.onReachabilityChanged = { [weak self] reach in
      Task { @MainActor in
        guard let self else { return }
        if reach == .reachable, self.liveManager?.currentGame == nil {
          try? await self.requestLiveStatus()
          Log.event(
            .loadStarted,
            level: .debug,
            message: "sync.reachability.requestLiveStatus",
            metadata: nil
          )
        }
      }
    }
    // Live status request handler: if we have an active game, publish roster and snapshot
    self.service.onReceiveLiveStatusRequest = { [weak self] in
      Task { @MainActor in
        guard let self, let live = self.liveManager, let current = live.currentGame else { return }
        if let storage = self.storage {
          let rb = RosterSnapshotBuilder(storage: storage)
          if let roster = try? rb.build(includeArchived: false, includeGuests: true) {
            try? await self.publishRoster(roster)
          }
        }
        let snapshot = GameSnapshotBuilder.make(
          from: current,
          elapsedTime: live.elapsedTime,
          isTimerRunning: live.isTimerRunning
        )
        try? await self.publish(snapshot: snapshot)
      }
    }

    // Respond to roster requests if storage is bound (phone acts as source of truth)
    self.service.onReceiveRosterRequest = { [weak self] in
      Task { @MainActor in
        guard let self else { return }
        guard let storage = self.storage else {
          Log.event(
            .loadFailed,
            level: .warn,
            message: "roster.sync.request.ignored",
            metadata: ["reason": "noStorageBound"]
          )
          return
        }
        do {
          let builder = RosterSnapshotBuilder(storage: storage)
          let snapshot = try builder.build(includeArchived: false, includeGuests: true)
          Log.event(
            .loadStarted,
            level: .info,
            message: "roster.sync.responding",
            metadata: [
              "players": "\(snapshot.players.count)",
              "teams": "\(snapshot.teams.count)",
              "presets": "\(snapshot.presets.count)"
            ]
          )
          try await self.publishRoster(snapshot)
          Log.event(
            .saveSucceeded,
            level: .info,
            message: "roster.sync.published",
            metadata: [
              "players": "\(snapshot.players.count)",
              "teams": "\(snapshot.teams.count)",
              "presets": "\(snapshot.presets.count)"
            ]
          )
        } catch {
          Log.error(error, event: .saveFailed, metadata: ["phase": "onReceiveRosterRequest"])
        }
      }
    }
  }

  public func bind(liveManager: LiveGameStateManager, gameManager: SwiftDataGameManager) {
    self.liveManager = liveManager
    self.gameManager = gameManager
  }

  public func start() async {
    await service.start()
    try? await service.requestLiveStatus()
  }

  public func stop() async {
    await service.stop()
    stopTimerPulse()
  }

  /// Check if another device is actively tracking the timer
  /// Returns true if another device is reachable and has recently sent timer updates
  public func isAnotherDeviceActivelyTracking() -> Bool {
    // If we are the timer pulse leader, another device is not actively tracking
    if isTimerPulseLeader {
      return false
    }
    
    // Check if another device is reachable
    guard service.currentReachability == .reachable else {
      return false
    }
    
    // Check if we've received timer updates recently (within last 3 seconds)
    // This indicates another device is actively tracking
    let recentThreshold: TimeInterval = 3.0
    let timeSinceLastUpdate = Date().timeIntervalSince(lastTimerSetReceivedAt)
    return timeSinceLastUpdate < recentThreshold
  }

  // MARK: - Outbound helpers

  public func publish(delta: LiveGameDeltaDTO) async throws {
    try await service.sendLiveDelta(delta)
    // Manage timer pulse leadership based on outbound lifecycle
    switch delta.operation {
    case .setGameState(let state):
      switch state {
      case .playing:
        isTimerPulseLeader = true
        startTimerPulse()
      case .paused, .completed:
        isTimerPulseLeader = false
        stopTimerPulse()
      default:
        break
      }
    case .setElapsedTime(_, let isRunning):
      // If we publish setElapsedTime running=true, assume leadership
      if isRunning {
        isTimerPulseLeader = true
        // No need to start a new pulse if one is running; start if missing
        startTimerPulse()
      } else {
        isTimerPulseLeader = false
        stopTimerPulse()
      }
    default:
      break
    }
  }

  public func publish(snapshot: LiveGameSnapshotDTO) async throws {
    try await service.sendLiveSnapshot(snapshot)
  }

  public func publishStart(_ config: GameStartConfiguration) async throws {
    try await service.sendStartConfiguration(config)
  }

  public func publishRoster(_ roster: RosterSnapshotDTO) async throws {
    try await service.sendRosterSnapshot(roster)
  }

  public func publishHistory(_ summaries: HistorySummariesDTO) async throws {
    try await service.sendHistorySummaries(summaries)
  }

  public func requestRoster() async throws {
    try await service.requestRosterSnapshot()
  }

  public func requestHistory() async throws {
    try await service.requestHistorySummaries()
  }

  public func requestLiveStatus() async throws {
    try await service.requestLiveStatus()
  }

  // MARK: - Binding helpers
  public func bind(storage: any SwiftDataStorageProtocol) {
    self.storage = storage
  }

  // MARK: - Inbound handling

  private func handle(roster: RosterSnapshotDTO) async {
    guard let gm = gameManager else { return }
    try? await (gm.storage as? SwiftDataStorage)?.importRosterSnapshot(roster, mode: .merge)
  }

  private func handle(startConfig: GameStartConfiguration) async {
    guard let live = liveManager else { return }
    // Attempt to start the game with provided configuration. If participants
    // are missing locally, request roster and retry once after a brief delay.
    do {
      if let gm = gameManager, let desiredId = startConfig.gameId {
        if let existing = try? await gm.storage.loadGame(id: desiredId) {
          await live.setCurrentGame(existing)
        } else {
          let rules = startConfig.rules ?? startConfig.gameType.defaultRules
          let newGame = Game(
            id: desiredId,
            gameType: startConfig.gameType,
            rules: rules
          )
          switch (startConfig.participants.side1, startConfig.participants.side2) {
          case (.players(let a), .players(let b)):
            newGame.participantMode = .players
            newGame.side1PlayerIds = a
            newGame.side2PlayerIds = b
          case (.team(let t1), .team(let t2)):
            newGame.participantMode = .teams
            newGame.side1TeamId = t1
            newGame.side2TeamId = t2
          default:
            break
          }
          try? await gm.storage.saveGame(newGame)
          await live.setCurrentGame(newGame)
        }
      } else {
        _ = try await live.startNewGame(with: startConfig)
      }
      Log.event(
        .loadSucceeded,
        level: .info,
        message: "start.config.applied",
        metadata: ["gameType": startConfig.gameType.rawValue]
      )
    } catch {
      Log.event(
        .loadFailed,
        level: .warn,
        message: "start.config.apply.failed",
        metadata: ["error": error.localizedDescription]
      )
      // Best-effort roster fetch then retry once
      try? await requestRoster()
      try? await Task.sleep(for: .milliseconds(200))
      _ = try? await live.startNewGame(with: startConfig)
    }
  }

  private func handle(snapshot: LiveGameSnapshotDTO) async {
    guard let gm = gameManager else { return }
    Log.event(
      .loadSucceeded,
      level: .info,
      message: "live.snapshot.received",
      metadata: [
        "gameId": snapshot.gameId.uuidString,
        "gameType": snapshot.gameType.rawValue
      ]
    )

    // If participants are unknown locally, request roster once (watch bootstrap path)
    do {
      var missingReferences = false
      switch snapshot.participantMode {
      case .players:
        for pid in snapshot.side1PlayerIds + snapshot.side2PlayerIds {
          let exists = (try? gm.storage.loadPlayer(id: pid)) != nil
          if !exists { missingReferences = true; break }
        }
      case .teams:
        if let t1 = snapshot.side1TeamId {
          let exists = (try? gm.storage.loadTeam(id: t1)) != nil
          if !exists { missingReferences = true }
        }
        if let t2 = snapshot.side2TeamId, missingReferences == false {
          let exists = (try? gm.storage.loadTeam(id: t2)) != nil
          if !exists { missingReferences = true }
        }
      default:
        break
      }
      if missingReferences {
        try? await requestRoster()
      }
    }

    // Load or use current game
    let existing = try? await gm.storage.loadGame(id: snapshot.gameId)
    let game = existing ?? Game(id: snapshot.gameId, gameType: snapshot.gameType)

    // Apply snapshot onto model
    game.score1 = snapshot.score1
    game.score2 = snapshot.score2
    game.currentServer = snapshot.currentServer
    // Reset server LWW tracking on authoritative snapshot
    lastServerSetReceivedAt = Date()
    lastServerValueReceived = snapshot.currentServer
    game.serverNumber = snapshot.serverNumber
    game.serverPosition = snapshot.serverPosition
    game.sideOfCourt = snapshot.sideOfCourt
    game.gameState = snapshot.gameState
    game.isFirstServiceSequence = snapshot.isFirstServiceSequence

    game.winningScore = snapshot.winningScore
    game.winByTwo = snapshot.winByTwo
    game.kitchenRule = snapshot.kitchenRule
    game.doubleBounceRule = snapshot.doubleBounceRule
    game.sideSwitchingRule = snapshot.sideSwitchingRule
    game.servingRotation = snapshot.servingRotation
    game.scoringType = snapshot.scoringType
    game.timeLimit = snapshot.timeLimit
    game.maxRallies = snapshot.maxRallies

    game.participantMode = snapshot.participantMode
    game.side1PlayerIds = snapshot.side1PlayerIds
    game.side2PlayerIds = snapshot.side2PlayerIds
    game.side1TeamId = snapshot.side1TeamId
    game.side2TeamId = snapshot.side2TeamId

    try? await gm.updateGame(game)

    // Update timer: derive running state strictly from snapshot.gameState
    if let live = liveManager {
      live.setElapsedTime(snapshot.elapsedTime)
      switch snapshot.gameState {
      case .playing:
        // Use resume semantics so baseline aligns to received elapsed
        live.resumeTimer()
      case .paused:
        live.pauseTimer()
      case .completed:
        live.pauseTimer()
      case .initial, .serving:
        // Maintain current timer run state; elapsed already updated
        break
      }
      await live.setCurrentGame(game)
    }
  }

  private func handle(delta: LiveGameDeltaDTO) async {
    guard let gm = gameManager else { return }
    let target = try? await gm.storage.loadGame(id: delta.gameId)
    guard let game = target else { return }

    // Apply operation via game manager to preserve persistence behaviors
    switch delta.operation {
    case .score(let team):
      try? await gm.scorePoint(for: team, in: game)
      game.logEvent(.playerScored, at: delta.timestamp, teamAffected: team)

    case .undoLastPoint:
      try? await gm.undoLastPoint(in: game)
      game.logEvent(.scoreUndone, at: delta.timestamp)

    case .decrement(let team):
      try? await gm.decrementScore(for: team, in: game)

    case .setGameState(let state):
      game.gameState = state
      try? await gm.updateGame(game)
      // Keep timer/UI consistent with lifecycle on receivers
      if let live = liveManager {
        live.gameStateDidChange(to: state)
        if state == .completed {
          // End the live session on this device when the other side completes
          live.clearCurrentGame()
        }
      }
      // If remote set playing/paused/completed, they become effective source; stop local pulse
      switch state {
      case .playing:
        isTimerPulseLeader = false
        stopTimerPulse()
      case .paused, .completed:
        isTimerPulseLeader = false
        stopTimerPulse()
      default:
        break
      }

    case .switchServer:
      try? await gm.switchServer(in: game)

    case .setServer(let team):
      // LWW: accept only if this delta is newer than our last applied server update
      if delta.createdAt > lastServerSetReceivedAt {
        lastServerSetReceivedAt = delta.createdAt
        lastServerValueReceived = team
        try? await gm.setServer(to: team, in: game)
      } else {
        // Older delta received - log conflict but don't apply
        Log.event(
          .serverSwitched,
          level: .debug,
          message: "sync.server.ignored_older",
          context: .current(gameId: game.id),
          metadata: [
            "receivedTeam": "\(team)",
            "receivedAt": delta.createdAt.ISO8601Format(),
            "lastAppliedAt": lastServerSetReceivedAt.ISO8601Format(),
            "currentServer": "\(game.currentServer)"
          ]
        )
      }

    case .switchServingPlayer:
      try? await gm.switchServingPlayer(in: game)

    case .startSecondServe:
      try? await gm.startSecondServeForCurrentTeam(in: game)

    case .serviceFault:
      try? await gm.handleServiceFault(in: game)
      game.logEvent(.serviceFault, at: delta.timestamp, teamAffected: game.currentServer)

    case .nonServingTeamTap(let team):
      try? await gm.handleNonServingTeamTap(on: team, in: game)

    case .reset:
      // Timer reset functionality removed; ignore legacy reset deltas gracefully
      break

    case .setElapsedTime(let elapsed, let isRunning):
      // LWW: accept only if this delta is newer than our last applied timer update
      if delta.createdAt > lastTimerSetReceivedAt {
        lastTimerSetReceivedAt = delta.createdAt
        if let live = liveManager {
          // Compensate for transport delay only when state is playing
          let isPlaying = (game.gameState == .playing) && !game.isCompleted
          let lag = max(0, Date().timeIntervalSince(delta.createdAt))
          let adjustedElapsed = isPlaying ? (elapsed + lag) : elapsed
          let drift = abs(live.elapsedTime - adjustedElapsed)
          if drift > timerDriftThreshold {
            live.setElapsedTime(adjustedElapsed)
          }
          // Do not start/pause timers here; timer state is controlled by gameState changes
        }
      }
      // Remote timer updates imply remote leadership; stop local pulse when remote is running
      if isRunning {
        isTimerPulseLeader = false
        stopTimerPulse()
      }
    }

    // Update UI model if we're attached
    if let live = liveManager, live.currentGame?.id == game.id {
      await live.setCurrentGame(game)
    }
  }

  // MARK: - Event forwarding hooks
  public var onReceiveRosterSnapshot: (@Sendable (RosterSnapshotDTO) -> Void)? {
    get { service.onReceiveRosterSnapshot }
    set { service.onReceiveRosterSnapshot = newValue }
  }

  // MARK: - Timer Pulse Helpers
  private func startTimerPulse() {
    guard timerPulseTask == nil else { return }
    guard let live = liveManager else { return }
    timerPulseTask = Task { [weak self] in
      // Send a pulse every ~1 second while we are leader and timer is running
      while let self, self.isTimerPulseLeader {
        if live.isTimerRunning, let current = live.currentGame {
          let elapsed = live.elapsedTime
          try? await self.service.sendLiveDelta(LiveGameDeltaDTO(
            gameId: current.id,
            timestamp: elapsed,
            operation: .setElapsedTime(elapsed: elapsed, isRunning: true)
          ))
        }
        try? await Task.sleep(for: .seconds(timerPulseInterval))
      }
    }
  }

  private func stopTimerPulse() {
    timerPulseTask?.cancel()
    timerPulseTask = nil
  }
}


