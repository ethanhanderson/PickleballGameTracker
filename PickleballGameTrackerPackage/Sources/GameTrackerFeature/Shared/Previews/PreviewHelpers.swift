import GameTrackerCore
import SwiftData
import SwiftUI

// MARK: - Preview Configuration

/// Shared preview configuration constants
public enum PreviewConfig {
    public static let accentColor = Color.green
    public static let previewAccentColor = Color.green

    /// Standard delay for async preview operations
    public static let previewDelay: Duration = .milliseconds(100)

    /// Common preview names for consistency
    public static let previewNames = (
        empty: "Empty State",
        withData: "With Data",
        liveGame: "Live Game",
        roster: "With Roster",
        statistics: "Statistics",
        search: "Search",
        catalog: "Catalog"
    )
}

// MARK: - Standard Environment Setup

/// Creates a fully configured preview environment with all managers properly set up
@MainActor
public struct PreviewEnvironmentSetup {
    public let environment: PreviewEnvironment.Context
    public let gameManager: SwiftDataGameManager
    public let activeGameStateManager: LiveGameStateManager
    public let rosterManager: PlayerTeamManager?

    /// Creates a standard preview environment setup
    public static func create(
        container: ModelContainer? = nil,
        configureLiveGame: Bool = false
    ) async throws -> PreviewEnvironmentSetup {
        let ctx = container ?? PreviewEnvironment.app().container
        let environment = PreviewEnvironment.custom(ctx)

        let storage = environment.storage
        let gameManager = SwiftDataGameManager(storage: storage)
        let activeGameStateManager = environment.activeGameStateManager
        let rosterManager = environment.rosterManager ?? PlayerTeamManager(storage: storage)

        // Configure active game state manager
        activeGameStateManager.configure(gameManager: gameManager)

        // Set up proper delegation
        gameManager.activeGameDelegate = activeGameStateManager

        // Configure live game if requested
        if configureLiveGame {
            try await environment.configureLiveGame()
        }

        return PreviewEnvironmentSetup(
            environment: environment,
            gameManager: gameManager,
            activeGameStateManager: activeGameStateManager,
            rosterManager: rosterManager
        )
    }

    /// Creates a minimal preview environment setup for component previews
    public static func createMinimal(
        container: ModelContainer? = nil
    ) -> PreviewEnvironmentSetup {
        let ctx = container ?? PreviewEnvironment.empty().container
        let environment = PreviewEnvironment.custom(ctx)

        let storage = environment.storage
        let gameManager = SwiftDataGameManager(storage: storage)
        let activeGameStateManager = LiveGameStateManager.production(storage: storage)
        let rosterManager = environment.rosterManager ?? PlayerTeamManager(storage: storage)

        // Configure minimal setup
        activeGameStateManager.configure(gameManager: gameManager)

        return PreviewEnvironmentSetup(
            environment: environment,
            gameManager: gameManager,
            activeGameStateManager: activeGameStateManager,
            rosterManager: rosterManager
        )
    }
}

// MARK: - Standard Preview View Modifiers

/// Standard modifiers for preview views
public extension View {
    /// Applies standard preview container and environment setup
    func previewContainer(_ environment: PreviewEnvironment.Context) -> some View {
        self
            .modelContainer(environment.container)
            .environment(environment.activeGameStateManager)
            .environment(environment.gameManager)
    }

    /// Applies preview configuration with accent color
    func previewConfiguration() -> some View {
        self
            .accentColor(PreviewConfig.previewAccentColor)
            .tint(PreviewConfig.previewAccentColor)
    }

    /// Standard preview setup for views that need full environment
    func standardPreview(
        environment: PreviewEnvironment.Context,
        configureLiveGame: Bool = false
    ) -> some View {
        self
            .previewContainer(environment)
            .previewConfiguration()
            // Note: configureLiveGame removed due to async issues in preview context
    }

    /// Minimal preview setup for component-level previews
    func minimalPreview(environment: PreviewEnvironment.Context) -> some View {
        self
            .previewContainer(environment)
            .previewConfiguration()
    }
}

// MARK: - Preview Data Helpers

/// Helper functions for creating common preview scenarios
@MainActor
public enum PreviewDataHelpers {
    /// Creates a preview with a specific game state
    public static func createGamePreview(
        game: Game,
        scenario: PreviewEnvironment.Scenario = .liveGame
    ) async throws -> some View {
        let env: PreviewEnvironment.Context = {
            switch scenario {
            case .app: return PreviewEnvironment.app()
            case .liveGame: return PreviewEnvironment.liveGame()
            case .catalog: return PreviewEnvironment.catalog()
            case .history: return PreviewEnvironment.history()
            case .statistics: return PreviewEnvironment.statistics()
            case .search: return PreviewEnvironment.search()
            case .roster: return PreviewEnvironment.roster()
            case .empty: return PreviewEnvironment.empty()
            case .custom(let container): return PreviewEnvironment.custom(container)
            }
        }()

        let setup = try await PreviewEnvironmentSetup.create(container: env.container, configureLiveGame: true)

        return AnyView(
            NavigationStack {
                LiveView(
                    game: game,
                    gameManager: setup.gameManager
                )
            }
            .previewContainer(setup.environment)
            .environment(setup.activeGameStateManager)
            .previewConfiguration()
        )
    }

    /// Creates a preview with roster data
    public static func createRosterPreview(
        container: ModelContainer? = nil
    ) -> some View {
        let ctx = container ?? PreviewEnvironment.roster().container
        let environment = PreviewEnvironment.custom(ctx)

        return AnyView(
            RosterView(manager: environment.rosterManager ?? PlayerTeamManager(storage: environment.storage))
                .previewContainer(environment)
                .previewConfiguration()
        )
    }

    /// Creates a preview with search functionality
    public static func createSearchPreview(
        initialSearchText: String = "",
        hasResults: Bool = true
    ) -> some View {
        let environment = PreviewEnvironment.custom(hasResults ? PreviewEnvironment.search().container : PreviewEnvironment.empty().container)

        return AnyView(
            GameSearchView(
                navigationState: AppNavigationState(),
                initialSearchText: initialSearchText,
                loadHistoryOnAppear: false
            )
            .previewContainer(environment)
            .previewConfiguration()
        )
    }
}

// MARK: - Legacy Migration Helpers

/// Helper to migrate from direct PreviewDataSeeder usage to PreviewEnvironment
@MainActor
public enum PreviewMigrationHelper {
    /// Migrates from direct PreviewDataSeeder.container() to PreviewEnvironment
    public static func migrateToEnvironment(
        currentContainer: ModelContainer,
        desiredScenario: PreviewEnvironment.Scenario
    ) -> PreviewEnvironment.Context {
        // For now, return the equivalent environment based on the scenario
        // This is a migration helper that can be used to gradually migrate files
        return PreviewEnvironment.custom(currentContainer)
    }

    /// Creates a PreviewEnvironment equivalent for common PreviewDataSeeder usage patterns
    public static func equivalentEnvironment(for seederMethod: String) -> PreviewEnvironment.Scenario {
        switch seederMethod {
        case "emptyContainer":
            return .empty
        case "liveGameContainer":
            return .liveGame
        case "statisticsContainer":
            return .statistics
        case "searchContainer":
            return .search
        case "rosterContainer":
            return .roster
        case "catalogContainer":
            return .catalog
        case "historyContainer":
            return .history
        default:
            return .app
        }
    }
}

// MARK: - Preview State Helpers

/// Helper for creating previews with specific UI states
@MainActor
public enum PreviewStateHelpers {
    /// Creates an empty state preview
    public static func emptyState(
        icon: String = "magnifyingglass",
        title: String = "No Data",
        description: String = "Nothing to show"
    ) -> some View {
        EmptyStateView(icon: icon, title: title, description: description)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Creates a loading state preview
    public static func loadingState() -> some View {
        ProgressView()
            .progressViewStyle(.circular)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Creates an error state preview
    public static func errorState(
        message: String = "Something went wrong"
    ) -> some View {
        ErrorView(error: NSError(domain: "PreviewError", code: 0, userInfo: [NSLocalizedDescriptionKey: message]), retry: nil)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
