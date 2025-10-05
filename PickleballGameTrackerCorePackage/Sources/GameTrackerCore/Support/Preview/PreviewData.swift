//
//  PreviewData.swift
//  SharedGameCore
//
//  Created by Ethan Anderson on 1/27/25.
//

import Foundation
import SwiftData
import SwiftUI

/// Centralized preview data provider for all views in the Pickleball Score Tracking app.
///
/// ## Overview
///
/// This struct provides static game data collections for use in SwiftUI previews and tests.
/// The data uses `CompletedGameFactory` for flexible, realistic game generation.
///
/// ## Generating Custom Games
///
/// For custom preview scenarios, use `CompletedGameFactory` directly:
///
/// ```swift
/// // Random game with default settings
/// let game = CompletedGameFactory().generate()
///
/// // Specific tournament game
/// let tournamentGame = CompletedGameFactory()
///     .gameType(.tournament)
///     .scores(winner: 15, loser: 13)
///     .timestamp(hoursAgo: 2)
///     .duration(minutes: 35)
///     .generate()
///
/// // Batch generation with consistent settings
/// let games = CompletedGameFactory.batch(count: 10) { factory in
///     factory
///         .gameType(.recreational)
///         .timestamp(withinDays: 7)
/// }
/// ```
///
/// ## Convenience Methods
///
/// For common scenarios, use the helper methods:
/// - `generateRandomHistory(count:)` - Random games with varied data
/// - `generateRecentHistory(count:withinDays:)` - Games within a time range
/// - `generateGamesOfType(count:gameType:)` - Games of a specific type
///
/// For specific testing scenarios, use `CompletedGameFactory` presets:
/// - `recentCompetitiveWin()` - Close match from last few hours
/// - `dominantVictory()` - Large point differential
/// - `trainingSession()` - Quick game to 7 points
/// - `tournamentMatch()` - Tournament format (15 or 21 points)
/// - `realisticHistory(count:withinDays:)` - Realistic mix of game types
/// - `balancedWinLoss(count:)` - Equal wins and losses
/// - `improvementProgression(count:)` - Shows player improvement over time
///
/// ## Individual Game Scenarios
///
/// Use the static properties for testing individual game states:
/// - `earlyGame`, `midGame`, `closeGame` - In-progress game states
/// - `completedGame` - Completed game example
/// - `emptyGames` - Empty array for testing empty states
@MainActor
public struct PreviewGameData {

  // MARK: - Common Game Manager

  /// Standard game manager for preview use
  public static let gameManager = SwiftDataGameManager()

  // MARK: - Single Game Scenarios

  /// Early game state (low scores)
  public static var earlyGame: Game {
    ActiveGameFactory.earlyGame()
  }

  /// Mid-game state (moderate scores)
  public static var midGame: Game {
    ActiveGameFactory.midGame()
  }

  /// Close game state (near winning)
  public static var closeGame: Game {
    ActiveGameFactory.closeGame()
  }

  /// Match point scenario
  public static var matchPointGame: Game {
    ActiveGameFactory.matchPoint()
  }

  /// Completed game (Team 1 wins)
  public static var completedGame: Game {
    CompletedGameFactory()
      .scores(11, 7)
      .duration(minutes: 25)
      .rallies(20)
      .timestamp(hoursAgo: 0)
      .generate()
  }

  /// High-scoring tournament game
  public static var highScoreGame: Game {
    ActiveGameFactory()
      .gameType(.tournament)
      .scores(15, 13)
      .winningScore(15)
      .server(team: 2)
      .state(.playing)
      .generate()
  }

  /// Training game (shorter format)
  public static var trainingGame: Game {
    ActiveGameFactory()
      .gameType(.training)
      .scores(6, 4)
      .winningScore(7)
      .server(team: 1)
      .state(.playing)
      .generate()
  }

  /// Paused game
  public static var pausedGame: Game {
    ActiveGameFactory.pausedGame()
  }

  // MARK: - Serving Scenarios

  /// Team 1 serving, player 1
  public static var team1Player1Serving: Game {
    ActiveGameFactory()
      .scores(5, 3)
      .server(team: 1, player: 1)
      .state(.playing)
      .generate()
  }

  /// Team 1 serving, player 2
  public static var team1Player2Serving: Game {
    ActiveGameFactory()
      .scores(7, 5)
      .server(team: 1, player: 2)
      .state(.playing)
      .generate()
  }

  /// Team 2 serving
  public static var team2Serving: Game {
    ActiveGameFactory()
      .scores(4, 6)
      .server(team: 2, player: 1)
      .state(.playing)
      .generate()
  }


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

  /// Creates a model container populated with roster data for previews
  public static func createRosterPreviewContainer(
    players: [PlayerProfile],
    teams: [TeamProfile]
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
    SwiftDataSeeding.seedRoster(players: players, teams: teams, into: context)
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

    // Add historical games using factory
    let generatedGames = CompletedGameFactory.realisticHistory(count: 15, withinDays: 30)
    for generated in generatedGames {
      context.insert(generated.game)
    }

    try context.save()
    return container
  }

  // MARK: - Helper Functions
  
  /// Generates a collection of random completed games with their completion dates.
  ///
  /// Uses `CompletedGameFactory` to generate realistic, varied game data.
  /// Each game will have randomized scores, timestamps, and game types.
  ///
  /// Returns `GeneratedGame` instances that include both the game and its intended
  /// completion date for proper seeding via `GameStore.complete()`.
  ///
  /// - Parameter count: Number of games to generate (default: 10)
  /// - Returns: Array of GeneratedGame instances
  ///
  /// Example:
  /// ```swift
  /// let generated = PreviewGameData.generateRandomHistory(count: 20)
  /// for gen in generated {
  ///     context.insert(gen.game)
  ///     try? store.complete(gen.game, at: gen.completionDate)
  /// }
  /// ```
  public static func generateRandomHistory(count: Int = 10) -> [CompletedGameFactory.GeneratedGame] {
    CompletedGameFactory.batchWithDates(count: count)
  }
  
  /// Generates a collection of games within a specific time range with completion dates.
  ///
  /// - Parameters:
  ///   - count: Number of games to generate
  ///   - withinDays: Maximum days in the past to distribute games
  /// - Returns: Array of GeneratedGame instances with varied timestamps
  ///
  /// Example:
  /// ```swift
  /// let generated = PreviewGameData.generateRecentHistory(count: 15, withinDays: 7)
  /// ```
  public static func generateRecentHistory(count: Int = 10, withinDays days: Int = 7) -> [CompletedGameFactory.GeneratedGame] {
    CompletedGameFactory.batchWithDates(count: count) { factory in
      factory.timestamp(withinDays: days)
    }
  }
  
  /// Generates a collection of games for a specific game type with completion dates.
  ///
  /// - Parameters:
  ///   - count: Number of games to generate
  ///   - gameType: The type of games to generate
  /// - Returns: Array of GeneratedGame instances of the specified type
  ///
  /// Example:
  /// ```swift
  /// let generated = PreviewGameData.generateGamesOfType(count: 5, gameType: .tournament)
  /// ```
  public static func generateGamesOfType(count: Int = 10, gameType: GameType) -> [CompletedGameFactory.GeneratedGame] {
    CompletedGameFactory.batchWithDates(count: count) { factory in
      factory.gameType(gameType)
    }
  }


  /// Creates an active game with specified scores
  @available(*, deprecated, message: "Use ActiveGameFactory directly for more flexible configuration")
  public static func createActiveGame(
    _ gameType: GameType = .recreational,
    score1: Int,
    score2: Int,
    currentServer: Int = 1,
    serverNumber: Int = 1,
    rallies: Int = 10
  ) -> Game {
    ActiveGameFactory()
      .gameType(gameType)
      .scores(score1, score2)
      .server(team: currentServer, player: serverNumber)
      .rallies(rallies)
      .state(.playing)
      .generate()
  }

  /// Count how many teams a player is a member of
  public static func teamCount(for player: PlayerProfile, in teams: [TeamProfile]) -> Int {
    teams.filter { $0.players.contains(where: { $0.id == player.id }) }.count
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

  // MARK: - New Utilities for View Previews

  /// Creates an empty in-memory container with full schema for previews that don't need data
  public static func createEmptyPreviewContainer() throws -> ModelContainer {
    try createPreviewContainer(with: [])
  }

  /// Convenience to create a container preloaded with a single game
  public static func createContainer(for game: Game) throws -> ModelContainer {
    try createPreviewContainer(with: [game])
  }

  /// A stable set of sample game types for search/list previews
  public static var sampleGameTypes: [GameType] {
    [trainingGame.gameType, midGame.gameType, highScoreGame.gameType]
  }


  /// Lightweight roster preview context for common roster previews
  public struct RosterPreviewContext {
    public let container: ModelContainer
    public let players: [PlayerProfile]
    public let teams: [TeamProfile]
  }

  /// Makes a roster preview context with active players/teams by default
  public static func makeRosterPreviewContext(
    includeArchived: Bool = false
  ) throws -> RosterPreviewContext {
    let schema = Schema([
      Game.self, GameVariation.self, GameSummary.self, PlayerProfile.self, TeamProfile.self,
      GameTypePreset.self,
    ])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try ModelContainer(
      for: schema,
      configurations: [config]
    )
    
    let (allPlayers, allTeams) = TeamProfileFactory.realisticTeams(playerCount: 12, teamSize: 2)
    for player in allPlayers {
      container.mainContext.insert(player)
    }
    for team in allTeams {
      container.mainContext.insert(team)
    }
    
    let context = container.mainContext
    let players = try context.fetch(FetchDescriptor<PlayerProfile>())
      .filter { includeArchived || !$0.isArchived }
    let teams = try context.fetch(FetchDescriptor<TeamProfile>())
      .filter { includeArchived || !$0.isArchived }
    
    return RosterPreviewContext(container: container, players: players, teams: teams)
  }

  // MARK: - Live Game Context

  /// Lightweight live game preview context for screens that need a game + manager
  public struct LiveGamePreviewContext {
    public let container: ModelContainer
    public let game: Game
    public let gameManager: SwiftDataGameManager
    public let liveGameStateManager: LiveGameStateManager
  }

  /// Creates a live game preview context from a provided sample game
  public static func makeLiveGameContext(game: Game) throws -> LiveGamePreviewContext {
    let container = try createContainer(for: game)
    let storage = SwiftDataStorage(modelContainer: container)
    let gameManager = SwiftDataGameManager(storage: storage)
    let active = LiveGameStateManager.production(storage: storage)
    active.configure(gameManager: gameManager)
    active.setCurrentGame(game)
    return LiveGamePreviewContext(
      container: container,
      game: game,
      gameManager: gameManager,
      liveGameStateManager: active
    )
  }

  /// Create a random live game using the provided game manager and loaded roster
  public static func createRandomLiveGame(using gameManager: SwiftDataGameManager) async throws
    -> Game
  {
    let context = gameManager.storage.modelContainer.mainContext

    // Fetch active roster
    let players = try context.fetch(FetchDescriptor<PlayerProfile>())
      .filter { $0.isArchived == false }
    let teams = try context.fetch(FetchDescriptor<TeamProfile>())
      .filter { $0.isArchived == false }

    // Decide singles vs doubles (prefer doubles when teams exist)
    let canDoSingles = players.count >= 2
    let canDoDoubles = teams.count >= 2

    let doSingles: Bool = {
      switch (canDoSingles, canDoDoubles) {
      case (true, true): return Bool.random()
      case (true, false): return true
      case (false, true): return false
      default: return true
      }
    }()

    if doSingles, canDoSingles {
      let shuffled = players.shuffled()
      let p1 = shuffled[0]
      let p2 = shuffled[1]
      let variation = GameVariation(
        name: "\(p1.name) vs \(p2.name)",
        gameType: .recreational,
        teamSize: 1,
        winningScore: 11,
        winByTwo: true,
        kitchenRule: true,
        doubleBounceRule: true,
        servingRotation: .standard,
        sideSwitchingRule: .never,
        scoringType: .sideOut
      )
      let matchup = MatchupSelection(
        teamSize: 1,
        mode: .players(sideA: [p1.id], sideB: [p2.id])
      )
      let game = try await gameManager.createGame(variation: variation, matchup: matchup)
      game.participantMode = .players
      game.side1PlayerIds = [p1.id]
      game.side2PlayerIds = [p2.id]
      game.gameState = .playing
      return game
    }

    if canDoDoubles {
      let shuffled = teams.shuffled()
      let t1 = shuffled[0]
      let t2 = shuffled[1]
      let variation = GameVariation(
        name: "\(t1.name) vs \(t2.name)",
        gameType: .recreational,
        teamSize: 2,
        winningScore: 11,
        winByTwo: true,
        kitchenRule: true,
        doubleBounceRule: true,
        servingRotation: .standard,
        sideSwitchingRule: .never,
        scoringType: .sideOut
      )
      let matchup = MatchupSelection(
        teamSize: 2,
        mode: .teams(team1Id: t1.id, team2Id: t2.id)
      )
      let game = try await gameManager.createGame(variation: variation, matchup: matchup)
      game.participantMode = .teams
      game.side1TeamId = t1.id
      game.side2TeamId = t2.id
      game.gameState = .playing
      return game
    }

    // Fallback: no roster available - create a simple active game without participants
    let variation = GameVariation(name: "Practice Game", gameType: .training, teamSize: 1)
    let game = try await gameManager.createGame(variation: variation)
    game.gameState = .playing
    return game
  }
}

// MARK: - Event Factories for Previews

extension PreviewGameData {

  /// Attach realistic events to a game using GameEventFactory
  /// - Parameters:
  ///   - game: The game to attach events to
  ///   - eventCount: Maximum number of events to generate
  /// - Returns: The same game instance for chaining
  @discardableResult
  public static func attachRealisticEvents(to game: Game, eventCount: Int? = nil) -> Game {
    if let eventCount = eventCount {
      return GameEventFactory.populateGameWithEvents(game, eventCount: eventCount)
    } else {
      let estimatedDuration: TimeInterval = Double(game.totalRallies) * Double.random(in: 20...40)
      let events = GameEventFactory.createRealisticGameNarrative(
        for: game,
        targetDuration: estimatedDuration
      )
      game.events = events
      return game
    }
  }

  /// Create a game with realistic event narrative
  public static var gameWithRealisticEvents: Game {
    let game = midGame
    return attachRealisticEvents(to: game)
  }

  /// Create a completed game with full narrative
  public static var gameWithFullNarrative: Game {
    let game = completedGame
    let events = GameEventFactory.createRealisticGameNarrative(
      for: game,
      targetDuration: game.duration ?? 1200
    )
    game.events = events
    return game
  }

  /// Create an active game with realistic rally sequences
  public static func createGameWithRealisticEvents(rallyCount: Int = 15) -> Game {
    let base = ActiveGameFactory()
      .gameType(Bool.random() ? .training : .recreational)
      .scores(Int.random(in: 0...10), Int.random(in: 0...10))
      .server(team: [1, 2].randomElement()!, player: [1, 2].randomElement()!)
      .rallies(rallyCount)
      .state(.playing)
      .generate()

    return attachRealisticEvents(to: base)
  }

  /// Create a container preloaded with a game with realistic events
  public static func createContainerWithRealisticEventsGame(rallyCount: Int = 15) throws -> ModelContainer {
    try createContainer(for: createGameWithRealisticEvents(rallyCount: rallyCount))
  }
}
