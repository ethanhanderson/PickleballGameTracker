import GameTrackerCore
import SwiftData
import SwiftUI

// MARK: - Main View

@MainActor
struct EventButtonsCard: View {
    let game: Game
    let currentTimestamp: TimeInterval
    let tintColor: Color
    let gameManager: SwiftDataGameManager
    let teamNumber: Int
    let onEventLogged: ((GameEvent) -> Void)?

    // Undo state management
    @State private var showingUndoButtonAtIndex: Int?
    @State private var undoTimer: Timer?
    private let undoDuration: TimeInterval = 15.0

    @Environment(\.modelContext) private var modelContext

    init(
        game: Game,
        currentTimestamp: TimeInterval,
        tintColor: Color,
        gameManager: SwiftDataGameManager,
        teamNumber: Int,
        onEventLogged: ((GameEvent) -> Void)? = nil
    ) {
        self.game = game
        self.currentTimestamp = currentTimestamp
        self.tintColor = tintColor
        self.gameManager = gameManager
        self.teamNumber = teamNumber
        self.onEventLogged = onEventLogged
        self._showingUndoButtonAtIndex = State(initialValue: nil)
        self._undoTimer = State(initialValue: nil)
    }

    private var primaryEvents: [GameEventType] {
        game.primaryGameEvents
    }

    private var scoringPlayers: [PlayerProfile] {
        // Resolve players for this team using variation-derived names and roster lookup
        let teamName = teamDisplayName

        // Try exact player match (singles case)
        if let player = try? modelContext.fetch(
            FetchDescriptor<PlayerProfile>(predicate: #Predicate { $0.name == teamName })
        ).first {
            return [player]
        }

        // Try team match (doubles case)
        if let team = try? modelContext.fetch(
            FetchDescriptor<TeamProfile>(predicate: #Predicate { $0.name == teamName })
        ).first {
            let required = max(1, min(game.effectiveTeamSize, 2))
            return Array(team.players.prefix(required))
        }

        // Fallback: synthesize UI-only players if roster lookup fails
        let required = max(1, min(game.effectiveTeamSize, 2))
        if required == 1 {
            return [PlayerProfile(name: teamName)]
        } else {
            return [PlayerProfile(name: "Player 1"), PlayerProfile(name: "Player 2")]
        }
    }

    private var teamDisplayName: String {
        // Use variation-derived team labels (e.g., "A vs B")
        let configs = game.teamsWithLabels
        if let cfg = configs.first(where: { $0.teamNumber == teamNumber }) {
            return cfg.teamName
        }
        // Fallback generic name
        return teamNumber == 1 ? "Team 1" : "Team 2"
    }

    private func scoringIconName(for playerIndex: Int) -> String {
        // Singles: single user filled icon; Doubles: two-person filled icon for each
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
        guard game.gameState == .playing else { return }
        let timestamp = currentTimestamp
        let teamAffected = game.currentServer

        game.logEvent(eventType, at: timestamp, teamAffected: teamAffected)

        if eventType.typicallyChangesServe {
            Task {
                try? await gameManager.handleServiceFault(in: game)
            }
        }

        if let event = game.events.last {
            onEventLogged?(event)
        }
    }

    private func scorePoint(for player: PlayerProfile, at index: Int) {
        Task {
            do {
                // Score for the provided team number (player mapping not available in Core v1)
                try await gameManager.scorePoint(for: teamNumber, in: game)

                // Show undo button for this player at the specific index
                startUndoTimer(for: index)

                // Create a scoring event with custom description
                let timestamp = currentTimestamp
                let customDescription = "\(player.name) scored"
                game.logEvent(
                    .playerScored,
                    at: timestamp,
                    teamAffected: self.teamNumber,
                    description: customDescription
                )

                // Notify about the event
                if let event = game.events.last {
                    onEventLogged?(event)
                }
            } catch {
                print("Failed to score point: \(error)")
            }
        }
    }

    private func undoLastPoint() {
        // Hide the undo button immediately when tapped
        stopUndoTimer()

        Task {
            do {
                try await gameManager.undoLastPoint(in: game)

                // Log the undo event
                let timestamp = currentTimestamp
                game.logEvent(
                    .serveChange,
                    at: timestamp,
                    teamAffected: game.currentServer,
                    description: "Last point undone"
                )

                // Notify about the event
                if let event = game.events.last {
                    onEventLogged?(event)
                }
            } catch {
                print("Failed to undo point: \(error)")
                // Note: Button is already hidden, so no need to restore it on error
            }
        }
    }

    @MainActor
    private func startUndoTimer(for index: Int) {
        stopUndoTimer() // Stop any existing timer
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
                        // Show undo button with transition
                        UndoButton(
                            tintColor: tintColor,
                            action: undoAction,
                            customIconName: scoringIconName(index)
                        )
                        .animation(.easeInOut(duration: 0.2), value: showingUndoButtonAtIndex == index)
                    } else {
                        // Show normal score button
                        EventCardButton(
                            eventType: .playerScored,
                            tintColor: tintColor,
                            isEnabled: true,
                            action: { scorePoint(player, index) },
                            customDescription: "\(player.name) scored",
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
            .frame(maxWidth: .infinity)
        }
        .controlSize(.large)
        .buttonStyle(.glassProminent)
        .tint(tintColor.opacity(0.15))  // Slightly more subtle tint for undo button
        .foregroundStyle(.primary)
        .accessibilityLabel("Undo last point")
        .accessibilityHint("Tap to undo the last scored point")
        .help("Undo last point")
        .transition(.scale(scale: 0.9).combined(with: .opacity))  // Smoother scale transition
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
    let env = PreviewEnvironment.liveGame()
    return EventButtonsCard(
        game: (try? env.container.mainContext.fetch(FetchDescriptor<Game>()).first) ?? Game(gameType: .recreational),
        currentTimestamp: 123.4,
        tintColor: Color.green,
        gameManager: env.gameManager,
        teamNumber: 1
    )
    .modelContainer(env.container)
    .padding()
}
