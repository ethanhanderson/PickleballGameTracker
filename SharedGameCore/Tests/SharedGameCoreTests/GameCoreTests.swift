//
//  GameCoreTests.swift
//  SharedGameCore
//
//  Created by Ethan Anderson on 7/9/25.
//

import Foundation
import Testing

@testable import SharedGameCore

@Suite("Game Core Functionality")
struct GameCoreTests {

  // MARK: - Game Model Tests

  @Test("Game initialization with default values")
  func testGameInitialization() {
    let game = Game(gameType: .recreational)

    #expect(game.gameType == .recreational)
    #expect(game.score1 == 0)
    #expect(game.score2 == 0)
    #expect(game.isCompleted == false)
    #expect(game.currentServer == 1)
    #expect(game.serverPosition == .right)
    #expect(game.sideOfCourt == .side1)
    #expect(game.gameState == .initial)
    #expect(game.winningScore == 11)
    #expect(game.winByTwo == true)
    #expect(game.totalRallies == 0)
  }

  @Test("Game initialization with custom values")
  func testGameInitializationWithCustomValues() {
    let game = Game(
      gameType: .tournament,
      score1: 5,
      score2: 3,
      currentServer: 2,
      serverPosition: .left,
      sideOfCourt: .side2,
      gameState: .playing,
      winningScore: 15,
      winByTwo: false
    )

    #expect(game.gameType == .tournament)
    #expect(game.score1 == 5)
    #expect(game.score2 == 3)
    #expect(game.currentServer == 2)
    #expect(game.serverPosition == .left)
    #expect(game.sideOfCourt == .side2)
    #expect(game.gameState == .playing)
    #expect(game.winningScore == 15)
    #expect(game.winByTwo == false)
  }

  @Test("Score formatting")
  func testFormattedScore() {
    let game = Game(gameType: .recreational, score1: 11, score2: 9)
    #expect(game.formattedScore == "11 - 9")
  }

  @Test("Game completion workflow")
  func testGameCompletion() {
    let game = Game(gameType: .recreational, score1: 11, score2: 9)
    #expect(game.isCompleted == false)
    #expect(game.completedDate == nil)

    game.completeGame()

    #expect(game.isCompleted == true)
    #expect(game.completedDate != nil)
    #expect(game.gameState == .completed)
  }

  @Test("Game reset functionality")
  func testGameReset() {
    let game = Game(gameType: .recreational, score1: 11, score2: 9)
    game.completeGame()

    game.resetGame()

    #expect(game.score1 == 0)
    #expect(game.score2 == 0)
    #expect(game.isCompleted == false)
    #expect(game.completedDate == nil)
    #expect(game.currentServer == 1)
    #expect(game.serverPosition == .right)
    #expect(game.sideOfCourt == .side1)
    #expect(game.gameState == .initial)
  }

  @Test("Winner determination")
  func testWinnerDetermination() {
    // Incomplete game should have no winner
    let incompleteGame = Game(gameType: .recreational, score1: 11, score2: 5, isCompleted: false)
    #expect(incompleteGame.winner == nil)

    // Player 1 wins
    let player1Wins = Game(gameType: .recreational, score1: 11, score2: 5, isCompleted: true)
    #expect(player1Wins.winner == "Player 1")

    // Player 2 wins
    let player2Wins = Game(gameType: .recreational, score1: 5, score2: 11, isCompleted: true)
    #expect(player2Wins.winner == "Player 2")

    // Team game
    let teamWins = Game(gameType: .tournament, score1: 11, score2: 8, isCompleted: true)
    #expect(teamWins.winner == "Team 1")

    // Tie game
    let tieGame = Game(gameType: .recreational, score1: 11, score2: 11, isCompleted: true)
    #expect(tieGame.winner == "Tie")
  }

  // MARK: - Scoring Tests

  @Test("Basic scoring functionality")
  func testBasicScoring() {
    let game = Game(gameType: .recreational)

    game.scorePoint1()
    #expect(game.score1 == 1)
    #expect(game.score2 == 0)
    #expect(game.totalRallies == 1)
    #expect(game.gameState == .playing)

    game.scorePoint2()
    #expect(game.score1 == 1)
    #expect(game.score2 == 1)
    #expect(game.totalRallies == 2)
  }

  @Test("Score undo functionality")
  func testScoreUndo() {
    let game = Game(gameType: .recreational)
    game.scorePoint1()
    game.scorePoint2()

    #expect(game.score1 == 1)
    #expect(game.score2 == 1)
    #expect(game.totalRallies == 2)

    game.undoLastPoint()
    #expect(game.score1 == 1)
    #expect(game.score2 == 0)
    #expect(game.totalRallies == 1)
  }

  @Test("Undo prevents negative scores")
  func testUndoPreventNegativeScores() {
    let game = Game(gameType: .recreational, score1: 0, score2: 1)
    game.totalRallies = 1

    game.undoLastPoint()
    #expect(game.score1 == 0)
    #expect(game.score2 == 0)
    #expect(game.totalRallies == 0)
  }

  // MARK: - Game Completion Logic Tests

  @Test("Auto-completion at winning score")
  func testAutoCompletion() {
    let game = Game(gameType: .recreational, score1: 10, score2: 8)
    #expect(game.shouldComplete == false)

    game.scorePoint1()  // 11-8, should auto-complete
    #expect(game.shouldComplete == true)
    #expect(game.isCompleted == true)  // Auto-completion should have occurred
  }

  @Test("Win by two rule enforcement")
  func testWinByTwoRule() {
    let game = Game(gameType: .recreational, score1: 10, score2: 10, winByTwo: true)

    game.scorePoint1()  // 11-10, not complete due to win by two
    #expect(game.shouldComplete == false)
    #expect(game.isCompleted == false)

    game.scorePoint1()  // 12-10, should complete
    #expect(game.shouldComplete == true)
    #expect(game.isCompleted == true)
  }

  @Test("Match point detection")
  func testMatchPointDetection() {
    let game = Game(
      gameType: .recreational, score1: 10, score2: 8, winningScore: 11, winByTwo: true)

    #expect(game.isAtMatchPoint(team: 1) == true)  // 10→11 vs 8, wins
    #expect(game.isAtMatchPoint(team: 2) == false)  // 8→9 vs 10, doesn't win

    // Test with win by two requirement
    let tiedGame = Game(
      gameType: .recreational, score1: 10, score2: 10, winningScore: 11, winByTwo: true)
    #expect(tiedGame.isAtMatchPoint(team: 1) == false)  // 10→11 vs 10, need win by 2
    #expect(tiedGame.isAtMatchPoint(team: 2) == false)
  }

  // MARK: - Server Switching Tests

  @Test("Initial server state")
  func testInitialServerState() {
    let game = Game(gameType: .recreational)
    #expect(game.currentServer == 1)
    #expect(game.serverPosition == .right)
    #expect(game.sideOfCourt == .side1)
    #expect(game.gameState == .initial)
  }

  @Test("Automatic server switching on scoring")
  func testAutomaticServerSwitching() {
    let game = Game(gameType: .recreational)
    #expect(game.currentServer == 1)

    game.scorePoint1()
    #expect(game.currentServer == 2)
    #expect(game.gameState == .playing)

    game.scorePoint2()
    #expect(game.currentServer == 1)

    game.scorePoint1()
    #expect(game.currentServer == 2)
  }

  @Test("Side switching at 6 combined points (default rule)")
  func testSideSwitchingAtSix() {
    let game = Game(gameType: .recreational)
    #expect(game.sideOfCourt == .side1)

    // Reach combined score 6
    for _ in 0..<3 { game.scorePoint1() }  // 3-0
    for _ in 0..<3 { game.scorePoint2() }  // 3-3 (combined 6)

    // After the 6th point, side should switch once
    #expect(game.sideOfCourt == .side2)
  }

  @Test("Side switching rule: everyPoint toggles sides each rally")
  func testSideSwitchingEveryPoint() {
    let variation = GameVariation(
      name: "EveryPoint",
      gameType: .recreational,
      sideSwitchingRule: .everyPoint,
      scoringType: .sideOut
    )
    let game = Game(gameVariation: variation)
    #expect(game.sideOfCourt == .side1)

    game.scorePoint1()  // combined 1
    #expect(game.sideOfCourt == .side2)

    game.scorePoint2()  // combined 2
    #expect(game.sideOfCourt == .side1)
  }

  @Test("Side switching rule: halfway toggles at winningScore/2")
  func testSideSwitchingAtHalfway() {
    let variation = GameVariation(
      name: "Halfway",
      gameType: .recreational,
      winningScore: 10,
      sideSwitchingRule: .atHalfway,
      scoringType: .sideOut
    )
    let game = Game(gameVariation: variation)
    #expect(game.sideOfCourt == .side1)

    // Halfway is 5; reach combined 5
    for _ in 0..<3 { game.scorePoint1() }  // 3-0
    for _ in 0..<2 { game.scorePoint2() }  // 3-2 (combined 5)
    #expect(game.sideOfCourt == .side2)
  }

  @Test("Manual server switching")
  func testManualServerSwitching() {
    let game = Game(gameType: .recreational)
    #expect(game.currentServer == 1)

    game.switchServer()
    #expect(game.currentServer == 2)

    game.switchServer()
    #expect(game.currentServer == 1)
  }

  @Test("Server setting to specific team")
  func testServerSetting() {
    let game = Game(gameType: .recreational)

    game.setServer(to: 2)
    #expect(game.currentServer == 2)

    game.setServer(to: 1)
    #expect(game.currentServer == 1)

    // Invalid server numbers should be ignored
    game.setServer(to: 3)
    #expect(game.currentServer == 1)  // Should remain unchanged
  }
}

// MARK: - GameType Tests

@Suite("GameType Functionality")
struct GameTypeTests {

  @Test("GameType display names")
  func testDisplayNames() {
    #expect(GameType.recreational.displayName == "Recreational")
    #expect(GameType.tournament.displayName == "Tournament")
    #expect(GameType.training.displayName == "Training")
    #expect(GameType.social.displayName == "Social")
    #expect(GameType.custom.displayName == "Custom")
  }

  @Test("GameType player labels")
  func testPlayerLabels() {
    // Singles (team size 1)
    #expect(GameType.recreational.playerLabel1(teamSize: 1) == "Player 1")
    #expect(GameType.recreational.playerLabel2(teamSize: 1) == "Player 2")
    #expect(GameType.recreational.shortPlayerLabel1(teamSize: 1) == "P1")
    #expect(GameType.recreational.shortPlayerLabel2(teamSize: 1) == "P2")

    // Doubles (team size 2)
    #expect(GameType.recreational.playerLabel1(teamSize: 2) == "Team 1")
    #expect(GameType.recreational.playerLabel2(teamSize: 2) == "Team 2")
    #expect(GameType.recreational.shortPlayerLabel1(teamSize: 2) == "T1")
    #expect(GameType.recreational.shortPlayerLabel2(teamSize: 2) == "T2")
  }

  @Test("GameType raw values")
  func testRawValues() {
    #expect(GameType.recreational.rawValue == "recreational")
    #expect(GameType.tournament.rawValue == "tournament")
    #expect(GameType.training.rawValue == "training")
    #expect(GameType.social.rawValue == "social")
    #expect(GameType.custom.rawValue == "custom")
  }

  @Test("GameType enumeration completeness")
  func testAllCases() {
    let allCases = GameType.allCases
    #expect(allCases.count == 5)
    #expect(allCases.contains(.recreational))
    #expect(allCases.contains(.tournament))
    #expect(allCases.contains(.training))
    #expect(allCases.contains(.social))
    #expect(allCases.contains(.custom))
  }
}

// MARK: - Game State Enums Tests

@Suite("Game State Enums")
struct GameStateEnumTests {

  @Test("ServerPosition values")
  func testServerPositionValues() {
    #expect(ServerPosition.left.rawValue == "left")
    #expect(ServerPosition.right.rawValue == "right")
    #expect(ServerPosition.left.displayName == "Left")
    #expect(ServerPosition.right.displayName == "Right")
    #expect(ServerPosition.allCases.count == 2)
  }

  @Test("SideOfCourt values")
  func testSideOfCourtValues() {
    #expect(SideOfCourt.side1.rawValue == "side1")
    #expect(SideOfCourt.side2.rawValue == "side2")
    #expect(SideOfCourt.side1.displayName == "Side 1")
    #expect(SideOfCourt.side2.displayName == "Side 2")
    #expect(SideOfCourt.allCases.count == 2)
  }

  @Test("GameState values")
  func testGameStateValues() {
    #expect(GameState.serving.rawValue == "serving")
    #expect(GameState.playing.rawValue == "playing")
    #expect(GameState.completed.rawValue == "completed")
    #expect(GameState.paused.rawValue == "paused")

    #expect(GameState.serving.displayName == "Serving")
    #expect(GameState.playing.displayName == "Playing")
    #expect(GameState.completed.displayName == "Completed")
    #expect(GameState.paused.displayName == "Paused")
    #expect(GameState.allCases.count == 5)
  }
}
