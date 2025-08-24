//
//  ActiveGameSyncServiceTests.swift
//  SharedGameCoreTests
//
//  Unit tests for cross-device synchronization service
//

import XCTest

@testable import SharedGameCore

@MainActor
final class ActiveGameSyncServiceTests: XCTestCase {

  // MARK: - Properties

  private var syncService: ActiveGameSyncService!

  // MARK: - Setup & Teardown

  override func setUp() async throws {
    try await super.setUp()
    syncService = ActiveGameSyncService.shared
  }

  override func tearDown() async throws {
    syncService = nil
    try await super.tearDown()
  }

  // MARK: - Basic Service Tests

  func testSyncServiceInitialization() throws {
    XCTAssertNotNil(syncService)
    XCTAssertEqual(syncService.syncState, .disconnected)
    XCTAssertFalse(syncService.isSyncEnabled)
    XCTAssertNil(syncService.lastError)
  }

  func testSyncStateTransitions() async throws {
    let initialState = syncService.syncState
    XCTAssertEqual(initialState, .disconnected)

    // Test sync enabled/disabled
    syncService.setSyncEnabled(true)
    XCTAssertTrue(syncService.isSyncEnabled)

    syncService.setSyncEnabled(false)
    XCTAssertFalse(syncService.isSyncEnabled)
  }

  // MARK: - Message Schema Tests

  func testActiveGameStateDTOCreation() throws {
    let gameId = UUID()
    let dto = ActiveGameStateDTO(
      gameId: gameId,
      gameType: .recreational,
      createdDate: Date(),
      score1: 5,
      score2: 3,
      isCompleted: false,
      gameState: .playing,
      currentServer: 1,
      serverNumber: 1,
      serverPosition: .right,
      sideOfCourt: .side1,
      isFirstServiceSequence: true,
      elapsedSeconds: 150.0,
      isTimerRunning: true,
      lastTimerStartTime: Date(),
      winningScore: 11,
      winByTwo: true,
      kitchenRule: true,
      doubleBounceRule: true
    )

    XCTAssertEqual(dto.gameId, gameId)
    XCTAssertEqual(dto.gameType, .recreational)
    XCTAssertEqual(dto.score1, 5)
    XCTAssertEqual(dto.score2, 3)
    XCTAssertFalse(dto.isCompleted)
    XCTAssertEqual(dto.gameState, .playing)
    XCTAssertTrue(dto.isTimerRunning)
    XCTAssertEqual(dto.elapsedSeconds, 150.0)
  }

  func testHistoryGameDTOCreation() throws {
    let game = Game(
      gameType: .recreational,
      score1: 11,
      score2: 9,
      isCompleted: true,
      createdDate: Date(),
      lastModified: Date()
    )
    game.completedDate = Date()
    game.duration = 1800.0  // 30 minutes
    game.winningScore = 11
    game.notes = "Great game!"

    let dto = HistoryGameDTO(from: game)

    XCTAssertEqual(dto.id, game.id)
    XCTAssertEqual(dto.gameType, .recreational)
    XCTAssertEqual(dto.score1, 11)
    XCTAssertEqual(dto.score2, 9)
    XCTAssertTrue(dto.isCompleted)
    XCTAssertNotNil(dto.completedDate)
    XCTAssertEqual(dto.duration, 1800.0)
    XCTAssertEqual(dto.winningScore, 11)
    XCTAssertEqual(dto.notes, "Great game!")
  }

  func testSyncMessageSerialization() throws {
    let dto = ActiveGameStateDTO(
      gameId: UUID(),
      gameType: .training,
      createdDate: Date(),
      score1: 8,
      score2: 6,
      isCompleted: false,
      gameState: .serving,
      currentServer: 2,
      serverNumber: 2,
      serverPosition: .left,
      sideOfCourt: .side2,
      isFirstServiceSequence: false,
      elapsedSeconds: 300.0,
      isTimerRunning: false,
      lastTimerStartTime: nil,
      winningScore: 11,
      winByTwo: true,
      kitchenRule: true,
      doubleBounceRule: true
    )

    let message = SyncMessage.activeGameState(dto)

    // Test serialization
    let encoder = JSONEncoder()
    let data = try encoder.encode(message)
    XCTAssertGreaterThan(data.count, 0)

    // Test deserialization
    let decoder = JSONDecoder()
    let decodedMessage = try decoder.decode(SyncMessage.self, from: data)

    if case .activeGameState(let decodedDTO) = decodedMessage {
      XCTAssertEqual(decodedDTO.gameId, dto.gameId)
      XCTAssertEqual(decodedDTO.gameType, dto.gameType)
      XCTAssertEqual(decodedDTO.score1, dto.score1)
      XCTAssertEqual(decodedDTO.score2, dto.score2)
      XCTAssertEqual(decodedDTO.gameState, dto.gameState)
      XCTAssertEqual(decodedDTO.elapsedSeconds, dto.elapsedSeconds)
      XCTAssertEqual(decodedDTO.isTimerRunning, dto.isTimerRunning)
    } else {
      XCTFail("Failed to decode active game state message")
    }
  }

  func testTimerDriftDetection() throws {
    let dto = ActiveGameStateDTO(
      gameId: UUID(),
      gameType: .recreational,
      createdDate: Date(),
      score1: 0,
      score2: 0,
      isCompleted: false,
      gameState: .playing,
      currentServer: 1,
      serverNumber: 1,
      serverPosition: .right,
      sideOfCourt: .side1,
      isFirstServiceSequence: true,
      elapsedSeconds: 100.0,
      isTimerRunning: true,
      lastTimerStartTime: Date(),
      winningScore: 11,
      winByTwo: true,
      kitchenRule: true,
      doubleBounceRule: true
    )

    // Test no drift (within threshold)
    XCTAssertFalse(dto.hasSignificantTimerDrift(from: 100.5))
    XCTAssertFalse(dto.hasSignificantTimerDrift(from: 99.5))

    // Test significant drift (outside threshold)
    XCTAssertTrue(dto.hasSignificantTimerDrift(from: 102.0))
    XCTAssertTrue(dto.hasSignificantTimerDrift(from: 98.0))
  }

  // MARK: - Error Handling Tests

  func testSyncErrorTypes() throws {
    let errors: [SyncError] = [
      .watchConnectivityNotSupported,
      .sessionNotAvailable,
      .deviceNotReachable,
      .messageEncodingFailed(NSError(domain: "test", code: 1)),
      .messageDecodingFailed(NSError(domain: "test", code: 2)),
    ]

    for error in errors {
      XCTAssertNotNil(error.errorDescription)
      XCTAssertFalse(error.errorDescription!.isEmpty)
    }
  }
}

// MARK: - Test Helpers

extension ActiveGameSyncServiceTests {

  /// Create a test game for sync testing
  private func createTestGame() -> Game {
    let game = Game(
      gameType: .recreational,
      score1: 7,
      score2: 5,
      isCompleted: false,
      createdDate: Date(),
      lastModified: Date()
    )

    game.gameState = .playing
    game.currentServer = 1
    game.serverNumber = 1
    game.serverPosition = .right
    game.sideOfCourt = .side1
    game.isFirstServiceSequence = true

    return game
  }

  /// Create a test ActiveGameStateDTO
  private func createTestActiveGameStateDTO() -> ActiveGameStateDTO {
    return ActiveGameStateDTO(
      gameId: UUID(),
      gameType: .recreational,
      createdDate: Date().addingTimeInterval(-700),
      score1: 10,
      score2: 8,
      isCompleted: false,
      gameState: .playing,
      currentServer: 2,
      serverNumber: 2,
      serverPosition: .left,
      sideOfCourt: .side2,
      isFirstServiceSequence: false,
      elapsedSeconds: 600.0,
      isTimerRunning: true,
      lastTimerStartTime: Date().addingTimeInterval(-600),
      winningScore: 11,
      winByTwo: true,
      kitchenRule: true,
      doubleBounceRule: true
    )
  }
}
