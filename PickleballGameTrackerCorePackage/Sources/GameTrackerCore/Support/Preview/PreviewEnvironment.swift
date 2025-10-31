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
    case gameSetup // Game setup with roster, variations, and history (no active game)
    case empty // Empty state for empty view testing
    case custom(ModelContainer) // Custom container
    
    /// Returns the appropriate container for this scenario.
    ///
    /// This computed property encapsulates the mapping between scenarios and their
    /// container creation methods, eliminating the need for manual switch statements
    /// when creating containers.
    ///
    /// - Note: When adding a new scenario, implement its case here and create the
    ///   corresponding container method in `PreviewDataSeeder`.
    @MainActor
    var containerProvider: ModelContainer {
      switch self {
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
      case .gameSetup:
        return PreviewDataSeeder.gameSetupContainer()
      case .empty:
        return PreviewDataSeeder.emptyContainer()
      case .custom(let container):
        return container
      }
    }
    
    /// Indicates whether this scenario should include a roster manager.
    ///
    /// Used to determine if `PlayerTeamManager` should be initialized for this
    /// scenario's context.
    var needsRosterManager: Bool {
      switch self {
      case .app, .liveGame, .roster, .gameSetup:
        return true
      case .catalog, .history, .statistics, .search, .empty, .custom:
        return false
      }
    }
    
    /// Configuration characteristics for this scenario.
    ///
    /// Defines the default configuration settings for each scenario, eliminating
    /// the need for manual configuration initialization in `Configuration` static
    /// properties.
    ///
    /// - Note: When adding a new scenario, define its characteristics here to
    ///   automatically generate its configuration preset.
    var configurationCharacteristics: (
      withLiveGame: Bool,
      withPlayerAssignments: Bool,
      gameState: GameState?
    ) {
      switch self {
      case .app:
        return (withLiveGame: true, withPlayerAssignments: true, gameState: nil)
      case .liveGame:
        return (withLiveGame: true, withPlayerAssignments: true, gameState: .playing)
      case .catalog:
        return (withLiveGame: false, withPlayerAssignments: false, gameState: nil)
      case .history:
        return (withLiveGame: false, withPlayerAssignments: false, gameState: nil)
      case .statistics:
        return (withLiveGame: false, withPlayerAssignments: true, gameState: nil)
      case .search:
        return (withLiveGame: false, withPlayerAssignments: true, gameState: nil)
      case .roster:
        return (withLiveGame: false, withPlayerAssignments: true, gameState: nil)
      case .gameSetup:
        return (withLiveGame: false, withPlayerAssignments: true, gameState: nil)
      case .empty:
        return (withLiveGame: false, withPlayerAssignments: false, gameState: nil)
      case .custom:
        return (withLiveGame: false, withPlayerAssignments: false, gameState: nil)
      }
    }
    
    /// Creates a `Context` directly from this scenario using default configuration.
    ///
    /// This convenience method eliminates the need for separate static helper functions
    /// on `PreviewEnvironment`. Instead of calling `PreviewEnvironment.app()`, you can
    /// call `PreviewEnvironment.Scenario.app.makeContext()`.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Direct scenario-to-context
    /// let env = PreviewEnvironment.Scenario.app.makeContext()
    ///
    /// // Or use the PreviewEnvironment helper (maintained for compatibility)
    /// let env = PreviewEnvironment.app()
    /// ```
    ///
    /// - Returns: A fully configured `Context` for this scenario.
    @MainActor
    public func makeContext() -> PreviewEnvironment.Context {
      let characteristics = configurationCharacteristics
      let configuration = Configuration(
        scenario: self,
        withLiveGame: characteristics.withLiveGame,
        withPlayerAssignments: characteristics.withPlayerAssignments,
        gameState: characteristics.gameState
      )
      return PreviewEnvironment.make(configuration: configuration)
    }
  }

  public struct Configuration: Sendable {
    public let scenario: Scenario
    public let withLiveGame: Bool
    public let withPlayerAssignments: Bool
    public let gameState: GameState?
    public let randomizeTimer: Bool
    public let initialElapsedTime: TimeInterval?
    public let startTimer: Bool

    public init(
      scenario: Scenario,
      withLiveGame: Bool = false,
      withPlayerAssignments: Bool = false,
      gameState: GameState? = nil,
      randomizeTimer: Bool = false,
      initialElapsedTime: TimeInterval? = nil,
      startTimer: Bool = true
    ) {
      self.scenario = scenario
      self.withLiveGame = withLiveGame
      self.withPlayerAssignments = withPlayerAssignments
      self.gameState = gameState
      self.randomizeTimer = randomizeTimer
      self.initialElapsedTime = initialElapsedTime
      self.startTimer = startTimer
    }

    // MARK: - Configuration Presets
    //
    // These presets are auto-generated from scenario characteristics.
    // When adding a new scenario, define its characteristics in
    // `Scenario.configurationCharacteristics` and the preset will be
    // automatically available here.
    
    public static var app: Configuration {
      let characteristics = Scenario.app.configurationCharacteristics
      return Configuration(
        scenario: .app,
        withLiveGame: characteristics.withLiveGame,
        withPlayerAssignments: characteristics.withPlayerAssignments,
        gameState: characteristics.gameState
      )
    }
    
    public static var liveGame: Configuration {
      let characteristics = Scenario.liveGame.configurationCharacteristics
      return Configuration(
        scenario: .liveGame,
        withLiveGame: characteristics.withLiveGame,
        withPlayerAssignments: characteristics.withPlayerAssignments,
        gameState: characteristics.gameState
      )
    }
    
    public static var catalog: Configuration {
      let characteristics = Scenario.catalog.configurationCharacteristics
      return Configuration(
        scenario: .catalog,
        withLiveGame: characteristics.withLiveGame,
        withPlayerAssignments: characteristics.withPlayerAssignments,
        gameState: characteristics.gameState
      )
    }
    
    public static var history: Configuration {
      let characteristics = Scenario.history.configurationCharacteristics
      return Configuration(
        scenario: .history,
        withLiveGame: characteristics.withLiveGame,
        withPlayerAssignments: characteristics.withPlayerAssignments,
        gameState: characteristics.gameState
      )
    }
    
    public static var statistics: Configuration {
      let characteristics = Scenario.statistics.configurationCharacteristics
      return Configuration(
        scenario: .statistics,
        withLiveGame: characteristics.withLiveGame,
        withPlayerAssignments: characteristics.withPlayerAssignments,
        gameState: characteristics.gameState
      )
    }
    
    public static var search: Configuration {
      let characteristics = Scenario.search.configurationCharacteristics
      return Configuration(
        scenario: .search,
        withLiveGame: characteristics.withLiveGame,
        withPlayerAssignments: characteristics.withPlayerAssignments,
        gameState: characteristics.gameState
      )
    }
    
    public static var roster: Configuration {
      let characteristics = Scenario.roster.configurationCharacteristics
      return Configuration(
        scenario: .roster,
        withLiveGame: characteristics.withLiveGame,
        withPlayerAssignments: characteristics.withPlayerAssignments,
        gameState: characteristics.gameState
      )
    }
    
    public static var gameSetup: Configuration {
      let characteristics = Scenario.gameSetup.configurationCharacteristics
      return Configuration(
        scenario: .gameSetup,
        withLiveGame: characteristics.withLiveGame,
        withPlayerAssignments: characteristics.withPlayerAssignments,
        gameState: characteristics.gameState
      )
    }
    
    public static var empty: Configuration {
      let characteristics = Scenario.empty.configurationCharacteristics
      return Configuration(
        scenario: .empty,
        withLiveGame: characteristics.withLiveGame,
        withPlayerAssignments: characteristics.withPlayerAssignments,
        gameState: characteristics.gameState
      )
    }

    public static func custom(_ container: ModelContainer) -> Configuration {
      Configuration(scenario: .custom(container), withLiveGame: false, withPlayerAssignments: false, gameState: nil)
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
    let container = configuration.scenario.containerProvider
    let storage = SwiftDataStorage(modelContainer: container)
    let gameManager = SwiftDataGameManager(storage: storage)
    let active = LiveGameStateManager.production(storage: storage)

    let rosterManager: PlayerTeamManager? = configuration.scenario.needsRosterManager
      ? PlayerTeamManager(storage: storage)
      : nil

    // Configure live game state if needed
    if configuration.withLiveGame {
      Task { @MainActor in
        active.configure(gameManager: gameManager)
        do {
          var allGames = try container.mainContext.fetch(FetchDescriptor<Game>())
          if allGames.isEmpty {
            _ = try await PreviewGameData.createRandomLiveGame(using: gameManager)
            allGames = try container.mainContext.fetch(FetchDescriptor<Game>())
          }
          var candidate = allGames.first(where: { !$0.isCompleted })
          if candidate == nil {
            _ = try await PreviewGameData.createRandomLiveGame(using: gameManager)
            allGames = try container.mainContext.fetch(FetchDescriptor<Game>())
            candidate = allGames.first(where: { !$0.isCompleted }) ?? allGames.first
          }
          if let firstGame = candidate {
            // Apply desired game state via manager where possible
            if let desiredState = configuration.gameState {
              switch desiredState {
              case .playing:
                await active.setCurrentGame(firstGame)
                // Ensure timer reset before applying elapsed
                active.setElapsedTime(0)
                // Apply timer configuration
                if let initial = configuration.initialElapsedTime {
                  active.setElapsedTime(initial)
                } else if configuration.randomizeTimer {
                  let minutes = Int.random(in: 1...35)
                  let seconds = Int.random(in: 0...59)
                  let random = TimeInterval(minutes * 60 + seconds)
                  active.setElapsedTime(random)
                }
                if configuration.startTimer {
                  try? await active.startGame()
                } else {
                  // Keep game in playing state but timer not running
                  firstGame.gameState = .playing
                  await active.setCurrentGame(firstGame)
                }
              case .paused:
                await active.setCurrentGame(firstGame)
                if let initial = configuration.initialElapsedTime {
                  active.setElapsedTime(initial)
                } else if configuration.randomizeTimer {
                  let minutes = Int.random(in: 1...35)
                  let seconds = Int.random(in: 0...59)
                  let random = TimeInterval(minutes * 60 + seconds)
                  active.setElapsedTime(random)
                }
                // Ensure paused state
                try? await active.pauseGame()
              case .initial, .completed, .serving:
                firstGame.gameState = desiredState
                await active.setCurrentGame(firstGame)
                if let initial = configuration.initialElapsedTime {
                  active.setElapsedTime(initial)
                } else if configuration.randomizeTimer {
                  let minutes = Int.random(in: 1...35)
                  let seconds = Int.random(in: 0...59)
                  let random = TimeInterval(minutes * 60 + seconds)
                  active.setElapsedTime(random)
                }
              }
            } else {
              // No explicit desired state; still set current and optional timer
              await active.setCurrentGame(firstGame)
              if let initial = configuration.initialElapsedTime {
                active.setElapsedTime(initial)
              } else if configuration.randomizeTimer {
                let minutes = Int.random(in: 1...35)
                let seconds = Int.random(in: 0...59)
                let random = TimeInterval(minutes * 60 + seconds)
                active.setElapsedTime(random)
              }
            }
          }
        } catch {
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


  // MARK: - Convenience Helpers
  //
  // These helpers delegate to `Scenario.makeContext()` for a consistent API.
  // They are maintained for backward compatibility and ergonomics.
  //
  // You can also use the scenario directly: `Scenario.app.makeContext()`

  public static func app() -> Context {
    Scenario.app.makeContext()
  }

  public static func liveGame() -> Context {
    Scenario.liveGame.makeContext()
  }

  public static func catalog() -> Context {
    Scenario.catalog.makeContext()
  }

  public static func history() -> Context {
    Scenario.history.makeContext()
  }

  public static func statistics() -> Context {
    Scenario.statistics.makeContext()
  }

  public static func search() -> Context {
    Scenario.search.makeContext()
  }

  public static func roster() -> Context {
    Scenario.roster.makeContext()
  }

  public static func gameSetup() -> Context {
    Scenario.gameSetup.makeContext()
  }

  public static func empty() -> Context {
    Scenario.empty.makeContext()
  }

  public static func custom(_ container: ModelContainer) -> Context {
    Scenario.custom(container).makeContext()
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
  public func configureLiveGame() async throws {
    guard rosterManager != nil else { return }

    // Ensure there's a live game in the container; if none, create a simple one
    let allGames = try container.mainContext.fetch(FetchDescriptor<Game>())
    if let liveGame = allGames.first(where: { $0.gameState == .playing }) {
      await activeGameStateManager.setCurrentGame(liveGame)
      if liveGame.gameState == .initial {
        try await activeGameStateManager.startGame()
      }
    } else {
      // Create a basic live game for preview context
      let game = Game(gameType: .recreational)
      game.gameState = .playing
      container.mainContext.insert(game)
      try container.mainContext.save()
      await activeGameStateManager.setCurrentGame(game)
    }
  }

  /// Configures a live game with optional state and timer parameters
  @MainActor
  public func configureLiveGame(
    gameState: GameState = .playing,
    initialElapsedTime: TimeInterval? = nil,
    randomizeElapsedTime: Bool = false
  ) async throws {
    // Ensure we have at least one game to work with
    var allGames = try container.mainContext.fetch(FetchDescriptor<Game>())
    if allGames.isEmpty {
      _ = try await PreviewGameData.createRandomLiveGame(using: gameManager)
      allGames = try container.mainContext.fetch(FetchDescriptor<Game>())
    }

    guard let firstGame = allGames.first else { return }

    // Set current game
    await activeGameStateManager.setCurrentGame(firstGame)

    // Apply elapsed time if requested
    if let initialElapsedTime {
      activeGameStateManager.setElapsedTime(initialElapsedTime)
    } else if randomizeElapsedTime {
      let random = TimeInterval(Int.random(in: 0...(15 * 60)))
      activeGameStateManager.setElapsedTime(random)
    }

    // Apply desired game state
    switch gameState {
    case .playing:
      try? await activeGameStateManager.startGame()
    case .paused:
      try? await activeGameStateManager.pauseGame()
    case .initial:
      firstGame.gameState = .initial
    case .completed:
      firstGame.gameState = .completed
      firstGame.isCompleted = true
      firstGame.completedDate = Date()
    case .serving:
      firstGame.gameState = .serving
    }
  }
}

// MARK: - Simplified Preview API (Modern)

/// Modern, simplified preview helpers that delegate to PreviewContainers.
///
/// These provide cleaner, more maintainable preview setup compared to the legacy
/// PreviewEnvironment.Context pattern. New code should prefer PreviewContainers directly.
extension PreviewEnvironment {
    
    /// Create a simple container for a scenario (delegates to PreviewContainers)
    ///
    /// This is a compatibility bridge. New code should use `PreviewContainers` directly:
    ///
    /// ```swift
    /// // Preferred:
    /// .modelContainer(PreviewContainers.standard())
    ///
    /// // Legacy (still supported):
    /// .modelContainer(PreviewEnvironment.container(for: .app))
    /// ```
    @available(*, deprecated, message: "Use PreviewContainers directly for new code")
    public static func container(for scenario: Scenario) -> ModelContainer {
        switch scenario {
        case .app: return PreviewContainers.standard()
        case .liveGame: return PreviewContainers.liveGame()
        case .catalog, .gameSetup: return PreviewContainers.standard()
        case .history, .search, .statistics: return PreviewContainers.history()
        case .roster: return PreviewContainers.roster()
        case .empty: return PreviewContainers.empty()
        case .custom(let container): return container
        }
    }
    
    /// Create managers for operations (delegates to PreviewContainers)
    ///
    /// This is a compatibility bridge. New code should use `PreviewContainers.managers()` directly.
    @available(*, deprecated, message: "Use PreviewContainers.managers() for new code")
    public static func createManagers(for container: ModelContainer) -> (
        gameManager: SwiftDataGameManager,
        liveGameManager: LiveGameStateManager
    ) {
        return PreviewContainers.managers(for: container)
    }
}
