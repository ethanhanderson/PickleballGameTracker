//
//  GameHistorySummary.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 7/9/25.
//

import CorePackage
import SwiftUI

// MARK: - Models

private struct GameStat {
    let title: String
    let value: String
    let icon: String
}

private struct GameStats {
    let totalGames: Int
    let completedGames: [Game]
    let activeGames: [Game]
    let winRate: Double
    let currentStreak: (type: String, count: Int)?
    let closeGamesCount: Int
    let bestWinMargin: Int?
    let recentFormWinRate: Double?
}

public struct GameHistorySummary: View {
    let games: [Game]

    private var gameStats: GameStats {
        let completed = games.filter { $0.isCompleted }
        let active = games.filter { !$0.isCompleted }
        let winRate = calculateWinRate(from: completed)

        return GameStats(
            totalGames: games.count,
            completedGames: completed,
            activeGames: active,
            winRate: winRate,
            currentStreak: calculateCurrentStreak(from: completed),
            closeGamesCount: calculateCloseGames(from: completed),
            bestWinMargin: calculateBestWinMargin(from: completed),
            recentFormWinRate: calculateRecentFormWinRate(from: completed)
        )
    }

    // MARK: - Calculation Methods

    private func calculateWinRate(from games: [Game]) -> Double {
        guard !games.isEmpty else { return 0.0 }
        let wins = games.filter { $0.winner == $0.effectivePlayerLabel1 }.count
        return Double(wins) / Double(games.count)
    }

    private func calculateCurrentStreak(from games: [Game]) -> (
        type: String, count: Int
    )? {
        guard !games.isEmpty else { return nil }

        let sortedGames = games.sorted {
            ($0.completedDate ?? Date.distantPast)
                > ($1.completedDate ?? Date.distantPast)
        }

        guard let firstGame = sortedGames.first else { return nil }
        let isWinningStreak =
            firstGame.winner == firstGame.effectivePlayerLabel1

        var streakCount = 1
        for game in sortedGames.dropFirst() {
            let gameIsWin = game.winner == game.effectivePlayerLabel1
            if gameIsWin == isWinningStreak {
                streakCount += 1
            } else {
                break
            }
        }

        return (type: isWinningStreak ? "W" : "L", count: streakCount)
    }

    private func calculateCloseGames(from games: [Game]) -> Int {
        games.filter { abs($0.score1 - $0.score2) <= 2 }.count
    }

    private func calculateBestWinMargin(from games: [Game]) -> Int? {
        let wins = games.filter { $0.winner == $0.effectivePlayerLabel1 }
        guard !wins.isEmpty else { return nil }
        return wins.map { abs($0.score1 - $0.score2) }.max()
    }

    private func calculateRecentFormWinRate(from games: [Game]) -> Double? {
        guard games.count >= 3 else { return nil }
        let recentCount = min(5, games.count)
        let recentGames = Array(games.suffix(recentCount))
        let recentWins = recentGames.filter {
            $0.winner == $0.effectivePlayerLabel1
        }.count
        return Double(recentWins) / Double(recentGames.count)
    }

    // MARK: - Stat Building

    private var displayStats: [GameStat] {
        let stats = gameStats
        var availableStats: [GameStat] = []

        // Always show total games
        availableStats.append(
            GameStat(
                title: "Games",
                value: "\(stats.totalGames)",
                icon: "gamecontroller.fill"
            )
        )

        // Show win rate if we have completed games
        if !stats.completedGames.isEmpty {
            availableStats.append(
                GameStat(
                    title: "Win Rate",
                    value: "\(Int(stats.winRate * 100))%",
                    icon: "trophy.fill"
                )
            )
        }

        // Add streak if available
        if let streak = stats.currentStreak {
            availableStats.append(
                GameStat(
                    title: "Streak",
                    value: "\(streak.count)\(streak.type)",
                    icon: streak.type == "W" ? "flame.fill" : "wind"
                )
            )
        }

        // Add close games if we have enough data
        if stats.completedGames.count >= 2 {
            availableStats.append(
                GameStat(
                    title: "Close Games",
                    value: "\(stats.closeGamesCount)",
                    icon: "target"
                )
            )
        }

        // Add best win margin if available
        if let bestMargin = stats.bestWinMargin {
            availableStats.append(
                GameStat(
                    title: "Best Win",
                    value: "+\(bestMargin)",
                    icon: "star.fill"
                )
            )
        }

        // Add recent form if available
        if let recentRate = stats.recentFormWinRate {
            availableStats.append(
                GameStat(
                    title: "Recent",
                    value: "\(Int(recentRate * 100))%",
                    icon: "chart.line.uptrend.xyaxis"
                )
            )
        }

        // Add active games if available and we need more stats
        if !stats.activeGames.isEmpty && availableStats.count < 6 {
            availableStats.append(
                GameStat(
                    title: "Active",
                    value: "\(stats.activeGames.count)",
                    icon: "play.circle.fill"
                )
            )
        }

        return Array(availableStats.prefix(6))  // Show max 6 stats
    }

    public var body: some View {
        VStack(alignment: .leading) {
            statsGrid
        }
    }

    // MARK: - View Components
    private var statsGrid: some View {
        let stats = displayStats
        let columns = Array(repeating: GridItem(.flexible()), count: 3)

        return LazyVGrid(columns: columns, spacing: DesignSystem.Spacing.lg) {
            ForEach(stats.indices, id: \.self) { index in
                statItem(stats[index])
            }
        }
        .padding(.vertical, DesignSystem.Spacing.lg)
    }

    private func statItem(_ stat: GameStat) -> some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: stat.icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(DesignSystem.Colors.primary)
                .shadow(
                    color: DesignSystem.Colors.primary.opacity(0.3),
                    radius: 3,
                    x: 0,
                    y: 2
                )

            SimpleStatCard(title: stat.title, value: stat.value)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Previews

#Preview("With Games") {
    GameHistorySummary(games: PreviewGameData.competitivePlayerGames)
        .padding()
}

#Preview("New Player") {
    GameHistorySummary(games: PreviewGameData.newPlayerGames)
        .padding()
}

#Preview("Empty State") {
    GameHistorySummary(games: PreviewGameData.emptyGames)
        .padding()
}
