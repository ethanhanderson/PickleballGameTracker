import Foundation
import SwiftData

/// Unified preview container provider with factory-based seeding
///
/// Provides simple, consistent API for creating preview containers across the app.
/// All containers use factory-based data generation for realistic, varied preview data.
///
/// ## Basic Usage
///
/// ```swift
/// #Preview {
///     MyView()
///         .modelContainer(PreviewContainers.standard())
/// }
/// ```
///
/// ## Available Scenarios
///
/// - `minimal()` - Fast loading with minimal data (4 players, 5 games, 7 days)
/// - `standard()` - Default for most previews (12 players, 18 games, 30 days, active game)
/// - `extensive()` - Large dataset for stress testing (20 players, 40 games, 90 days)
/// - `roster()` - Roster management (12 players, teams, 5 variations)
/// - `liveGame()` - Live game features (8 players, teams, active game)
/// - `history()` - History views (12 players, 30 games, 30 days)
/// - `empty()` - Empty state testing
///
@MainActor
public enum PreviewContainers {
    
    // MARK: - Primary Scenarios
    
    /// Quick, minimal data for fast preview iteration
    ///
    /// - 4 players
    /// - 2 teams
    /// - 5 variations
    /// - 5 games over 7 days
    /// - No active game
    public static func minimal() -> ModelContainer {
        return SwiftDataContainer.createPreviewContainer { context in
            let store = GameStore(context: context)
            
            PreviewScenarioBuilder(context: context, store: store)
                .withRoster(playerCount: 4, teamSize: 2)
                .withVariations(count: 5)
                .withHistory(playerGames: 3, teamGames: 2, days: 7)
                .seed()
        }
    }
    
    /// Standard preview data for general use (default)
    ///
    /// - 12 players
    /// - 6 teams
    /// - 10 variations
    /// - 18 games over 30 days
    /// - 1 active game
    public static func standard() -> ModelContainer {
        return SwiftDataContainer.createPreviewContainer { context in
            let store = GameStore(context: context)
            
            PreviewScenarioBuilder(context: context, store: store)
                .withRoster(playerCount: 12, teamSize: 2)
                .withVariations(count: 10)
                .withHistory(playerGames: 12, teamGames: 6, days: 30)
                .withActiveGame(state: .playing)
                .seed()

            // Ensure at least one completed game with participants exists for each game type
            ensureResumeableHistory(context: context, store: store)
        }
    }
    
    /// Large dataset for performance testing
    ///
    /// - 20 players
    /// - 10 teams
    /// - 15 variations
    /// - 40 games over 90 days
    /// - No active game (to avoid clutter)
    public static func extensive() -> ModelContainer {
        return SwiftDataContainer.createPreviewContainer { context in
            let store = GameStore(context: context)
            
            PreviewScenarioBuilder(context: context, store: store)
                .withRoster(playerCount: 20, teamSize: 2)
                .withVariations(count: 15)
                .withHistory(playerGames: 25, teamGames: 15, days: 90)
                .seed()
        }
    }
    
    // MARK: - Specialized Scenarios
    
    /// Roster management scenario
    ///
    /// - 12 players
    /// - 6 teams
    /// - 5 variations
    /// - No games (focus on roster)
    public static func roster() -> ModelContainer {
        return SwiftDataContainer.createPreviewContainer { context in
            let store = GameStore(context: context)
            
            PreviewScenarioBuilder(context: context, store: store)
                .withRoster(playerCount: 12, teamSize: 2)
                .withVariations(count: 5)
                .seed()
        }
    }
    
    /// Live game scenario
    ///
    /// - 8 players
    /// - 4 teams
    /// - 10 variations
    /// - 1 active game (mid-game, playing state)
    /// - Minimal history (3 games for context)
    public static func liveGame() -> ModelContainer {
        return SwiftDataContainer.createPreviewContainer { context in
            let store = GameStore(context: context)
            
            PreviewScenarioBuilder(context: context, store: store)
                .withRoster(playerCount: 8, teamSize: 2)
                .withVariations(count: 10)
                .withHistory(playerGames: 2, teamGames: 1, days: 7)
                .withActiveGame(state: .playing)
                .seed()

            // Ensure at least one completed game with participants exists for each game type
            ensureResumeableHistory(context: context, store: store)
        }
    }
    
    /// History view scenario
    ///
    /// - 12 players
    /// - 6 teams
    /// - 10 variations
    /// - 30 games over 30 days (focus on history)
    /// - No active game
    public static func history() -> ModelContainer {
        return SwiftDataContainer.createPreviewContainer { context in
            let store = GameStore(context: context)
            
            PreviewScenarioBuilder(context: context, store: store)
                .withRoster(playerCount: 12, teamSize: 2)
                .withVariations(count: 10)
                .withHistory(playerGames: 20, teamGames: 10, days: 30)
                .seed()

            // Ensure at least one completed game with participants exists for each game type
            ensureResumeableHistory(context: context, store: store)
        }
    }
    
    /// Empty state testing
    ///
    /// - No data at all
    public static func empty() -> ModelContainer {
        return SwiftDataContainer.createPreviewContainer()
    }
    
    // MARK: - Manager Creation Helpers
    
    /// Create managers for a given container
    ///
    /// Use this when your preview needs to perform operations (create, update, delete)
    /// in addition to displaying data.
    ///
    /// ```swift
    /// #Preview {
    ///     let container = PreviewContainers.standard()
    ///     let (gameManager, liveGameManager) = PreviewContainers.managers(for: container)
    ///     
    ///     MyView()
    ///         .modelContainer(container)
    ///         .environment(gameManager)
    ///         .environment(liveGameManager)
    /// }
    /// ```
    public static func managers(for container: ModelContainer) -> (
        gameManager: SwiftDataGameManager,
        liveGameManager: LiveGameStateManager
    ) {
        let storage = SwiftDataStorage(modelContainer: container)
        let gameManager = SwiftDataGameManager(storage: storage)
        let liveGameManager = LiveGameStateManager.preview(container: container)
        
        // Configure delegation
        liveGameManager.configure(gameManager: gameManager)
        
        return (gameManager, liveGameManager)
    }
    
    /// Create a roster manager for a given container
    ///
    /// Use this when your preview needs to perform roster operations.
    ///
    /// ```swift
    /// #Preview {
    ///     let container = PreviewContainers.roster()
    ///     let rosterManager = PreviewContainers.rosterManager(for: container)
    ///     
    ///     RosterView()
    ///         .modelContainer(container)
    ///         .environment(rosterManager)
    /// }
    /// ```
    public static func rosterManager(for container: ModelContainer) -> PlayerTeamManager {
        let storage = SwiftDataStorage(modelContainer: container)
        return PlayerTeamManager(storage: storage)
    }
    
    // MARK: - Complete Preview Setup
    
    /// Complete preview setup with container, managers, and activated game
    ///
    /// Use this for app-level previews that need a fully configured environment with
    /// an active game already set in the LiveGameStateManager.
    ///
    /// ```swift
    /// #Preview {
    ///     let setup = PreviewContainers.liveGameSetup()
    ///     
    ///     AppNavigationView()
    ///         .modelContainer(setup.container)
    ///         .environment(setup.liveGameManager)
    ///         .environment(setup.gameManager)
    ///         .environment(setup.rosterManager)
    /// }
    /// ```
    public struct LiveGameSetup {
        public let container: ModelContainer
        public let gameManager: SwiftDataGameManager
        public let liveGameManager: LiveGameStateManager
        public let rosterManager: PlayerTeamManager
    }
    
    /// Creates a complete live game preview setup with activated game
    ///
    /// This method:
    /// 1. Creates a container with seeded data including active game
    /// 2. Creates and configures all managers
    /// 3. Fetches and activates the game in LiveGameStateManager
    ///
    /// Perfect for app-level previews that need the full environment ready to go.
    public static func liveGameSetup() -> LiveGameSetup {
        let container = liveGame()
        
        let managers = managers(for: container)
        let rosterManager = rosterManager(for: container)
        
        if let activeGame = try? container.mainContext.fetch(
            FetchDescriptor<Game>(
                predicate: #Predicate { $0.isCompleted == false },
                sortBy: [SortDescriptor<Game>(\.createdDate, order: .reverse)]
            )
        ).first(where: { $0.gameState == .playing }) {
            Task { @MainActor in
                await managers.liveGameManager.setCurrentGame(activeGame)
            }
        }
        
        return LiveGameSetup(
            container: container,
            gameManager: managers.gameManager,
            liveGameManager: managers.liveGameManager,
            rosterManager: rosterManager
        )
    }
    
    /// Creates a complete preview setup with standard data (no active game)
    ///
    /// Use this for app-level previews that need managers but no active game.
    public static func standardSetup() -> LiveGameSetup {
        let container = standard()
        let managers = managers(for: container)
        let rosterManager = rosterManager(for: container)
        
        return LiveGameSetup(
            container: container,
            gameManager: managers.gameManager,
            liveGameManager: managers.liveGameManager,
            rosterManager: rosterManager
        )
    }
    
    /// Creates a complete preview setup with empty data
    ///
    /// Use this for testing empty states at the app level.
    public static func emptySetup() -> LiveGameSetup {
        let container = empty()
        let managers = managers(for: container)
        let rosterManager = rosterManager(for: container)
        
        return LiveGameSetup(
            container: container,
            gameManager: managers.gameManager,
            liveGameManager: managers.liveGameManager,
            rosterManager: rosterManager
        )
    }
}

// MARK: - Resumeable History Helpers

private extension PreviewContainers {
    static func ensureResumeableHistory(context: ModelContext, store: GameStore) {
        for type in GameType.allCases {
            let existing: [Game] = (try? context.fetch(
                FetchDescriptor<Game>(
                    predicate: #Predicate { $0.isCompleted && $0.gameType == type }
                )
            )) ?? []
            guard existing.isEmpty else { continue }

            // Fetch roster
            let players: [PlayerProfile] = (try? context.fetch(
                FetchDescriptor<PlayerProfile>(predicate: #Predicate { !$0.isArchived })
            )) ?? []
            let teams: [TeamProfile] = (try? context.fetch(
                FetchDescriptor<TeamProfile>(predicate: #Predicate { !$0.isArchived })
            )) ?? []

            // Prefer teams for doubles-leaning types; otherwise players
            if type.defaultTeamSize > 1, teams.count >= 2 {
                let t1 = teams.randomElement()!
                var t2 = teams.randomElement()!
                var guardCount = 0
                while t2.id == t1.id && guardCount < 5 { t2 = teams.randomElement()!; guardCount += 1 }

                let generated = CompletedGameFactory(context: context)
                    .assignTeams(t1, t2)
                    .gameType(type)
                    .timestamp(hoursAgo: 0)
                    .generateWithDate()

                context.insert(generated.game)
                try? store.complete(generated.game, at: generated.completionDate)
                continue
            }

            if players.count >= 2 {
                let shuffled = players.shuffled()
                let p1 = shuffled[0]
                let p2 = shuffled[1]

                let generated = CompletedGameFactory(context: context)
                    .assignPlayers(p1, p2)
                    .gameType(type)
                    .timestamp(hoursAgo: 0)
                    .generateWithDate()

                context.insert(generated.game)
                try? store.complete(generated.game, at: generated.completionDate)
                continue
            }

            // Fallback: create a basic anonymous game for the type (last-resort)
            let generated = CompletedGameFactory()
                .gameType(type)
                .timestamp(hoursAgo: 0)
                .generateWithDate()
            context.insert(generated.game)
            try? store.complete(generated.game, at: generated.completionDate)
        }
    }
}

