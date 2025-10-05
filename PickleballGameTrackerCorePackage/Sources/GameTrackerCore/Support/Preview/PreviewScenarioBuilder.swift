//
//  PreviewScenarioBuilder.swift
//  GameTrackerCore
//
//  Created by Refactor on 10/1/25.
//

import Foundation
import SwiftData

/// Fluent builder for creating complete preview scenarios with composable data generation.
///
/// ## Overview
///
/// `PreviewScenarioBuilder` provides a declarative, type-safe way to construct preview scenarios
/// by composing factories and seeding operations. It replaces scattered seeding logic with a
/// single, reusable interface.
///
/// ## Basic Usage
///
/// ```swift
/// let builder = PreviewScenarioBuilder(context: context, store: store)
///     .withRoster(playerCount: 12, teamSize: 2)
///     .withVariations(count: 10)
///     .withHistory(gameCount: 20, days: 30)
///     .withActiveGame()
///
/// builder.seed()
/// ```
///
/// ## Benefits
///
/// - **Composable**: Chain configuration methods to build complex scenarios
/// - **Type-safe**: Configuration validated at compile time
/// - **Reusable**: Common patterns extracted into preset methods
/// - **Testable**: Easy to verify seeding behavior
/// - **Maintainable**: Single source of truth for seeding logic
@MainActor
public struct PreviewScenarioBuilder {
    
    // MARK: - Properties
    
    private let context: ModelContext
    private let store: GameStore
    
    private var playerCount: Int = 0
    private var teamSize: Int = 2
    private var variationCount: Int = 0
    private var historyPlayerGamesCount: Int = 0
    private var historyTeamGamesCount: Int = 0
    private var historyTimeRangeDays: Int = 30
    private var searchGamesCount: Int = 0
    private var searchTimeRangeDays: Int = 30
    private var shouldCreateActiveGame: Bool = false
    private var activeGameState: GameState?
    
    // MARK: - Initialization
    
    /// Creates a new scenario builder.
    ///
    /// - Parameters:
    ///   - context: ModelContext to seed data into
    ///   - store: GameStore for completing games
    public init(context: ModelContext, store: GameStore) {
        self.context = context
        self.store = store
    }
    
    /// Creates a builder with a container's main context.
    ///
    /// - Parameter container: Container to seed into
    public init(container: ModelContainer) {
        self.context = container.mainContext
        self.store = GameStore(context: container.mainContext)
    }
    
    // MARK: - Configuration Methods
    
    /// Adds roster data (players and teams) to the scenario.
    ///
    /// Uses `TeamProfileFactory.realisticTeams()` to generate a complete roster
    /// with proper relationships and realistic distributions.
    ///
    /// - Parameters:
    ///   - playerCount: Number of players to generate
    ///   - teamSize: Size of teams (typically 2 for doubles)
    /// - Returns: Self for method chaining
    public func withRoster(playerCount: Int, teamSize: Int = 2) -> Self {
        var copy = self
        copy.playerCount = playerCount
        copy.teamSize = teamSize
        return copy
    }
    
    /// Adds game variations to the scenario.
    ///
    /// Uses `GameVariationFactory` to generate diverse variations.
    ///
    /// - Parameter count: Number of variations to generate
    /// - Returns: Self for method chaining
    public func withVariations(count: Int) -> Self {
        var copy = self
        copy.variationCount = count
        return copy
    }
    
    /// Adds completed game history to the scenario.
    ///
    /// Generates realistic completed games with proper `GameSummary` records.
    /// Games are distributed across player and team matchups when roster is present.
    ///
    /// - Parameters:
    ///   - playerGames: Number of singles games
    ///   - teamGames: Number of doubles games
    ///   - days: Time range to distribute games across
    /// - Returns: Self for method chaining
    public func withHistory(playerGames: Int = 0, teamGames: Int = 0, days: Int = 30) -> Self {
        var copy = self
        copy.historyPlayerGamesCount = playerGames
        copy.historyTeamGamesCount = teamGames
        copy.historyTimeRangeDays = days
        return copy
    }
    
    /// Adds completed games for search testing.
    ///
    /// Similar to history but optimized for search scenarios with varied metadata.
    ///
    /// - Parameters:
    ///   - count: Number of games to generate
    ///   - days: Time range to distribute across
    /// - Returns: Self for method chaining
    public func withSearchData(count: Int, days: Int = 30) -> Self {
        var copy = self
        copy.searchGamesCount = count
        copy.searchTimeRangeDays = days
        return copy
    }
    
    /// Adds an active game to the scenario.
    ///
    /// Creates a mid-game state with realistic scores and participant assignments
    /// when roster is present.
    ///
    /// - Parameter state: Optional specific game state (defaults to .playing)
    /// - Returns: Self for method chaining
    public func withActiveGame(state: GameState? = nil) -> Self {
        var copy = self
        copy.shouldCreateActiveGame = true
        copy.activeGameState = state
        return copy
    }
    
    // MARK: - Preset Configurations
    
    /// Creates a minimal scenario for fast preview loading.
    ///
    /// Includes:
    /// - 4 players, 2 teams
    /// - 5 variations
    /// - 5 recent games (3 player, 2 team)
    public static func minimal(context: ModelContext, store: GameStore) -> PreviewScenarioBuilder {
        PreviewScenarioBuilder(context: context, store: store)
            .withRoster(playerCount: 4, teamSize: 2)
            .withVariations(count: 5)
            .withHistory(playerGames: 3, teamGames: 2, days: 7)
    }
    
    /// Creates a standard scenario for general previews.
    ///
    /// Includes:
    /// - 12 players, teams
    /// - 10 variations
    /// - 18 games (12 player, 6 team) over 30 days
    /// - Active game
    public static func standard(context: ModelContext, store: GameStore) -> PreviewScenarioBuilder {
        PreviewScenarioBuilder(context: context, store: store)
            .withRoster(playerCount: 12, teamSize: 2)
            .withVariations(count: 10)
            .withHistory(playerGames: 12, teamGames: 6, days: 30)
            .withActiveGame()
    }
    
    /// Creates an extensive scenario for stress testing.
    ///
    /// Includes:
    /// - 20 players, teams
    /// - 20 variations
    /// - 40 games (25 player, 15 team) over 90 days
    public static func extensive(context: ModelContext, store: GameStore) -> PreviewScenarioBuilder {
        PreviewScenarioBuilder(context: context, store: store)
            .withRoster(playerCount: 20, teamSize: 2)
            .withVariations(count: 20)
            .withHistory(playerGames: 25, teamGames: 15, days: 90)
    }
    
    /// Creates a scenario focused on roster management.
    ///
    /// Includes:
    /// - 12 players, teams with varied attributes
    /// - 5 basic variations
    public static func roster(context: ModelContext, store: GameStore) -> PreviewScenarioBuilder {
        PreviewScenarioBuilder(context: context, store: store)
            .withRoster(playerCount: 12, teamSize: 2)
            .withVariations(count: 5)
    }
    
    /// Creates a scenario for history/search features.
    ///
    /// Includes:
    /// - 12 players, teams
    /// - 10 variations
    /// - 30 games distributed over 30 days
    public static func history(context: ModelContext, store: GameStore) -> PreviewScenarioBuilder {
        PreviewScenarioBuilder(context: context, store: store)
            .withRoster(playerCount: 12, teamSize: 2)
            .withVariations(count: 10)
            .withHistory(playerGames: 20, teamGames: 10, days: 30)
    }
    
    /// Creates a scenario for live game features.
    ///
    /// Includes:
    /// - 8 players, teams
    /// - 5 variations
    /// - Active mid-game
    public static func liveGame(context: ModelContext, store: GameStore) -> PreviewScenarioBuilder {
        PreviewScenarioBuilder(context: context, store: store)
            .withRoster(playerCount: 8, teamSize: 2)
            .withVariations(count: 5)
            .withActiveGame(state: .playing)
    }
    
    // MARK: - Seeding Execution
    
    /// Executes the configured seeding operations.
    ///
    /// Operations are performed in order:
    /// 1. Roster (players/teams)
    /// 2. Variations
    /// 3. History games
    /// 4. Search data
    /// 5. Active game
    ///
    /// All operations use the builder's context and store.
    public func seed() {
        // 1. Seed roster
        if playerCount > 0 {
            let (players, teams) = TeamProfileFactory.realisticTeams(
                playerCount: playerCount,
                teamSize: teamSize
            )
            for player in players {
                context.insert(player)
            }
            for team in teams {
                context.insert(team)
            }
        }
        
        // 2. Seed variations
        if variationCount > 0 {
            let variations = GameVariationFactory.realisticCatalog(count: variationCount)
            for variation in variations {
                context.insert(variation)
            }
        }
        
        // 3. Seed history
        seedHistory()
        
        // 4. Seed search data
        if searchGamesCount > 0 {
            let searchGames = CompletedGameFactory.realisticHistory(
                count: searchGamesCount,
                withinDays: searchTimeRangeDays
            )
            for generated in searchGames {
                context.insert(generated.game)
                try? store.complete(generated.game, at: generated.completionDate)
            }
        }
        
        // 5. Create active game
        if shouldCreateActiveGame {
            seedActiveGame()
        }
    }
    
    // MARK: - Private Helpers
    
    private func seedHistory() {
        guard historyPlayerGamesCount > 0 || historyTeamGamesCount > 0 else { return }
        
        let players = (try? context.fetch(FetchDescriptor<PlayerProfile>())) ?? []
        let teams = (try? context.fetch(FetchDescriptor<TeamProfile>())) ?? []
        
        // Player games
        if historyPlayerGamesCount > 0 && players.count >= 2 {
            for _ in 0..<historyPlayerGamesCount {
                let generated = CompletedGameFactory(context: context)
                    .withPlayers()
                    .gameType([.recreational, .tournament, .training].randomElement()!)
                    .timestamp(withinDays: historyTimeRangeDays)
                    .generateWithDate()
                context.insert(generated.game)
                try? store.complete(generated.game, at: generated.completionDate)
            }
        }
        
        // Team games
        if historyTeamGamesCount > 0 && teams.count >= 2 {
            for _ in 0..<historyTeamGamesCount {
                let generated = CompletedGameFactory(context: context)
                    .withTeams()
                    .gameType([.recreational, .tournament].randomElement()!)
                    .timestamp(withinDays: historyTimeRangeDays)
                    .generateWithDate()
                context.insert(generated.game)
                try? store.complete(generated.game, at: generated.completionDate)
            }
        }
    }
    
    private func seedActiveGame() {
        let players = (try? context.fetch(FetchDescriptor<PlayerProfile>())) ?? []
        let teams = (try? context.fetch(FetchDescriptor<TeamProfile>())) ?? []
        
        let doSingles: Bool = {
            switch (players.count >= 2, teams.count >= 2) {
            case (true, true): return Bool.random()
            case (true, false): return true
            case (false, true): return false
            default: return true
            }
        }()
        
        if doSingles && players.count >= 2 {
            let shuffled = players.shuffled()
            let p1 = shuffled[0]
            let p2 = shuffled[1]
            
            let variation = GameVariationFactory.forMatchup(
                players: [p1, p2],
                gameType: .recreational
            )
            
            let game = ActiveGameFactory(context: context)
                .variation(variation)
                .midGame()
                .state(activeGameState ?? .playing)
                .server(team: [1, 2].randomElement()!, player: 1)
                .generate()
            context.insert(game)
        } else if teams.count >= 2 {
            let shuffled = teams.shuffled()
            let t1 = shuffled[0]
            let t2 = shuffled[1]
            
            let variation = GameVariationFactory.forMatchup(
                teams: [t1, t2],
                gameType: .recreational
            )
            
            let game = ActiveGameFactory(context: context)
                .variation(variation)
                .midGame()
                .state(activeGameState ?? .playing)
                .server(team: [1, 2].randomElement()!, player: [1, 2].randomElement()!)
                .generate()
            context.insert(game)
        }
    }
}

// MARK: - Convenience Extensions

extension PreviewScenarioBuilder {
    /// Seeds data and returns the configured context for immediate use.
    ///
    /// Useful for inline preview configurations:
    /// ```swift
    /// let context = PreviewScenarioBuilder.standard(context: ctx, store: store)
    ///     .seedAndReturn()
    /// ```
    @discardableResult
    public func seedAndReturn() -> ModelContext {
        seed()
        return context
    }
}

