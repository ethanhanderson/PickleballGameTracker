import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct LiveView: View {
    @Bindable var game: Game
    let gameManager: SwiftDataGameManager
    @Environment(LiveGameStateManager.self) private var activeGameStateManager
    @Environment(\.modelContext) private var modelContext
    let onDismiss: (() -> Void)?

    init(
        game: Game,
        gameManager: SwiftDataGameManager,
        onDismiss: (() -> Void)? = nil
    ) {
        self.game = game
        self.gameManager = gameManager
        self.onDismiss = onDismiss
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
                isGameActive: activeGameStateManager.isGameActive,
                isResetting: isResetting,
                isToggling: isToggling,
                pulseAnimation: pulseAnimation,
                resetTrigger: resetTrigger,
                playPauseTrigger: playPauseTrigger,
                onResetTimer: resetTimer,
                onToggleTimer: toggleTimer
            )

            ForEach(game.teamsWithLabels, id: \.teamNumber) { teamConfig in
                SideScoreSection(
                    game: game,
                    teamNumber: teamConfig.teamNumber,
                    teamName: teamConfig.teamName,
                    gameManager: gameManager,
                    isGameActive: activeGameStateManager.isGameActive,
                    currentTimestamp: activeGameStateManager.elapsedTime,
                    onEventLogged: handleEventLogged
                )
                .tint(teamTintColor(for: teamConfig.teamName))
            }
            
            Spacer()

            GameControlButton(
                game: game,
                isGamePaused: !activeGameStateManager.isGameActive,
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
            activeGameStateManager.setCurrentGame(game)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
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

    private func toggleTimer() {
        guard !isToggling && !isResetting else { return }

        Task { @MainActor in
            isToggling = true
            defer { isToggling = false }
            playPauseTrigger.toggle()
            activeGameStateManager.toggleTimer()
            try? await Task.sleep(for: .milliseconds(100))
        }
    }

    private func resetTimer() {
        guard !isResetting && !isToggling else { return }

        Task { @MainActor in
            isResetting = true
            defer {
                pulseAnimation = false
                isResetting = false
            }

            // Reset the timer and update game creation date
            resetTrigger.toggle()
            pulseAnimation = true
            activeGameStateManager.resetElapsedTime()
            game.createdDate = Date()

            // Small delay for animation
            try? await Task.sleep(for: .milliseconds(250))
        }
    }

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
        } else {
            // For non-serving events, just update the game
            Task { @MainActor in
                try? await gameManager.updateGame(game)
            }
        }

        // Could add additional haptic feedback, analytics, etc. here
    }
}

// MARK: - Color Helpers

private extension LiveView {
    func teamTintColor(for teamName: String) -> Color {
        // Try team match first
        if let team = try? modelContext.fetch(FetchDescriptor<TeamProfile>(predicate: #Predicate { $0.name == teamName })).first {
            return team.primaryColor
        }
        // Try player match
        if let player = try? modelContext.fetch(FetchDescriptor<PlayerProfile>(predicate: #Predicate { $0.name == teamName })).first {
            return player.primaryColor
        }
        // Fallback to game-provided tint helper
        if teamName == game.teamsWithLabels.first?.teamName {
            return game.teamTintColor(for: 1)
        } else if teamName == game.teamsWithLabels.dropFirst().first?.teamName {
            return game.teamTintColor(for: 2)
        }
        return Color.accentColor
    }
}

#Preview {
    let env = PreviewEnvironment.liveGame()
    let ctx = env.container.mainContext
    let fetched = (try? ctx.fetch(FetchDescriptor<Game>())) ?? []
    let game = fetched.first(where: { $0.gameState == .playing }) ?? fetched.first ?? Game(gameType: .recreational)

    NavigationStack {
        LiveView(
            game: game,
            gameManager: SwiftDataGameManager(storage: env.storage)
        )
    }
    .modelContainer(env.container)
    .environment(env.activeGameStateManager)
}

#Preview("Singles Game") {
    let env = PreviewEnvironment.liveGame()
    let ctx = env.container.mainContext
    let fetched = (try? ctx.fetch(FetchDescriptor<Game>())) ?? []
    let game = fetched.first(where: { $0.gameVariation?.teamSize == 1 }) ?? fetched.first ?? Game(gameType: .recreational)

    NavigationStack {
        LiveView(
            game: game,
            gameManager: SwiftDataGameManager(storage: env.storage)
        )
    }
    .modelContainer(env.container)
    .environment(env.activeGameStateManager)
}

#Preview("Teams Game") {
    let env = PreviewEnvironment.liveGame()
    let ctx = env.container.mainContext
    let fetched = (try? ctx.fetch(FetchDescriptor<Game>())) ?? []
    let game = fetched.first(where: { $0.gameVariation?.teamSize ?? $0.gameType.defaultTeamSize > 1 }) ?? fetched.first ?? Game(gameType: .recreational)

    NavigationStack {
        LiveView(
            game: game,
            gameManager: SwiftDataGameManager(storage: env.storage)
        )
    }
    .modelContainer(env.container)
    .environment(env.activeGameStateManager)
}

