//
//  PreviewData.swift
//  SharedGameCore
//
//  Created by Ethan Anderson on 1/27/25.
//

import Foundation
import SwiftData

/// Centralized preview data provider for all views in the Pickleball Score Tracking app
@MainActor
public struct PreviewGameData {

  // MARK: - Common Game Manager

  /// Standard game manager for preview use
  public static let gameManager = SwiftDataGameManager()

  // MARK: - Single Game Scenarios

  /// Early game state (low scores)
  public static let earlyGame: Game = {
    let game = Game(gameType: .recreational)
    game.score1 = 2
    game.score2 = 3
    game.currentServer = 1
    game.gameState = .playing
    game.totalRallies = 5
    game.lastModified = Date()
    return game
  }()

  /// Mid-game state (moderate scores)
  public static let midGame: Game = {
    let game = Game(gameType: .recreational)
    game.score1 = 7
    game.score2 = 5
    game.currentServer = 2
    game.gameState = .playing
    game.totalRallies = 15
    game.lastModified = Date()
    return game
  }()

  /// Close game state (near winning)
  public static let closeGame: Game = {
    let game = Game(gameType: .recreational)
    game.score1 = 10
    game.score2 = 9
    game.currentServer = 1
    game.gameState = .playing
    game.totalRallies = 25
    game.lastModified = Date()
    return game
  }()

  /// Match point scenario
  public static let matchPointGame: Game = {
    let game = Game(gameType: .recreational)
    game.score1 = 10
    game.score2 = 8
    game.currentServer = 1
    game.gameState = .playing
    game.totalRallies = 22
    game.lastModified = Date()
    return game
  }()

  /// Completed game (Team 1 wins)
  public static let completedGame: Game = {
    let game = Game(gameType: .recreational)
    game.score1 = 11
    game.score2 = 7
    game.isCompleted = true
    game.completedDate = Date()
    game.duration = 25 * 60  // 25 minutes
    game.totalRallies = 20
    game.lastModified = Date()
    return game
  }()

  /// High-scoring tournament game
  public static let highScoreGame: Game = {
    let game = Game(gameType: .tournament)
    game.score1 = 15
    game.score2 = 13
    game.currentServer = 2
    game.gameState = .playing
    game.totalRallies = 35
    game.lastModified = Date()
    return game
  }()

  /// Training game (shorter format)
  public static let trainingGame: Game = {
    let game = Game(gameType: .training)
    game.score1 = 6
    game.score2 = 4
    game.currentServer = 1
    game.gameState = .playing
    game.totalRallies = 12
    game.lastModified = Date()
    return game
  }()

  /// Paused game
  public static let pausedGame: Game = {
    let game = Game(gameType: .recreational)
    game.score1 = 5
    game.score2 = 6
    game.currentServer = 2
    game.gameState = .paused
    game.totalRallies = 14
    game.lastModified = Date()
    return game
  }()

  // MARK: - Serving Scenarios

  /// Team 1 serving, player 1
  public static let team1Player1Serving: Game = {
    let game = Game(gameType: .recreational)
    game.score1 = 5
    game.score2 = 3
    game.currentServer = 1
    game.serverNumber = 1
    game.gameState = .playing
    game.totalRallies = 10
    return game
  }()

  /// Team 1 serving, player 2
  public static let team1Player2Serving: Game = {
    let game = Game(gameType: .recreational)
    game.score1 = 7
    game.score2 = 5
    game.currentServer = 1
    game.serverNumber = 2
    game.gameState = .playing
    game.totalRallies = 15
    return game
  }()

  /// Team 2 serving
  public static let team2Serving: Game = {
    let game = Game(gameType: .recreational)
    game.score1 = 4
    game.score2 = 6
    game.currentServer = 2
    game.serverNumber = 1
    game.gameState = .playing
    game.totalRallies = 12
    return game
  }()

  // MARK: - Historical Game Collections

  /// Games representing a competitive player's recent history
  public static let competitivePlayerGames: [Game] = [
    createCompletedGame(.recreational, 11, 9, hoursAgo: 1, duration: 28 * 60, rallies: 24),
    createCompletedGame(.tournament, 15, 13, hoursAgo: 6, duration: 40 * 60, rallies: 32),
    createCompletedGame(.recreational, 11, 13, daysAgo: 1, duration: 35 * 60, rallies: 28),
    createCompletedGame(.training, 7, 5, daysAgo: 2, duration: 18 * 60, rallies: 14),
    createCompletedGame(.recreational, 12, 10, daysAgo: 3, duration: 32 * 60, rallies: 26),
  ]

  /// Games representing a recreational player's history
  public static let recreationalPlayerGames: [Game] = [
    createCompletedGame(.recreational, 11, 6, hoursAgo: 2, duration: 22 * 60, rallies: 18),
    createCompletedGame(.training, 7, 8, daysAgo: 1, duration: 15 * 60, rallies: 10),
    createCompletedGame(.recreational, 11, 8, daysAgo: 3, duration: 25 * 60, rallies: 16),
    createCompletedGame(.training, 6, 7, daysAgo: 5, duration: 12 * 60, rallies: 8),
  ]

  /// Games representing a new player learning
  public static let newPlayerGames: [Game] = [
    createCompletedGame(.training, 7, 11, hoursAgo: 3, duration: 20 * 60, rallies: 8),
    createCompletedGame(.recreational, 8, 11, daysAgo: 1, duration: 25 * 60, rallies: 12),
    createCompletedGame(.training, 11, 9, daysAgo: 2, duration: 18 * 60, rallies: 10),
  ]

  /// Games representing a player on a hot streak
  public static let hotStreakPlayerGames: [Game] = [
    createCompletedGame(.recreational, 11, 7, hoursAgo: 2, duration: 25 * 60, rallies: 15),
    createCompletedGame(.training, 7, 4, hoursAgo: 8, duration: 18 * 60, rallies: 8),
    createCompletedGame(.recreational, 11, 8, daysAgo: 1, duration: 22 * 60, rallies: 12),
    createCompletedGame(.tournament, 15, 12, daysAgo: 2, duration: 35 * 60, rallies: 20),
    createCompletedGame(.recreational, 11, 6, daysAgo: 3, duration: 20 * 60, rallies: 10),
  ]

  /// Games representing a dominant player
  public static let dominantPlayerGames: [Game] = [
    createCompletedGame(.recreational, 11, 3, hoursAgo: 4, duration: 22 * 60, rallies: 12),
    createCompletedGame(.training, 7, 2, daysAgo: 1, duration: 15 * 60, rallies: 6),
    createCompletedGame(.tournament, 15, 6, daysAgo: 2, duration: 28 * 60, rallies: 18),
    createCompletedGame(.recreational, 11, 4, daysAgo: 4, duration: 20 * 60, rallies: 10),
  ]

  /// Empty game collection for testing empty states
  public static let emptyGames: [Game] = []

  /// Mixed game types for comprehensive testing
  public static let mixedGames: [Game] = [
    earlyGame,
    completedGame,
    closeGame,
    trainingGame,
    highScoreGame,
  ]

  // MARK: - Roster (Players/Teams)

  /// Sample players for roster previews (includes both active and archived)
  public static let samplePlayers: [PlayerProfile] = {
    let ethan = PlayerProfile(
      name: "Ethan",
      avatarImageData: nil,
      iconSymbolName: "tennis.racket",
      iconTintColor: .blue,
      skillLevel: .advanced,
      preferredHand: .right
    )
    let reed = PlayerProfile(
      name: "Reed",
      avatarImageData: nil,
      iconSymbolName: "figure.tennis",
      iconTintColor: .green,
      skillLevel: .intermediate,
      preferredHand: .right
    )
    let ricky = PlayerProfile(
      name: "Ricky",
      avatarImageData: nil,
      iconSymbolName: "figure.walk",
      iconTintColor: .orange,
      skillLevel: .beginner,
      preferredHand: .left
    )
    let dave = PlayerProfile(
      name: "Dave",
      avatarImageData: nil,
      iconSymbolName: "medal.fill",
      iconTintColor: .purple,
      skillLevel: .expert,
      preferredHand: .right
    )

    // Archived players
    let archivedAlex = PlayerProfile(
      name: "Alex",
      avatarImageData: nil,
      iconSymbolName: "person.fill",
      iconTintColor: .brown,
      skillLevel: .intermediate,
      preferredHand: .right
    )
    archivedAlex.isArchived = true

    let archivedJordan = PlayerProfile(
      name: "Jordan",
      avatarImageData: nil,
      iconSymbolName: "person.fill",
      iconTintColor: .indigo,
      skillLevel: .advanced,
      preferredHand: .left
    )
    archivedJordan.isArchived = true

    return [ethan, reed, ricky, dave, archivedAlex, archivedJordan]
  }()

  /// Sample teams for roster previews (includes both active and archived)
  public static let sampleTeams: [TeamProfile] = {
    let t1 = TeamProfile(
      name: "Ethan & Reed",
      avatarImageData: nil,
      iconSymbolName: "person.2.fill",
      iconTintColor: .teal,
      players: [samplePlayers[0], samplePlayers[1]]
    )
    let t2 = TeamProfile(
      name: "Ricky & Dave",
      avatarImageData: nil,
      iconSymbolName: "figure.mind.and.body",
      iconTintColor: .pink,
      players: [samplePlayers[2], samplePlayers[3]]
    )

    // Archived teams
    let archivedTeam1 = TeamProfile(
      name: "Alex & Jordan",
      avatarImageData: nil,
      iconSymbolName: "person.2.fill",
      iconTintColor: .brown,
      players: [samplePlayers[4], samplePlayers[5]]  // archived players
    )
    archivedTeam1.isArchived = true

    let archivedTeam2 = TeamProfile(
      name: "Old Veterans",
      avatarImageData: nil,
      iconSymbolName: "trophy.fill",
      iconTintColor: .indigo,
      players: [samplePlayers[0], samplePlayers[3]]  // mix of active and archived players
    )
    archivedTeam2.isArchived = true

    return [t1, t2, archivedTeam1, archivedTeam2]
  }()

  /// Creates a model container populated with roster data for previews
  public static func createRosterPreviewContainer(
    players: [PlayerProfile] = samplePlayers,
    teams: [TeamProfile] = sampleTeams
  ) throws -> ModelContainer {
    let schema = Schema([
      Game.self, GameVariation.self, GameSummary.self, PlayerProfile.self, TeamProfile.self,
      GameTypePreset.self,
    ])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try ModelContainer(
      for: schema,
      configurations: [config]
    )
    let context = container.mainContext
    // Deep-clone players and teams into this container to avoid cross-container @Model reuse
    var oldIdToNewPlayer: [UUID: PlayerProfile] = [:]
    for src in players {
      let clone = PlayerProfile(
        id: src.id,
        name: src.name,
        notes: src.notes,
        isArchived: src.isArchived,
        avatarImageData: src.avatarImageData,
        iconSymbolName: src.iconSymbolName,
        iconTintColor: src.iconTintColor,
        skillLevel: src.skillLevel,
        preferredHand: src.preferredHand,
        createdDate: src.createdDate,
        lastModified: Date()
      )
      context.insert(clone)
      oldIdToNewPlayer[src.id] = clone
    }
    for src in teams {
      let remappedPlayers: [PlayerProfile] = src.players.compactMap { oldIdToNewPlayer[$0.id] }
      let clone = TeamProfile(
        id: src.id,
        name: src.name,
        notes: src.notes,
        isArchived: src.isArchived,
        avatarImageData: src.avatarImageData,
        iconSymbolName: src.iconSymbolName,
        iconTintColor: src.iconTintColor,
        players: remappedPlayers,
        suggestedGameType: src.suggestedGameType,
        createdDate: src.createdDate,
        lastModified: Date()
      )
      context.insert(clone)
    }
    // Ensure every active player belongs to at least one active team that includes their name
    do {
      let activeTeams = try context.fetch(
        FetchDescriptor<TeamProfile>(predicate: #Predicate { $0.isArchived == false })
      )
      for (_, player) in oldIdToNewPlayer {
        guard player.isArchived == false else { continue }
        let hasNamedTeam = activeTeams.contains { team in
          team.players.contains(where: { $0.id == player.id })
            && team.name.localizedCaseInsensitiveContains(player.name)
        }
        if hasNamedTeam == false {
          let solo = TeamProfile(
            name: player.name,
            avatarImageData: nil,
            iconSymbolName: "person.fill",
            iconTintColor: player.iconTintColor,
            players: [player]
          )
          context.insert(solo)
        }
      }
    } catch {
      // Non-fatal for previews; continue
    }
    try context.save()
    return container
  }

  // MARK: - Model Container Setup

  /// Creates an in-memory model container with sample data
  public static func createPreviewContainer(with games: [Game] = mixedGames) throws
    -> ModelContainer
  {
    // Include full schema needed by previews that touch roster/search screens
    let schema = Schema([
      Game.self, GameVariation.self, GameSummary.self, PlayerProfile.self, TeamProfile.self,
      GameTypePreset.self,
    ])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try ModelContainer(
      for: schema,
      configurations: [config]
    )
    let context = container.mainContext

    for game in games {
      context.insert(game)
    }

    try context.save()
    return container
  }

  /// Creates a model container with comprehensive test data
  public static func createFullPreviewContainer() throws -> ModelContainer {
    let schema = Schema([
      Game.self, GameVariation.self, GameSummary.self, PlayerProfile.self, TeamProfile.self,
      GameTypePreset.self,
    ])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try ModelContainer(
      for: schema,
      configurations: [config]
    )
    let context = container.mainContext

    // Add active game
    context.insert(midGame)

    // Add historical games
    for game in competitivePlayerGames {
      context.insert(game)
    }

    for game in recreationalPlayerGames {
      context.insert(game)
    }

    try context.save()
    return container
  }

  // MARK: - Helper Functions

  /// Creates a completed game with specified parameters
  public static func createCompletedGame(
    _ gameType: GameType,
    _ score1: Int,
    _ score2: Int,
    hoursAgo: Int = 0,
    daysAgo: Int = 0,
    duration: TimeInterval = 20 * 60,
    rallies: Int = 15,
    notes: String? = nil
  ) -> Game {
    let game = Game(gameType: gameType)
    game.score1 = score1
    game.score2 = score2
    game.isCompleted = true
    game.duration = duration
    game.totalRallies = rallies
    game.notes = notes

    var dateComponents = DateComponents()
    if hoursAgo > 0 {
      dateComponents.hour = -hoursAgo
    }
    if daysAgo > 0 {
      dateComponents.day = -daysAgo
    }

    let completedDate = Calendar.current.date(byAdding: dateComponents, to: Date()) ?? Date()
    game.completedDate = completedDate
    game.lastModified = completedDate

    return game
  }

  /// Creates an active game with specified scores
  public static func createActiveGame(
    _ gameType: GameType = .recreational,
    score1: Int,
    score2: Int,
    currentServer: Int = 1,
    serverNumber: Int = 1,
    rallies: Int = 10
  ) -> Game {
    let game = Game(gameType: gameType)
    game.score1 = score1
    game.score2 = score2
    game.currentServer = currentServer
    game.serverNumber = serverNumber
    game.gameState = .playing
    game.totalRallies = rallies
    game.lastModified = Date()
    return game
  }

  /// Team names for consistent preview display
  public static let teamNames = (team1: "Team Alpha", team2: "Team Beta")

  /// Closures for common preview actions (no-op for previews)
  public static let previewActions = (
    onGameCompleted: {} as @Sendable () -> Void,
    onBack: {} as @Sendable () -> Void,
    onGameSelected: { (_: Game) in } as @Sendable (Game) -> Void,
    onGameDeleted: { (_: Game) in } as @Sendable (Game) -> Void
  )
}
