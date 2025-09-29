import Testing
import SwiftData
@testable import GameTrackerCore

@Suite("LiveGameStateManager startNewGame(with:) configuration validation")
struct LiveGameStateManager_StartConfigTests {

  @Test("Singles requires exactly one player per side")
  @MainActor
  func singlesPlayerCountValidation() async throws {
    let container = PreviewEnvironment.empty().container
    let manager = LiveGameStateManager.preview(container: container)
    let cfg = GameStartConfiguration(
      gameType: .recreational,
      teamSize: .singles,
      participants: Participants(side1: .players([]), side2: .players([UUID()]))
    )
    await #expect(throws: GameVariationError.self) {
      _ = try await manager.startNewGame(with: cfg)
    }
  }

  @Test("Doubles players mode requires two players per side")
  @MainActor
  func doublesPlayersCountValidation() async throws {
    let container = PreviewEnvironment.empty().container
    let manager = LiveGameStateManager.preview(container: container)
    let cfg = GameStartConfiguration(
      gameType: .recreational,
      teamSize: .doubles,
      participants: Participants(side1: .players([UUID()]), side2: .players([UUID(), UUID()]))
    )
    await #expect(throws: GameVariationError.self) {
      _ = try await manager.startNewGame(with: cfg)
    }
  }

  @Test("Valid singles players start succeeds and sets current game")
  @MainActor
  func validSinglesStart() async throws {
    let container = PreviewEnvironment.empty().container
    let manager = LiveGameStateManager.preview(container: container)
    let p1 = UUID(), p2 = UUID()
    let cfg = GameStartConfiguration(
      gameType: .recreational,
      teamSize: .singles,
      participants: Participants(side1: .players([p1]), side2: .players([p2]))
    )

    let game = try await manager.startNewGame(with: cfg)
    #expect(manager.currentGame?.id == game.id)
    #expect(game.gameType == .recreational)
    #expect(game.effectiveTeamSize == 1)
  }
}


