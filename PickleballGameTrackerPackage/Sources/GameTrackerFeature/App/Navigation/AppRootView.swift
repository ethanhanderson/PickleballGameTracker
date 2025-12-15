import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
public struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LiveGameStateManager.self) private var activeGameStateManager
    @Environment(SwiftDataGameManager.self) private var gameManager
    @Environment(LiveSyncCoordinator.self) private var syncCoordinator
    @Environment(PlayerTeamManager.self) private var rosterManager
    @State private var personalizationEngine = PersonalizationEngine()

    @State private var globalNav = GlobalNavigationState.shared
    @Environment(\.scenePhase) private var scenePhase

    @State private var showingLiveGameSheet = false
    @State private var setupSheet: SetupSheetToken?
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
            .environment(personalizationEngine)
            .applyLiveGameSheet(
                showingLiveGameSheet: $showingLiveGameSheet,
                currentGame: activeGameStateManager.currentGame,
                gameManager: gameManager,
                personalizationEngine: personalizationEngine,
                globalNav: globalNav
            )
            .applySetupSheet(
                setupSheet: $setupSheet,
                gameManager: gameManager,
                activeGameStateManager: activeGameStateManager,
                personalizationEngine: personalizationEngine,
                rosterManager: rosterManager,
                syncCoordinator: syncCoordinator,
                globalNav: globalNav,
                handleSetupGameStart: handleSetupGameStart
            )
            .applyPersistenceResetSheet(
                showPersistenceResetPrompt: $showPersistenceResetPrompt,
                globalNav: globalNav
            )
            .task { await setupObservers() }
            .onDisappear { cleanupObservers() }
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
        setupSheet = SetupSheetToken(id: gameType.rawValue, gameType: gameType)
        SetupNotificationService.shared.clearPendingNotifications()
        Log.event(
            .viewAppear,
            level: .info,
            message: "Setup requested from watch → opening SetupView",
            metadata: ["gameType": gameType.rawValue]
        )
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

            await LiveGameStartSync.syncGameStart(
                source: "setupFromWatch",
                game: game,
                liveManager: activeGameStateManager,
                syncCoordinator: syncCoordinator
            )
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
        if let liveOpenObserver { NotificationCenter.default.removeObserver(liveOpenObserver) }
        if let setupRequestObserver { NotificationCenter.default.removeObserver(setupRequestObserver) }
        if let setupNotificationObserver { NotificationCenter.default.removeObserver(setupNotificationObserver) }
        liveOpenObserver = nil
        setupRequestObserver = nil
        setupNotificationObserver = nil
    }
}

// MARK: - Previews

#Preview("Main") {
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

#Preview("Blank") {
    let setup = PreviewContainers.emptySetup()
    let syncCoordinator = LiveSyncCoordinator(service: NoopSyncService())

    AppRootView()
        .tint(.green)
        .modelContainer(setup.container)
        .environment(setup.liveGameManager)
        .environment(setup.gameManager)
        .environment(setup.rosterManager)
        .environment(syncCoordinator)
}

#Preview("Main • Randomized Profile (Seeded)") {
    // Seeded daily randomization: rotate profile by day-of-year for stable daily variety
    let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
    let profiles: [PersonalizationProfile] = [
        .coldStart, .singlesHeavy, .doublesHeavy, .beginnerFriendly, .competitive, .mixedRecent
    ]
    let chosen = profiles[dayOfYear % profiles.count]
    let p = PersonalizationPreviewFactory.build(profile: chosen)
    
    let (gameManager, liveGameManager) = PreviewContainers.managers(for: p.container)
    let rosterManager = PreviewContainers.rosterManager(for: p.container)
    let syncCoordinator = LiveSyncCoordinator(service: NoopSyncService())
    
    AppRootView()
        .tint(.green)
        .modelContainer(p.container)
        .environment(liveGameManager)
        .environment(gameManager)
        .environment(rosterManager)
        .environment(syncCoordinator)
        .environment(p.engine)
}
