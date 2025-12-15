import GameTrackerCore
import SwiftData
import SwiftUI

// MARK: - Main View

@MainActor
struct EventButtonsCard: View {
    let game: Game
    let currentTimestamp: TimeInterval
    let tintColor: Color
    let teamNumber: Int
    let onEventLogged: ((GameEvent) -> Void)?
    
    enum LayoutStyle {
        case standard
        case scoreAndOutInline
    }

    let layout: LayoutStyle
    let singlePlayer: PlayerProfile?
    let onOutTapped: (() -> Void)?

    @State private var showingUndoButtonAtIndex: Int?
    @State private var undoTimer: Timer?
    private let undoDuration: TimeInterval = 15.0

    @Environment(\.modelContext) private var modelContext
    @Environment(SwiftDataGameManager.self) private var gameManager

    init(
        game: Game,
        currentTimestamp: TimeInterval,
        tintColor: Color,
        teamNumber: Int,
        onEventLogged: ((GameEvent) -> Void)? = nil,
        layout: LayoutStyle = .standard,
        singlePlayer: PlayerProfile? = nil,
        onOutTapped: (() -> Void)? = nil
    ) {
        self.game = game
        self.currentTimestamp = currentTimestamp
        self.tintColor = tintColor
        self.teamNumber = teamNumber
        self.onEventLogged = onEventLogged
        self.layout = layout
        self.singlePlayer = singlePlayer
        self._showingUndoButtonAtIndex = State(initialValue: nil)
        self._undoTimer = State(initialValue: nil)
        self.onOutTapped = onOutTapped
    }

    private var primaryEvents: [GameEventType] {
        game.primaryGameEvents
    }

    private var scoringPlayers: [PlayerProfile] {
        // Determine players for the current side and cap to UI-supported maximum (2)
        switch game.participantMode {
        case .players:
            if teamNumber == 1, let sidePlayers = game.resolveSide1Players(context: modelContext) {
                return Array(sidePlayers.prefix(2))
            }
            if teamNumber == 2, let sidePlayers = game.resolveSide2Players(context: modelContext) {
                return Array(sidePlayers.prefix(2))
            }

        case .teams:
            if teamNumber == 1, let team = game.resolveSide1Team(context: modelContext) {
                return Array(team.players.prefix(2))
            }
            if teamNumber == 2, let team = game.resolveSide2Team(context: modelContext) {
                return Array(team.players.prefix(2))
            }
        }

        preconditionFailure("Participant data is missing for scoring buttons (team=\(teamNumber)). Ensure participants are set and resolvable before rendering.")
    }

    private var teamDisplayName: String {
        let configs = game.teamsWithLabels(context: modelContext)
        if let cfg = configs.first(where: { $0.teamNumber == teamNumber }) {
            return cfg.teamName
        }
        preconditionFailure("Team display name not resolvable for team=\(teamNumber). Ensure participants are set.")
    }

    private func scoringIconName(for playerIndex: Int) -> String {
        return scoringPlayers.count <= 1 ? "person.fill" : "person.2.fill"
    }

    var body: some View {
        Group {
            switch layout {
            case .standard:
                VStack(spacing: DesignSystem.Spacing.sm) {
                    ScoringButtonsSection(
                        scoringPlayers: scoringPlayers,
                        tintColor: tintColor,
                        scoringIconName: scoringIconName(for:),
                        scorePoint: scorePoint(for:at:),
                        showsPlayerName: scoringPlayers.count > 1,
                        showingUndoButtonAtIndex: showingUndoButtonAtIndex,
                        undoAction: undoLastPoint
                    )

                    EventsSection(
                        primaryEvents: primaryEvents,
                        tintColor: tintColor,
                        logEvent: logEvent(_:)
                    )
                }
            case .scoreAndOutInline:
                HStack(spacing: DesignSystem.Spacing.sm) {
                    if let player = singlePlayer {
                        EventCardButton(
                            eventType: .playerScored,
                            tintColor: tintColor,
                            isEnabled: true,
                            action: { scorePoint(for: player, at: 0) },
                            customDescription: "\(player.name) scored",
                            customIconName: scoringIconName(for: 0)
                        )
                    } else {
                        ScoringButtonsSection(
                            scoringPlayers: scoringPlayers,
                            tintColor: tintColor,
                            scoringIconName: scoringIconName(for:),
                            scorePoint: scorePoint(for:at:),
                            showsPlayerName: scoringPlayers.count > 1,
                            showingUndoButtonAtIndex: showingUndoButtonAtIndex,
                            undoAction: undoLastPoint
                        )
                    }

                    EventCardButton(
                        eventType: .ballOutOfBounds,
                        tintColor: tintColor,
                        isEnabled: true,
                        action: {
                            onOutTapped?()
                            logEvent(.ballOutOfBounds)
                        },
                        customDescription: nil,
                        customIconName: nil
                    )
                    .accessibilityLabel("Out")
                }
            }
        }
    }

    private func logEvent(_ eventType: GameEventType) {
        guard game.safeGameState == .playing else {
            Log.event(
                .actionTapped,
                level: .warn,
                message: "Ignored event tap outside of active play",
                context: .current(gameId: game.id),
                metadata: [
                    "event": eventType.rawValue,
                    "state": game.safeGameState.rawValue,
                    "teamNumber": "\(teamNumber)"
                ]
            )
            return
        }

        let timestamp = currentTimestamp
        let teamAffected = resolvedTeamAffected()

        if eventType.typicallyChangesServe {
            Task { @MainActor in
                await handleServeChangingEvent(
                    eventType,
                    timestamp: timestamp,
                    teamAffected: teamAffected
                )
            }
        } else {
            logNonServeChangingEvent(
                eventType,
                timestamp: timestamp,
                teamAffected: teamAffected
            )
        }
    }

    private func logNonServeChangingEvent(
        _ eventType: GameEventType,
        timestamp: TimeInterval,
        teamAffected: Int
    ) {
        game.logEvent(eventType, at: timestamp, teamAffected: teamAffected)
        if let event = game.events.last {
            onEventLogged?(event)
        }

        Log.event(
            .actionTapped,
            level: .info,
            message: "Logged non-serve event",
            context: .current(gameId: game.id),
            metadata: [
                "event": eventType.rawValue,
                "teamAffected": "\(teamAffected)",
                "teamNumber": "\(teamNumber)"
            ]
        )
    }

    @MainActor
    private func handleServeChangingEvent(
        _ eventType: GameEventType,
        timestamp: TimeInterval,
        teamAffected: Int
    ) async {
        let serverBefore = game.currentServer
        let serverNumberBefore = game.serverNumber

        game.logEvent(eventType, at: timestamp, teamAffected: teamAffected)
        if let event = game.events.last {
            onEventLogged?(event)
        }

        let baseMetadata = serveChangeMetadata(
            eventType: eventType,
            teamAffected: teamAffected,
            serverBefore: serverBefore,
            serverNumberBefore: serverNumberBefore
        )

        Log.event(
            .actionTapped,
            level: .info,
            message: "Serve-changing event tapped",
            context: .current(gameId: game.id),
            metadata: baseMetadata
        )

        do {
            try await syncPublish(.fault(event: eventType, team: teamAffected), timestamp: timestamp)
        } catch {
            Log.error(
                error,
                event: .syncFailed,
                context: .current(gameId: game.id),
                metadata: baseMetadata
            )
        }

        do {
            try await gameManager.handleServiceFault(in: game)
            _syncCoordinator.noteLocalServeMutation()
            Log.event(
                .serverSwitched,
                level: .info,
                context: .current(gameId: game.id),
                metadata: serveChangeMetadata(
                    eventType: eventType,
                    teamAffected: teamAffected,
                    serverBefore: serverBefore,
                    serverNumberBefore: serverNumberBefore,
                    serverAfter: game.currentServer,
                    serverNumberAfter: game.serverNumber
                )
            )
        } catch {
            Log.error(
                error,
                event: .serverSwitched,
                context: .current(gameId: game.id),
                metadata: serveChangeMetadata(
                    eventType: eventType,
                    teamAffected: teamAffected,
                    serverBefore: serverBefore,
                    serverNumberBefore: serverNumberBefore,
                    failureReason: "handleServiceFault"
                )
            )
        }
    }

    private func resolvedTeamAffected() -> Int {
        switch teamNumber {
        case 1, 2:
            return teamNumber
        default:
            return game.currentServer
        }
    }

    private func serveChangeMetadata(
        eventType: GameEventType,
        teamAffected: Int,
        serverBefore: Int,
        serverNumberBefore: Int,
        serverAfter: Int? = nil,
        serverNumberAfter: Int? = nil,
        failureReason: String? = nil
    ) -> [String: String] {
        var metadata: [String: String] = [
            "event": eventType.rawValue,
            "teamAffected": "\(teamAffected)",
            "cardTeam": "\(teamNumber)",
            "serverBefore": "T\(serverBefore)P\(serverNumberBefore)"
        ]

        if let serverAfter {
            metadata["serverAfter"] = "T\(serverAfter)P\(serverNumberAfter ?? 1)"
        }
        if let serverNumberAfter {
            metadata["serverNumberAfter"] = "\(serverNumberAfter)"
        }
        if let failureReason {
            metadata["failure"] = failureReason
        }

        return metadata
    }

    private func scorePoint(for player: PlayerProfile, at index: Int) {
        Task {
            do {
                let timestamp = currentTimestamp
                // Always include player name for per-player layouts so UI can derive per-player scores from events.
                // For side-based layouts (e.g., doubles), also include the player name to keep parity and richer logs.
                let customDescription: String? = {
                    if game.layoutStyle == .players { return "\(player.name) scored" }
                    return game.effectiveTeamSize > 0 ? "\(player.name) scored" : nil
                }()
                
                try await gameManager.scorePointAndLogEvent(
                    for: teamNumber,
                    in: game,
                    at: timestamp,
                    customDescription: customDescription
                )
                _syncCoordinator.noteLocalScoreMutation()
                
                if game.layoutStyle == .players {
                    try? await gameManager.setServer(to: teamNumber, in: game)
                    _syncCoordinator.noteLocalServeMutation()
                }

                startUndoTimer(for: index)

                let target = LiveScoreTarget.player(team: teamNumber, player: player)
                try? await _syncCoordinator.publishScoreEvent(
                    for: game,
                    target: target,
                    assignsServe: game.layoutStyle == .players,
                    timestamp: timestamp
                )
            } catch {
                print("Failed to score point: \(error)")
            }
        }
    }

    private func undoLastPoint() {
        stopUndoTimer()

        Task {
            do {
                let timestamp = currentTimestamp
                try await gameManager.undoLastPoint(in: game)
                game.logEvent(.scoreUndone, at: timestamp, teamAffected: game.currentServer)
                try? await syncPublish(.undoLastPoint, timestamp: timestamp)
                _syncCoordinator.noteLocalScoreMutation()
            } catch {
                print("Failed to undo point: \(error)")
            }
        }
    }

    // MARK: - Sync Helper
    @MainActor
    private func syncPublish(_ op: LiveGameDeltaDTO.Operation, timestamp: TimeInterval) async throws {
        let envSync = _syncCoordinator
        try await envSync.publish(delta: LiveGameDeltaDTO(
            gameId: game.id,
            timestamp: timestamp,
            operation: op
        ))
    }

    @Environment(LiveSyncCoordinator.self) private var _syncCoordinator

    @MainActor
    private func startUndoTimer(for index: Int) {
        stopUndoTimer()
        showingUndoButtonAtIndex = index

        undoTimer = Timer.scheduledTimer(withTimeInterval: undoDuration, repeats: false) { _ in
            Task { @MainActor in
                self.showingUndoButtonAtIndex = nil
            }
        }
    }

    @MainActor
    private func stopUndoTimer() {
        undoTimer?.invalidate()
        undoTimer = nil
        showingUndoButtonAtIndex = nil
    }

}

// MARK: - Child Components

@MainActor
private struct ScoringButtonsSection: View {
    let scoringPlayers: [PlayerProfile]
    let tintColor: Color
    let scoringIconName: (Int) -> String
    let scorePoint: (PlayerProfile, Int) -> Void
    let showsPlayerName: Bool
    let showingUndoButtonAtIndex: Int?
    let undoAction: () -> Void

    var body: some View {
        if !scoringPlayers.isEmpty {
            HStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(
                    Array(scoringPlayers.enumerated()),
                    id: \.offset
                ) { index, player in
                    if showingUndoButtonAtIndex == index {
                        UndoButton(
                            tintColor: tintColor,
                            action: undoAction,
                            customIconName: scoringIconName(index)
                        )
                        .animation(.easeInOut(duration: 0.2), value: showingUndoButtonAtIndex == index)
                    } else {
                        EventCardButton(
                            eventType: .playerScored,
                            tintColor: tintColor,
                            isEnabled: true,
                            action: { scorePoint(player, index) },
                            customDescription: showsPlayerName ? "\(player.name) scored" : nil,
                            customIconName: scoringIconName(index)
                        )
                    }
                }
            }
        }
    }
}

@MainActor
private struct EventsSection: View {
    let primaryEvents: [GameEventType]
    let tintColor: Color
    let logEvent: (GameEventType) -> Void

    var body: some View {
        ForEach(Array(primaryEvents.chunked(into: eventsPerRow).enumerated()), id: \.offset) { rowIndex, row in
            HStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(Array(row.enumerated()), id: \.offset) { eventIndex, eventType in
                    EventCardButton(
                        eventType: eventType,
                        tintColor: tintColor,
                        isEnabled: true,
                        action: { logEvent(eventType) },
                        customDescription: nil,
                        customIconName: nil
                    )
                }
            }
        }
    }

    private var eventsPerRow: Int { 2 }
}

@MainActor
private struct UndoButton: View {
    let tintColor: Color
    let action: () -> Void
    let customIconName: String

    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(tintColor)
                    .rotationEffect(.degrees(-90))

                Text("Undo")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
        }
        .buttonSizing(.flexible)
        .controlSize(.large)
        .buttonStyle(.glassProminent)
        .tint(tintColor.opacity(0.15))
        .foregroundStyle(.primary)
        .accessibilityLabel("Undo last point")
        .accessibilityHint("Tap to undo the last scored point")
        .help("Undo last point")
        .transition(.scale(scale: 0.9).combined(with: .opacity))
    }
}

// MARK: - Custom Transitions

extension AnyTransition {
    static var blurReplace: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 1.1).combined(with: .opacity)
        )
    }
}

#Preview {
    let container = PreviewContainers.liveGame()
    let (gameManager, _) = PreviewContainers.managers(for: container)
    let syncCoordinator = LiveSyncCoordinator(service: NoopSyncService())
    let game = PreviewContainers.exampleGame(in: container)

    return EventButtonsCard(
        game: game,
        currentTimestamp: 123.4,
        tintColor: Color.green,
        teamNumber: 1
    )
    .modelContainer(container)
    .environment(gameManager)
    .environment(syncCoordinator)
    .padding()
}
