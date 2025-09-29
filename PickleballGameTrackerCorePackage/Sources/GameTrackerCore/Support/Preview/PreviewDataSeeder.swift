import Foundation
import SwiftData

@MainActor
public enum PreviewDataSeeder {
  public static func containerWithSampleData() -> ModelContainer {
    SwiftDataContainer.createPreviewContainer { context in
      SwiftDataSeeding.seedCommonVariations(into: context)

      // Fetch a seeded variation for the sample game
      if let variation = try? context.fetch(
        FetchDescriptor<GameVariation>(predicate: #Predicate { $0.name == "Recreational Doubles" })
      ).first {
        let game = Game(gameVariation: variation)
        game.score1 = 7
        game.score2 = 5
        context.insert(game)
      }
    }
  }

  // New: standard API used by previews/tests per Phase 3
  public static func container() -> ModelContainer {
    SwiftDataContainer.createPreviewContainer { context in
      // Seed: a few common scenarios to keep previews consistent
      SwiftDataSeeding.seedCommonVariations(into: context)

      let rec = try? context.fetch(
        FetchDescriptor<GameVariation>(predicate: #Predicate { $0.name == "Recreational Doubles" })
      ).first
      let tour = try? context.fetch(
        FetchDescriptor<GameVariation>(predicate: #Predicate { $0.name == "Tournament Doubles" })
      ).first

      if let rec {
        let g1 = Game(gameVariation: rec)
        g1.score1 = 6
        g1.score2 = 4
        context.insert(g1)

        let g2 = Game(gameVariation: rec)
        g2.score1 = 10
        g2.score2 = 9
        context.insert(g2)
      }

      if let tour {
        let g3 = Game(gameVariation: tour)
        g3.score1 = 15
        g3.score2 = 13
        g3.completeGame()
        context.insert(g3)
      }
    }
  }

  // New: empty container for empty-state previews/tests
  public static func emptyContainer() -> ModelContainer {
    SwiftDataContainer.createPreviewContainer()
  }

  // New: catalog-focused container (alias to container for now)
  public static func catalogContainer() -> ModelContainer {
    container()
  }

  // New: history-focused container that ensures GameSummary records are created
  public static func historyContainer() -> ModelContainer {
    SwiftDataContainer.createPreviewContainer { context in
      // Seed a couple variations
      SwiftDataSeeding.seedCommonVariations(into: context)

      // Use GameStore so summaries are produced
      let store = GameStore(context: context)

      let historyTemplates: [Game] =
        PreviewGameData.competitivePlayerGames
        + PreviewGameData.recreationalPlayerGames
        + PreviewGameData.newPlayerGames

      for template in historyTemplates {
        let g = Game(gameType: template.gameType)
        g.score1 = template.score1
        g.score2 = template.score2
        g.currentServer = template.currentServer
        g.serverNumber = template.serverNumber
        g.totalRallies = template.totalRallies
        g.createdDate = template.createdDate
        g.lastModified = template.lastModified
        g.isArchived = template.isArchived
        if template.isCompleted {
          g.duration = template.duration
        }
        context.insert(g)
        if template.isCompleted {
          try? store.complete(g, at: template.completedDate ?? .now)
        } else {
          try? store.save(g)
        }
      }
    }
  }

  // New: app-wide container with roster, variations, history, and one active game
  public static func appContainer() -> ModelContainer {
    SwiftDataContainer.createPreviewContainer { context in
      // Seed sample roster via new system
      SwiftDataSeeding.seedSampleRoster(into: context)

      // Seed common variations
      SwiftDataSeeding.seedCommonVariations(into: context)

      // Seed history via GameStore for summaries
      let store = GameStore(context: context)
      let historyTemplates: [Game] =
        PreviewGameData.competitivePlayerGames
        + PreviewGameData.recreationalPlayerGames
        + PreviewGameData.newPlayerGames
      for template in historyTemplates {
        let g = Game(gameType: template.gameType)
        g.score1 = template.score1
        g.score2 = template.score2
        g.currentServer = template.currentServer
        g.serverNumber = template.serverNumber
        g.totalRallies = template.totalRallies
        g.createdDate = template.createdDate
        g.lastModified = template.lastModified
        if template.isCompleted {
          g.duration = template.duration
        }
        context.insert(g)
        if template.isCompleted {
          try? store.complete(g, at: template.completedDate ?? .now)
        } else {
          try? store.save(g)
        }
      }

      // Add one active in-progress game for the preview bar
      // Create a named variation using available roster if possible
      let players = try? context.fetch(FetchDescriptor<PlayerProfile>()).filter { !$0.isArchived }
      let teams = try? context.fetch(FetchDescriptor<TeamProfile>()).filter { !$0.isArchived }
      let useSingles: Bool = {
        switch ((players?.count ?? 0) >= 2, (teams?.count ?? 0) >= 2) {
        case (true, true): return Bool.random()
        case (true, false): return true
        case (false, true): return false
        default: return true
        }
      }()

      if useSingles, let players, players.count >= 2 {
        let p = players.shuffled()
        let p1 = p[0], p2 = p[1]
        let variation = try? GameVariation.createValidated(
          name: "\(p1.name) vs \(p2.name)",
          gameType: .recreational,
          teamSize: 1,
          winningScore: 11,
          winByTwo: true,
          kitchenRule: true,
          doubleBounceRule: true,
          servingRotation: .standard,
          sideSwitchingRule: .never,
          scoringType: .sideOut,
          isCustom: true
        )
        let activeGame = Game(gameVariation: variation ?? GameVariation(name: "Preview Singles", gameType: .recreational, teamSize: 1))
        activeGame.score1 = Int.random(in: 0...10)
        activeGame.score2 = Int.random(in: 0...10)
        activeGame.currentServer = [1, 2].randomElement()!
        activeGame.serverNumber = 1
        activeGame.totalRallies = Int.random(in: 8...24)
        activeGame.lastModified = .now
        context.insert(activeGame)
        try? store.save(activeGame)
      } else if let teams, teams.count >= 2 {
        let t = teams.shuffled()
        let t1 = t[0], t2 = t[1]
        let variation = try? GameVariation.createValidated(
          name: "\(t1.name) vs \(t2.name)",
          gameType: .recreational,
          teamSize: 2,
          winningScore: 11,
          winByTwo: true,
          kitchenRule: true,
          doubleBounceRule: true,
          servingRotation: .standard,
          sideSwitchingRule: .never,
          scoringType: .sideOut,
          isCustom: true
        )
        let activeGame = Game(gameVariation: variation ?? GameVariation(name: "Preview Doubles", gameType: .recreational, teamSize: 2))
        activeGame.score1 = Int.random(in: 0...10)
        activeGame.score2 = Int.random(in: 0...10)
        activeGame.currentServer = [1, 2].randomElement()!
        activeGame.serverNumber = [1, 2].randomElement()!
        activeGame.totalRallies = Int.random(in: 8...24)
        activeGame.lastModified = .now
        context.insert(activeGame)
        try? store.save(activeGame)
      } else {
        // Fallback to generic midGame
        let active = PreviewGameData.midGame
        let activeGame = Game(gameType: active.gameType)
        activeGame.score1 = active.score1
        activeGame.score2 = active.score2
        activeGame.currentServer = active.currentServer
        activeGame.serverNumber = active.serverNumber
        activeGame.totalRallies = active.totalRallies
        activeGame.lastModified = .now
        context.insert(activeGame)
        try? store.save(activeGame)
      }
    }
  }

  // New: live game container with roster and active game for LiveView-style previews
  public static func liveGameContainer() -> ModelContainer {
    SwiftDataContainer.createPreviewContainer { context in
      // Seed sample roster
      SwiftDataSeeding.seedSampleRoster(into: context)

      // Seed common variations
      SwiftDataSeeding.seedCommonVariations(into: context)

      // Create a random active game (similar to LiveView helper logic)
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

        let variation: GameVariation
        if let existing = try! context.fetch(FetchDescriptor<GameVariation>()).first(where: { $0.name == "\(p1.name) vs \(p2.name)" }) {
          variation = existing
        } else {
          variation = try! GameVariation.createValidated(
            name: "\(p1.name) vs \(p2.name)",
            gameType: .recreational,
            teamSize: 1,
            winningScore: 11,
            winByTwo: true,
            kitchenRule: true,
            doubleBounceRule: true,
            servingRotation: .standard,
            sideSwitchingRule: .never,
            scoringType: .sideOut,
            isCustom: true
          )
        }

        let game = Game(gameVariation: variation)
        game.currentServer = [1, 2].randomElement()!
        game.serverNumber = 1
        game.gameState = .playing
        game.score1 = Int.random(in: 0...10)
        game.score2 = Int.random(in: 0...10)
        context.insert(game)
      } else if activeTeams.count >= 2 {
        let shuffled = activeTeams.shuffled()
        let t1 = shuffled[0]
        let t2 = shuffled[1]

        let variation: GameVariation
        let allVariations = try! context.fetch(FetchDescriptor<GameVariation>())
        if let existing = allVariations.first(where: { $0.name == "\(t1.name) vs \(t2.name)" }) {
          variation = existing
        } else {
          variation = try! GameVariation.createValidated(
            name: "\(t1.name) vs \(t2.name)",
            gameType: .recreational,
            teamSize: 2,
            winningScore: 11,
            winByTwo: true,
            kitchenRule: true,
            doubleBounceRule: true,
            servingRotation: .standard,
            sideSwitchingRule: .never,
            scoringType: .sideOut,
            isCustom: true
          )
        }

        let game = Game(gameVariation: variation)

        game.currentServer = [1, 2].randomElement()!
        game.serverNumber = [1, 2].randomElement()!
        game.gameState = .playing
        game.score1 = Int.random(in: 0...10)
        game.score2 = Int.random(in: 0...10)
        context.insert(game)
      }
    }
  }

  // New: statistics-focused container with rich game history for statistics calculations
  public static func statisticsContainer() -> ModelContainer {
    SwiftDataContainer.createPreviewContainer { context in
      // Seed sample roster for player statistics
      // SwiftDataSeeding.seedSampleRoster(into: context)

      // Seed common variations
      // SwiftDataSeeding.seedCommonVariations(into: context)

      // Create diverse game history for meaningful statistics
      // TODO: Add comprehensive seeding when compilation issues are resolved
      // let store = GameStore(context: context)
      // let historyTemplates: [Game] = PreviewGameData.competitivePlayerGames +
      //   PreviewGameData.recreationalPlayerGames +
      //   PreviewGameData.newPlayerGames +
      //   PreviewGameData.tournamentGames +
      //   PreviewGameData.casualGames

      // for template in historyTemplates {
      //   let g = Game(gameVariation: template.gameVariation)
      //   g.score1 = template.score1
      //   g.score2 = template.score2
      //   g.currentServer = template.currentServer
      //   g.serverNumber = template.serverNumber
      //   g.totalRallies = template.totalRallies
      //   g.createdDate = template.createdDate
      //   g.lastModified = template.lastModified
      //   g.isArchived = template.isArchived
      //   if template.isCompleted {
      //     g.duration = template.duration
      //   }
      //   context.insert(g)
      //   if template.isCompleted {
      //     try? store.complete(g, at: template.completedDate ?? .now)
      //   } else {
      //     try? store.save(g)
      //   }
      // }
    }
  }

  // New: search-focused container with searchable content
  public static func searchContainer() -> ModelContainer {
    SwiftDataContainer.createPreviewContainer { context in
      // Seed sample roster with varied names for search testing
      SwiftDataSeeding.seedSampleRoster(into: context)

      // Seed common variations
      SwiftDataSeeding.seedCommonVariations(into: context)

      // Create mixed game history with varied metadata for search
      let store = GameStore(context: context)
      let searchTemplates: [Game] = PreviewGameData.competitivePlayerGames +
        PreviewGameData.recreationalPlayerGames

      for template in searchTemplates {
        let g = Game(gameVariation: template.gameVariation!)
        g.score1 = template.score1
        g.score2 = template.score2
        g.currentServer = template.currentServer
        g.serverNumber = template.serverNumber
        g.totalRallies = template.totalRallies
        g.createdDate = template.createdDate
        g.lastModified = template.lastModified
        if template.isCompleted {
          g.duration = template.duration
        }
        context.insert(g)
        if template.isCompleted {
          try? store.complete(g, at: template.completedDate ?? .now)
        } else {
          try? store.save(g)
        }
      }
    }
  }

  // New: roster-focused container for player/team management views
  public static func rosterContainer() -> ModelContainer {
    SwiftDataContainer.createPreviewContainer { context in
      // Seed comprehensive roster for management testing
      SwiftDataSeeding.seedSampleRoster(into: context)

      // Add some variations for context
      SwiftDataSeeding.seedCommonVariations(into: context)
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
    case .empty:
      return PreviewEnvironment.make(configuration: .empty)
    case .custom(let container):
      return PreviewEnvironment.make(configuration: .custom(container))
    }
  }
}
