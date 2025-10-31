import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
public struct AppNavigationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LiveGameStateManager.self) private var activeGameStateManager
    @Environment(SwiftDataGameManager.self) private var gameManager
    @Environment(LiveSyncCoordinator.self) private var syncCoordinator

    @Namespace var animation

    @State private var selectedTab: AppTab = .games
    @State private var showingLiveGameSheet = false
    @State private var showingSetupSheet = false
    @State private var setupGameType: GameType?
    private struct SetupSheetToken: Identifiable { let id: String; let gameType: GameType }
    @State private var setupSheet: SetupSheetToken?
    @State private var deepLinkDestination: DeepLinkDestination?
    @State private var showDeepLink: Bool = false
    @State private var statisticsFilter:
        (gameId: String?, gameTypeId: String?)? = nil
    @State private var deepLinkObserver: (any NSObjectProtocol)? = nil
    @State private var showPersistenceResetPrompt: Bool = false
    @State private var liveOpenObserver: (any NSObjectProtocol)? = nil
    @State private var setupRequestObserver: (any NSObjectProtocol)? = nil

    public init() {}

    private func applyDeepLink(_ destination: DeepLinkDestination) {
        switch destination {
        case .statistics(let gameId, let gameTypeId):
            statisticsFilter = (gameId, gameTypeId)
            selectedTab = .statistics
            showDeepLink = false
            deepLinkDestination = nil
        case .setup(let gameTypeId):
            if let gameType = GameType(rawValue: gameTypeId) {
                setupGameType = gameType
                setupSheet = SetupSheetToken(id: gameType.rawValue, gameType: gameType)
            }
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
                HistoryView()
                    .accessibilityIdentifier("Tab.History")
                    .tint(.accentColor)
            }

            Tab(
                "Roster",
                systemImage: "person.2",
                value: AppTab.roster
            ) {
                RosterView()
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
        // Sync v2 is always on; no explicit enable needed
        .if(activeGameStateManager.hasLiveGame) { view in
            view.tabViewBottomAccessory {
                LiveGameMiniPreview(
                    onTap: { showingLiveGameSheet = true },
                    animation: animation
                )
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .task {
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

            setupRequestObserver = NotificationCenter.default.addObserver(
                forName: Notification.Name("OpenSetupRequested"),
                object: nil,
                queue: .main
            ) { notification in
                let gameType = notification.userInfo?["gameType"] as? GameType
                Task { @MainActor in
                    if let gameType {
                        // Ensure any existing deep-link sheet is dismissed
                        if showDeepLink {
                            showDeepLink = false
                            deepLinkDestination = nil
                        }
                        // Present SetupView directly for parity with phone flow
                        setupGameType = gameType
                        setupSheet = SetupSheetToken(id: gameType.rawValue, gameType: gameType)
                        selectedTab = .games
                        Log.event(
                            .viewAppear,
                            level: .info,
                            message: "Setup requested from watch → opening SetupView",
                            metadata: ["gameType": gameType.rawValue]
                        )
                    }
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
            if let setupRequestObserver {
                NotificationCenter.default.removeObserver(setupRequestObserver)
            }
            deepLinkObserver = nil
            liveOpenObserver = nil
            setupRequestObserver = nil
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
                        onDismiss: {
                            Task { @MainActor in
                                showingLiveGameSheet = false
                            }
                        },
                        animation: animation
                    )
                }
                .environment(gameManager)
                .navigationTransition(.zoom(sourceID: "sheet", in: animation))
                .tint(.accentColor)
            }
        }
        .sheet(item: $setupSheet) { token in
            let gameType = token.gameType
            SetupView(
                gameType: gameType,
                onStartGame: { gameType, rules, matchup in
                    setupSheet = nil
                    Task { @MainActor in
                        do {
                            let config = GameStartConfiguration(
                                gameType: gameType,
                                matchup: matchup,
                                rules: rules
                            )
                            let game = try await activeGameStateManager.startNewGame(with: config)

                            Log.event(
                                .viewAppear,
                                level: .info,
                                message: "Game created from watch setup request",
                                context: .current(gameId: game.id),
                                metadata: [
                                    "gameType": gameType.rawValue,
                                    "teamSize": "\(matchup.teamSize)"
                                ]
                            )

                            // Standardize live presentation trigger
                            NotificationCenter.default.post(
                                name: Notification.Name("OpenLiveGameRequested"),
                                object: nil
                            )

                            // Mirror game start on companion
                            // 1) Publish roster snapshot first to ensure identities exist
                            let rosterBuilder = RosterSnapshotBuilder(storage: SwiftDataStorage.shared)
                            if let roster = try? rosterBuilder.build(includeArchived: false) {
                                try? await syncCoordinator.publishRoster(roster)
                            }
                            // 2) Publish start configuration with gameId so watch uses same ID
                            let cfg = GameStartConfiguration(
                                gameId: game.id,
                                gameType: config.gameType,
                                teamSize: config.teamSize,
                                participants: config.participants,
                                notes: config.notes,
                                rules: config.rules
                            )
                            try? await syncCoordinator.publishStart(cfg)
                        } catch {
                            Log.error(
                                error,
                                event: .saveFailed,
                                metadata: ["phase": "setupFromWatch"]
                            )
                        }
                    }
                }
            )
            .environment(gameManager)
            .environment(activeGameStateManager)
        }
        .sheet(isPresented: $showDeepLink) {
            NavigationStack {
                DeepLinkDestinationView(
                    destination: deepLinkDestination
                )
            }
            .environment(gameManager)
            .environment(activeGameStateManager)
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
    let setup = PreviewContainers.liveGameSetup()
    
    AppNavigationView()
        .tint(.green)
        .modelContainer(setup.container)
        .environment(setup.liveGameManager)
        .environment(setup.gameManager)
        .environment(setup.rosterManager)
}

#Preview("Blank") {
    let setup = PreviewContainers.emptySetup()
    
    AppNavigationView()
        .tint(.green)
        .modelContainer(setup.container)
        .environment(setup.liveGameManager)
        .environment(setup.gameManager)
        .environment(setup.rosterManager)
}
