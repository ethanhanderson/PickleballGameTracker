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
        onEventLogged: ((GameEvent) -> Void)? = nil
    ) {
        self.game = game
        self.currentTimestamp = currentTimestamp
        self.tintColor = tintColor
        self.teamNumber = teamNumber
        self.onEventLogged = onEventLogged
        self._showingUndoButtonAtIndex = State(initialValue: nil)
        self._undoTimer = State(initialValue: nil)
    }

    private var primaryEvents: [GameEventType] {
        game.primaryGameEvents
    }

    private var scoringPlayers: [PlayerProfile] {
        let playersPerSide = max(1, min(game.teamSize, 2))

        switch game.participantMode {
        case .players:
            if teamNumber == 1, let sidePlayers = game.resolveSide1Players(context: modelContext) {
                return Array(sidePlayers.prefix(playersPerSide))
            }
            if teamNumber == 2, let sidePlayers = game.resolveSide2Players(context: modelContext) {
                return Array(sidePlayers.prefix(playersPerSide))
            }

        case .teams:
            if teamNumber == 1, let team = game.resolveSide1Team(context: modelContext) {
                return Array(team.players.prefix(playersPerSide))
            }
            if teamNumber == 2, let team = game.resolveSide2Team(context: modelContext) {
                return Array(team.players.prefix(playersPerSide))
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
        if game.effectiveTeamSize == 1 { return "person.fill" }
        return "person.2.fill"
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            ScoringButtonsSection(
                scoringPlayers: scoringPlayers,
                tintColor: tintColor,
                scoringIconName: scoringIconName(for:),
                scorePoint: scorePoint(for:at:),
                showsPlayerName: game.effectiveTeamSize > 1,
                showingUndoButtonAtIndex: showingUndoButtonAtIndex,
                undoAction: undoLastPoint
            )

            EventsSection(
                primaryEvents: primaryEvents,
                tintColor: tintColor,
                logEvent: logEvent(_:)
            )
        }
    }

    private func logEvent(_ eventType: GameEventType) {
        guard game.safeGameState == .playing else { return }
        let timestamp = currentTimestamp
        let teamAffected = game.currentServer

        if eventType.typicallyChangesServe {
            Task { @MainActor in
                do {
                    let faultTeam = teamAffected
                    game.logEvent(eventType, at: timestamp, teamAffected: faultTeam)
                    try? await syncPublish(.fault(event: eventType, team: faultTeam), timestamp: timestamp)
                    try await gameManager.handleServiceFault(in: game)
                } catch {
                    print("Failed to handle service fault: \(error)")
                }
            }
        } else {
            game.logEvent(eventType, at: timestamp, teamAffected: teamAffected)
            if let event = game.events.last {
                onEventLogged?(event)
            }
        }
    }

    private func scorePoint(for player: PlayerProfile, at index: Int) {
        Task {
            do {
                let timestamp = currentTimestamp
                let customDescription: String? = game.effectiveTeamSize > 1 ? "\(player.name) scored" : nil
                
                try await gameManager.scorePointAndLogEvent(
                    for: teamNumber,
                    in: game,
                    at: timestamp,
                    customDescription: customDescription
                )

                startUndoTimer(for: index)

                try? await syncPublish(.score(team: teamNumber), timestamp: timestamp)
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
    
    return EventButtonsCard(
        game: (try? container.mainContext.fetch(FetchDescriptor<Game>()).first) ?? Game(gameType: .recreational),
        currentTimestamp: 123.4,
        tintColor: Color.green,
        teamNumber: 1
    )
    .modelContainer(container)
    .environment(gameManager)
    .padding()
}
