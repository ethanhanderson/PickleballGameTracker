import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
public struct AppNavigationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LiveGameStateManager.self) private var activeGameStateManager

    @Namespace var animation

    @State private var rosterManager: PlayerTeamManager
    @State private var gameManager = SwiftDataGameManager()
    @State private var selectedTab: AppTab = .games
    @State private var showingLiveGameSheet = false
    @State private var deepLinkDestination: DeepLinkDestination?
    @State private var showDeepLink: Bool = false
    @State private var statisticsFilter:
        (gameId: String?, gameTypeId: String?)? = nil
    @State private var deepLinkObserver: (any NSObjectProtocol)? = nil
    @State private var showPersistenceResetPrompt: Bool = false
    @State private var liveOpenObserver: (any NSObjectProtocol)? = nil

    public init(
        rosterManager: PlayerTeamManager = PlayerTeamManager(),
        gameManager: SwiftDataGameManager? = nil
    ) {
        _rosterManager = State(initialValue: rosterManager)
        if let gameManager { _gameManager = State(initialValue: gameManager) }
    }

    private func applyDeepLink(_ destination: DeepLinkDestination) {
        switch destination {
        case .statistics(let gameId, let gameTypeId):
            statisticsFilter = (gameId, gameTypeId)
            selectedTab = .statistics
            showDeepLink = false
            deepLinkDestination = nil
        default:
            deepLinkDestination = destination
            showDeepLink = true
        }
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            Tab(
                "Games",
                systemImage: "rectangle.grid.2x2.fill",
                value: AppTab.games
            ) {
                CatalogView()
                    .accessibilityIdentifier("Tab.Games")
                    .tint(.accentColor)
            }

            Tab("History", systemImage: "clock", value: AppTab.history) {
                GameHistoryView()
                    .accessibilityIdentifier("Tab.History")
                    .tint(.accentColor)
            }

            Tab(
                "Roster",
                systemImage: "person.2",
                value: AppTab.roster
            ) {
                RosterView(manager: rosterManager)
                    .accessibilityIdentifier("Tab.Roster")
                    .tint(.accentColor)
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
                .tint(.accentColor)
            }

            Tab(
                "Search",
                systemImage: "magnifyingglass",
                value: AppTab.search,
                role: .search
            ) {
                GameSearchView(
                    navigationState: AppNavigationState()
                )
                .accessibilityIdentifier("Tab.Search")
                .tint(.accentColor)
            }
        }
        .environment(gameManager)
        .if(activeGameStateManager.hasActiveGame) { view in
            view.tabViewBottomAccessory {
                LiveGameMiniPreview(
                    onTap: { showingLiveGameSheet = true },
                    animation: animation
                )
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .task {
            activeGameStateManager.configure(gameManager: gameManager)

            Task.detached(priority: .background) {
                do {
                    let isHealthy = try await SwiftDataContainer.shared
                        .validateAndRecoverStore()
                    let stats = await SwiftDataContainer.shared
                        .getContainerStatistics()
                    await LoggingService.shared.log(
                        level: isHealthy ? .info : .warn,
                        event: .loadSucceeded,
                        message: "Store validation completed",
                        metadata: [
                            "isHealthy": String(isHealthy),
                            "gameCount": String(stats.gameCount),
                            "lastUpdated": String(
                                describing: stats.lastUpdated
                            ),
                        ]
                    )
                    let usingFallback = await MainActor.run {
                        SwiftDataContainer.shared.isUsingFallbackInMemory
                    }
                    if isHealthy == false || usingFallback {
                        await MainActor.run {
                            showPersistenceResetPrompt = true
                        }
                    }
                } catch {
                    await LoggingService.shared.log(
                        level: .error,
                        event: .loadFailed,
                        message: "Store validation error",
                        metadata: ["error": String(describing: error)]
                    )
                    await MainActor.run { showPersistenceResetPrompt = true }
                }
            }

            deepLinkObserver = DeepLinkBus.observe { dest in
                Task { @MainActor in
                    applyDeepLink(dest)
                }
            }

            liveOpenObserver = NotificationCenter.default.addObserver(
                forName: Notification.Name("OpenLiveGameRequested"),
                object: nil,
                queue: .main
            ) { _ in
                Task { @MainActor in
                    showingLiveGameSheet = true
                }
            }
        }
        .onDisappear {
            if let deepLinkObserver {
                NotificationCenter.default.removeObserver(deepLinkObserver)
            }
            if let liveOpenObserver {
                NotificationCenter.default.removeObserver(liveOpenObserver)
            }
            deepLinkObserver = nil
            liveOpenObserver = nil
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
                applyDeepLink(dest)
            } catch {
                Log.error(
                    error,
                    event: .loadFailed,
                    metadata: ["phase": "deepLinkResolve"]
                )
            }
        }
        .sheet(isPresented: $showingLiveGameSheet) {
            if let currentGame = activeGameStateManager.currentGame {
                NavigationStack {
                    LiveView(
                        game: currentGame,
                        gameManager: gameManager,
                        onDismiss: {
                            Task { @MainActor in
                                showingLiveGameSheet = false
                            }
                        },
                        animation: animation
                    )
                }
                .navigationTransition(.zoom(sourceID: "sheet", in: animation))
                .tint(.accentColor)
            }
        }
        .sheet(isPresented: $showDeepLink) {
            NavigationStack {
                DeepLinkDestinationView(
                    destination: deepLinkDestination,
                    gameManager: gameManager,
                    activeGameStateManager: activeGameStateManager
                )
            }
            .tint(.accentColor)
        }
        .sheet(isPresented: $showPersistenceResetPrompt) {
            PersistenceResetPromptView()
                .accessibilityIdentifier("PersistenceResetPrompt")
        }

    }
}

// MARK: - Previews

#Preview("Main") {
    let env = PreviewEnvironment.make(
        configuration: .init(
            scenario: .app,
            withLiveGame: true,
            withPlayerAssignments: true,
            gameState: .playing,
            randomizeTimer: true,
            startTimer: false
        )
    )
    AppNavigationView(
        rosterManager: env.rosterManager ?? PlayerTeamManager(storage: env.storage),
        gameManager: env.gameManager
    )
    .tint(.green)
    .modelContainer(env.container)
    .environment(env.activeGameStateManager)
}

#Preview("Blank") {
    let env = PreviewEnvironment.empty()
    AppNavigationView(
        rosterManager: PlayerTeamManager(storage: env.storage),
        gameManager: SwiftDataGameManager(storage: env.storage)
    )
    .tint(.green)
    .modelContainer(env.container)
    .environment(env.activeGameStateManager)
}
