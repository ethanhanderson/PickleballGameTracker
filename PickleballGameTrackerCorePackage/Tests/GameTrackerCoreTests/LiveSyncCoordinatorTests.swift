//
//  LiveSyncCoordinatorTests.swift
//  GameTrackerCoreTests
//
//

import Testing
@testable import GameTrackerCore

import Foundation

@Suite("LiveSyncCoordinator Phone↔Watch pairing")
struct LiveSyncCoordinatorTests {

  // MARK: - Helpers

  @MainActor
  private func makePairedManagers() -> (
    phone: (storage: MockSwiftDataStorage, gameManager: SwiftDataGameManager, live: LiveGameStateManager, sync: LiveSyncCoordinator, transport: TestSyncService),
    watch: (storage: MockSwiftDataStorage, gameManager: SwiftDataGameManager, live: LiveGameStateManager, sync: LiveSyncCoordinator, transport: TestSyncService)
  ) {
    // Phone side
    let phoneStorage = MockSwiftDataStorage()
    let phoneGameManager = SwiftDataGameManager(storage: phoneStorage)
    let phoneLive = LiveGameStateManager()
    phoneLive.configure(gameManager: phoneGameManager)

    let phoneTransport = TestSyncService(role: .phone)
    let phoneSync = LiveSyncCoordinator(service: phoneTransport)
    phoneSync.bind(liveManager: phoneLive, gameManager: phoneGameManager)
    phoneSync.bind(storage: phoneStorage)
    phoneLive.configure(syncCoordinator: phoneSync)

    // Watch side
    let watchStorage = MockSwiftDataStorage()
    let watchGameManager = SwiftDataGameManager(storage: watchStorage)
    let watchLive = LiveGameStateManager()
    watchLive.configure(gameManager: watchGameManager)

    let watchTransport = TestSyncService(role: .watch)
    let watchSync = LiveSyncCoordinator(service: watchTransport)
    watchSync.bind(liveManager: watchLive, gameManager: watchGameManager)
    watchLive.configure(syncCoordinator: watchSync)

    // Connect transports
    phoneTransport.peer = watchTransport
    watchTransport.peer = phoneTransport

    return (
      phone: (phoneStorage, phoneGameManager, phoneLive, phoneSync, phoneTransport),
      watch: (watchStorage, watchGameManager, watchLive, watchSync, watchTransport)
    )
  }

  // MARK: - Tests

  @Test("Starting a game on phone publishes snapshot that brings watch into the same live game")
  @MainActor
  func phoneStartPropagatesSnapshotToWatch() async throws {
    let paired = makePairedManagers()
    let phone = paired.phone
    let watch = paired.watch

    // Create a new game on phone and set it as current.
    let game = try await phone.gameManager.createGame(type: .recreational)
    await phone.live.setCurrentGame(game)

    let snapshot = GameSnapshotBuilder.make(
      from: game,
      elapsedTime: phone.live.elapsedTime,
      isTimerRunning: phone.live.isTimerRunning
    )

    try await phone.sync.publish(snapshot: snapshot)

    // Allow async delivery.
    try? await Task.sleep(for: .milliseconds(10))

    let watchGame = watch.live.currentGame
    #require(watchGame != nil)
    #expect(watchGame?.id == game.id)
    #expect(watchGame?.gameType == game.gameType)
  }

  @Test("Completing a game on watch ends the live session on phone")
  @MainActor
  func watchCompletionEndsPhoneLiveSession() async throws {
    let paired = makePairedManagers()
    let phone = paired.phone
    let watch = paired.watch

    // Create a game on phone and share snapshot to watch so both track the same ID.
    let game = try await phone.gameManager.createGame(type: .recreational)
    game.gameState = .playing
    try await phone.gameManager.updateGame(game)
    await phone.live.setCurrentGame(game)
    phone.live.gameStateDidChange(to: .playing)

    let snapshot = GameSnapshotBuilder.make(
      from: game,
      elapsedTime: phone.live.elapsedTime,
      isTimerRunning: true
    )
    try await phone.sync.publish(snapshot: snapshot)
    try? await Task.sleep(for: .milliseconds(10))

    // Sanity: watch is tracking the same game.
    #require(watch.live.currentGame?.id == game.id)

    // Complete on watch side.
    try await watch.live.completeCurrentGame()

    // Allow completion delta to propagate.
    try? await Task.sleep(for: .milliseconds(20))

    // Phone should clear its live session and mark the game as completed.
    #expect(phone.live.currentGame == nil)
    let persistedOnPhone = try await phone.storage.loadGame(id: game.id)
    #require(persistedOnPhone != nil)
    #expect(persistedOnPhone?.isCompleted == true)
  }

  @Test("Completing an unused game on watch still clears the phone session")
  @MainActor
  func watchUnusedCompletionStillEndsPhoneLiveSession() async throws {
    let paired = makePairedManagers()
    let phone = paired.phone
    let watch = paired.watch

    let game = try await phone.gameManager.createGame(type: .recreational)
    game.gameState = .playing
    try await phone.gameManager.updateGame(game)
    await phone.live.setCurrentGame(game)
    phone.live.gameStateDidChange(to: .playing)

    let snapshot = GameSnapshotBuilder.make(
      from: game,
      elapsedTime: 0,
      isTimerRunning: true
    )
    try await phone.sync.publish(snapshot: snapshot)
    try? await Task.sleep(for: .milliseconds(10))

    #require(watch.live.currentGame?.id == game.id)
    watch.live.setElapsedTime(0)

    try await watch.live.completeCurrentGame()
    try? await Task.sleep(for: .milliseconds(30))

    #expect(watch.storage.deletedGameIds.contains(game.id))
    #expect(phone.live.currentGame == nil)

    let persistedOnPhone = try await phone.storage.loadGame(id: game.id)
    #require(persistedOnPhone != nil)
    #expect(persistedOnPhone?.gameState == .completed)
  }

  @Test("Timer setElapsedTime uses last-write-wins semantics on receiver")
  @MainActor
  func timerSetElapsedTimeLastWriteWins() async throws {
    let paired = makePairedManagers()
    let phone = paired.phone
    let watch = paired.watch

    // Start a playing game on phone and share to watch.
    let game = try await phone.gameManager.createGame(type: .recreational)
    game.gameState = .playing
    try await phone.gameManager.updateGame(game)
    await phone.live.setCurrentGame(game)
    phone.live.gameStateDidChange(to: .playing)

    let snapshot = GameSnapshotBuilder.make(
      from: game,
      elapsedTime: 0,
      isTimerRunning: true
    )
    try await phone.sync.publish(snapshot: snapshot)
    try? await Task.sleep(for: .milliseconds(10))

    #require(watch.live.currentGame?.id == game.id)

    let newerCreatedAt = Date()
    let olderCreatedAt = newerCreatedAt.addingTimeInterval(-5)

    let newerDelta = LiveGameDeltaDTO(
      gameId: game.id,
      createdAt: newerCreatedAt,
      timestamp: 12,
      operation: .setElapsedTime(elapsed: 12, isRunning: false)
    )

    let olderDelta = LiveGameDeltaDTO(
      gameId: game.id,
      createdAt: olderCreatedAt,
      timestamp: 3,
      operation: .setElapsedTime(elapsed: 3, isRunning: false)
    )

    // Deliver newer delta first, then an older one out of order.
    try await phone.sync.publish(delta: newerDelta)
    try await phone.sync.publish(delta: olderDelta)

    try? await Task.sleep(for: .milliseconds(20))

    let elapsed = watch.live.elapsedTime
    // The newer (12s) update should win; the older (3s) delta must not pull the timer back.
    #expect(elapsed >= 11.5)
    #expect(abs(elapsed - 3) > 1.0)
  }

  @Test("Cutthroat player scoring propagates player description to peer")
  @MainActor
  func cutthroatPlayerScoringPropagatesDescription() async throws {
    let paired = makePairedManagers()
    let phone = paired.phone
    let watch = paired.watch

    let player = PlayerProfile(
      name: "Jordan",
      accentColor: StoredRGBAColor(red: 0.8, green: 0.2, blue: 0.3)
    )

    let game = try await phone.gameManager.createGame(type: .cutthroat)
    game.participantMode = .players
    game.side1PlayerIds = [player.id]
    await phone.live.setCurrentGame(game)

    let snapshot = GameSnapshotBuilder.make(
      from: game,
      elapsedTime: 0,
      isTimerRunning: true
    )
    try await phone.sync.publish(snapshot: snapshot)
    try? await Task.sleep(for: .milliseconds(10))

    let delta = LiveGameDeltaDTO(
      gameId: game.id,
      timestamp: 4,
      operation: .score(
        team: 1,
        playerId: player.id,
        playerName: player.name
      )
    )

    try await watch.sync.publish(delta: delta)
    try? await Task.sleep(for: .milliseconds(20))

    let persisted = try await phone.storage.loadGame(id: game.id)
    #require(persisted != nil)
    #expect(persisted?.score1 == 1)
    #expect(persisted?.events.last?.customDescription == "\(player.name) scored")
  }

  @Test("Score assignments set serve on receiving device")
  @MainActor
  func scoreAssignmentSetsServe() async throws {
    let paired = makePairedManagers()
    let phone = paired.phone
    let watch = paired.watch

    let game = try await phone.gameManager.createGame(type: .recreational)
    game.gameState = .playing
    try await phone.gameManager.updateGame(game)
    await phone.live.setCurrentGame(game)
    phone.live.gameStateDidChange(to: .playing)

    let snapshot = GameSnapshotBuilder.make(
      from: game,
      elapsedTime: 0,
      isTimerRunning: true
    )
    try await phone.sync.publish(snapshot: snapshot)
    try? await Task.sleep(for: .milliseconds(10))

    let delta = LiveGameDeltaDTO(
      gameId: game.id,
      timestamp: 5,
      operation: .scoreAndSetServe(team: 2, playerId: nil, playerName: "Jordan")
    )

    try await watch.sync.publish(delta: delta)
    try? await Task.sleep(for: .milliseconds(20))

    let persisted = try await phone.storage.loadGame(id: game.id)
    #require(persisted != nil)
    #expect(persisted?.score2 == 1)
    #expect(persisted?.currentServer == 2)
  }

  @Test("Older score delta is ignored after newer score already applied")
  @MainActor
  func scoreDeltaLastWriteWins() async throws {
    let paired = makePairedManagers()
    let phone = paired.phone
    let watch = paired.watch

    let game = try await phone.gameManager.createGame(type: .recreational)
    await phone.live.setCurrentGame(game)

    let snapshot = GameSnapshotBuilder.make(
      from: game,
      elapsedTime: 0,
      isTimerRunning: true
    )
    try await phone.sync.publish(snapshot: snapshot)
    try? await Task.sleep(for: .milliseconds(10))

    let newerTime = Date()
    let newerDelta = LiveGameDeltaDTO(
      gameId: game.id,
      createdAt: newerTime,
      timestamp: 6,
      operation: .score(team: 1, playerId: nil, playerName: "Alex")
    )
    let olderDelta = LiveGameDeltaDTO(
      gameId: game.id,
      createdAt: newerTime.addingTimeInterval(-5),
      timestamp: 2,
      operation: .score(team: 1, playerId: nil, playerName: "Casey")
    )

    try await watch.sync.publish(delta: newerDelta)
    try? await Task.sleep(for: .milliseconds(20))
    var persisted = try await phone.storage.loadGame(id: game.id)
    #require(persisted != nil)
    let scoreAfterNewer = persisted?.score1 ?? 0

    try await watch.sync.publish(delta: olderDelta)
    try? await Task.sleep(for: .milliseconds(20))

    persisted = try await phone.storage.loadGame(id: game.id)
    #require(persisted != nil)
    let scoreAfterOlder = persisted?.score1 ?? 0

    #expect(scoreAfterOlder == scoreAfterNewer)
    #expect(persisted?.events.last?.customDescription == "Alex scored")
  }

  @Test("Remote score delta within tie window is ignored when local device is more active")
  @MainActor
  func remoteScoreDeltaIgnoredWhenLocalActive() async throws {
    let paired = makePairedManagers()
    let phone = paired.phone
    let watch = paired.watch

    let game = try await phone.gameManager.createGame(type: .recreational)
    await phone.live.setCurrentGame(game)
    let bootstrap = GameSnapshotBuilder.make(
      from: game,
      elapsedTime: 0,
      isTimerRunning: true
    )
    try await phone.sync.publish(snapshot: bootstrap)
    try? await Task.sleep(for: .milliseconds(20))

    try await phone.live.scorePoint(for: 1)
    try? await Task.sleep(for: .milliseconds(10))
    let referenceDate = Date()
    phone.sync.noteLocalScoreMutation(at: referenceDate)
    let scoreAfterLocal = try await phone.storage.loadGame(id: game.id)?.score1 ?? 0

    let remoteDelta = LiveGameDeltaDTO(
      gameId: game.id,
      createdAt: referenceDate.addingTimeInterval(0.05),
      timestamp: referenceDate.timeIntervalSince1970,
      operation: .score(team: 1, playerId: nil, playerName: "Watch")
    )
    try await watch.sync.publish(delta: remoteDelta)
    try? await Task.sleep(for: .milliseconds(40))

    let persisted = try await phone.storage.loadGame(id: game.id)
    #require(persisted != nil)
    #expect(persisted?.score1 == scoreAfterLocal)
  }

  @Test("Stale snapshot does not override active local score or timer")
  @MainActor
  func staleSnapshotIgnoredWhenLocalIsPreferred() async throws {
    let paired = makePairedManagers()
    let phone = paired.phone
    let watch = paired.watch

    let game = try await phone.gameManager.createGame(type: .recreational)
    await phone.live.setCurrentGame(game)
    let bootstrap = GameSnapshotBuilder.make(
      from: game,
      elapsedTime: 0,
      isTimerRunning: true
    )
    try await phone.sync.publish(snapshot: bootstrap)
    try? await Task.sleep(for: .milliseconds(20))

    try await phone.live.scorePoint(for: 1)
    phone.sync.noteLocalScoreMutation(at: Date())
    let scoreAfterLocal = try await phone.storage.loadGame(id: game.id)?.score1 ?? 0

    // Build a stale snapshot with outdated score and elapsed time.
    let staleSnapshot = bootstrap.with(
      snapshotCreatedAt: Date().addingTimeInterval(-10),
      score1: 0,
      elapsedTime: 0,
      isTimerRunning: false
    )
    try await watch.sync.publish(snapshot: staleSnapshot)
    try? await Task.sleep(for: .milliseconds(40))

    let persisted = try await phone.storage.loadGame(id: game.id)
    #require(persisted != nil)
    #expect(persisted?.score1 == scoreAfterLocal)
  }
}

private extension LiveGameSnapshotDTO {
  func with(
    snapshotCreatedAt: Date? = nil,
    score1: Int? = nil,
    score2: Int? = nil,
    elapsedTime: TimeInterval? = nil,
    isTimerRunning: Bool? = nil
  ) -> LiveGameSnapshotDTO {
    LiveGameSnapshotDTO(
      id: id,
      gameId: gameId,
      snapshotCreatedAt: snapshotCreatedAt ?? self.snapshotCreatedAt,
      elapsedTime: elapsedTime ?? self.elapsedTime,
      isTimerRunning: isTimerRunning ?? self.isTimerRunning,
      gameType: gameType,
      score1: score1 ?? self.score1,
      score2: score2 ?? self.score2,
      currentServer: currentServer,
      serverNumber: serverNumber,
      serverPosition: serverPosition,
      sideOfCourt: sideOfCourt,
      gameState: gameState,
      isFirstServiceSequence: isFirstServiceSequence,
      winningScore: winningScore,
      winByTwo: winByTwo,
      kitchenRule: kitchenRule,
      doubleBounceRule: doubleBounceRule,
      sideSwitchingRule: sideSwitchingRule,
      servingRotation: servingRotation,
      scoringType: scoringType,
      timeLimit: timeLimit,
      maxRallies: maxRallies,
      participantMode: participantMode,
      side1PlayerIds: side1PlayerIds,
      side2PlayerIds: side2PlayerIds,
      side1TeamId: side1TeamId,
      side2TeamId: side2TeamId
    )
  }
}

