import Foundation
import SwiftData

/// Factory for creating game information and statistics for display purposes
@MainActor
public final class GameInfoFactory {
    private let modelContext: ModelContext
    private let statisticsAggregator: StatisticsAggregator

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.statisticsAggregator = StatisticsAggregator(modelContext: modelContext)
    }

    // MARK: - Game Overview

    public struct GameOverview {
        public let gameType: GameType
        public let effectivePlayerLabel1: String
        public let effectivePlayerLabel2: String
        public let currentScore: String
        public let gameState: GameState
        public let isCompleted: Bool
        public let createdDate: Date
        public let formattedDuration: String?
        public let winningScore: Int
        public let winByTwo: Bool
    }

    public func createGameOverview(for game: Game) -> GameOverview {
        GameOverview(
            gameType: game.gameType,
            effectivePlayerLabel1: game.effectivePlayerLabel1,
            effectivePlayerLabel2: game.effectivePlayerLabel2,
            currentScore: game.formattedScore,
            gameState: game.gameState,
            isCompleted: game.isCompleted,
            createdDate: game.createdDate,
            formattedDuration: game.formattedDuration,
            winningScore: game.winningScore,
            winByTwo: game.winByTwo
        )
    }

    // MARK: - Game Rules

    public struct GameRules {
        public let winningScore: Int
        public let winByTwo: Bool
        public let kitchenRule: Bool
        public let doubleBounceRule: Bool
        public let effectiveTeamSize: Int
        public let hasCustomVariation: Bool
        public let variationName: String?
    }

    public func createGameRules(for game: Game) -> GameRules {
        GameRules(
            winningScore: game.winningScore,
            winByTwo: game.winByTwo,
            kitchenRule: game.kitchenRule,
            doubleBounceRule: game.doubleBounceRule,
            effectiveTeamSize: game.effectiveTeamSize,
            hasCustomVariation: false,
            variationName: nil
        )
    }

    // MARK: - Current Game State

    public struct CurrentGameState {
        public let currentServer: Int
        public let currentServingPlayerLabel: String
        public let serverPosition: ServerPosition
        public let sideOfCourt: SideOfCourt
        public let serverNumber: Int
        public let isFirstServiceSequence: Bool
        public let isAtMatchPoint1: Bool
        public let isAtMatchPoint2: Bool
    }

    public func createCurrentGameState(for game: Game) -> CurrentGameState {
        CurrentGameState(
            currentServer: game.currentServer,
            currentServingPlayerLabel: game.currentServingPlayerLabel,
            serverPosition: game.serverPosition,
            sideOfCourt: game.sideOfCourt,
            serverNumber: game.serverNumber,
            isFirstServiceSequence: game.isFirstServiceSequence,
            isAtMatchPoint1: game.isAtMatchPoint(team: 1),
            isAtMatchPoint2: game.isAtMatchPoint(team: 2)
        )
    }

    // MARK: - Live Statistics

    public struct LiveStatistics {
        public let totalRallies: Int
        public let averageRallyLength: Double?
        public let currentLead: String
        public let scoreDifferential: Int
        public let ralliesPerPoint: Double
        public let timeElapsed: String?
        public let estimatedCompletionTime: String?
    }

    public func createLiveStatistics(for game: Game) async -> LiveStatistics {
        let totalScore = game.score1 + game.score2
        let scoreDifferential = abs(game.score1 - game.score2)
        let currentLead = game.score1 > game.score2 ? game.effectivePlayerLabel1 :
                         game.score2 > game.score1 ? game.effectivePlayerLabel2 : "Tied"

        let ralliesPerPoint = totalScore > 0 ? Double(game.totalRallies) / Double(totalScore) : 0

        // Estimate completion time based on current pace
        let estimatedCompletionTime: String?
        if let duration = game.duration, totalScore > 0 {
            let averageTimePerPoint = duration / Double(totalScore)
            let remainingPoints = max(0, Double(game.winningScore) - Double(max(game.score1, game.score2)))
            let estimatedSeconds = averageTimePerPoint * remainingPoints
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.minute, .second]
            formatter.unitsStyle = .abbreviated
            estimatedCompletionTime = formatter.string(from: estimatedSeconds)
        } else {
            estimatedCompletionTime = nil
        }

        return LiveStatistics(
            totalRallies: game.totalRallies,
            averageRallyLength: nil, // Would need rally-level timing data
            currentLead: currentLead,
            scoreDifferential: scoreDifferential,
            ralliesPerPoint: ralliesPerPoint,
            timeElapsed: game.formattedDuration,
            estimatedCompletionTime: estimatedCompletionTime
        )
    }

    // MARK: - Performance Insights

    public struct PerformanceInsights {
        public let winRate: Double?
        public let serveWinRate: Double?
        public let recentForm: [Bool]? // Last 5 games, true = win
        public let averageScore: String?
    }

    public func createPerformanceInsights(for game: Game) async -> PerformanceInsights {
        do {
            // Get win rate for this game type and players
            let winRateSummary = try statisticsAggregator.computeWinRate(gameTypeId: game.gameType.rawValue)
            let winRate = winRateSummary.totalGames > 0 ? winRateSummary.winRate : nil

            // Get serve win rate
            let serveSummary = try statisticsAggregator.computeServeWinRate(gameTypeId: game.gameType.rawValue)
            let serveWinRate = serveSummary.totalServePoints > 0 ? serveSummary.serveWinRate : nil

            // Get recent games for this player combination
            let recentGames = try await getRecentGames(for: game, limit: 5)
            let recentForm = recentGames.map { $0.score1 > $0.score2 }

            // Calculate average score
            let averageScore: String?
            if !recentGames.isEmpty {
                let avgScore1 = Double(recentGames.reduce(0) { $0 + $1.score1 }) / Double(recentGames.count)
                let avgScore2 = Double(recentGames.reduce(0) { $0 + $1.score2 }) / Double(recentGames.count)
                averageScore = String(format: "%.1f - %.1f", avgScore1, avgScore2)
            } else {
                averageScore = nil
            }

            return PerformanceInsights(
                winRate: winRate,
                serveWinRate: serveWinRate,
                recentForm: recentForm,
                averageScore: averageScore
            )
        } catch {
            // Return empty insights if data fetch fails
            return PerformanceInsights(
                winRate: nil,
                serveWinRate: nil,
                recentForm: nil,
                averageScore: nil
            )
        }
    }

    // MARK: - Helper Methods

    private func getRecentGames(for game: Game, limit: Int) async throws -> [Game] {
        let allGames = try modelContext.fetch(FetchDescriptor<Game>(
            sortBy: [SortDescriptor(\.completedDate, order: .reverse)]
        ))

        // Filter manually since we're dealing with complex relationships
        let filteredGames = allGames.filter { g in
            g.isCompleted && g.gameType.rawValue == game.gameType.rawValue
        }

        return Array(filteredGames.prefix(limit))
    }
}
