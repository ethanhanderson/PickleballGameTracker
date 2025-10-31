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
    @Environment(\.modelContext) private var modelContext
    @Environment(SwiftDataGameManager.self) private var gameManager

    init(
        game: Game,
        teamNumber: Int,
        teamName: String,
        isGameLive: Bool,
        currentTimestamp: TimeInterval,
        onEventLogged: ((GameEvent) -> Void)? = nil
    ) {
        self.game = game
        self.teamNumber = teamNumber
        self.teamName = teamName
        self.isGameLive = isGameLive
        self.currentTimestamp = currentTimestamp
        self.onEventLogged = onEventLogged
    }

    private var teamTintColor: Color {
        game.teamTintColor(for: teamNumber, context: modelContext)
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            SideScoreTopCard(
                game: game,
                teamNumber: teamNumber,
                teamName: teamName,
                isGameLive: isGameLive,
                showTapIndicator: game.gameState == .playing || game.gameState == .paused,
                tintOverride: teamTintColor
            )
            .animation(
                Animation.spring(response: 0.3, dampingFraction: 0.8),
                value: teamNumber == 1 ? game.score1 : game.score2
            )

            if isGameLive && game.currentServer == teamNumber && game.gameState == .playing {
                EventButtonsCard(
                    game: game,
                    currentTimestamp: currentTimestamp,
                    tintColor: teamTintColor,
                    teamNumber: teamNumber,
                    onEventLogged: onEventLogged
                )
                .accessibilityIdentifier(
                    "SideScoreCard.events.team\(teamNumber)"
                )
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
    let context = container.mainContext
    let game: Game = (try? context.fetch(FetchDescriptor<Game>()).first(where: { $0.effectiveTeamSize == 1 }))
        ?? ((try? context.fetch(FetchDescriptor<Game>()))?.first ?? Game(gameType: .recreational))

    SideScorePreviewHost(game: game)
        .modelContainer(container)
        .environment(gameManager)
}

#Preview("Random Team") {
    let container = PreviewContainers.liveGame()
    let (gameManager, _) = PreviewContainers.managers(for: container)
    let context = container.mainContext
    let game: Game = (try? context.fetch(FetchDescriptor<Game>()).first(where: { $0.effectiveTeamSize > 1 }))
        ?? ((try? context.fetch(FetchDescriptor<Game>()))?.first ?? Game(gameType: .recreational))

    SideScorePreviewHost(game: game)
        .modelContainer(container)
        .environment(gameManager)
}
