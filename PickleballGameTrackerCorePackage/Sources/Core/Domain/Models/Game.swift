//
//  Game.swift
//  SharedGameCore
//
//  Created by Ethan Anderson on 7/9/25.
//

import Foundation
import SwiftData

@Model
public final class Game: Hashable {
  @Attribute(.unique) public var id: UUID
  public var gameType: GameType

  // Game Variation - new property for customization
  @Relationship public var gameVariation: GameVariation?

  // Basic Score Tracking
  public var score1: Int
  public var score2: Int
  public var isCompleted: Bool
  public var isArchived: Bool = false
  public var createdDate: Date
  public var completedDate: Date?
  public var lastModified: Date
  public var duration: TimeInterval?

  // Essential Game State
  public var currentServer: Int  // 1 or 2 (which team is serving)
  public var serverNumber: Int  // 1 or 2 (which player on the serving team is serving)
  public var serverPosition: ServerPosition  // left or right
  public var sideOfCourt: SideOfCourt  // side1 or side2
  public var gameState: GameState  // serving, playing, completed, paused
  public var isFirstServiceSequence: Bool  // true if this is the first service sequence of the game

  // Basic Game Settings (with variation support)
  public var winningScore: Int
  public var winByTwo: Bool

  // Essential Rule Settings (with variation support)
  public var kitchenRule: Bool
  public var doubleBounceRule: Bool

  // Optional Context
  public var notes: String?

  // Game statistics
  public var totalRallies: Int = 0

  public init(
    id: UUID = UUID(),
    gameType: GameType,
    gameVariation: GameVariation? = nil,
    score1: Int = 0,
    score2: Int = 0,
    isCompleted: Bool = false,
    isArchived: Bool = false,
    createdDate: Date = Date(),
    lastModified: Date = Date(),
    currentServer: Int = 1,
    serverNumber: Int = 1,
    serverPosition: ServerPosition = .right,
    sideOfCourt: SideOfCourt = .side1,
    gameState: GameState = .initial,
    isFirstServiceSequence: Bool = true,
    winningScore: Int? = nil,
    winByTwo: Bool? = nil,
    kitchenRule: Bool? = nil,
    doubleBounceRule: Bool? = nil,
    notes: String? = nil
  ) {
    self.id = id
    self.gameType = gameType
    self.gameVariation = gameVariation
    self.score1 = score1
    self.score2 = score2
    self.isCompleted = isCompleted
    self.createdDate = createdDate
    self.completedDate = nil
    self.lastModified = lastModified
    self.duration = nil
    self.isArchived = isArchived
    self.currentServer = currentServer
    self.serverNumber = serverNumber
    self.serverPosition = serverPosition
    self.sideOfCourt = sideOfCourt
    self.gameState = gameState
    self.isFirstServiceSequence = isFirstServiceSequence

    // Use variation settings if available, otherwise use defaults
    self.winningScore = winningScore ?? gameVariation?.winningScore ?? 11
    self.winByTwo = winByTwo ?? gameVariation?.winByTwo ?? true
    self.kitchenRule = kitchenRule ?? gameVariation?.kitchenRule ?? true
    self.doubleBounceRule = doubleBounceRule ?? gameVariation?.doubleBounceRule ?? true
    self.notes = notes
  }

  // Convenience initializer for creating games with variations
  public convenience init(gameVariation: GameVariation) {
    self.init(
      gameType: gameVariation.gameType,
      gameVariation: gameVariation,
      winningScore: gameVariation.winningScore,
      winByTwo: gameVariation.winByTwo,
      kitchenRule: gameVariation.kitchenRule,
      doubleBounceRule: gameVariation.doubleBounceRule
    )
  }
}

// MARK: - Game Extensions

extension Game {
  /// Formatted score string for display
  public var formattedScore: String {
    return "\(score1) - \(score2)"
  }

  /// Formatted date string
  public var formattedDate: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter.string(from: createdDate)
  }

  /// Formatted duration string
  public var formattedDuration: String? {
    guard let duration = duration else { return nil }
    let hours = Int(duration) / 3600
    let minutes = Int(duration) % 3600 / 60
    let seconds = Int(duration) % 60

    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    } else {
      return String(format: "%d:%02d", minutes, seconds)
    }
  }

  /// Winner of the game (if completed)
  public var winner: String? {
    guard isCompleted else { return nil }

    if score1 > score2 {
      return effectivePlayerLabel1
    } else if score2 > score1 {
      return effectivePlayerLabel2
    } else {
      return "Tie"
    }
  }

  /// Get effective player labels considering variation team sizes
  public var effectivePlayerLabel1: String {
    if let variation = gameVariation {
      return variation.playerLabel1
    }
    return gameType.playerLabel1
  }

  public var effectivePlayerLabel2: String {
    if let variation = gameVariation {
      return variation.playerLabel2
    }
    return gameType.playerLabel2
  }

  /// Get effective team size from variation or game type
  public var effectiveTeamSize: Int {
    return gameVariation?.teamSize ?? gameType.defaultTeamSize
  }

  /// Get the label for the currently serving player
  public var currentServingPlayerLabel: String {
    if effectiveTeamSize == 1 {
      return currentServer == 1 ? effectivePlayerLabel1 : effectivePlayerLabel2
    } else {
      let teamLabel = currentServer == 1 ? effectivePlayerLabel1 : effectivePlayerLabel2
      return "\(teamLabel) - Player \(serverNumber)"
    }
  }

  /// Get a short label for the currently serving player
  public var currentServingPlayerShortLabel: String {
    if effectiveTeamSize == 1 {
      return currentServer == 1 ? "P1" : "P2"
    } else {
      let teamPrefix = currentServer == 1 ? "T1" : "T2"
      return "\(teamPrefix)P\(serverNumber)"
    }
  }

  /// Check if a specific player on a team is currently serving
  public func isPlayerServing(team: Int, player: Int) -> Bool {
    return currentServer == team && serverNumber == player
  }

  /// Check if game meets winning conditions
  public var shouldComplete: Bool {
    let standardWin = (score1 >= winningScore || score2 >= winningScore)
    let winByTwoSatisfied = !winByTwo || abs(score1 - score2) >= 2

    // Check if time limit is reached (if set in variation)
    let timeLimitReached: Bool
    if let timeLimit = gameVariation?.timeLimit,
      let duration = duration
    {
      timeLimitReached = duration >= timeLimit
    } else {
      timeLimitReached = false
    }

    // Check if max rallies reached (if set in variation)
    let maxRalliesReached: Bool
    if let maxRallies = gameVariation?.maxRallies {
      maxRalliesReached = totalRallies >= maxRallies
    } else {
      maxRalliesReached = false
    }

    return (standardWin && winByTwoSatisfied) || timeLimitReached || maxRalliesReached
  }

  /// Check if a specific team is at match point (one point away from winning)
  public func isAtMatchPoint(team: Int) -> Bool {
    guard !isCompleted else { return false }
    guard team == 1 || team == 2 else { return false }

    // Simulate scoring one more point for this team
    let simulatedScore1 = team == 1 ? score1 + 1 : score1
    let simulatedScore2 = team == 2 ? score2 + 1 : score2

    // Check if this would result in a win
    let standardWin = (simulatedScore1 >= winningScore || simulatedScore2 >= winningScore)
    let winByTwoSatisfied = !winByTwo || abs(simulatedScore1 - simulatedScore2) >= 2

    return standardWin && winByTwoSatisfied
  }

  /// Get the next server based on current game state and official pickleball rules
  public var nextServer:
    (
      server: Int, serverNumber: Int, position: ServerPosition,
      side: SideOfCourt
    )
  {
    // Check if side switching should occur based on variation rules
    let shouldSwitchSide: Bool
    if let variation = gameVariation {
      shouldSwitchSide = variation.sideSwitchingRule.shouldSwitchSides(
        currentScore1: score1,
        currentScore2: score2,
        winningScore: winningScore
      )
    } else {
      // Default side switching logic - official pickleball rule
      shouldSwitchSide = (score1 + score2) == 6
    }

    let newSide: SideOfCourt =
      shouldSwitchSide ? (sideOfCourt == .side1 ? .side2 : .side1) : sideOfCourt

    // For singles, simple alternation by server position based on score
    if effectiveTeamSize == 1 {
      let newServer = currentServer == 1 ? 2 : 1
      let newPosition: ServerPosition = (score1 + score2) % 2 == 0 ? .right : .left
      return (server: newServer, serverNumber: 1, position: newPosition, side: newSide)
    }

    // For doubles, follow official pickleball service sequence rules
    // When serving team scores: server switches positions but stays serving
    // When serving team faults: serve passes to partner (if first server) or to other team

    // The serving team scored a point - same server switches sides
    let totalScore = score1 + score2
    let newPosition: ServerPosition = totalScore % 2 == 0 ? .right : .left

    return (server: currentServer, serverNumber: serverNumber, position: newPosition, side: newSide)
  }

  /// Complete the game
  public func completeGame(at date: Date = Date()) {
    isCompleted = true
    completedDate = date
    gameState = .completed
    duration = date.timeIntervalSince(createdDate)
    lastModified = Date()
  }

  /// Reset the game to initial state
  public func resetGame() {
    score1 = 0
    score2 = 0
    isCompleted = false
    completedDate = nil
    duration = nil
    currentServer = 1
    serverNumber = 1
    serverPosition = .right
    sideOfCourt = .side1
    gameState = .initial
    isFirstServiceSequence = true
    totalRallies = 0
    lastModified = Date()
  }

  /// Resume from pause
  public func resumeGame() {
    gameState = .playing
    lastModified = Date()
  }

  /// Pause the game
  public func pauseGame() {
    gameState = .paused
    lastModified = Date()
  }

  /// Score a point for team/player 1
  public func scorePoint1() {
    guard !isCompleted else { return }
    score1 += 1
    totalRallies += 1
    lastModified = Date()

    // Update server state based on pickleball rules
    let nextServerInfo = nextServer
    currentServer = nextServerInfo.server
    serverNumber = nextServerInfo.serverNumber
    serverPosition = nextServerInfo.position
    sideOfCourt = nextServerInfo.side

    // Update game state to playing if needed
    if gameState == .initial || gameState == .serving {
      gameState = .playing
    }

    // Check if game should complete
    if shouldComplete {
      completeGame()
    }
  }

  /// Score a point for team/player 2
  public func scorePoint2() {
    guard !isCompleted else { return }
    score2 += 1
    totalRallies += 1
    lastModified = Date()

    // Update server state based on pickleball rules
    let nextServerInfo = nextServer
    currentServer = nextServerInfo.server
    serverNumber = nextServerInfo.serverNumber
    serverPosition = nextServerInfo.position
    sideOfCourt = nextServerInfo.side

    // Update game state to playing if needed
    if gameState == .initial || gameState == .serving {
      gameState = .playing
    }

    // Check if game should complete
    if shouldComplete {
      completeGame()
    }
  }

  /// Undo the last point scored
  public func undoLastPoint() {
    guard totalRallies > 0 else { return }

    // Simple undo - reduce the higher score
    if score1 > score2 {
      score1 = max(0, score1 - 1)
    } else if score2 > score1 {
      score2 = max(0, score2 - 1)
    } else if score1 > 0 && score2 > 0 {
      // If tied, reduce score2 (most recent)
      score2 = max(0, score2 - 1)
    }

    totalRallies = max(0, totalRallies - 1)

    // Recalculate server state based on new score
    // Note: This is a simplified approach. A more robust solution would track
    // the actual serving history, but this works for basic undo functionality.
    if totalRallies == 0 {
      // Reset to initial serving state
      currentServer = 1
      serverNumber = 1
      serverPosition = .right
      sideOfCourt = .side1
      gameState = .initial
      isFirstServiceSequence = true
    } else {
      // Recalculate based on current scores (simplified approach)
      let totalScore = score1 + score2

      // For singles
      if effectiveTeamSize == 1 {
        currentServer = (totalScore % 2 == 0) ? 1 : 2
        serverNumber = 1
      } else {
        // For doubles - simplified approach that may not be perfect after undo
        // but provides reasonable behavior
        currentServer = (totalScore % 2 == 0) ? 1 : 2
        serverNumber = 1  // Reset to first server for simplicity
      }

      serverPosition = (totalScore % 2 == 0) ? .right : .left

      // Side switching logic (simplified) - official pickleball rule
      sideOfCourt = (score1 + score2) >= 6 ? .side2 : .side1
      gameState = .serving
      isFirstServiceSequence = (totalScore <= 2)  // Approximate first sequence tracking
    }

    // Reset completion state if needed
    isCompleted = false
    completedDate = nil
    lastModified = Date()
  }

  /// Manually switch the serving team (for corrections or rule variations)
  public func switchServer() {
    guard !isCompleted else { return }
    currentServer = currentServer == 1 ? 2 : 1
    lastModified = Date()
  }

  /// Manually set the serving team (for game setup or corrections)
  public func setServer(to team: Int) {
    guard !isCompleted else { return }
    guard team == 1 || team == 2 else { return }
    currentServer = team
    lastModified = Date()
  }

  /// Switch the serving player within the current serving team (for doubles)
  public func switchServingPlayer() {
    guard !isCompleted else { return }
    guard effectiveTeamSize > 1 else { return }  // Only applicable to doubles/multi-player teams
    serverNumber = serverNumber == 1 ? 2 : 1
    lastModified = Date()
  }

  /// Set the serving player within the current serving team
  public func setServingPlayer(to player: Int) {
    guard !isCompleted else { return }
    guard player == 1 || player == 2 else { return }
    guard effectiveTeamSize > 1 else { return }  // Only applicable to doubles/multi-player teams
    serverNumber = player
    lastModified = Date()
  }

  /// Handle service fault - switches to partner or other team based on pickleball rules
  public func handleServiceFault() {
    guard !isCompleted else { return }
    guard effectiveTeamSize > 1 else {
      // Singles - just switch teams
      switchServer()
      return
    }

    // Doubles service fault handling
    if isFirstServiceSequence {
      // First service sequence - only one player serves, then switch teams
      currentServer = currentServer == 1 ? 2 : 1
      serverNumber = 1
      isFirstServiceSequence = false
    } else {
      // Regular service sequence
      if serverNumber == 1 {
        // First server faulted, switch to second server on same team
        serverNumber = 2
      } else {
        // Second server faulted, switch teams and reset to first server
        currentServer = currentServer == 1 ? 2 : 1
        serverNumber = 1
      }
    }

    lastModified = Date()
  }

  // MARK: - Hashable Conformance

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  public static func == (lhs: Game, rhs: Game) -> Bool {
    return lhs.id == rhs.id
  }
}
