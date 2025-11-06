import GameTrackerCore
import SwiftUI

// MARK: - View Extensions (Navigation, Sheets, Deep Links, Persistence Reset)

extension View {
    func withNavigationLifecycle(
        globalNav: GlobalNavigationState,
        selectedTab: AppTab,
        scenePhase: ScenePhase,
        rootId: @escaping (AppTab) -> String
    ) -> some View {
        self
            .onAppear {
                globalNav.setCurrentRootView(rootId(selectedTab))
                globalNav.setCurrentTab(selectedTab)
                globalNav.setActive(scenePhase == .active)
            }
            .onChange(of: selectedTab) { _, newValue in
                globalNav.setCurrentTab(newValue)
                globalNav.setCurrentRootView(rootId(newValue))
            }
            .onChange(of: scenePhase) { _, newPhase in
                globalNav.setActive(newPhase == .active)
            }
    }
}

extension View {
    func applyLiveGameSheet(
        showingLiveGameSheet: Binding<Bool>,
        currentGame: Game?,
        gameManager: SwiftDataGameManager,
        globalNav: GlobalNavigationState
    ) -> some View {
        self
            .sheet(isPresented: showingLiveGameSheet) {
                if let currentGame {
                    NavigationStack {
                        LiveView(
                            game: currentGame,
                            onDismiss: {
                                Task { @MainActor in
                                    showingLiveGameSheet.wrappedValue = false
                                }
                            }
                        )
                    }
                    .environment(gameManager)
                }
            }
            .onChange(of: showingLiveGameSheet.wrappedValue) { _, newValue in
                if newValue {
                    globalNav.registerSheet("liveGame")
                } else {
                    globalNav.unregisterSheet("liveGame")
                }
            }
    }

    func applySetupSheet(
        setupSheet: Binding<SetupSheetToken?>,
        gameManager: SwiftDataGameManager,
        activeGameStateManager: LiveGameStateManager,
        globalNav: GlobalNavigationState,
        handleSetupGameStart: @escaping (GameType, GameRules?, MatchupSelection) async -> Void
    ) -> some View {
        self
            .sheet(item: setupSheet) { (token: SetupSheetToken) in
                SetupView(
                    gameType: token.gameType,
                    onStartGame: { gameType, rules, matchup in
                        Task { @MainActor in
                            await handleSetupGameStart(gameType, rules, matchup)
                        }
                    }
                )
                .environment(gameManager)
                .environment(activeGameStateManager)
            }
            .onChange(of: setupSheet.wrappedValue?.id) { _, _ in
                if setupSheet.wrappedValue != nil {
                    globalNav.registerSheet("setup")
                } else {
                    globalNav.unregisterSheet("setup")
                }
            }
    }

    func applyDeepLinkSheet(
        showDeepLink: Binding<Bool>,
        deepLinkDestination: DeepLinkDestination?,
        gameManager: SwiftDataGameManager,
        activeGameStateManager: LiveGameStateManager,
        globalNav: GlobalNavigationState
    ) -> some View {
        self
            .sheet(isPresented: showDeepLink) {
                NavigationStack {
                    DeepLinkDestinationView(
                        destination: deepLinkDestination
                    )
                }
                .environment(gameManager)
                .environment(activeGameStateManager)
            }
            .onChange(of: showDeepLink.wrappedValue) { _, newValue in
                if newValue {
                    globalNav.registerSheet("deepLink")
                } else {
                    globalNav.unregisterSheet("deepLink")
                }
            }
    }

    func applyPersistenceResetSheet(
        showPersistenceResetPrompt: Binding<Bool>,
        globalNav: GlobalNavigationState
    ) -> some View {
        self
            .sheet(isPresented: showPersistenceResetPrompt) {
                PersistenceResetPromptView()
                    .accessibilityIdentifier("PersistenceResetPrompt")
            }
            .onChange(of: showPersistenceResetPrompt.wrappedValue) { _, newValue in
                if newValue {
                    globalNav.registerSheet("persistenceReset")
                } else {
                    globalNav.unregisterSheet("persistenceReset")
                }
            }
    }
}


