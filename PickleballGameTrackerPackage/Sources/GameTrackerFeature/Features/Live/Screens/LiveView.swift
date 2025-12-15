import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct LiveView: View {
    @Bindable var game: Game
    @Environment(LiveGameStateManager.self) private var activeGameStateManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(SwiftDataGameManager.self) private var gameManager
    @Environment(LiveSyncCoordinator.self) private var syncCoordinator
    @Environment(PersonalizationEngine.self) private var personalizationEngine
    @Environment(\.scenePhase) private var scenePhase
    let onDismiss: (() -> Void)?

    // Snapshot identifiers and static metadata that remain valid even if the model is deleted.
    let gameIdSnapshot: UUID
    let gameTypeSnapshot: GameType

    init(
        game: Game,
        onDismiss: (() -> Void)? = nil
    ) {
        self.game = game
        self.onDismiss = onDismiss
        self.gameIdSnapshot = game.id
        self.gameTypeSnapshot = game.gameType
    }

    @State private var hasEndedGame: Bool = false
    @State private var endError: Error? = nil
    @State private var isResetting: Bool = false
    @State private var isToggling: Bool = false
    @State private var resetTrigger: Bool = false
    @State private var playPauseTrigger: Bool = false
    @State private var showEventsHistory = false
    @State private var servingPlayerId: UUID? = nil
    @State private var rowFrames: [UUID: CGRect] = [:]
    @State private var viewportFrame: CGRect = .zero
    @State private var didRecordUsageStart: Bool = false

    private var isEndState: Bool {
        hasEndedGame || game.safeIsCompleted || game.isDetachedFromContext
    }

    private var gameTintColor: Color {
        gameTypeSnapshot.color
    }

    private var isCutthroat: Bool {
        gameTypeSnapshot == .cutthroat
    }

    private var usesPlayerScrollLayout: Bool {
        game.layoutStyle == .players
    }

    private var restrictScrollDismissal: Bool {
        isCutthroat && usesPlayerScrollLayout
    }

    var body: some View {
        mainContent
        .safeAreaPadding(.vertical)
        .task {
            await activeGameStateManager.setCurrentGame(game)
            ensureInitialServerIfNeeded()
            syncCoordinator.setLiveViewForeground(scenePhase == .active)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isEndState && !game.isDetachedFromContext {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: gameTypeSnapshot.iconName)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(
                                    gameTintColor.gradient
                                )
                                .shadow(
                                    color: gameTintColor
                                        .opacity(0.3),
                                    radius: 2,
                                    x: 0,
                                    y: 1
                                )

                            Text(gameTypeSnapshot.displayName)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }

            if !isEndState {
                LiveToolbar(
                    game: game,
                    gameType: gameTypeSnapshot,
                    gameManager: gameManager,
                    activeGameStateManager: activeGameStateManager,
                    onEndGame: {
                        let gameId = gameIdSnapshot
                        let elapsed = activeGameStateManager.elapsedTime
                        let willDelete = game.isUnused(elapsedTime: elapsed)
                        hasEndedGame = true
                        do {
                            try await activeGameStateManager.completeCurrentGame()
                            // Record completion for personalization only if this won't be deleted as unused
                            if !willDelete {
                                personalizationEngine.recordComplete(
                                    context: modelContext,
                                    gameType: gameTypeSnapshot
                                )
                            }
                        } catch {
                            endError = error
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
        .presentationContentInteraction(
            restrictScrollDismissal ? .resizes : .automatic
        )
        // React to external model removal: transition to end state and, when appropriate, dismiss instead of rendering an empty view
        .onChange(of: activeGameStateManager.currentGame?.id) { _, newId in
            if newId == nil {
                if hasEndedGame {
                    // Local end: we already show the end card; allow the user to dismiss.
                } else {
                    hasEndedGame = true
                    onDismiss?()
                    dismiss()
                }
            }
        }
        .onChange(of: game.isDetachedFromContext) { _, detached in
            if detached {
                if hasEndedGame {
                    // Local end: we already show the end card; allow the user to dismiss.
                } else {
                    hasEndedGame = true
                    onDismiss?()
                    dismiss()
                }
            }
        }
        // Defer personalization start: record at first meaningful activity or when elapsed crosses 5 minutes
        .onChange(of: activeGameStateManager.elapsedTime) { oldValue, newValue in
            let threshold: TimeInterval = 5 * 60
            if didRecordUsageStart == false, oldValue < threshold, newValue >= threshold {
                recordUsageStartIfNeeded()
            }
        }
        // Also treat scoring progression as meaningful activity
        .onChange(of: game.totalRallies) { oldValue, newValue in
            if didRecordUsageStart == false, !game.isDetachedFromContext, newValue > oldValue, newValue > 0 {
                recordUsageStartIfNeeded()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            syncCoordinator.setLiveViewForeground(newPhase == .active)
        }
        .onDisappear {
            // Release active game state on dismissal once the game is completed
            if game.safeIsCompleted {
                activeGameStateManager.clearCurrentGame()
            }
            syncCoordinator.setLiveViewForeground(false)
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        if isEndState {
            GameEndedView(gameType: gameTypeSnapshot)
        } else {
            liveContent
                .tint(gameTintColor)
        }
    }

    @ViewBuilder
    private var liveContent: some View {
        if usesPlayerScrollLayout {
            playerScrollLayout
        } else {
            standardLayout
        }
    }

    private var playerScrollLayout: some View {
        GeometryReader { _ in
            ScrollViewReader { proxy in
                ZStack {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            playerRowsContent(proxy: proxy)
                        }
                    }
                    .onPreferenceChange(RowFramePreferenceKey.self) { newValue in
                        rowFrames.merge(newValue, uniquingKeysWith: { _, new in new })
                    }
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ViewportFramePreferenceKey.self,
                            value: geo.frame(in: .global)
                        )
                    }
                }
                .onPreferenceChange(ViewportFramePreferenceKey.self) { newViewport in
                    viewportFrame = newViewport
                }
            }
        }
        .safeAreaPadding()
        .applyLiveSafeAreaBars(
            top: {
                TimerCard(
                    game: game,
                    formattedElapsedTime: activeGameStateManager
                        .formattedElapsedTimeWithCentiseconds
                )
                .safeAreaPadding(.horizontal)
            },
            bottom: {
                GameControlButton(
                    game: game,
                    isGamePaused: !activeGameStateManager.isGameLive,
                    isGameInitial: activeGameStateManager.isGameInitial,
                    isToggling: isToggling,
                    isResetting: isResetting,
                    onToggleGame: toggleGame
                )
                .safeAreaPadding(.horizontal)
                .accessibilityIdentifier("LiveView.toggleGameButton")
            }
        )
    }

    @ViewBuilder
    private func playerRowsContent(proxy: ScrollViewProxy) -> some View {
        let rows = game.participantRows(context: modelContext)
        if rows.isEmpty {
            EmptyStateView(
                icon: "person.2.slash",
                title: "Players Unavailable",
                description: "Player details for this game could not be loaded."
            )
        } else {
            ForEach(rows, id: \.id) { row in
                let player = row.player
                let team = row.teamNumber
                SideScoreSection(
                    game: game,
                    teamNumber: team,
                    teamName: player.name,
                    isGameLive: activeGameStateManager.isGameLive,
                    currentTimestamp: activeGameStateManager.elapsedTime,
                    onEventLogged: handleEventLoggedMeaningful,
                    singlePlayer: player,
                    isExpanded: servingPlayerId == player.id,
                    onTopCardTapped: {
                        servingPlayerId = player.id
                        scrollRowIntoViewIfNeeded(rowId: player.id, proxy: proxy)
                    },
                    onOutClearsServe: {
                        advanceServeAfterOut()
                    }
                )
                .id(player.id)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: RowFramePreferenceKey.self,
                            value: [player.id: geo.frame(in: .global)]
                        )
                    }
                )
            }
        }
    }

    private var standardLayout: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            TimerCard(
                game: game,
                formattedElapsedTime: activeGameStateManager.formattedElapsedTimeWithCentiseconds
            )
            .safeAreaPadding(.horizontal)

            let teams = game.teamsWithLabels(context: modelContext)
            if teams.isEmpty {
                EmptyStateView(
                    icon: "person.2.slash",
                    title: "Participants Unavailable",
                    description: "Team details for this game could not be loaded."
                )
                .padding(.horizontal)
            } else {
                ForEach(teams, id: \.teamNumber) { teamConfig in
                    SideScoreSection(
                        game: game,
                        teamNumber: teamConfig.teamNumber,
                        teamName: teamConfig.teamName,
                        isGameLive: activeGameStateManager.isGameLive,
                        currentTimestamp: activeGameStateManager.elapsedTime,
                        onEventLogged: handleEventLogged
                    )
                    .padding(.horizontal)
                    .tint(
                        game.teamTintColor(
                            for: teamConfig.teamNumber,
                            context: modelContext
                        )
                    )
                }
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
            .padding(.horizontal)
            .accessibilityIdentifier("LiveView.toggleGameButton")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // Timer bezel controls removed — timer is controlled only via GameControlButton

    private func recordUsageStartIfNeeded() {
        guard didRecordUsageStart == false else { return }
        // Only record once per live session
        didRecordUsageStart = true
        personalizationEngine.recordStart(
            context: modelContext,
            gameType: gameTypeSnapshot,
            rules: nil
        )
    }

    private func scrollRowIntoViewIfNeeded(rowId: UUID, proxy: ScrollViewProxy, threshold: CGFloat = 44) {
        guard let rowRect = rowFrames[rowId] else { return }
        let viewport = viewportFrame
        let isAbove = rowRect.minY < viewport.minY + threshold
        let isBelow = rowRect.maxY > viewport.maxY - threshold
        if isAbove || isBelow {
            withAnimation(.easeInOut) {
                proxy.scrollTo(rowId, anchor: .top)
            }
        }
    }

    private func currentParticipantIds() -> [UUID] {
        guard !game.isDetachedFromContext else { return [] }
        return game
            .participantRows(context: modelContext)
            .map { $0.player.id }
    }

    private func ensureInitialServerIfNeeded() {
        guard gameTypeSnapshot == .cutthroat, servingPlayerId == nil else { return }
        let ids = currentParticipantIds()
        if let first = ids.first {
            servingPlayerId = first
        }
    }

    private func advanceServeAfterOut() {
        // For cutthroat, advance to next player; otherwise just clear serve indicator.
        guard gameTypeSnapshot == .cutthroat else {
            servingPlayerId = nil
            return
        }
        let ids = currentParticipantIds()
        guard !ids.isEmpty else {
            servingPlayerId = nil
            return
        }
        if let current = servingPlayerId, let idx = ids.firstIndex(of: current) {
            let next = ids[(idx + 1) % ids.count]
            servingPlayerId = next
        } else {
            servingPlayerId = ids.first
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
            let state = game.safeGameState
            let elapsed = activeGameStateManager.elapsedTime
            Task { @MainActor in
                try? await syncCoordinator.publish(
                    delta: LiveGameDeltaDTO(
                        gameId: game.id,
                        timestamp: elapsed,
                        operation: .setGameState(state)
                    )
                )
                // Also publish precise timer state for tight sync
                try? await syncCoordinator.publish(
                    delta: LiveGameDeltaDTO(
                        gameId: game.id,
                        timestamp: elapsed,
                        operation: .setElapsedTime(
                            elapsed: elapsed,
                            isRunning: activeGameStateManager.isTimerRunning
                        )
                    )
                )
            }
        }
    }

    private func handleEventLogged(_ event: GameEvent) {
        handleEventLoggedMeaningful(event)
    }

    private func handleEventLoggedMeaningful(_ event: GameEvent) {
        // Treat any event except pause/resume/completed as meaningful
        switch event.eventType {
        case .gamePaused, .gameResumed, .gameCompleted:
            break
        default:
            recordUsageStartIfNeeded()
        }
    }
}

// MARK: - End-of-Game Card

@MainActor
private struct GameEndedView: View {
    let gameType: GameType

    var body: some View {
        VStack {
            Spacer()
            EmptyStateView(
                icon: "flag.checkered",
                title: "Game Has Ended",
                description: "This game has ended. You can review it in your history if activity was recorded."
            )
            .padding()
            .tint(gameType.color)
            Spacer()
        }
    }
}

// MARK: - Preference Keys for Scroll Position Tracking
private struct RowFramePreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: [UUID: CGRect] { [:] }
    nonisolated static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private struct ViewportFramePreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGRect { .zero }
    nonisolated static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

#Preview {
    let container = PreviewContainers.liveGame()
    let (gameManager, liveGameManager) = PreviewContainers.managers(
        for: container
    )
    let syncCoordinator = LiveSyncCoordinator(service: NoopSyncService())
    let personalizationEngine = PersonalizationEngine()
    let game = PreviewContainers.exampleGame(in: container)

    NavigationStack {
        LiveView(game: game)
    }
    .modelContainer(container)
    .environment(liveGameManager)
    .environment(gameManager)
    .environment(syncCoordinator)
    .environment(personalizationEngine)
}

// MARK: - Soft Scroll Edge Effect (iOS 26 availability)
private struct SoftScrollEdgeEffectModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.scrollEdgeEffectStyle(.soft, for: .vertical)
        } else {
            content
        }
    }
}

extension View {
    fileprivate func applySoftScrollEdgeEffect() -> some View {
        modifier(SoftScrollEdgeEffectModifier())
    }
}

// MARK: - Live Safe Area Bars (iOS 26 safeAreaBar with fallback)
private struct LiveBarsModifier<Top: View, Bottom: View>: ViewModifier {
    let top: () -> Top
    let bottom: () -> Bottom

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .safeAreaBar(edge: .top, alignment: .center, spacing: nil) {
                    top()
                }
                .safeAreaBar(edge: .bottom, alignment: .center, spacing: nil) {
                    bottom()
                }
        } else {
            content
                .safeAreaInset(edge: .top) {
                    top()
                }
                .safeAreaInset(edge: .bottom) {
                    bottom()
                }
        }
    }
}

private extension View {
    func applyLiveSafeAreaBars<Top: View, Bottom: View>(
        top: @escaping () -> Top,
        bottom: @escaping () -> Bottom
    ) -> some View {
        modifier(LiveBarsModifier(top: top, bottom: bottom))
    }
}

#Preview("Singles Game") {
    let container = PreviewContainers.liveGame()
    let (gameManager, liveGameManager) = PreviewContainers.managers(
        for: container
    )
    let syncCoordinator = LiveSyncCoordinator(service: NoopSyncService())
    let personalizationEngine = PersonalizationEngine()
    let game = PreviewContainers.exampleGame(in: container, preferTeamSize: 1)

    NavigationStack {
        LiveView(game: game)
    }
    .modelContainer(container)
    .environment(liveGameManager)
    .environment(gameManager)
    .environment(syncCoordinator)
    .environment(personalizationEngine)
}

#Preview("Teams Game") {
    let container = PreviewContainers.liveGame()
    let (gameManager, liveGameManager) = PreviewContainers.managers(
        for: container
    )
    let syncCoordinator = LiveSyncCoordinator(service: NoopSyncService())
    let personalizationEngine = PersonalizationEngine()
    let game = PreviewContainers.exampleGame(in: container, preferTeamSize: 2)

    NavigationStack {
        LiveView(game: game)
    }
    .modelContainer(container)
    .environment(liveGameManager)
    .environment(gameManager)
    .environment(syncCoordinator)
    .environment(personalizationEngine)
}

#Preview("Cutthroat Game") {
    let container = PreviewContainers.liveGame()
    let (gameManager, liveGameManager) = PreviewContainers.managers(
        for: container
    )
    let syncCoordinator = LiveSyncCoordinator(service: NoopSyncService())
    let personalizationEngine = PersonalizationEngine()
    let game = PreviewContainers.exampleGame(in: container, type: .cutthroat)

    NavigationStack {
        LiveView(game: game)
    }
    .modelContainer(container)
    .environment(liveGameManager)
    .environment(gameManager)
    .environment(syncCoordinator)
    .environment(personalizationEngine)
}
