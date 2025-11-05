import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct LiveView: View {
    @Bindable var game: Game
    @Environment(LiveGameStateManager.self) private var activeGameStateManager
    @Environment(\.modelContext) private var modelContext
    @Environment(SwiftDataGameManager.self) private var gameManager
    @Environment(LiveSyncCoordinator.self) private var syncCoordinator
    let onDismiss: (() -> Void)?
    var animation: Namespace.ID?

    init(
        game: Game,
        onDismiss: (() -> Void)? = nil,
        animation: Namespace.ID? = nil
    ) {
        self.game = game
        self.onDismiss = onDismiss
        self.animation = animation
    }

    @State private var isResetting: Bool = false
    @State private var isToggling: Bool = false
    @State private var pulseAnimation: Bool = false
    @State private var resetTrigger: Bool = false
    @State private var playPauseTrigger: Bool = false
    @State private var showEventsHistory = false

    var body: some View {
        Group {
            if !game.isDetachedFromContext {
                VStack(spacing: DesignSystem.Spacing.md) {
                    TimerCard(
                        game: game,
                        formattedElapsedTime: activeGameStateManager
                            .formattedElapsedTimeWithCentiseconds,
                        isTimerPaused: !activeGameStateManager.isTimerRunning,
                        isGameLive: activeGameStateManager.isGameLive,
                        isResetting: isResetting,
                        isToggling: isToggling,
                        pulseAnimation: pulseAnimation,
                        resetTrigger: resetTrigger,
                        playPauseTrigger: playPauseTrigger
                    )

                    ForEach(game.teamsWithLabels(context: modelContext), id: \.teamNumber) { teamConfig in
                        SideScoreSection(
                            game: game,
                            teamNumber: teamConfig.teamNumber,
                            teamName: teamConfig.teamName,
                            isGameLive: activeGameStateManager.isGameLive,
                            currentTimestamp: activeGameStateManager.elapsedTime,
                            onEventLogged: handleEventLogged
                        )
                        .tint(game.teamTintColor(for: teamConfig.teamNumber, context: modelContext))
                    }

                    Spacer()

                    GameControlButton(
                        game: game,
                        isGamePaused: !activeGameStateManager.isGameLive,
                        isGameInitial: activeGameStateManager.isGameInitial,
                        isToggling: isToggling,
                        isResetting: isResetting,
                        onToggleGame: toggleGame
                    )
                    .accessibilityIdentifier("LiveView.toggleGameButton")
                }
                .tint(game.gameType.color)
            } else {
                // When the game model is no longer available (detached/deleted), render an empty view
                // so the navigation dismissal can complete without touching SwiftData properties.
                EmptyView()
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .padding(.top, DesignSystem.Spacing.md)
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .task {
            await activeGameStateManager.setCurrentGame(game)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !game.isDetachedFromContext {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: game.gameType.iconName)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(
                                    game.gameType.color.gradient
                                )
                                .shadow(
                                    color: game.gameType.color
                                        .opacity(0.3),
                                    radius: 2,
                                    x: 0,
                                    y: 1
                                )

                            Text(game.gameType.displayName)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                        }
                        
                        // Role badge removed per sync v2 (no leader/follower UI)
                    }
                }
            }

            LiveToolbar(
                game: game,
                gameManager: gameManager,
                activeGameStateManager: activeGameStateManager,
                onEndGame: {
                    let gameId = game.id
                    let elapsed = activeGameStateManager.elapsedTime
                    do {
                        try await activeGameStateManager.completeCurrentGame()
                        try? await syncCoordinator.publish(delta: LiveGameDeltaDTO(
                            gameId: gameId,
                            timestamp: elapsed,
                            operation: .setGameState(.completed)
                        ))
                    } catch {
                        Log.error(
                            error,
                            event: .saveFailed,
                            context: .current(gameId: gameId),
                            metadata: ["action": "endGame"]
                        )
                    }
                },
                showEventsHistory: $showEventsHistory
            )
        }
        // Keep feedback using safe accessors; tint is applied conditionally above
        .sensoryFeedbackGameAction(
            trigger: game.safeGameState,
            feedback: {
                switch game.safeGameState {
                case .playing:
                    return .impact(weight: .heavy, intensity: 1.0)
                case .completed:
                    return .success
                default:
                    return nil
                }
            },
            isGamePlaying: { true }
        )
        .observeHapticServiceTriggers()
        .onDisappear {
            // Release active game state on dismissal once the game is completed
            if game.safeIsCompleted {
                activeGameStateManager.clearCurrentGame()
            }
        }
    }

    // Timer bezel controls removed — timer is controlled only via GameControlButton

    private func toggleGame() {
        guard !isToggling && !isResetting else { return }
        if game.isCompleted {
            activeGameStateManager.clearCurrentGame()
            onDismiss?()
            return
        }
        Task { @MainActor in
            isToggling = true
            defer { isToggling = false }
            try? await activeGameStateManager.toggleGameState()
            try? await Task.sleep(for: .milliseconds(100))
            let state = game.safeGameState
            let elapsed = activeGameStateManager.elapsedTime
            Task { @MainActor in
                try? await syncCoordinator.publish(delta: LiveGameDeltaDTO(
                    gameId: game.id,
                    timestamp: elapsed,
                    operation: .setGameState(state)
                ))
                // Also publish precise timer state for tight sync
                try? await syncCoordinator.publish(delta: LiveGameDeltaDTO(
                    gameId: game.id,
                    timestamp: elapsed,
                    operation: .setElapsedTime(elapsed: elapsed, isRunning: activeGameStateManager.isTimerRunning)
                ))
            }
        }
    }

    private func handleEventLogged(_ event: GameEvent) { }
}

// MARK: - Color Helpers

private extension LiveView { }

#Preview {
    let container = PreviewContainers.liveGame()
    let (gameManager, liveGameManager) = PreviewContainers.managers(for: container)
    let ctx = container.mainContext
    let fetched = (try? ctx.fetch(FetchDescriptor<Game>())) ?? []
    let game = fetched.first(where: { $0.gameState == .playing }) ?? fetched.first ?? Game(gameType: .recreational)

    NavigationStack {
        LiveView(game: game)
    }
    .modelContainer(container)
    .environment(liveGameManager)
    .environment(gameManager)
}

#Preview("Singles Game") {
    let container = PreviewContainers.liveGame()
    let (gameManager, liveGameManager) = PreviewContainers.managers(for: container)
    let ctx = container.mainContext
    let fetched = (try? ctx.fetch(FetchDescriptor<Game>())) ?? []
    let game = fetched.first(where: { $0.effectiveTeamSize == 1 && !$0.isCompleted }) ?? fetched.first(where: { !$0.isCompleted }) ?? Game(gameType: .recreational)

    NavigationStack {
        LiveView(game: game)
    }
    .modelContainer(container)
    .environment(liveGameManager)
    .environment(gameManager)
}

#Preview("Teams Game") {
    let container = PreviewContainers.liveGame()
    let (gameManager, liveGameManager) = PreviewContainers.managers(for: container)
    let ctx = container.mainContext
    let fetched = (try? ctx.fetch(FetchDescriptor<Game>())) ?? []
    let game = fetched.first(where: { $0.effectiveTeamSize > 1 && !$0.isCompleted }) ?? fetched.first(where: { !$0.isCompleted }) ?? Game(gameType: .recreational)

    NavigationStack {
        LiveView(game: game)
    }
    .modelContainer(container)
    .environment(liveGameManager)
    .environment(gameManager)
}

