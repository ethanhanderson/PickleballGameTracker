import Foundation
import SwiftData
import Observation

@MainActor
@Observable
public final class LiveSyncCoordinator {
  private var service: any SyncService
  private weak var liveManager: LiveGameStateManager?
  private weak var gameManager: SwiftDataGameManager?
  private var storage: (any SwiftDataStorageProtocol)?
  // Timer sync: pulse sender leadership and LWW timestamp tracking
  private enum TimerLeadership {
    case none
    case local
    case remote
  }

  private var timerLeadership: TimerLeadership = .none {
    didSet {
      guard timerLeadership != oldValue else { return }
      switch timerLeadership {
      case .local:
        isTimerPulseLeader = true
      default:
        isTimerPulseLeader = false
      }
      recordTimerLeadershipChange(for: timerLeadership)
    }
  }
  private var isTimerPulseLeader: Bool = false
  private var timerPulseTask: Task<Void, Never>? = nil
  private var lastTimerSetReceivedAt: Date = .distantPast
  private let timerPulseInterval: TimeInterval = 0.5       // 2 Hz pulses for tighter drift
  private let timerDriftResolver = TimerDriftResolver()
  // Store last received elapsed (authoritative from peer) and a window to force-snap on resume
  private var lastTimerElapsedAdjustedReceived: TimeInterval? = nil
  private var pendingForceSnapUntil: Date? = nil
  private let timerForceSnapWindow: TimeInterval = 1.5
  
  // Server sync: LWW timestamp tracking for conflict resolution
  private var scoreMutationSnapshot = MutationPrioritySnapshot.empty
  private var serveMutationSnapshot = MutationPrioritySnapshot.empty
  private var serverAssignmentSnapshot = MutationPrioritySnapshot.empty
  private var lifecycleMutationSnapshot = MutationPrioritySnapshot.empty
  private var timerMutationSnapshot = MutationPrioritySnapshot.empty

  // Activity tracking
  private var localActivityState = DeviceActivityState(role: .local)
  private var peerActivityState = DeviceActivityState(role: .peer)
  private let activityLookbackWindow: TimeInterval = 90
  private let activityTieBreakerEpsilon: Double = 0.2
  private let mutationTieWindow: TimeInterval = 0.4
  private let activityDominanceThreshold: Double = 0.35

  // Roster sync: track what watch knows about (phone side only)
  private var knownWatchRoster: (players: [UUID: Date], teams: [UUID: Date], presets: [UUID: Date]) = ([:], [:], [:])
  private var hasReceivedInventory: Bool = false
  private var inventorySentThisSession: Bool = false
  public var reachability: SyncReachability = .unavailable

  public init(service: any SyncService) {
    self.service = service
    self.reachability = service.currentReachability

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

    // Start request handler: request phone to present Setup and start game
    // Note: WatchConnectivityTransport schedules a push notification when receiving the request
    // AppNavigationView will either open immediately (if app is active and no sheets) or let notification show
    self.service.onReceiveStartRequest = { request in
      Task { @MainActor in
        NotificationCenter.default.post(
          name: Notification.Name("OpenSetupRequested"),
          object: nil,
          userInfo: [
            "gameType": request.gameType,
            "gameTypeId": request.gameType.rawValue
          ]
        )
      }
    }

    // History summaries request handler (phone side): build and send recent summaries
    self.service.onReceiveHistoryRequest = { [weak self] in
      Task { @MainActor in
        guard let self, let storage = self.storage as? SwiftDataStorage else { return }
        do {
          let context = storage.modelContainer.mainContext
          var fd = FetchDescriptor<GameSummary>(
            sortBy: [SortDescriptor(\.completedDate, order: .reverse)]
          )
          fd.fetchLimit = 50
          let rows = try context.fetch(fd)
          let dtos: [HistorySummaryDTO] = rows.map {
            HistorySummaryDTO(
              gameId: $0.gameId,
              gameTypeId: $0.gameTypeId,
              completedDate: $0.completedDate,
              winningTeam: $0.winningTeam,
              pointDifferential: $0.pointDifferential,
              duration: $0.duration,
              totalRallies: $0.totalRallies
            )
          }
          try await self.publishHistory(HistorySummariesDTO(summaries: dtos))
          Log.event(
            .saveSucceeded,
            level: .info,
            message: "history.summaries.sent",
            metadata: ["count": "\(dtos.count)"]
          )
        } catch {
          Log.error(error, event: .saveFailed, metadata: ["phase": "onReceiveHistoryRequest"])
        }
      }
    }

    // History summaries import handler (watch side): upsert into local store
    self.service.onReceiveHistorySummaries = { [weak self] payload in
      Task { @MainActor in
        guard let self, let gm = self.gameManager else { return }
        do {
          if let storage = gm.storage as? SwiftDataStorage {
            let context = storage.modelContainer.mainContext
            for s in payload.summaries {
              let descriptor = FetchDescriptor<GameSummary>(
                predicate: #Predicate<GameSummary> { $0.gameId == s.gameId }
              )
              if let existing = try context.fetch(descriptor).first {
                existing.gameTypeId = s.gameTypeId
                existing.completedDate = s.completedDate
                existing.winningTeam = s.winningTeam
                existing.pointDifferential = s.pointDifferential
                existing.duration = s.duration
                existing.totalRallies = s.totalRallies
              } else {
                let row = GameSummary(
                  gameId: s.gameId,
                  gameTypeId: s.gameTypeId,
                  completedDate: s.completedDate,
                  winningTeam: s.winningTeam,
                  pointDifferential: s.pointDifferential,
                  duration: s.duration,
                  totalRallies: s.totalRallies
                )
                context.insert(row)
              }
            }
            try context.save()
            Log.event(
              .saveSucceeded,
              level: .info,
              message: "history.summaries.imported",
              metadata: ["count": "\(payload.summaries.count)"]
            )
          }
        } catch {
          Log.error(error, event: .saveFailed, metadata: ["phase": "onReceiveHistorySummaries"])
        }
      }
    }

    // Reachability: when transport becomes reachable, send inventory (watch) or handle status (phone)
    self.service.onReachabilityChanged = { [weak self] reach in
      Task { @MainActor in
        guard let self else { return }
        self.reachability = reach
        if reach == .reachable {
          // Watch side: has a game manager but no bound storage
          if self.gameManager != nil && self.storage == nil {
            if !self.inventorySentThisSession {
              try? await self.sendRosterInventory()
              self.inventorySentThisSession = true
            }
            // Whenever the watch becomes reachable, ask the phone for live status so we can
            // sync into an in-progress game (including its current timer value).
            try? await self.requestLiveStatus()
            Log.event(
              .loadStarted,
              level: .debug,
              message: "sync.watch.reachability.requestLiveStatus",
              metadata: nil
            )
          }
          // Phone side: storage bound, acts as roster and status source of truth.
          // Always request live status on reachability so we converge to the latest state,
          // even if this device already has a current game.
          if self.storage != nil {
            try? await self.requestLiveStatus()
            Log.event(
              .loadStarted,
              level: .debug,
              message: "sync.reachability.requestLiveStatus",
              metadata: [
                "hasCurrentGame": String(self.liveManager?.currentGame != nil)
              ]
            )
          }
        }
      }
    }
    // Live status request handler: if we have an active game, send roster diff then snapshot
    self.service.onReceiveLiveStatusRequest = { [weak self] in
      Task { @MainActor in
        guard let self, let live = self.liveManager, let current = live.currentGame else { return }
        if self.preferredDeviceRole() == .peer {
          Log.event(
            .realtimeEvent,
            level: .debug,
            message: "live.statusRequest.skipped_lowPriority",
            metadata: [
              "reason": "peerPreferred",
              "gameId": current.id.uuidString
            ]
          )
          return
        }
        // If no inventory received yet, fallback to old snapshot path for backward compatibility
        if !self.hasReceivedInventory {
          if let storage = self.storage {
            let rb = RosterSnapshotBuilder(storage: storage)
            if let roster = try? rb.build(includeArchived: false, includeGuests: true) {
              try? await self.publishRoster(roster)
            }
          }
        } else {
          // Use new inventory→upsert flow
          try? await self.sendRosterDiff()
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
    // Fallback to old snapshot path for backward compatibility
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

    // Roster inventory handler: update known watch state and compute/send diff
    self.service.onReceiveRosterInventory = { [weak self] inventory in
      Task { @MainActor in
        guard let self else { return }
        self.knownWatchRoster = (inventory.players, inventory.teams, inventory.presets)
        self.hasReceivedInventory = true
        Log.event(
          .loadSucceeded,
          level: .debug,
          message: "roster.inventory.received",
          metadata: [
            "players": "\(inventory.players.count)",
            "teams": "\(inventory.teams.count)",
            "presets": "\(inventory.presets.count)"
          ]
        )
        // Compute diff and send upsert
        try? await self.sendRosterDiff()
      }
    }

    // Roster upsert handler: import into local store (watch side)
    self.service.onReceiveRosterUpsert = { [weak self] upsert in
      Task { @MainActor in
        guard let self, let gm = self.gameManager else { return }
        do {
          if let storage = gm.storage as? SwiftDataStorage {
            try await storage.importRosterUpsert(upsert)
            Log.event(
              .saveSucceeded,
              level: .info,
              message: "roster.upsert.applied",
              metadata: [
                "players": "\(upsert.players.count)",
                "teams": "\(upsert.teams.count)",
                "presets": "\(upsert.presets.count)"
              ]
            )
          }
        } catch {
          Log.error(error, event: .saveFailed, metadata: ["phase": "onReceiveRosterUpsert"])
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

  public func noteLocalScoreMutation(at date: Date = Date()) {
    localActivityState.recordScoreMutation(at: date)
    updateMutationSnapshot(&scoreMutationSnapshot, source: .local, appliedAt: date)
  }

  public func noteLocalServeMutation(at date: Date = Date()) {
    localActivityState.recordServeMutation(at: date)
    updateMutationSnapshot(&serveMutationSnapshot, source: .local, appliedAt: date)
    updateMutationSnapshot(&serverAssignmentSnapshot, source: .local, appliedAt: date)
  }

  public func noteLocalLifecycleMutation(at date: Date = Date()) {
    localActivityState.recordLifecycleMutation(at: date)
    updateMutationSnapshot(&lifecycleMutationSnapshot, source: .local, appliedAt: date)
  }

  public func noteLocalUserInteraction(at date: Date = Date()) {
    localActivityState.recordUserInteraction(at: date)
  }

  public func setLiveViewForeground(_ isForeground: Bool, at date: Date = Date()) {
    localActivityState.setForeground(isForeground, at: date)
  }

  /// Check if another device is actively tracking the timer
  /// Returns true if another device is reachable and has recently sent timer updates
  public func isAnotherDeviceActivelyTracking() -> Bool {
    guard service.currentReachability == .reachable else {
      return false
    }
    if timerLeadership == .local {
      return false
    }
    let recentThreshold: TimeInterval = 3.0
    let now = Date()
    let timeSinceLastTimerSet = now.timeIntervalSince(lastTimerSetReceivedAt)
    let timeSincePeerPulse = now.timeIntervalSince(peerActivityState.lastTimerPulseAt)
    let peerTier = peerActivityState.activityTier(now: now, lookbackWindow: activityLookbackWindow)
    let peerScore = peerActivityScore(now: now)
    _ = preferredDeviceRole(now: now)
    if min(timeSinceLastTimerSet, timeSincePeerPulse) < recentThreshold {
      return true
    }
    if peerScore < 0.35 {
      return false
    }
    return peerTier == .active
  }

  // MARK: - Outbound helpers

  public func publish(delta: LiveGameDeltaDTO) async throws {
    // Invariant: only publish deltas for the currently active game
    if let current = liveManager?.currentGame?.id, current != delta.gameId {
      Log.event(
        .loadFailed,
        level: .error,
        message: "sync.publish.mismatchedGameContext",
        context: .current(gameId: delta.gameId),
        metadata: ["expectedGameId": current.uuidString, "gotGameId": delta.gameId.uuidString]
      )
      throw SyncInvariantError.mismatchedGameContext(expected: current, got: delta.gameId)
    }
    try await service.sendLiveDelta(delta)
    // Manage timer pulse leadership based on outbound lifecycle
    switch delta.operation {
    case .setGameState(let state):
      switch state {
      case .playing:
        assumeLocalTimerLeadership()
      case .paused, .completed:
        clearTimerLeadership()
      default:
        break
      }
      updateMutationSnapshot(&lifecycleMutationSnapshot, source: .local, appliedAt: delta.createdAt)
    case .setElapsedTime(_, let isRunning):
      // If we publish setElapsedTime running=true, assume leadership
      if isRunning {
        assumeLocalTimerLeadership()
      } else {
        clearTimerLeadership()
      }
      updateMutationSnapshot(&timerMutationSnapshot, source: .local, appliedAt: delta.createdAt)
    default:
      break
    }
  }

  public func publish(snapshot: LiveGameSnapshotDTO) async throws {
    try await service.sendLiveSnapshot(snapshot)
  }

  public func publishStart(_ config: GameStartConfiguration) async throws {
    Log.event(
      .saveStarted,
      level: .info,
      message: "sync.start.publish",
      metadata: [
        "gameId": config.gameId?.uuidString ?? "nil",
        "gameType": config.gameType.rawValue
      ]
    )
    // Ensure participants exist on watch before sending start config
    try await ensureParticipantsOnWatch(for: config)
    try await service.sendStartConfiguration(config)
    Log.event(
      .saveSucceeded,
      level: .info,
      message: "sync.start.sent",
      metadata: [
        "gameId": config.gameId?.uuidString ?? "nil",
        "gameType": config.gameType.rawValue
      ]
    )
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

  public func requestStart(gameType: GameType) async throws {
    try await service.sendStartRequest(StartGameRequestDTO(gameType: gameType))
  }

  public func sendRosterInventory() async throws {
    guard let gm = gameManager, let storage = gm.storage as? SwiftDataStorage else { return }
    let builder = RosterInventoryBuilder(storage: storage)
    let inventory = try builder.build(includeArchived: false, includeGuests: true)
    try await service.sendRosterInventory(inventory)
    Log.event(
      .saveSucceeded,
      level: .info,
      message: "roster.inventory.sent",
      metadata: [
        "players": "\(inventory.players.count)",
        "teams": "\(inventory.teams.count)",
        "presets": "\(inventory.presets.count)"
      ]
    )
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
    guard let live = liveManager, let gm = gameManager else { return }
    Log.event(
      .loadStarted,
      level: .info,
      message: "start.config.received",
      metadata: [
        "gameId": startConfig.gameId?.uuidString ?? "nil",
        "gameType": startConfig.gameType.rawValue
      ]
    )
    
    // Verify participants exist locally before starting
    let canStart = await verifyParticipantsLocally(for: startConfig, storage: gm.storage)
    if !canStart {
      Log.event(
        .loadFailed,
        level: .warn,
        message: "start.config.blocked.missingParticipants",
        metadata: ["gameType": startConfig.gameType.rawValue]
      )
      // Best-effort roster fetch then retry once
      try? await requestRoster()
      try? await Task.sleep(for: .milliseconds(500))
      // Re-verify after fetch
      let canStartAfterWait = await verifyParticipantsLocally(for: startConfig, storage: gm.storage)
      if !canStartAfterWait {
        Log.event(
          .loadFailed,
          level: .error,
          message: "start.config.failed.participantsStillMissing",
          metadata: ["gameType": startConfig.gameType.rawValue]
        )
        return
      }
    }
    
    // Attempt to start the game with provided configuration
    do {
      if let desiredId = startConfig.gameId {
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
    }
  }

  private func verifyParticipantsLocally(for config: GameStartConfiguration, storage: any SwiftDataStorageProtocol) async -> Bool {
    switch (config.participants.side1, config.participants.side2) {
    case (.players(let a), .players(let b)):
      for playerId in a + b {
        if (try? storage.loadPlayer(id: playerId)) == nil {
          return false
        }
      }
      return true
    case (.team(let t1), .team(let t2)):
      guard let team1 = try? storage.loadTeam(id: t1),
            let team2 = try? storage.loadTeam(id: t2) else {
        return false
      }
      // Verify team members exist
      for player in team1.players {
        if (try? storage.loadPlayer(id: player.id)) == nil {
          return false
        }
      }
      for player in team2.players {
        if (try? storage.loadPlayer(id: player.id)) == nil {
          return false
        }
      }
      return true
    default:
      return false
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
    let snapshotContext = LogContext.current(gameId: snapshot.gameId)

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
      }
      if missingReferences {
        try? await requestRoster()
      }
    }

    // Load or use current game
    let existing = try? await gm.storage.loadGame(id: snapshot.gameId)
    let game = existing ?? Game(id: snapshot.gameId, gameType: snapshot.gameType)

    // Apply snapshot onto model
    let canApplyScoreFromSnapshot = shouldAcceptRemoteMutation(
      createdAt: snapshot.snapshotCreatedAt,
      snapshot: scoreMutationSnapshot,
      label: "sync.snapshot.score.ignored_lowPriority",
      context: snapshotContext
    )
    if canApplyScoreFromSnapshot {
      game.score1 = snapshot.score1
      game.score2 = snapshot.score2
      updateMutationSnapshot(&scoreMutationSnapshot, source: .remote, appliedAt: snapshot.snapshotCreatedAt)
    }
    // Avoid overriding recent serve changes while actively playing to prevent UI flip-flop
    let isPlaying = (snapshot.gameState == .playing) && !game.isCompleted
    let recentServeWindow: TimeInterval = 0.25
    let serveSnapshotAccepted = shouldAcceptRemoteMutation(
      createdAt: snapshot.snapshotCreatedAt,
      snapshot: serveMutationSnapshot,
      label: "sync.snapshot.serve.ignored_lowPriority",
      context: snapshotContext
    )
    let shouldApplyServeStateFromSnapshot = serveSnapshotAccepted && ((!isPlaying) || (Date().timeIntervalSince(serveMutationSnapshot.appliedAt) > recentServeWindow))
    if shouldApplyServeStateFromSnapshot {
      game.currentServer = snapshot.currentServer
      // Reset server LWW tracking on authoritative snapshot
      let now = Date()
      updateMutationSnapshot(&serveMutationSnapshot, source: .snapshot, appliedAt: now)
      updateMutationSnapshot(&serverAssignmentSnapshot, source: .snapshot, appliedAt: now)
      game.serverNumber = snapshot.serverNumber
      game.serverPosition = snapshot.serverPosition
      game.sideOfCourt = snapshot.sideOfCourt
    }
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

    // Treat a playing snapshot from the peer as an authoritative timer update
    let timerSnapshotAccepted = shouldAcceptRemoteMutation(
      createdAt: snapshot.snapshotCreatedAt,
      snapshot: timerMutationSnapshot,
      label: "sync.snapshot.timer.ignored_lowPriority",
      context: snapshotContext
    )
    if snapshot.gameState == .playing, timerSnapshotAccepted {
      let now = Date()
      lastTimerSetReceivedAt = now
      lastTimerElapsedAdjustedReceived = snapshot.elapsedTime
      updateMutationSnapshot(&timerMutationSnapshot, source: .snapshot, appliedAt: now)
      peerActivityState.recordTimerPulse(at: now)
    }

    // Update timer: derive running state strictly from snapshot.gameState
    if let live = liveManager {
      if timerSnapshotAccepted {
        live.setElapsedTime(snapshot.elapsedTime)
        switch snapshot.gameState {
        case .playing:
          live.resumeTimer()
        case .paused:
          live.pauseTimer()
        case .completed:
          live.pauseTimer()
        case .initial, .serving:
          break
        }
      }
      await live.setCurrentGame(game)
    }
  }

  private func handle(delta: LiveGameDeltaDTO) async {
    guard let gm = gameManager else { return }
    let target = try? await gm.storage.loadGame(id: delta.gameId)
    if target == nil {
      // If we can't resolve the game record but this is a completion for our
      // currently active session, still clear the live session so the UI ends
      if case .setGameState(let state) = delta.operation,
         state == .completed,
         let live = liveManager,
         live.currentGame?.id == delta.gameId {
        live.gameStateDidChange(to: .completed)
        live.clearCurrentGame()
      }
      return
    }
    guard let game = target else { return }

    // Apply operation via game manager to preserve persistence behaviors
    switch delta.operation {
    case .score(let team, let playerId, let playerName):
      await applyScoreOperation(
        team: team,
        playerId: playerId,
        playerName: playerName,
        delta: delta,
        game: game,
        manager: gm,
        assignsServe: false
      )

    case .scoreAndSetServe(let team, let playerId, let playerName):
      await applyScoreOperation(
        team: team,
        playerId: playerId,
        playerName: playerName,
        delta: delta,
        game: game,
        manager: gm,
        assignsServe: true
      )

    case .undoLastPoint:
      guard shouldAcceptRemoteMutation(
        createdAt: delta.createdAt,
        snapshot: scoreMutationSnapshot,
        label: "sync.score.undo.ignored_lowPriority",
        context: .current(gameId: game.id)
      ) else { break }
      try? await gm.undoLastPoint(in: game)
      game.logEvent(.scoreUndone, at: delta.timestamp)
      peerActivityState.recordScoreMutation()
      updateMutationSnapshot(&scoreMutationSnapshot, source: .remote, appliedAt: delta.createdAt)

    case .decrement(let team):
      guard shouldAcceptRemoteMutation(
        createdAt: delta.createdAt,
        snapshot: scoreMutationSnapshot,
        label: "sync.score.decrement.ignored_lowPriority",
        context: .current(gameId: game.id)
      ) else { break }
      try? await gm.decrementScore(for: team, in: game)
      peerActivityState.recordScoreMutation()
      updateMutationSnapshot(&scoreMutationSnapshot, source: .remote, appliedAt: delta.createdAt)

    case .setGameState(let state):
      if state != .completed {
        guard shouldAcceptRemoteMutation(
          createdAt: delta.createdAt,
          snapshot: lifecycleMutationSnapshot,
          label: "sync.lifecycle.ignored_lowPriority",
          context: .current(gameId: game.id)
        ) else { break }
      }
      updateMutationSnapshot(&lifecycleMutationSnapshot, source: .remote, appliedAt: delta.createdAt)
      game.gameState = state
      try? await gm.updateGame(game)
      // If transitioning to playing, pre-apply the most recent authoritative elapsed
      // so the resume baseline matches the phone precisely.
      if state == .playing {
        // Arm a brief window to force-snap subsequent elapsed updates as well
        pendingForceSnapUntil = Date().addingTimeInterval(timerForceSnapWindow)
        if let live = liveManager,
           let adjusted = lastTimerElapsedAdjustedReceived,
           Date().timeIntervalSince(lastTimerSetReceivedAt) < 2.0 {
          live.setElapsedTime(adjusted)
        }
      } else {
        pendingForceSnapUntil = nil
      }
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
        assumeRemoteTimerLeadership()
      case .paused, .completed:
        clearTimerLeadership()
      default:
        break
      }
      peerActivityState.recordLifecycleMutation()

    case .switchServer:
      if shouldAcceptRemoteMutation(
        createdAt: delta.createdAt,
        snapshot: serveMutationSnapshot,
        label: "sync.server.switch.ignored_lowPriority",
        context: .current(gameId: game.id)
      ) {
        try? await gm.switchServer(in: game)
        peerActivityState.recordServeMutation()
        updateMutationSnapshot(&serveMutationSnapshot, source: .remote, appliedAt: delta.createdAt)
      }

    case .setServer(let team):
      if shouldAcceptRemoteMutation(
        createdAt: delta.createdAt,
        snapshot: serverAssignmentSnapshot,
        label: "sync.server.set.ignored_lowPriority",
        context: .current(gameId: game.id)
      ) {
        try? await gm.setServer(to: team, in: game)
        peerActivityState.recordServeMutation()
        updateMutationSnapshot(&serveMutationSnapshot, source: .remote, appliedAt: delta.createdAt)
        updateMutationSnapshot(&serverAssignmentSnapshot, source: .remote, appliedAt: delta.createdAt)
      }

    case .switchServingPlayer:
      if shouldAcceptRemoteMutation(
        createdAt: delta.createdAt,
        snapshot: serveMutationSnapshot,
        label: "sync.server.switchPlayer.ignored_lowPriority",
        context: .current(gameId: game.id)
      ) {
        try? await gm.switchServingPlayer(in: game)
        peerActivityState.recordServeMutation()
        updateMutationSnapshot(&serveMutationSnapshot, source: .remote, appliedAt: delta.createdAt)
      }

    case .startSecondServe:
      if shouldAcceptRemoteMutation(
        createdAt: delta.createdAt,
        snapshot: serveMutationSnapshot,
        label: "sync.server.secondServe.ignored_lowPriority",
        context: .current(gameId: game.id)
      ) {
        try? await gm.startSecondServeForCurrentTeam(in: game)
        peerActivityState.recordServeMutation()
        updateMutationSnapshot(&serveMutationSnapshot, source: .remote, appliedAt: delta.createdAt)
      }

    case .fault(let event, let team):
      if shouldAcceptRemoteMutation(
        createdAt: delta.createdAt,
        snapshot: serveMutationSnapshot,
        label: "sync.server.fault.ignored_lowPriority",
        context: .current(gameId: game.id)
      ) {
        game.logEvent(event, at: delta.timestamp, teamAffected: team)
        if event.typicallyChangesServe {
          try? await gm.handleServiceFault(in: game)
        }
        peerActivityState.recordServeMutation()
        updateMutationSnapshot(&serveMutationSnapshot, source: .remote, appliedAt: delta.createdAt)
      }

    case .nonServingTeamTap(let team):
      if shouldAcceptRemoteMutation(
        createdAt: delta.createdAt,
        snapshot: serveMutationSnapshot,
        label: "sync.server.tap.ignored_lowPriority",
        context: .current(gameId: game.id)
      ) {
        try? await gm.handleNonServingTeamTap(on: team, in: game)
        peerActivityState.recordServeMutation()
        updateMutationSnapshot(&serveMutationSnapshot, source: .remote, appliedAt: delta.createdAt)
      }

    case .reset:
      // Timer reset functionality removed; ignore legacy reset deltas gracefully
      break

    case .setElapsedTime(let elapsed, let isRunning):
      if shouldAcceptRemoteTimerMutation(createdAt: delta.createdAt) {
        lastTimerSetReceivedAt = delta.createdAt
        if let live = liveManager {
          // Compensate for transport delay only when state is playing
          let isPlaying = (game.gameState == .playing) && !game.isCompleted
          let lag = max(0, Date().timeIntervalSince(delta.createdAt))
          let adjustedElapsed = isPlaying ? (elapsed + lag) : elapsed
          let shouldForceSnap = (pendingForceSnapUntil?.timeIntervalSinceNow ?? -1) > 0
          let resolvedElapsed = timerDriftResolver.resolve(
            currentElapsed: live.elapsedTime,
            targetElapsed: adjustedElapsed,
            forceSnap: shouldForceSnap
          )
          if resolvedElapsed != live.elapsedTime {
            live.setElapsedTime(resolvedElapsed)
          }
          lastTimerElapsedAdjustedReceived = resolvedElapsed
        }
        updateMutationSnapshot(&timerMutationSnapshot, source: .remote, appliedAt: delta.createdAt)
        peerActivityState.recordTimerPulse()
      }
      // Remote timer updates imply remote leadership; stop local pulse when remote is running
      if isRunning {
        assumeRemoteTimerLeadership()
      } else {
        clearTimerLeadership()
      }
    }

    // Update UI model if we're attached
    if let live = liveManager, live.currentGame?.id == game.id {
      await live.setCurrentGame(game)
    }
  }

  private func applyScoreOperation(
    team: Int,
    playerId: UUID?,
    playerName: String?,
    delta: LiveGameDeltaDTO,
    game: Game,
    manager: SwiftDataGameManager,
    assignsServe: Bool
  ) async {
    guard shouldAcceptRemoteMutation(
      createdAt: delta.createdAt,
      snapshot: scoreMutationSnapshot,
      label: assignsServe ? "sync.scoreServe.ignored_lowPriority" : "sync.score.ignored_lowPriority",
      context: .current(gameId: game.id)
    ) else {
      return
    }

    let description = resolveScoreDescription(playerId: playerId, fallbackName: playerName)
    try? await manager.scorePointAndLogEvent(
      for: team,
      in: game,
      at: delta.timestamp,
      customDescription: description
    )
    peerActivityState.recordScoreMutation()
    updateMutationSnapshot(&scoreMutationSnapshot, source: .remote, appliedAt: delta.createdAt)

    guard assignsServe else { return }
    try? await manager.setServer(to: team, in: game)
    peerActivityState.recordServeMutation()
    updateMutationSnapshot(&serveMutationSnapshot, source: .remote, appliedAt: delta.createdAt)
    updateMutationSnapshot(&serverAssignmentSnapshot, source: .remote, appliedAt: delta.createdAt)
  }

  private func resolveScoreDescription(
    playerId: UUID?,
    fallbackName: String?
  ) -> String? {
    if let fallbackName {
      return "\(fallbackName) scored"
    }
    guard let playerId else { return nil }
    if let storage = (gameManager?.storage as? SwiftDataStorage),
       let player = try? storage.loadPlayer(id: playerId) {
      return "\(player.name) scored"
    }
    return nil
  }

  // MARK: - Event forwarding hooks
  public var onReceiveRosterSnapshot: (@Sendable (RosterSnapshotDTO) -> Void)? {
    get { service.onReceiveRosterSnapshot }
    set { service.onReceiveRosterSnapshot = newValue }
  }

  // MARK: - Roster Sync Helpers

  private func sendRosterDiff() async throws {
    guard let storage = storage else { return }
    let builder = RosterSnapshotBuilder(storage: storage)
    let fullRoster = try builder.build(includeArchived: false, includeGuests: true)

    // Compute diff: items missing on watch or with newer lastModified
    var playersToSend: [BackupPlayerDTO] = []
    for player in fullRoster.players {
      if let watchModified = knownWatchRoster.players[player.id] {
        if player.lastModified > watchModified {
          playersToSend.append(player)
        }
      } else {
        playersToSend.append(player)
      }
    }

    var teamsToSend: [BackupTeamDTO] = []
    for team in fullRoster.teams {
      if let watchModified = knownWatchRoster.teams[team.id] {
        if team.lastModified > watchModified {
          teamsToSend.append(team)
        }
      } else {
        teamsToSend.append(team)
      }
    }

    var presetsToSend: [BackupPresetDTO] = []
    for preset in fullRoster.presets {
      if let watchModified = knownWatchRoster.presets[preset.id] {
        if preset.lastModified > watchModified {
          presetsToSend.append(preset)
        }
      } else {
        presetsToSend.append(preset)
      }
    }

    if !playersToSend.isEmpty || !teamsToSend.isEmpty || !presetsToSend.isEmpty {
      let upsert = RosterUpsertDTO(
        players: playersToSend,
        teams: teamsToSend,
        presets: presetsToSend
      )
      try await service.sendRosterUpsert(upsert)
      // Update known state after sending
      for player in playersToSend {
        knownWatchRoster.players[player.id] = player.lastModified
      }
      for team in teamsToSend {
        knownWatchRoster.teams[team.id] = team.lastModified
      }
      for preset in presetsToSend {
        knownWatchRoster.presets[preset.id] = preset.lastModified
      }
      Log.event(
        .saveSucceeded,
        level: .info,
        message: "roster.upsert.sent",
        metadata: [
          "players": "\(playersToSend.count)",
          "teams": "\(teamsToSend.count)",
          "presets": "\(presetsToSend.count)"
        ]
      )
    }
  }

  private func ensureParticipantsOnWatch(for config: GameStartConfiguration) async throws {
    guard let storage = storage else { return }

    // Collect all participant IDs
    var requiredPlayerIds: Set<UUID> = []
    var requiredTeamIds: Set<UUID> = []

    switch (config.participants.side1, config.participants.side2) {
    case (.players(let a), .players(let b)):
      requiredPlayerIds = Set(a + b)
    case (.team(let t1), .team(let t2)):
      requiredTeamIds = [t1, t2]
    default:
      break
    }

    // Check if any are missing or stale
    var needsUpsert = false
    var missingPlayerIds: Set<UUID> = []
    var missingTeamIds: Set<UUID> = []

    for playerId in requiredPlayerIds {
      if let watchModified = knownWatchRoster.players[playerId] {
        // Check if phone version is newer
        if let phonePlayer = try? storage.loadPlayer(id: playerId) {
          if phonePlayer.lastModified > watchModified {
            needsUpsert = true
            missingPlayerIds.insert(playerId)
          }
        }
      } else {
        // Missing entirely
        needsUpsert = true
        missingPlayerIds.insert(playerId)
      }
    }

    for teamId in requiredTeamIds {
      if let watchModified = knownWatchRoster.teams[teamId] {
        if let phoneTeam = try? storage.loadTeam(id: teamId) {
          if phoneTeam.lastModified > watchModified {
            needsUpsert = true
            missingTeamIds.insert(teamId)
          }
        }
      } else {
        needsUpsert = true
        missingTeamIds.insert(teamId)
      }
    }

    // Also need to include team members if sending teams
    if !missingTeamIds.isEmpty {
      for teamId in missingTeamIds {
        if let team = try? storage.loadTeam(id: teamId) {
          for player in team.players {
            if knownWatchRoster.players[player.id] == nil {
              missingPlayerIds.insert(player.id)
              needsUpsert = true
            }
          }
        }
      }
    }

    if needsUpsert {
      let builder = RosterSnapshotBuilder(storage: storage)
      let fullRoster = try builder.build(includeArchived: false, includeGuests: true)

      let playersToSend = fullRoster.players.filter { missingPlayerIds.contains($0.id) }
      let teamsToSend = fullRoster.teams.filter { missingTeamIds.contains($0.id) }

      let upsert = RosterUpsertDTO(
        players: playersToSend,
        teams: teamsToSend,
        presets: []
      )
      try await service.sendRosterUpsert(upsert)

      // Update known state
      for player in playersToSend {
        knownWatchRoster.players[player.id] = player.lastModified
      }
      for team in teamsToSend {
        knownWatchRoster.teams[team.id] = team.lastModified
      }

      Log.event(
        .saveSucceeded,
        level: .info,
        message: "roster.upsert.sent.beforeStart",
        metadata: [
          "players": "\(playersToSend.count)",
          "teams": "\(teamsToSend.count)"
        ]
      )
    }
  }

  // MARK: - Timer Pulse Helpers

  private func assumeLocalTimerLeadership() {
    if timerLeadership != .local {
      timerLeadership = .local
    }
    startTimerPulse()
  }

  private func assumeRemoteTimerLeadership() {
    if timerLeadership != .remote {
      timerLeadership = .remote
    }
    stopTimerPulse()
  }

  private func clearTimerLeadership() {
    if timerLeadership != .none {
      timerLeadership = .none
    }
    stopTimerPulse()
  }

  private func startTimerPulse() {
    guard timerPulseTask == nil else { return }
    guard let live = liveManager else { return }
    timerPulseTask = Task { [weak self] in
      // Send a pulse every ~1 second while we are leader and timer is running
      while let self, self.isTimerPulseLeader {
        if live.isTimerRunning, let current = live.currentGame {
          let elapsed = live.elapsedTime
          let now = Date()
          self.localActivityState.recordTimerPulse(at: now)
          self.updateMutationSnapshot(&self.timerMutationSnapshot, source: .local, appliedAt: now)
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

  private func recordTimerLeadershipChange(for leadership: TimerLeadership, at date: Date = Date()) {
    switch leadership {
    case .local:
      localActivityState.recordTimerLeadershipChange(at: date)
    case .remote:
      peerActivityState.recordTimerLeadershipChange(at: date)
    case .none:
      break
    }
  }

  private func localActivityScore(now: Date = Date()) -> Double {
    localActivityState.activityScore(now: now, lookbackWindow: activityLookbackWindow)
  }

  private func peerActivityScore(now: Date = Date()) -> Double {
    peerActivityState.activityScore(now: now, lookbackWindow: activityLookbackWindow)
  }

  private func preferredDeviceRole(now: Date = Date()) -> DeviceActivityRole {
    let localScore = localActivityScore(now: now)
    let peerScore = peerActivityScore(now: now)
    if abs(localScore - peerScore) <= activityTieBreakerEpsilon {
      return .local
    }
    return localScore >= peerScore ? .local : .peer
  }

  private func updateMutationSnapshot(
    _ snapshot: inout MutationPrioritySnapshot,
    source: DeviceMutationSource,
    appliedAt: Date
  ) {
    let now = Date()
    snapshot = MutationPrioritySnapshot(
      appliedAt: appliedAt,
      source: source,
      localScore: localActivityScore(now: now),
      peerScore: peerActivityScore(now: now)
    )
  }

  private func shouldAcceptRemoteMutation(
    createdAt: Date,
    snapshot: MutationPrioritySnapshot,
    label: String,
    context: LogContext?
  ) -> Bool {
    if createdAt >= snapshot.appliedAt + mutationTieWindow {
      return true
    }
    if createdAt <= snapshot.appliedAt - mutationTieWindow {
      logMutationRejection(
        label: label,
        context: context,
        createdAt: createdAt,
        snapshot: snapshot,
        reason: "olderThanWindow"
      )
      return false
    }

    let now = Date()
    let localScore = localActivityScore(now: now)
    let peerScore = peerActivityScore(now: now)

    if peerScore - localScore >= activityDominanceThreshold {
      return true
    }
    if localScore - peerScore >= activityDominanceThreshold {
      logMutationRejection(
        label: label,
        context: context,
        createdAt: createdAt,
        snapshot: snapshot,
        reason: "localDominant"
      )
      return false
    }

    if snapshot.source == .local {
      logMutationRejection(
        label: label,
        context: context,
        createdAt: createdAt,
        snapshot: snapshot,
        reason: "localTieBreaker"
      )
      return false
    }

    return true
  }

  private func logMutationRejection(
    label: String,
    context: LogContext?,
    createdAt: Date,
    snapshot: MutationPrioritySnapshot,
    reason: String
  ) {
    let resolvedContext = context ?? LogContext.current()
    let metadata: [String: String] = [
      "reason": reason,
      "incomingCreatedAt": createdAt.ISO8601Format(),
      "lastAppliedAt": snapshot.appliedAt.ISO8601Format(),
      "lastSource": "\(snapshot.source)",
      "snapshotLocalActivity": String(format: "%.3f", snapshot.localScore),
      "snapshotPeerActivity": String(format: "%.3f", snapshot.peerScore)
    ]
    Log.event(
      .realtimeEvent,
      level: .debug,
      message: label,
      context: resolvedContext,
      metadata: metadata
    )
  }

  private func shouldAcceptRemoteTimerMutation(createdAt: Date) -> Bool {
    if createdAt >= lastTimerSetReceivedAt + mutationTieWindow {
      return true
    }
    if createdAt <= lastTimerSetReceivedAt - mutationTieWindow {
      logMutationRejection(
        label: "sync.timer.ignored_lowPriority",
        context: nil,
        createdAt: createdAt,
        snapshot: timerMutationSnapshot,
        reason: "olderThanWindow"
      )
      return false
    }

    let now = Date()
    let localScore = localActivityScore(now: now)
    let peerScore = peerActivityScore(now: now)

    if peerScore - localScore >= activityDominanceThreshold {
      return true
    }
    if localScore - peerScore >= activityDominanceThreshold {
      logMutationRejection(
        label: "sync.timer.ignored_lowPriority",
        context: nil,
        createdAt: createdAt,
        snapshot: timerMutationSnapshot,
        reason: "localDominant"
      )
      return false
    }

    if timerMutationSnapshot.source == .local {
      logMutationRejection(
        label: "sync.timer.ignored_lowPriority",
        context: nil,
        createdAt: createdAt,
        snapshot: timerMutationSnapshot,
        reason: "localTieBreaker"
      )
      return false
    }

    return true
  }
}


