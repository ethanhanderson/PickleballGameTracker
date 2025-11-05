import GameTrackerCore
import SwiftData
import SwiftUI
import UserNotifications

@MainActor
public struct AppNavigationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LiveGameStateManager.self) private var activeGameStateManager
    @Environment(SwiftDataGameManager.self) private var gameManager
    @Environment(LiveSyncCoordinator.self) private var syncCoordinator

    @Namespace var animation
    
    @State private var globalNav = GlobalNavigationState.shared
    @Environment(\.scenePhase) private var scenePhase

    @State private var selectedTab: AppTab = .games
    @State private var showingLiveGameSheet = false
    @State private var showingSetupSheet = false
    @State private var setupGameType: GameType?
    private struct SetupSheetToken: Identifiable {
        let id: String
        let gameType: GameType
    }
    @State private var setupSheet: SetupSheetToken?
    @State private var deepLinkDestination: DeepLinkDestination?
    @State private var showDeepLink: Bool = false
    @State private var statisticsFilter:
        (gameId: String?, gameTypeId: String?)? = nil
    @State private var deepLinkObserver: (any NSObjectProtocol)? = nil
    @State private var showPersistenceResetPrompt: Bool = false
    @State private var liveOpenObserver: (any NSObjectProtocol)? = nil
    @State private var setupRequestObserver: (any NSObjectProtocol)? = nil
    @State private var setupNotificationObserver: (any NSObjectProtocol)? = nil

    public init() {}
    
    private func handleSetupRequest(for gameType: GameType) async {
        let isAppInForeground = scenePhase == .active
        let isSetupOpen = globalNav.isSheetOpen("setup")
        let anySheetOpen = globalNav.hasOpenSheet
        
        if !isAppInForeground || (anySheetOpen && !isSetupOpen) {
            // Let the already-scheduled notification show when app not active
            // or another sheet is in the way (avoid interrupting current flow)
            Log.event(
                .actionTapped,
                level: .info,
                message: "Setup requested from watch → notification will show",
                metadata: [
                    "gameType": gameType.rawValue,
                    "reason": !isAppInForeground ? "appNotInForeground" : "otherSheetOpen"
                ]
            )
            return
        }
        
        // App is active; either no sheets or Setup already open → clear notification
        SetupNotificationService.shared.clearPendingNotifications()
        
        // If Setup isn't open yet, open it immediately; otherwise no-op
        if !isSetupOpen {
            openSetupSheet(for: gameType)
        } else {
            Log.event(
                .viewAppear,
                level: .info,
                message: "Setup requested from watch → Setup already open",
                metadata: ["gameType": gameType.rawValue]
            )
        }
    }
    
    private func openSetupSheet(for gameType: GameType) {
        if showDeepLink {
            showDeepLink = false
            deepLinkDestination = nil
        }
        setupGameType = gameType
        setupSheet = SetupSheetToken(
            id: gameType.rawValue,
            gameType: gameType
        )
        selectedTab = .games
        SetupNotificationService.shared.clearPendingNotifications()
        Log.event(
            .viewAppear,
            level: .info,
            message: "Setup requested from watch → opening SetupView",
            metadata: ["gameType": gameType.rawValue]
        )
    }

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
                setupSheet = SetupSheetToken(
                    id: gameType.rawValue,
                    gameType: gameType
                )
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
            }

            Tab("History", systemImage: "clock", value: AppTab.history) {
                HistoryView()
                    .accessibilityIdentifier("Tab.History")
            }

            Tab(
                "Roster",
                systemImage: "person.2",
                value: AppTab.roster
            ) {
                RosterView()
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
                    navigationState: AppNavigationState()
                )
                .accessibilityIdentifier("Tab.Search")
            }
        }
        .onAppear {
            globalNav.setCurrentRootView(rootId(for: selectedTab))
            globalNav.setCurrentTab(selectedTab)
            globalNav.setActive(scenePhase == .active)
        }
        .onChange(of: selectedTab) { _, newValue in
            globalNav.setCurrentTab(newValue)
            globalNav.setCurrentRootView(rootId(for: newValue))
        }
        .onChange(of: scenePhase) { _, newPhase in
            globalNav.setActive(newPhase == .active)
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
        // Auto-dismiss the live sheet when the live game ends or is cleared
        .onChange(of: activeGameStateManager.hasLiveGame) { _, hasLive in
            if hasLive == false {
                showingLiveGameSheet = false
            }
        }
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

            // Pending launch intent is handled in the app target and forwarded here via NotificationCenter

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
                let userInfo = notification.userInfo ?? [:]
                let resolved: GameType? = {
                    if let gt = userInfo["gameType"] as? GameType { return gt }
                    if let id = userInfo["gameTypeId"] as? String, let gt = GameType(rawValue: id) { return gt }
                    if let raw = userInfo["gameType"] as? String, let gt = GameType(rawValue: raw) { return gt }
                    return nil
                }()
                Task { @MainActor in
                    if let gt = resolved {
                        await handleSetupRequest(for: gt)
                    } else {
                        Log.event(
                            .loadFailed,
                            level: .warn,
                            message: "OpenSetupRequested missing/invalid gameType"
                        )
                    }
                }
            }
            
            setupNotificationObserver = NotificationCenter.default.addObserver(
                forName: .setupNotificationTapped,
                object: nil,
                queue: .main
            ) { notification in
                let userInfo = notification.userInfo ?? [:]
                let resolved: GameType? = {
                    if let gt = userInfo["gameType"] as? GameType { return gt }
                    if let id = userInfo["gameTypeId"] as? String, let gt = GameType(rawValue: id) { return gt }
                    if let raw = userInfo["gameType"] as? String, let gt = GameType(rawValue: raw) { return gt }
                    return nil
                }()
                Task { @MainActor in
                    if let gt = resolved {
                        openSetupSheet(for: gt)
                    } else {
                        Log.event(
                            .loadFailed,
                            level: .warn,
                            message: "setupNotificationTapped missing/invalid gameType"
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
            if let setupNotificationObserver {
                NotificationCenter.default.removeObserver(setupNotificationObserver)
            }
            deepLinkObserver = nil
            liveOpenObserver = nil
            setupRequestObserver = nil
            setupNotificationObserver = nil
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
            }
        }
        .onChange(of: showingLiveGameSheet) { _, isPresented in
            if isPresented {
                globalNav.registerSheet("liveGame")
            } else {
                globalNav.unregisterSheet("liveGame")
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
                            let game =
                                try await activeGameStateManager.startNewGame(
                                    with: config
                                )

                            Log.event(
                                .viewAppear,
                                level: .info,
                                message:
                                    "Game created from watch setup request",
                                context: .current(gameId: game.id),
                                metadata: [
                                    "gameType": gameType.rawValue,
                                    "teamSize": "\(matchup.teamSize)",
                                ]
                            )

                            // Standardize live presentation trigger
                            NotificationCenter.default.post(
                                name: Notification.Name(
                                    "OpenLiveGameRequested"
                                ),
                                object: nil
                            )

                            // Mirror game start on companion
                            // 1) Publish roster snapshot first to ensure identities exist
                            let rosterBuilder = RosterSnapshotBuilder(
                                storage: SwiftDataStorage.shared
                            )
                            if let roster = try? rosterBuilder.build(
                                includeArchived: false
                            ) {
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
        .onChange(of: setupSheet?.id) { _, _ in
            if setupSheet != nil {
                globalNav.registerSheet("setup")
            } else {
                globalNav.unregisterSheet("setup")
            }
        }
        .sheet(isPresented: $showDeepLink) {
            NavigationStack {
                DeepLinkDestinationView(
                    destination: deepLinkDestination
                )
            }
            .environment(gameManager)
            .environment(activeGameStateManager)
        }
        .onChange(of: showDeepLink) { _, isPresented in
            if isPresented {
                globalNav.registerSheet("deepLink")
            } else {
                globalNav.unregisterSheet("deepLink")
            }
        }
        .sheet(isPresented: $showPersistenceResetPrompt) {
            PersistenceResetPromptView()
                .accessibilityIdentifier("PersistenceResetPrompt")
        }
        .onChange(of: showPersistenceResetPrompt) { _, isPresented in
            if isPresented {
                globalNav.registerSheet("persistenceReset")
            } else {
                globalNav.unregisterSheet("persistenceReset")
            }
        }
    }

    private func rootId(for tab: AppTab) -> String {
        switch tab {
        case .games: return "root.games"
        case .history: return "root.history"
        case .roster: return "root.roster"
        case .statistics: return "root.statistics"
        case .search: return "root.search"
        }
    }
}

// MARK: - Previews

#Preview("Main") {
    let setup = PreviewContainers.liveGameSetup()
    let syncCoordinator = LiveSyncCoordinator(service: NoopSyncService())

    AppNavigationView()
        .tint(.green)
        .modelContainer(setup.container)
        .environment(setup.liveGameManager)
        .environment(setup.gameManager)
        .environment(setup.rosterManager)
        .environment(syncCoordinator)
}

#Preview("Blank") {
    let setup = PreviewContainers.emptySetup()
    let syncCoordinator = LiveSyncCoordinator(service: NoopSyncService())

    AppNavigationView()
        .tint(.green)
        .modelContainer(setup.container)
        .environment(setup.liveGameManager)
        .environment(setup.gameManager)
        .environment(setup.rosterManager)
        .environment(syncCoordinator)
}
