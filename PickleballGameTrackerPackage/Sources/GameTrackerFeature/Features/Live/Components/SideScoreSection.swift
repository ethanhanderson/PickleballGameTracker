import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct SideScoreSection: View {
    @Bindable var game: Game
    let teamNumber: Int
    let teamName: String
    let gameManager: SwiftDataGameManager
    let isGameActive: Bool
    let currentTimestamp: TimeInterval
    let onEventLogged: ((GameEvent) -> Void)?
    @Environment(\.modelContext) private var modelContext

    init(
        game: Game,
        teamNumber: Int,
        teamName: String,
        gameManager: SwiftDataGameManager,
        isGameActive: Bool,
        currentTimestamp: TimeInterval,
        onEventLogged: ((GameEvent) -> Void)? = nil
    ) {
        self.game = game
        self.teamNumber = teamNumber
        self.teamName = teamName
        self.gameManager = gameManager
        self.isGameActive = isGameActive
        self.currentTimestamp = currentTimestamp
        self.onEventLogged = onEventLogged
    }

    private var teamTintColor: Color {
        // Use roster colors where available, fall back to game tint
        if let team = try? modelContext.fetch(FetchDescriptor<TeamProfile>(predicate: #Predicate { $0.name == teamName })).first {
            return team.primaryColor
        }
        if let player = try? modelContext.fetch(FetchDescriptor<PlayerProfile>(predicate: #Predicate { $0.name == teamName })).first {
            return player.primaryColor
        }
        return game.teamTintColor(for: teamNumber)
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            SideScoreTopCard(
                game: game,
                teamNumber: teamNumber,
                teamName: teamName,
                isGameActive: isGameActive,
                showTapIndicator: game.gameState == .playing || game.gameState == .paused,
                gameManager: gameManager,
                tintOverride: teamTintColor
            )
            .animation(
                Animation.spring(response: 0.3, dampingFraction: 0.8),
                value: teamNumber == 1 ? game.score1 : game.score2
            )

            if isGameActive && game.currentServer == teamNumber && game.gameState == .playing {
                EventButtonsCard(
                    game: game,
                    currentTimestamp: currentTimestamp,
                    tintColor: teamTintColor,
                    gameManager: gameManager,
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
    let gameManager: SwiftDataGameManager

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ForEach(game.teamsWithLabels, id: \.teamNumber) { teamConfig in
                SideScoreSection(
                    game: game,
                    teamNumber: teamConfig.teamNumber,
                    teamName: teamConfig.teamName,
                    gameManager: gameManager,
                    isGameActive: true,
                    currentTimestamp: 60.0
                )
            }
        }
    }
}

#Preview("Random Player") {
    let env = PreviewEnvironment.liveGame()
    let context = env.container.mainContext
    let game: Game = (try? context.fetch(FetchDescriptor<Game>()).first(where: { $0.gameVariation?.teamSize == 1 }))
        ?? ((try? context.fetch(FetchDescriptor<Game>()))?.first ?? Game(gameType: .recreational))

    SideScorePreviewHost(game: game, gameManager: env.gameManager)
        .modelContainer(env.container)
}

#Preview("Random Team") {
    let env = PreviewEnvironment.liveGame()
    let context = env.container.mainContext
    let game: Game = (try? context.fetch(FetchDescriptor<Game>()).first(where: { ($0.gameVariation?.teamSize ?? $0.gameType.defaultTeamSize) > 1 }))
        ?? ((try? context.fetch(FetchDescriptor<Game>()))?.first ?? Game(gameType: .recreational))

    SideScorePreviewHost(game: game, gameManager: env.gameManager)
        .modelContainer(env.container)
}
