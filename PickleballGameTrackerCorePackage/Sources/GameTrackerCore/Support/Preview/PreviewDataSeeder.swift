import Foundation
import SwiftData

/// Centralized preview data seeding with configurable data quantities.
///
/// ## Overview
///
/// `PreviewDataSeeder` provides a composable architecture for generating preview data
/// with centralized configuration of data quantities. All seeding methods use the shared
/// `quantities` configuration, making it easy to adjust preview data density globally.
///
/// ## Basic Usage
///
/// ```swift
/// // Use default quantities (standard preset)
/// let container = PreviewDataSeeder.appContainer()
///
/// // Switch to minimal data for faster previews
/// PreviewDataSeeder.quantities = .minimal
/// let minimalContainer = PreviewDataSeeder.appContainer()
///
/// // Use extensive data for performance testing
/// PreviewDataSeeder.quantities = .extensive
/// let largeContainer = PreviewDataSeeder.appContainer()
/// ```
///
/// ## Custom Quantities
///
/// ```swift
/// // Create custom configuration
/// PreviewDataSeeder.quantities = PreviewDataSeeder.DataQuantities(
///   historyPlayerGamesCount: 20,
///   historyTeamGamesCount: 10,
///   historyTimeRangeDays: 45,
///   searchGamesCount: 25,
///   searchTimeRangeDays: 45,
///   gameSetupHistoryCount: 15,
///   gameSetupTimeRangeDays: 30,
///   rosterPlayerCount: 16,
///   rosterTeamSize: 2
/// )
///
/// let customContainer = PreviewDataSeeder.appContainer()
/// ```
///
/// ## Presets
///
/// Three predefined quantity presets are available:
///
/// - `.standard` - Default quantities, balanced for most previews
///   - 12 player games, 6 team games in history
///   - 12 players on roster
///   - 30-day time range
///
/// - `.minimal` - Minimal data for fast preview loading
///   - 3 player games, 2 team games in history
///   - 4 players on roster
///   - 7-day time range
///
/// - `.extensive` - Large dataset for stress testing
///   - 25 player games, 15 team games in history
///   - 20 players on roster
///   - 90-day time range
///
/// ## Architecture
///
/// All container methods compose dedicated seeding methods that reference the shared
/// `quantities` configuration. Changes to quantities automatically propagate to all
/// environments that use those seeding methods.
@MainActor
public enum PreviewDataSeeder {
  
  // MARK: - Configuration
  
  public struct DataQuantities: Sendable {
    public let historyPlayerGamesCount: Int
    public let historyTeamGamesCount: Int
    public let historyTimeRangeDays: Int
    public let searchGamesCount: Int
    public let searchTimeRangeDays: Int
    public let gameSetupHistoryCount: Int
    public let gameSetupTimeRangeDays: Int
    public let rosterPlayerCount: Int
    public let rosterTeamSize: Int
    
    public init(
      historyPlayerGamesCount: Int = 12,
      historyTeamGamesCount: Int = 6,
      historyTimeRangeDays: Int = 30,
      searchGamesCount: Int = 15,
      searchTimeRangeDays: Int = 30,
      gameSetupHistoryCount: Int = 12,
      gameSetupTimeRangeDays: Int = 30,
      rosterPlayerCount: Int = 12,
      rosterTeamSize: Int = 2
    ) {
      self.historyPlayerGamesCount = historyPlayerGamesCount
      self.historyTeamGamesCount = historyTeamGamesCount
      self.historyTimeRangeDays = historyTimeRangeDays
      self.searchGamesCount = searchGamesCount
      self.searchTimeRangeDays = searchTimeRangeDays
      self.gameSetupHistoryCount = gameSetupHistoryCount
      self.gameSetupTimeRangeDays = gameSetupTimeRangeDays
      self.rosterPlayerCount = rosterPlayerCount
      self.rosterTeamSize = rosterTeamSize
    }
    
    public static let standard = DataQuantities()
    
    public static let minimal = DataQuantities(
      historyPlayerGamesCount: 3,
      historyTeamGamesCount: 2,
      historyTimeRangeDays: 7,
      searchGamesCount: 5,
      searchTimeRangeDays: 7,
      gameSetupHistoryCount: 3,
      gameSetupTimeRangeDays: 7,
      rosterPlayerCount: 4,
      rosterTeamSize: 2
    )
    
    public static let extensive = DataQuantities(
      historyPlayerGamesCount: 25,
      historyTeamGamesCount: 15,
      historyTimeRangeDays: 90,
      searchGamesCount: 30,
      searchTimeRangeDays: 90,
      gameSetupHistoryCount: 20,
      gameSetupTimeRangeDays: 60,
      rosterPlayerCount: 20,
      rosterTeamSize: 2
    )
  }
  
  public static var quantities: DataQuantities = .standard
  
  // MARK: - Dedicated Seeding Methods
  
  public static func seedRosterData(into context: ModelContext) {
    SwiftDataSeeding.seedSampleRoster(
      into: context,
      playerCount: quantities.rosterPlayerCount,
      teamSize: quantities.rosterTeamSize
    )
  }
  
  public static func seedCatalogData(into context: ModelContext) {
    // No catalog data to seed - variations are planned for v0.6
  }
  
  public static func seedHistoryData(into context: ModelContext, store: GameStore) {
    let players = try? context.fetch(FetchDescriptor<PlayerProfile>()).filter { !$0.isArchived }
    let teams = try? context.fetch(FetchDescriptor<TeamProfile>()).filter { !$0.isArchived }
    
    if let players, players.count >= 2 {
      for _ in 0..<quantities.historyPlayerGamesCount {
        let generated = CompletedGameFactory(context: context)
          .withPlayers()
          .gameType([.recreational, .tournament, .training].randomElement()!)
          .timestamp(withinDays: quantities.historyTimeRangeDays)
          .generateWithDate()
        context.insert(generated.game)
        try? store.complete(generated.game, at: generated.completionDate)
      }
    }
    
    if let teams, teams.count >= 2 {
      for _ in 0..<quantities.historyTeamGamesCount {
        let generated = CompletedGameFactory(context: context)
          .withTeams()
          .gameType([.recreational, .tournament].randomElement()!)
          .timestamp(withinDays: quantities.historyTimeRangeDays)
          .generateWithDate()
        context.insert(generated.game)
        try? store.complete(generated.game, at: generated.completionDate)
      }
    }
  }
  
  public static func seedLiveGameData(into context: ModelContext) {
    let activePlayers = try! context.fetch(FetchDescriptor<PlayerProfile>()).filter { !$0.isArchived }
    let activeTeams = try! context.fetch(FetchDescriptor<TeamProfile>()).filter { !$0.isArchived }

    let doSingles: Bool = {
      switch (activePlayers.count >= 2, activeTeams.count >= 2) {
      case (true, true): return Bool.random()
      case (true, false): return true
      case (false, true): return false
      default: return true
      }
    }()

    if doSingles, activePlayers.count >= 2 {
      let shuffled = activePlayers.shuffled()
      let p1 = shuffled[0]
      let p2 = shuffled[1]

      let game = ActiveGameFactory(context: context)
        .gameType(.recreational)
        .midGame()
        .state(.playing)
        .server(team: [1, 2].randomElement()!, player: 1)
        .generate()
      game.participantMode = .players
      game.side1PlayerIds = [p1.id]
      game.side2PlayerIds = [p2.id]
      context.insert(game)
    } else if activeTeams.count >= 2 {
      let shuffled = activeTeams.shuffled()
      let t1 = shuffled[0]
      let t2 = shuffled[1]

      let game = ActiveGameFactory(context: context)
        .gameType(.recreational)
        .midGame()
        .state(.playing)
        .server(team: [1, 2].randomElement()!, player: [1, 2].randomElement()!)
        .generate()
      game.participantMode = .teams
      game.side1TeamId = t1.id
      game.side2TeamId = t2.id
      context.insert(game)
    }
  }
  
  public static func seedSearchData(into context: ModelContext, store: GameStore) {
    let generatedGames = CompletedGameFactory.realisticHistory(
      count: quantities.searchGamesCount,
      withinDays: quantities.searchTimeRangeDays
    )
    for generated in generatedGames {
      context.insert(generated.game)
      try? store.complete(generated.game, at: generated.completionDate)
    }
  }
  
  public static func seedGameSetupData(into context: ModelContext, store: GameStore) {
    let generatedGames = CompletedGameFactory.realisticHistory(
      count: quantities.gameSetupHistoryCount,
      withinDays: quantities.gameSetupTimeRangeDays
    )
    for generated in generatedGames {
      context.insert(generated.game)
      try? store.complete(generated.game, at: generated.completionDate)
    }
  }
  
  public static func seedStatisticsData(into context: ModelContext, store: GameStore) {
    // TODO: Add comprehensive seeding when compilation issues are resolved
  }
  
  // MARK: - Container Methods
  
  public static func containerWithSampleData() -> ModelContainer {
    SwiftDataContainer.createPreviewContainer { context in
      let game = Game(gameType: .recreational)
      game.score1 = 7
      game.score2 = 5
      context.insert(game)
    }
  }

  public static func container() -> ModelContainer {
    SwiftDataContainer.createPreviewContainer { context in
      let g1 = Game(gameType: .recreational)
      g1.score1 = 6
      g1.score2 = 4
      context.insert(g1)

      let g2 = Game(gameType: .recreational)
      g2.score1 = 10
      g2.score2 = 9
      context.insert(g2)

      let g3 = Game(gameType: .tournament)
      g3.score1 = 15
      g3.score2 = 13
      g3.completeGame()
      context.insert(g3)
    }
  }

  public static func emptyContainer() -> ModelContainer {
    SwiftDataContainer.createPreviewContainer()
  }

  public static func catalogContainer() -> ModelContainer {
    SwiftDataContainer.createPreviewContainer { context in
      seedCatalogData(into: context)
    }
  }

  public static func historyContainer() -> ModelContainer {
    SwiftDataContainer.createPreviewContainer { context in
      seedRosterData(into: context)
      seedCatalogData(into: context)
      let store = GameStore(context: context)
      seedHistoryData(into: context, store: store)
    }
  }

  public static func appContainer() -> ModelContainer {
    SwiftDataContainer.createPreviewContainer { context in
      let store = GameStore(context: context)
      
      seedRosterData(into: context)
      seedCatalogData(into: context)
      seedHistoryData(into: context, store: store)
      seedSearchData(into: context, store: store)
      seedGameSetupData(into: context, store: store)
      seedStatisticsData(into: context, store: store)
      seedLiveGameData(into: context)
    }
  }

  public static func liveGameContainer() -> ModelContainer {
    SwiftDataContainer.createPreviewContainer { context in
      seedRosterData(into: context)
      seedCatalogData(into: context)
      seedLiveGameData(into: context)
    }
  }

  public static func statisticsContainer() -> ModelContainer {
    SwiftDataContainer.createPreviewContainer { context in
      seedRosterData(into: context)
      seedCatalogData(into: context)
      let store = GameStore(context: context)
      seedStatisticsData(into: context, store: store)
    }
  }

  public static func searchContainer() -> ModelContainer {
    SwiftDataContainer.createPreviewContainer { context in
      seedRosterData(into: context)
      seedCatalogData(into: context)
      let store = GameStore(context: context)
      seedSearchData(into: context, store: store)
    }
  }

  public static func rosterContainer() -> ModelContainer {
    SwiftDataContainer.createPreviewContainer { context in
      seedRosterData(into: context)
      seedCatalogData(into: context)
    }
  }

  public static func gameSetupContainer() -> ModelContainer {
    SwiftDataContainer.createPreviewContainer { context in
      seedRosterData(into: context)
      seedCatalogData(into: context)
      let store = GameStore(context: context)
      seedGameSetupData(into: context, store: store)
    }
  }

  // New: helper to create full preview environment with managers for LiveView-style previews
  public static func createLiveGamePreviewEnvironment() -> (
    container: ModelContainer,
    gameManager: SwiftDataGameManager,
    activeGameStateManager: LiveGameStateManager
  ) {
    let container = liveGameContainer()
    let storage = SwiftDataStorage(modelContainer: container)
    let gameManager = SwiftDataGameManager(storage: storage)

    let activeGameStateManager = LiveGameStateManager.production()
    activeGameStateManager.configure(gameManager: gameManager)

    return (container, gameManager, activeGameStateManager)
  }

  // MARK: - PreviewEnvironment Integration Helpers

  public static func makePreviewEnvironment(
    for scenario: PreviewEnvironment.Scenario
  ) -> PreviewEnvironment.Context {
    switch scenario {
    case .app:
      return PreviewEnvironment.make(configuration: .app)
    case .liveGame:
      return PreviewEnvironment.make(configuration: .liveGame)
    case .catalog:
      return PreviewEnvironment.make(configuration: .catalog)
    case .history:
      return PreviewEnvironment.make(configuration: .history)
    case .statistics:
      return PreviewEnvironment.make(configuration: .statistics)
    case .search:
      return PreviewEnvironment.make(configuration: .search)
    case .roster:
      return PreviewEnvironment.make(configuration: .roster)
    case .gameSetup:
      return PreviewEnvironment.make(configuration: .gameSetup)
    case .empty:
      return PreviewEnvironment.make(configuration: .empty)
    case .custom(let container):
      return PreviewEnvironment.make(configuration: .custom(container))
    }
  }
}
