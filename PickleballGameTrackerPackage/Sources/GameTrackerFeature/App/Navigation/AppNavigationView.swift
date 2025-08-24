//
//  AppNavigationView.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 7/9/25.
//

import SwiftData
import SwiftUI

@MainActor
public struct AppNavigationView: View {
  @Environment(\.modelContext) private var modelContext
  @State private var rosterManager: PlayerTeamManager

  public init(rosterManager: PlayerTeamManager = PlayerTeamManager()) {
    _rosterManager = State(initialValue: rosterManager)
  }
  @State private var selectedTab: AppTab = .games
  @State private var showingActiveGameSheet = false

  @State private var gameManager = SwiftDataGameManager()
  @Environment(ActiveGameStateManager.self) private var activeGameStateManager

  @State private var deepLinkDestination: DeepLinkDestination?
  @State private var showDeepLink: Bool = false
  @State private var statisticsFilter: (gameId: String?, gameTypeId: String?)? = nil
  @State private var deepLinkObserver: (any NSObjectProtocol)? = nil

  // MARK: - Body

  public var body: some View {
    TabView(selection: $selectedTab) {
      Tab("Games", systemImage: "gamecontroller", value: AppTab.games) {
        GameHomeView()
          .accessibilityIdentifier("Tab.Games")
      }

      Tab("History", systemImage: "clock", value: AppTab.history) {
        GameHistoryView()
          .accessibilityIdentifier("Tab.History")
      }

      Tab(
        "Roster",
        systemImage: "person.2",
        value: AppTab.roster
      ) {
        RosterHomeView(manager: rosterManager)
          .accessibilityIdentifier("Tab.Roster")
      }

      Tab(
        "Statistics",
        systemImage: "chart.bar",
        value: AppTab.statistics
      ) {
        StatisticsHomeView(
          gameId: statisticsFilter?.gameId,
          gameTypeId: statisticsFilter?.gameTypeId
        )
        .accessibilityIdentifier("Tab.Statistics")
      }

      Tab(
        "Search",
        systemImage: "magnifyingglass",
        value: AppTab.search,
        role: .search
      ) {
        GameSearchView(
          modelContext: modelContext,
          navigationState: AppNavigationState()
        )
        .accessibilityIdentifier("Tab.Search")
      }
    }
    .accentColor(DesignSystem.Colors.primary)
    .environment(gameManager)
    .tabViewBottomAccessory {
      if activeGameStateManager.hasActiveGame {
        GamePreviewControls(
          onTap: {
            showingActiveGameSheet = true
          }
        )
      }
    }
    .tabBarMinimizeBehavior(.onScrollDown)
    .task {
      // Configure both managers with proper relationships
      activeGameStateManager.configure(
        with: modelContext,
        gameManager: gameManager
      )
      // Ensure device sync is enabled so watch sees phone-created games
      activeGameStateManager.setSyncEnabled(true)

      // Observe in-app deep link requests via DeepLinkBus
      deepLinkObserver = DeepLinkBus.observe { dest in
        Task { @MainActor in
          switch dest {
          case .statistics(let gameId, let gameTypeId):
            statisticsFilter = (gameId, gameTypeId)
            selectedTab = .statistics
            showDeepLink = false
            deepLinkDestination = nil
          default:
            deepLinkDestination = dest
            showDeepLink = true
          }
        }
      }
    }
    .onDisappear {
      if let deepLinkObserver { NotificationCenter.default.removeObserver(deepLinkObserver) }
      deepLinkObserver = nil
    }
    .onOpenURL { url in
      do {
        let dest = try DeepLinkResolver().resolve(url)
        Log.event(
          .viewAppear,
          level: .info,
          message: "Deep link resolved",
          metadata: ["url": url.absoluteString]
        )
        switch dest {
        case .statistics(let gameId, let gameTypeId):
          statisticsFilter = (gameId, gameTypeId)
          selectedTab = .statistics
          showDeepLink = false
          deepLinkDestination = nil
        default:
          deepLinkDestination = dest
          showDeepLink = true
        }
      } catch {
        Log.error(
          error,
          event: .loadFailed,
          metadata: ["phase": "deepLinkResolve"]
        )
      }
    }
    .fullScreenCover(isPresented: $showingActiveGameSheet) {
      if let currentGame = activeGameStateManager.currentGame {
        NavigationStack {
          ActiveGameView(
            game: currentGame,
            gameManager: gameManager,
            onDismiss: {
              showingActiveGameSheet = false
            }
          )
        }
        .interactiveDismissDisabled(true)
      }
    }
    // Deep link presentation as a top-level sheet for non-Statistics destinations in v0.3
    .sheet(isPresented: $showDeepLink) {
      NavigationStack {
        DeepLinkDestinationView(
          destination: deepLinkDestination,
          gameManager: gameManager,
          activeGameStateManager: activeGameStateManager
        )
      }
    }

  }
}

// MARK: - Preview Support

extension AppNavigationView {
  fileprivate static func createPreviewContainer() -> ModelContainer {
    return SwiftDataContainer.createPreviewContainer()
  }

  fileprivate static var blankPreview: some View {
    let container = try! PreviewGameData.createPreviewContainer(with: [])
    let context = container.mainContext

    UserDefaults.standard.removeObject(forKey: "GameSearchHistory")

    let rosterManager = PlayerTeamManager(storage: SwiftDataStorage(modelContainer: container))

    return AppNavigationView(rosterManager: rosterManager)
      .modelContainer(container)
      .environment(ActiveGameStateManager.shared)
      .task {
        let stateManager = ActiveGameStateManager.shared
        stateManager.configure(with: context)
        stateManager.clearCurrentGame()
        try? context.delete(model: PlayerProfile.self)
        try? context.delete(model: TeamProfile.self)
        try? context.delete(model: GameTypePreset.self)
        try? context.delete(model: Game.self)
        try? context.delete(model: GameSummary.self)
        try? context.save()
      }
  }

  fileprivate static var populatedPreview: some View {
    let container = try! PreviewGameData.createFullPreviewContainer()
    let context = container.mainContext

    UserDefaults.standard.set(
      [GameType.training.rawValue, GameType.recreational.rawValue, GameType.tournament.rawValue],
      forKey: "GameSearchHistory")

    let rosterManager = PlayerTeamManager(storage: SwiftDataStorage(modelContainer: container))
    let alice = try? rosterManager.createPlayer(name: "Alice")
    let bob = try? rosterManager.createPlayer(name: "Bob")
    _ = try? rosterManager.createPlayer(name: "Charlie")
    if let a = alice, let b = bob {
      _ = try? rosterManager.createTeam(name: "Aces", players: [a, b])
    }

    return AppNavigationView(rosterManager: rosterManager)
      .modelContainer(container)
      .environment(ActiveGameStateManager.shared)
      .task {
        let stateManager = ActiveGameStateManager.shared
        stateManager.configure(with: context)
        stateManager.setCurrentGame(PreviewGameData.midGame)
        rosterManager.refreshAll()
      }
  }
}

// MARK: - Previews

#Preview("Blank") { AppNavigationView.blankPreview }

#Preview("Fully Populated") { AppNavigationView.populatedPreview }
