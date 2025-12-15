import GameTrackerCore
import SwiftUI

// MARK: - View Extensions (Navigation, Sheets, Deep Links, Persistence Reset)

extension View {
    func applyLiveGameSheet(
        showingLiveGameSheet: Binding<Bool>,
        currentGame: Game?,
        gameManager: SwiftDataGameManager,
        personalizationEngine: PersonalizationEngine,
        globalNav: GlobalNavigationState
    ) -> some View {
        self
            .sheet(isPresented: showingLiveGameSheet) {
                if let currentGame {
                    NavigationStack {
                        LiveGameScreen(
                            gameId: currentGame.id,
                            onDismiss: {
                                Task { @MainActor in
                                    showingLiveGameSheet.wrappedValue = false
                                }
                            }
                        )
                    }
                    .environment(gameManager)
                    .environment(personalizationEngine)
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
        personalizationEngine: PersonalizationEngine,
        rosterManager: PlayerTeamManager,
        syncCoordinator: LiveSyncCoordinator,
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
                .environment(personalizationEngine)
                .environment(rosterManager)
                .environment(syncCoordinator)
            }
            .onChange(of: setupSheet.wrappedValue?.id) { _, _ in
                if setupSheet.wrappedValue != nil {
                    globalNav.registerSheet("setup")
                } else {
                    globalNav.unregisterSheet("setup")
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
