import Testing
@testable import GameTrackerCore

@Suite("Game serve fault handling")
struct GameServeLogicTests {

  @Test("Singles service faults immediately switch serving team")
  @MainActor
  func singlesFaultsSwitchServe() {
    let game = Game(gameType: .recreational)
    game.teamSize = 1
    game.gameState = .playing
    game.currentServer = 1
    game.serverNumber = 1

    game.handleServiceFault()
    #expect(game.currentServer == 2)
    #expect(game.serverNumber == 1)

    game.handleServiceFault()
    #expect(game.currentServer == 1)
    #expect(game.serverNumber == 1)
  }

  @Test("First service sequence fault moves to opposing team before partner rotation")
  @MainActor
  func firstSequenceFaultAdvancesToOpposingTeam() {
    let game = Game(gameType: .recreational)
    game.teamSize = 2
    game.gameState = .playing
    game.currentServer = 1
    game.serverNumber = 1
    game.isFirstServiceSequence = true

    game.handleServiceFault()

    #expect(game.currentServer == 2)
    #expect(game.serverNumber == 1)
    #expect(game.isFirstServiceSequence == false)
  }

  @Test("Standard doubles rotation advances partner first, then switches sides")
  @MainActor
  func doublesFaultRotation() {
    let game = Game(gameType: .recreational)
    game.teamSize = 2
    game.gameState = .playing
    game.currentServer = 1
    game.serverNumber = 1
    game.isFirstServiceSequence = false

    game.handleServiceFault()
    #expect(game.currentServer == 1)
    #expect(game.serverNumber == 2)

    game.handleServiceFault()
    #expect(game.currentServer == 2)
    #expect(game.serverNumber == 1)

    game.handleServiceFault()
    #expect(game.currentServer == 2)
    #expect(game.serverNumber == 2)

    game.handleServiceFault()
    #expect(game.currentServer == 1)
    #expect(game.serverNumber == 1)
  }
}

