import Foundation
import SwiftData

@MainActor
public enum PreviewEnvironment {

  public enum Scenario: Sendable {
    case app // Full app state with roster, variations, history, and active game
    case liveGame // Live game scenario with roster and active game
    case catalog // Game catalog with variations only
    case history // History with completed games and summaries
    case statistics // Rich data for statistics views
    case search // Mixed data for search functionality
    case roster // Player and team management
    case empty // Empty state for empty view testing
    case custom(ModelContainer) // Custom container
  }

  public struct Configuration: Sendable {
    public let scenario: Scenario
    public let withActiveGame: Bool
    public let withPlayerAssignments: Bool
    public let gameState: GameState?

    public static let app: Configuration = Configuration(scenario: .app, withActiveGame: true, withPlayerAssignments: true, gameState: nil)
    public static let liveGame: Configuration = Configuration(scenario: .liveGame, withActiveGame: true, withPlayerAssignments: true, gameState: .playing)
    public static let catalog: Configuration = Configuration(scenario: .catalog, withActiveGame: false, withPlayerAssignments: false, gameState: nil)
    public static let history: Configuration = Configuration(scenario: .history, withActiveGame: false, withPlayerAssignments: false, gameState: nil)
    public static let statistics: Configuration = Configuration(scenario: .statistics, withActiveGame: false, withPlayerAssignments: true, gameState: nil)
    public static let search: Configuration = Configuration(scenario: .search, withActiveGame: false, withPlayerAssignments: true, gameState: nil)
    public static let roster: Configuration = Configuration(scenario: .roster, withActiveGame: false, withPlayerAssignments: true, gameState: nil)
    public static let empty: Configuration = Configuration(scenario: .empty, withActiveGame: false, withPlayerAssignments: false, gameState: nil)

    public static func custom(_ container: ModelContainer) -> Configuration {
      Configuration(scenario: .custom(container), withActiveGame: false, withPlayerAssignments: false, gameState: nil)
    }
  }

  public struct Context {
    public let container: ModelContainer
    public let storage: SwiftDataStorage
    public let gameManager: SwiftDataGameManager
    public let activeGameStateManager: LiveGameStateManager
    public let configuration: Configuration
    public let rosterManager: PlayerTeamManager?

    public init(
      container: ModelContainer,
      storage: SwiftDataStorage,
      gameManager: SwiftDataGameManager,
      activeGameStateManager: LiveGameStateManager,
      configuration: Configuration,
      rosterManager: PlayerTeamManager? = nil
    ) {
      self.container = container
      self.storage = storage
      self.gameManager = gameManager
      self.activeGameStateManager = activeGameStateManager
      self.configuration = configuration
      self.rosterManager = rosterManager
    }
  }

  public static func make(configuration: Configuration = .app) -> Context {
    let container = makeContainer(for: configuration)
    let storage = SwiftDataStorage(modelContainer: container)
    let gameManager = SwiftDataGameManager(storage: storage)
    let active = LiveGameStateManager.production(storage: storage)

    let rosterManager: PlayerTeamManager? = {
      switch configuration.scenario {
      case .app, .liveGame, .roster:
        return PlayerTeamManager(storage: storage, autoRefresh: false)
      default:
        return nil
      }
    }()

    // Configure active game state if needed
    if configuration.withActiveGame {
      Task { @MainActor in
        active.configure(gameManager: gameManager)
        if let desiredState = configuration.gameState {
          do {
            let allGames = try container.mainContext.fetch(FetchDescriptor<Game>())
            if let firstGame = allGames.first {
              firstGame.gameState = desiredState
            }
          } catch {
          }
        }
      }
    }

    return Context(
      container: container,
      storage: storage,
      gameManager: gameManager,
      activeGameStateManager: active,
      configuration: configuration,
      rosterManager: rosterManager
    )
  }

  private static func makeContainer(for configuration: Configuration) -> ModelContainer {
    switch configuration.scenario {
    case .app:
      return PreviewDataSeeder.appContainer()
    case .liveGame:
      return PreviewDataSeeder.liveGameContainer()
    case .catalog:
      return PreviewDataSeeder.catalogContainer()
    case .history:
      return PreviewDataSeeder.historyContainer()
    case .statistics:
      return PreviewDataSeeder.statisticsContainer()
    case .search:
      return PreviewDataSeeder.searchContainer()
    case .roster:
      return PreviewDataSeeder.rosterContainer()
    case .empty:
      return PreviewDataSeeder.emptyContainer()
    case .custom(let container):
      return container
    }
  }

  // MARK: - Convenience Helpers

  public static func app() -> Context {
    make(configuration: .app)
  }

  public static func liveGame() -> Context {
    make(configuration: .liveGame)
  }

  public static func catalog() -> Context {
    make(configuration: .catalog)
  }

  public static func history() -> Context {
    make(configuration: .history)
  }

  public static func statistics() -> Context {
    make(configuration: .statistics)
  }

  public static func search() -> Context {
    make(configuration: .search)
  }

  public static func roster() -> Context {
    make(configuration: .roster)
  }

  public static func empty() -> Context {
    make(configuration: .empty)
  }

  public static func custom(_ container: ModelContainer) -> Context {
    make(configuration: .custom(container))
  }

  // MARK: - Component Preview Helpers

  /// Creates a minimal environment for component previews (no active game, minimal data)
  public static func component() -> Context {
    make(configuration: .empty)
  }

  /// Creates an environment with sample game data for component testing
  public static func componentWithGame() -> Context {
    make(configuration: .liveGame)
  }

  /// Creates an environment with roster data for component testing
  public static func componentWithRoster() -> Context {
    make(configuration: .roster)
  }

  /// Creates a minimal environment for testing empty states
  public static func emptyComponent() -> Context {
    make(configuration: .empty)
  }

  // MARK: - Game State Specific Helpers

  /// Creates an environment with a paused game for testing
  @MainActor
  public static func pausedGame() -> Context {
    let env = make(configuration: .liveGame)

    do {
      let allGames = try env.container.mainContext.fetch(FetchDescriptor<Game>())
      if let game = allGames.first(where: { $0.gameState == .playing }) {
        game.gameState = .paused
      }
    } catch {
    }

    return env
  }

  /// Creates an environment with a completed game for testing
  @MainActor
  public static func completedGame() -> Context {
    let env = make(configuration: .history)

    do {
      let allGames = try env.container.mainContext.fetch(FetchDescriptor<Game>())
      if let game = allGames.first(where: { $0.gameState == .playing }) {
        game.gameState = .completed
        game.isCompleted = true
        game.completedDate = Date()
      }
    } catch {
    }

    return env
  }

  // MARK: - Search and Filter Helpers

  /// Creates an environment with search data for testing search functionality
  public static func searchableData() -> Context {
    make(configuration: .search)
  }

  /// Creates an environment with statistics data for testing statistical views
  public static func statisticsData() -> Context {
    make(configuration: .statistics)
  }
}

// MARK: - PreviewEnvironment Extensions

extension PreviewEnvironment.Context {
  @MainActor
  public var hasActiveGame: Bool {
    // Check if there's an active game in the container
    do {
      let allGames = try container.mainContext.fetch(FetchDescriptor<Game>())
      return allGames.contains(where: { $0.gameState == .playing })
    } catch {
      return false
    }
  }

  @MainActor
  public var gameCount: Int {
    do {
      let descriptor = FetchDescriptor<Game>()
      return try container.mainContext.fetchCount(descriptor)
    } catch {
      return 0
    }
  }

  @MainActor
  public var playerCount: Int {
    do {
      let allPlayers = try container.mainContext.fetch(FetchDescriptor<PlayerProfile>())
      return allPlayers.filter { !$0.isArchived }.count
    } catch {
      return 0
    }
  }

  @MainActor
  public func configureActiveGame() async throws {
    guard let rosterManager else { return }

    // Refresh roster to ensure we have players
    rosterManager.refreshAll()

    // Ensure there's an active game in the container; if none, create a simple one
    let allGames = try container.mainContext.fetch(FetchDescriptor<Game>())
    if let activeGame = allGames.first(where: { $0.gameState == .playing }) {
      activeGameStateManager.setCurrentGame(activeGame)
      if activeGame.gameState == .initial {
        try await activeGameStateManager.startGame()
      }
    } else {
      // Create a basic active game for preview context
      let game = Game(gameType: .recreational)
      game.gameState = .playing
      container.mainContext.insert(game)
      try container.mainContext.save()
      activeGameStateManager.setCurrentGame(game)
    }
  }
}


