import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct SideScoreSection: View {
    @Bindable var game: Game
    let teamNumber: Int
    let teamName: String
    let isGameLive: Bool
    let currentTimestamp: TimeInterval
    let onEventLogged: ((GameEvent) -> Void)?
    let singlePlayer: PlayerProfile?
    let isExpanded: Bool
    let onTopCardTapped: (() -> Void)?
    let onOutClearsServe: (() -> Void)?
    @Environment(\.modelContext) private var modelContext
    @Environment(SwiftDataGameManager.self) private var gameManager

    init(
        game: Game,
        teamNumber: Int,
        teamName: String,
        isGameLive: Bool,
        currentTimestamp: TimeInterval,
        onEventLogged: ((GameEvent) -> Void)? = nil,
        singlePlayer: PlayerProfile? = nil,
        isExpanded: Bool = false,
        onTopCardTapped: (() -> Void)? = nil,
        onOutClearsServe: (() -> Void)? = nil
    ) {
        self.game = game
        self.teamNumber = teamNumber
        self.teamName = teamName
        self.isGameLive = isGameLive
        self.currentTimestamp = currentTimestamp
        self.onEventLogged = onEventLogged
        self.singlePlayer = singlePlayer
        self.isExpanded = isExpanded
        self.onTopCardTapped = onTopCardTapped
        self.onOutClearsServe = onOutClearsServe
    }

    private var sectionTintColor: Color {
        if let singlePlayer { return singlePlayer.accentColor }
        return game.teamTintColor(for: teamNumber, context: modelContext)
    }

    var body: some View {
        Group {
            // If the model is detached, render nothing; parent will dismiss the live view.
            if game.isDetachedFromContext {
                Color.clear
            } else {
                // Safe to access SwiftData-backed properties after guard
                let isPlayersLayout = (game.layoutStyle == .players)
                VStack(spacing: DesignSystem.Spacing.md) {
                    SideScoreTopCard(
                        game: game,
                        teamNumber: teamNumber,
                        teamName: teamName,
                        isGameLive: isGameLive,
                        showTapIndicator: game.safeGameState == .playing || game.safeGameState == .paused,
                        tintOverride: sectionTintColor,
                        isServingPlayer: isExpanded,
                        onTapped: onTopCardTapped,
                        displayScore: (isPlayersLayout ? (singlePlayer.map { game.playerScore(for: $0) }) : nil)
                    )
                    .animation(
                        Animation.spring(response: 0.3, dampingFraction: 0.8),
                        value: (isPlayersLayout ? (singlePlayer.map { game.playerScore(for: $0) } ?? 0) : (teamNumber == 1 ? game.score1 : game.score2))
                    )

                    let shouldShowEvents: Bool = {
                        if isPlayersLayout {
                            return isExpanded && isGameLive && game.safeGameState == .playing
                        }
                        return isGameLive && game.currentServer == teamNumber && game.safeGameState == .playing
                    }()

                    if shouldShowEvents {
                        EventButtonsCard(
                            game: game,
                            currentTimestamp: currentTimestamp,
                            tintColor: sectionTintColor,
                            teamNumber: teamNumber,
                            onEventLogged: onEventLogged,
                            layout: game.gameType == .cutthroat ? .scoreAndOutInline : .standard,
                            singlePlayer: singlePlayer,
                            onOutTapped: onOutClearsServe
                        )
                        .accessibilityIdentifier(
                            "SideScoreCard.events.team\(teamNumber)"
                        )
                    }
                }
            }
        }
    }
}

// MARK: - SideScorePreviewHost

@MainActor
private struct SideScorePreviewHost: View {
    @Bindable var game: Game
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ForEach(game.teamsWithLabels(context: modelContext), id: \.teamNumber) { teamConfig in
                SideScoreSection(
                    game: game,
                    teamNumber: teamConfig.teamNumber,
                    teamName: teamConfig.teamName,
                    isGameLive: true,
                    currentTimestamp: 60.0
                )
            }
        }
    }
}

#Preview("Random Player") {
    let container = PreviewContainers.liveGame()
    let (gameManager, _) = PreviewContainers.managers(for: container)
    let syncCoordinator = LiveSyncCoordinator(service: NoopSyncService())
    let game: Game = PreviewContainers.exampleGame(in: container, preferTeamSize: 1)

    SideScorePreviewHost(game: game)
        .modelContainer(container)
        .environment(gameManager)
        .environment(syncCoordinator)
}

#Preview("Random Team") {
    let container = PreviewContainers.liveGame()
    let (gameManager, _) = PreviewContainers.managers(for: container)
    let syncCoordinator = LiveSyncCoordinator(service: NoopSyncService())
    let game: Game = PreviewContainers.exampleGame(in: container, preferTeamSize: 2)

    SideScorePreviewHost(game: game)
        .modelContainer(container)
        .environment(gameManager)
        .environment(syncCoordinator)
}
