import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
public struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LiveGameStateManager.self) private var activeGameStateManager
    @Environment(SwiftDataGameManager.self) private var gameManager
    @Environment(LiveSyncCoordinator.self) private var syncCoordinator

    @State private var globalNav = GlobalNavigationState.shared
    @Environment(\.scenePhase) private var scenePhase

    @State private var showingLiveGameSheet = false
    @State private var setupSheet: SetupSheetToken?
    @State private var deepLinkDestination: DeepLinkDestination?
    @State private var showDeepLink: Bool = false
    @State private var statisticsFilter: (gameId: String?, gameTypeId: String?)? = nil
    @State private var deepLinkObserver: (any NSObjectProtocol)? = nil
    @State private var showPersistenceResetPrompt: Bool = false
    @State private var liveOpenObserver: (any NSObjectProtocol)? = nil
    @State private var setupRequestObserver: (any NSObjectProtocol)? = nil
    @State private var setupNotificationObserver: (any NSObjectProtocol)? = nil
    @State private var selectedTab: AppTab = .games

    public init() {}

    private var mainTabView: some View {
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
                    gameId: nil,
                    gameTypeId: nil
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
        .applyLiveGameBottomAccessory(
            hasLiveGame: activeGameStateManager.hasLiveGame,
            onTap: {
                NotificationCenter.default.post(
                    name: Notification.Name("OpenLiveGameRequested"),
                    object: nil
                )
            }
        )
        .tabBarMinimizeBehavior(.onScrollDown)
    }

    public var body: some View {
        mainTabView
            .applyLiveGameSheet(
                showingLiveGameSheet: $showingLiveGameSheet,
                currentGame: activeGameStateManager.currentGame,
                gameManager: gameManager,
                globalNav: globalNav
            )
            .applySetupSheet(
                setupSheet: $setupSheet,
                gameManager: gameManager,
                activeGameStateManager: activeGameStateManager,
                globalNav: globalNav,
                handleSetupGameStart: handleSetupGameStart
            )
            .applyDeepLinkSheet(
                showDeepLink: $showDeepLink,
                deepLinkDestination: deepLinkDestination,
                gameManager: gameManager,
                activeGameStateManager: activeGameStateManager,
                globalNav: globalNav
            )
            .applyPersistenceResetSheet(
                showPersistenceResetPrompt: $showPersistenceResetPrompt,
                globalNav: globalNav
            )
            .task { await setupObservers() }
            .onDisappear { cleanupObservers() }
            .onOpenURL { url in
                handleDeepLink(url: url)
            }
    }

    // MARK: - Setup & Coordination

    private func handleSetupRequest(for gameType: GameType) async {
        let isAppInForeground = scenePhase == .active
        let isSetupOpen = globalNav.isSheetOpen("setup")
        let anySheetOpen = globalNav.hasOpenSheet

        if !isAppInForeground || (anySheetOpen && !isSetupOpen) {
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

        SetupNotificationService.shared.clearPendingNotifications()

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
        setupSheet = SetupSheetToken(id: gameType.rawValue, gameType: gameType)
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
            // The Statistics tab selection is managed by the destination view
            showDeepLink = false
            deepLinkDestination = nil
        case .setup(let gameTypeId):
            if let gameType = GameType(rawValue: gameTypeId) {
                setupSheet = SetupSheetToken(id: gameType.rawValue, gameType: gameType)
            }
        default:
            deepLinkDestination = destination
            showDeepLink = true
        }
    }

    private func handleDeepLink(url: URL) {
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

    private func handleSetupGameStart(gameType: GameType, rules: GameRules?, matchup: MatchupSelection) async {
        setupSheet = nil
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
                    "teamSize": "\(matchup.teamSize)",
                ]
            )

            NotificationCenter.default.post(
                name: Notification.Name("OpenLiveGameRequested"),
                object: nil
            )

            let rosterBuilder = RosterSnapshotBuilder(storage: SwiftDataStorage.shared)
            if let roster = try? rosterBuilder.build(includeArchived: false) {
                try? await syncCoordinator.publishRoster(roster)
            }
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
            Log.error(error, event: .saveFailed, metadata: ["phase": "setupFromWatch"])
        }
    }

    private func setupObservers() async {
        Task.detached(priority: .background) {
            do {
                let isHealthy = try await SwiftDataContainer.shared.validateAndRecoverStore()
                let stats = await SwiftDataContainer.shared.getContainerStatistics()
                await LoggingService.shared.log(
                    level: isHealthy ? .info : .warn,
                    event: .loadSucceeded,
                    message: "Store validation completed",
                    metadata: [
                        "isHealthy": String(isHealthy),
                        "gameCount": String(stats.gameCount),
                        "lastUpdated": String(describing: stats.lastUpdated),
                    ]
                )
                let usingFallback = await MainActor.run { SwiftDataContainer.shared.isUsingFallbackInMemory }
                if isHealthy == false || usingFallback {
                    await MainActor.run { showPersistenceResetPrompt = true }
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

    private func cleanupObservers() {
        if let deepLinkObserver { NotificationCenter.default.removeObserver(deepLinkObserver) }
        if let liveOpenObserver { NotificationCenter.default.removeObserver(liveOpenObserver) }
        if let setupRequestObserver { NotificationCenter.default.removeObserver(setupRequestObserver) }
        if let setupNotificationObserver { NotificationCenter.default.removeObserver(setupNotificationObserver) }
        deepLinkObserver = nil
        liveOpenObserver = nil
        setupRequestObserver = nil
        setupNotificationObserver = nil
    }
}

@MainActor
private struct LiveGameBottomAccessory: View {
    let hasLiveGame: Bool
    let onTap: () -> Void
    
    var body: some View {
        if hasLiveGame {
            LiveGameMiniPreview(onTap: onTap)
        }
    }
}

@MainActor
private struct CustomLiveGameView: View {
    let hasLiveGame: Bool
    let onTap: () -> Void
    
    var body: some View {
        if hasLiveGame {
            InlineMiniPreview(onTap: onTap)
        }
    }
}

private extension View {
    func applyLiveGameBottomAccessory(
        hasLiveGame: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        if #available(iOS 26.1, *) {
            return AnyView(
                self.tabViewBottomAccessory(isEnabled: hasLiveGame) {
                    LiveGameBottomAccessory(
                        hasLiveGame: hasLiveGame,
                        onTap: onTap
                    )
                }
            )
        } else if #available(iOS 26.0, *) {
            return AnyView(
                self.tabViewBottomAccessory {
                    LiveGameBottomAccessory(
                        hasLiveGame: hasLiveGame,
                        onTap: onTap
                    )
                }
            )
        } else {
            return AnyView(
                self.safeAreaInset(edge: .bottom) {
                    if hasLiveGame {
                        CustomLiveGameView(
                            hasLiveGame: hasLiveGame,
                            onTap: onTap
                        )
                        .background(.regularMaterial)
                    }
                }
            )
        }
    }
}

// MARK: - Previews

#Preview {
    let setup = PreviewContainers.liveGameSetup()
    let syncCoordinator = LiveSyncCoordinator(service: NoopSyncService())

    AppRootView()
        .tint(.green)
        .modelContainer(setup.container)
        .environment(setup.liveGameManager)
        .environment(setup.gameManager)
        .environment(setup.rosterManager)
        .environment(syncCoordinator)
}


