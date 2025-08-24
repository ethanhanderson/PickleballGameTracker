//
//  HapticFeedbackServiceTests.swift
//  SharedGameCoreTests
//
//  Unit tests for haptic feedback service
//

import XCTest

@testable import SharedGameCore

@MainActor
final class HapticFeedbackServiceTests: XCTestCase {

  // MARK: - Properties

  private var hapticService: HapticFeedbackService!

  // MARK: - Setup & Teardown

  override func setUp() async throws {
    try await super.setUp()
    hapticService = HapticFeedbackService.shared
  }

  override func tearDown() async throws {
    hapticService = nil
    try await super.tearDown()
  }

  // MARK: - Basic Service Tests

  func testHapticServiceInitialization() throws {
    XCTAssertNotNil(hapticService)
    XCTAssertTrue(hapticService.isEnabled)  // Should be enabled by default
  }

  func testHapticServiceEnabledState() throws {
    // Test enable/disable functionality
    hapticService.isEnabled = true
    XCTAssertTrue(hapticService.isEnabled)

    hapticService.isEnabled = false
    XCTAssertFalse(hapticService.isEnabled)

    // Reset to enabled state
    hapticService.isEnabled = true
  }

  // MARK: - Haptic Method Tests

  func testHapticMethods() throws {
    // Test that all haptic methods can be called without crashing
    // On simulator/test environment, these are essentially no-ops

    XCTAssertNoThrow(hapticService.scoreAction())
    XCTAssertNoThrow(hapticService.serveChange())
    XCTAssertNoThrow(hapticService.gameStateChange())
    XCTAssertNoThrow(hapticService.timerToggle())
    XCTAssertNoThrow(hapticService.gameComplete())
    XCTAssertNoThrow(hapticService.gameStart())
    XCTAssertNoThrow(hapticService.buttonSelection())
    XCTAssertNoThrow(hapticService.error())
    XCTAssertNoThrow(hapticService.warning())
    XCTAssertNoThrow(hapticService.prepareGenerators())
  }

  func testHapticMethodsWhenDisabled() throws {
    // Test that haptics don't trigger when disabled
    hapticService.isEnabled = false

    // These should still execute without error but not trigger actual haptics
    XCTAssertNoThrow(hapticService.scoreAction())
    XCTAssertNoThrow(hapticService.serveChange())
    XCTAssertNoThrow(hapticService.gameComplete())
    XCTAssertNoThrow(hapticService.timerToggle())

    // Re-enable for other tests
    hapticService.isEnabled = true
  }

  // MARK: - Game Action Tests

  func testGameActionHaptics() throws {
    let gameActions: [GameAction] = [
      .scoreTeam1,
      .scoreTeam2,
      .serveChange,
      .gameStateChange,
      .timerStart,
      .timerStop,
      .gameComplete,
      .gameStart,
      .buttonPress,
      .error,
      .warning,
    ]

    // Test that all game actions can be triggered without error
    for action in gameActions {
      XCTAssertNoThrow(hapticService.gameAction(action))
    }
  }

  func testGameActionMapping() throws {
    // Verify that different game actions map to appropriate haptic types
    // This is mainly ensuring the switch statement covers all cases

    let scoreActions: [GameAction] = [.scoreTeam1, .scoreTeam2]
    let timerActions: [GameAction] = [.timerStart, .timerStop]
    let notificationActions: [GameAction] = [.gameComplete, .error, .warning]

    for action in scoreActions + timerActions + notificationActions + [
      .serveChange, .gameStateChange, .gameStart, .buttonPress,
    ] {
      XCTAssertNoThrow(hapticService.gameAction(action))
    }
  }

  // MARK: - Singleton Tests

  func testSingletonBehavior() throws {
    let instance1 = HapticFeedbackService.shared
    let instance2 = HapticFeedbackService.shared

    // Verify singleton behavior - same instance
    XCTAssertTrue(instance1 === instance2)

    // Verify shared state
    instance1.isEnabled = false
    XCTAssertFalse(instance2.isEnabled)

    instance1.isEnabled = true
    XCTAssertTrue(instance2.isEnabled)
  }

  // MARK: - Performance Tests

  func testHapticPerformance() throws {
    // Measure performance of haptic calls
    measure {
      for _ in 0..<100 {
        hapticService.scoreAction()
      }
    }
  }

  func testPrepareGeneratorsPerformance() throws {
    // Measure performance of generator preparation
    measure {
      hapticService.prepareGenerators()
    }
  }
}
