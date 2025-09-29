//
//  PreviewData.swift
//  SharedGameCore
//
//  Created by Ethan Anderson on 1/27/25.
//

import Foundation
import SwiftData
import SwiftUI

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

  @available(*, deprecated, message: "Use SwiftDataSeeding.seedSampleRoster or seedRoster")
  public static let samplePlayers: [PlayerProfile] = {
    let ethan = PlayerProfile(
      name: "Ethan",
      avatarImageData: nil,
      iconSymbolName: "tennis.racket",
      accentColor: StoredRGBAColor(Color.blue),
      skillLevel: .advanced,
      preferredHand: .right
    )
    let reed = PlayerProfile(
      name: "Reed",
      avatarImageData: nil,
      iconSymbolName: "figure.tennis",
      accentColor: StoredRGBAColor(Color.green),
      skillLevel: .intermediate,
      preferredHand: .right
    )
    let ricky = PlayerProfile(
      name: "Ricky",
      avatarImageData: nil,
      iconSymbolName: "figure.walk",
      accentColor: StoredRGBAColor(Color.orange),
      skillLevel: .beginner,
      preferredHand: .left
    )
    let dave = PlayerProfile(
      name: "Dave",
      avatarImageData: nil,
      iconSymbolName: "medal.fill",
      accentColor: StoredRGBAColor(Color.purple),
      skillLevel: .expert,
      preferredHand: .right
    )

    // Archived players
    let archivedAlex = PlayerProfile(
      name: "Alex",
      avatarImageData: nil,
      iconSymbolName: "person.fill",
      accentColor: StoredRGBAColor(Color.brown),
      skillLevel: .intermediate,
      preferredHand: .right
    )
    archivedAlex.isArchived = true

    let archivedJordan = PlayerProfile(
      name: "Jordan",
      avatarImageData: nil,
      iconSymbolName: "person.fill",
      accentColor: StoredRGBAColor(Color.indigo),
      skillLevel: .advanced,
      preferredHand: .left
    )
    archivedJordan.isArchived = true

    return [ethan, reed, ricky, dave, archivedAlex, archivedJordan]
  }()

  @available(*, deprecated, message: "Use SwiftDataSeeding.seedSampleRoster or seedRoster")
  public static let sampleTeams: [TeamProfile] = {
    let t1 = TeamProfile(
      name: "Ethan & Reed",
      avatarImageData: nil,
      iconSymbolName: "person.2.fill",
      accentColor: StoredRGBAColor(Color.teal),
      players: [samplePlayers[0], samplePlayers[1]]
    )
    let t2 = TeamProfile(
      name: "Ricky & Dave",
      avatarImageData: nil,
      iconSymbolName: "figure.mind.and.body",
      accentColor: StoredRGBAColor(Color.pink),
      players: [samplePlayers[2], samplePlayers[3]]
    )

    // Archived teams
    let archivedTeam1 = TeamProfile(
      name: "Alex & Jordan",
      avatarImageData: nil,
      iconSymbolName: "person.2.fill",
      accentColor: StoredRGBAColor(Color.brown),
      players: [samplePlayers[4], samplePlayers[5]]  // archived players
    )
    archivedTeam1.isArchived = true

    let archivedTeam2 = TeamProfile(
      name: "Old Veterans",
      avatarImageData: nil,
      iconSymbolName: "trophy.fill",
      accentColor: StoredRGBAColor(Color.indigo),
      players: [samplePlayers[0], samplePlayers[3]]  // mix of active and archived players
    )
    archivedTeam2.isArchived = true

    return [t1, t2, archivedTeam1, archivedTeam2]
  }()

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

  /// Helper to filter only active (non-archived) players from `samplePlayers`
  public static var sampleActivePlayers: [PlayerProfile] {
    // Use context-based sample data seeding
    if let ctx = try? makeRosterPreviewContext(includeArchived: true) {
      return ctx.players.filter { $0.isArchived == false }
    }
    return []
  }

  /// Helper to filter only active (non-archived) teams from `sampleTeams`
  public static var sampleActiveTeams: [TeamProfile] {
    // Use context-based sample data seeding
    if let ctx = try? makeRosterPreviewContext(includeArchived: true) {
      return ctx.teams.filter { $0.isArchived == false }
    }
    return []
  }

  /// Counts how many teams include the given player
  public static func teamCount(for player: PlayerProfile, in teams: [TeamProfile]) -> Int {
    teams.filter { $0.players.contains(where: { $0.id == player.id }) }.count
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
    SwiftDataSeeding.seedSampleRoster(into: container.mainContext)
    let context = container.mainContext
    let allPlayers = try context.fetch(FetchDescriptor<PlayerProfile>())
    let allTeams = try context.fetch(FetchDescriptor<TeamProfile>())
    let players = includeArchived ? allPlayers : allPlayers.filter { $0.isArchived == false }
    let teams = includeArchived ? allTeams : allTeams.filter { $0.isArchived == false }
    return RosterPreviewContext(container: container, players: players, teams: teams)
  }

  // MARK: - Active Game Context

  /// Lightweight active game preview context for screens that need a game + manager
  public struct ActiveGamePreviewContext {
    public let container: ModelContainer
    public let game: Game
    public let gameManager: SwiftDataGameManager
    public let activeGameStateManager: LiveGameStateManager
  }

  /// Creates an active game preview context from a provided sample game
  public static func makeActiveGameContext(game: Game) throws -> ActiveGamePreviewContext {
    let container = try createContainer(for: game)
    let storage = SwiftDataStorage(modelContainer: container)
    let gameManager = SwiftDataGameManager(storage: storage)
    let active = LiveGameStateManager.production(storage: storage)
    active.configure(gameManager: gameManager)
    active.setCurrentGame(game)
    return ActiveGamePreviewContext(
      container: container,
      game: game,
      gameManager: gameManager,
      activeGameStateManager: active
    )
  }

  /// Create a random active game using the provided game manager and loaded roster
  public static func createRandomActiveGame(using gameManager: SwiftDataGameManager) async throws
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
  /// Generate a list of random events and attach to the given game
  /// - Parameters:
  ///   - game: The game to attach events to
  ///   - count: Number of events to generate
  ///   - maxTime: Upper bound for generated timestamps (seconds)
  /// - Returns: The same game instance for chaining
  @discardableResult
  public static func attachRandomEvents(
    to game: Game,
    count: Int = 20,
    maxTime: TimeInterval = 20 * 60
  ) -> Game {
    guard count > 0 else { return game }

    var currentTime: TimeInterval = 0
    let stepRange: ClosedRange<TimeInterval> = 5...45 // seconds between events

    for _ in 0..<count {
      // Advance time by a random step
      let delta = TimeInterval(Int.random(in: Int(stepRange.lowerBound)...Int(stepRange.upperBound)))
      currentTime = min(currentTime + delta, maxTime)

      // Pick a random event type
      let eventType = GameEventType.allCases.randomElement() ?? .serviceFault

      // Some event types are not team-specific
      let teamSpecificTypes: Set<GameEventType> = [
        .ballOutOfBounds, .ballInKitchenOnServe, .serviceFault,
        .ballHitNet, .doubleBounce, .kitchenViolation,
        .injuryTimeout, .substitution, .delayPenalty,
      ]

      let teamAffected: Int? = teamSpecificTypes.contains(eventType) ? [1, 2].randomElement() : nil

      // Optional short description for variety
      let descriptions = [
        "Rally ended abruptly",
        "Close call at the line",
        "Strong serve caused error",
        "Quick exchange at the net",
        "Long rally, forced mistake",
        "Communication mix-up",
        "Tactical timeout",
      ]
      let description: String? = Bool.random() ? descriptions.randomElement() : nil

      game.logEvent(eventType, at: currentTime, teamAffected: teamAffected, description: description)
    }

    return game
  }

  /// Create an active game pre-populated with a set of random events
  /// - Parameter count: Number of events to generate
  /// - Returns: A game with random scores and events, suitable for previews
  public static func createGameWithRandomEvents(count: Int = 24) -> Game {
    let base = createActiveGame(
      .recreational,
      score1: Int.random(in: 0...10),
      score2: Int.random(in: 0...10),
      currentServer: [1, 2].randomElement()!,
      serverNumber: [1, 2].randomElement()!,
      rallies: Int.random(in: 8...28)
    )

    // Give a chance for a different game type for visual variety
    if Bool.random() {
      base.gameType = .training
    }

    return attachRandomEvents(to: base, count: count)
  }

  /// Convenience to create a container preloaded with a single random-events game
  public static func createContainerWithRandomEventsGame(count: Int = 24) throws -> ModelContainer {
    try createContainer(for: createGameWithRandomEvents(count: count))
  }
}
