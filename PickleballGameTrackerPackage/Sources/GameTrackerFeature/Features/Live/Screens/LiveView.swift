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
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .padding(.top, DesignSystem.Spacing.md)
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .task {
            await activeGameStateManager.setCurrentGame(game)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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

            LiveToolbar(
                game: game,
                gameManager: gameManager,
                activeGameStateManager: activeGameStateManager,
                showEventsHistory: $showEventsHistory
            )
        }
        .tint(game.gameType.color)
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
            let state = game.gameState
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

    private func handleEventLogged(_ event: GameEvent) {
        // Handle serve changes for events that affect serving
        if event.affectsServing {
            Task { @MainActor in
                do {
                    // Use the game manager to handle the serve change properly
                    if game.effectiveTeamSize == 1 {
                        // Singles: persist in-view serve change applied by GlobalActionsView
                        try await gameManager.updateGame(game)
                    } else {
                        // Doubles: handle service fault
                        // Note: The game.handleServiceFault() is called in GlobalActionsView for immediate UI updates
                        // but we need to persist it through the manager for data consistency
                        try await gameManager.updateGame(game)
                    }

                    // Trigger haptic feedback for serve change
                    activeGameStateManager.triggerServeChangeHaptic()

                    Log.event(
                        .serverSwitched,
                        level: .info,
                        message: "Serve changed due to game event",
                        context: .current(gameId: game.id),
                        metadata: [
                            "eventType": event.eventType.rawValue,
                            "teamAffected": String(event.teamAffected ?? 0),
                            "timestamp": String(
                                format: "%.2f",
                                event.timestamp
                            ),
                        ]
                    )
                } catch {
                    Log.error(
                        error,
                        event: .serverSwitched,
                        context: .current(gameId: game.id),
                        metadata: ["action": "handleEventLogged_serveChange"]
                    )
                }
            }
            Task { @MainActor in
                try? await syncCoordinator.publish(delta: LiveGameDeltaDTO(
                    gameId: game.id,
                    timestamp: event.timestamp,
                    operation: .switchServer
                ))
            }
        } else {
            // For non-serving events, just update the game
            Task { @MainActor in
                try? await gameManager.updateGame(game)
            }
        }

        // Could add additional haptic feedback, analytics, etc. here
        Task { @MainActor in
            switch event.eventType {
            case .playerScored:
                try? await syncCoordinator.publish(delta: LiveGameDeltaDTO(
                    gameId: game.id,
                    timestamp: event.timestamp,
                    operation: .score(team: event.teamAffected ?? game.currentServer)
                ))
            case .scoreUndone:
                try? await syncCoordinator.publish(delta: LiveGameDeltaDTO(
                    gameId: game.id,
                    timestamp: event.timestamp,
                    operation: .undoLastPoint
                ))
            case .serviceFault:
                try? await syncCoordinator.publish(delta: LiveGameDeltaDTO(
                    gameId: game.id,
                    timestamp: event.timestamp,
                    operation: .serviceFault
                ))
            case .gamePaused:
                try? await syncCoordinator.publish(delta: LiveGameDeltaDTO(
                    gameId: game.id,
                    timestamp: event.timestamp,
                    operation: .setGameState(.paused)
                ))
            case .gameResumed:
                try? await syncCoordinator.publish(delta: LiveGameDeltaDTO(
                    gameId: game.id,
                    timestamp: event.timestamp,
                    operation: .setGameState(.playing)
                ))
            case .gameCompleted:
                try? await syncCoordinator.publish(delta: LiveGameDeltaDTO(
                    gameId: game.id,
                    timestamp: event.timestamp,
                    operation: .setGameState(.completed)
                ))
            default:
                break
            }
        }
    }
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

