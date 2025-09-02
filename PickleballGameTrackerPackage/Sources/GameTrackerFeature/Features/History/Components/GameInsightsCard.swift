//
//  GameInsightsCard.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 7/9/25.
//

import CorePackage
import SwiftUI

public struct GameInsightsCard: View {
    let games: [Game]

    private var completedGames: [Game] {
        games.filter { $0.isCompleted }
    }

    private var totalGames: Int { completedGames.count }

    private var winRate: Double {
        guard completedGames.count > 0 else { return 0.0 }
        let wins = completedGames.filter {
            $0.winner == $0.effectivePlayerLabel1
        }.count
        return Double(wins) / Double(completedGames.count)
    }

    private var currentStreak: (count: Int, isWinning: Bool)? {
        let sortedGames = completedGames.sorted {
            ($0.completedDate ?? $0.lastModified)
                > ($1.completedDate ?? $1.lastModified)
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

        return (streakCount, isWinningStreak)
    }

    private var closeGamesCount: Int {
        completedGames.filter { abs($0.score1 - $0.score2) <= 2 }.count
    }

    private var bestWinMargin: Int? {
        let wins = completedGames.filter {
            $0.winner == $0.effectivePlayerLabel1
        }
        guard !wins.isEmpty else { return nil }

        return wins.map { abs($0.score1 - $0.score2) }.max()
    }

    private var recentFormRate: Double? {
        let recentGames = Array(completedGames.suffix(5))
        guard recentGames.count >= 3 else { return nil }

        let recentWins = recentGames.filter {
            $0.winner == $0.effectivePlayerLabel1
        }.count
        return Double(recentWins) / Double(recentGames.count)
    }

    private func winningStreakMessage(for count: Int) -> (
        icon: String, message: String
    ) {
        switch count {
        case 3...4:
            return (
                "arrow.up.right.circle.fill",
                "Building momentum with a \(count)-game win streak!"
            )
        case 5...6:
            return (
                "star.circle.fill",
                "Excellent consistency - \(count) wins in a row!"
            )
        case 7...9:
            return (
                "crown.fill",
                "Dominating performance with \(count) straight wins!"
            )
        case 10...14:
            return (
                "trophy.fill",
                "Incredible streak - \(count) consecutive victories!"
            )
        case 15...19:
            return ("flame.fill", "Legendary run of \(count) straight wins!")
        default:  // 20+
            return (
                "sparkles", "Unstoppable champion - \(count) games undefeated!"
            )
        }
    }

    private var primaryInsight: (icon: String, message: String, color: Color) {
        // Prioritize insights based on what's most actionable/interesting

        // Check for current streak first (most engaging)
        if let streak = currentStreak, streak.count >= 3 {
            if streak.isWinning {
                let (icon, message) = winningStreakMessage(for: streak.count)
                return (icon, message, DesignSystem.Colors.success)
            } else {
                return (
                    "arrow.up.circle.fill",
                    "Learning phase - \(streak.count) games to analyze and improve",
                    DesignSystem.Colors.warning
                )
            }
        }

        // Check recent form (5+ games needed)
        if let recentForm = recentFormRate, totalGames >= 5 {
            if recentForm >= 0.8 {
                return (
                    "chart.line.uptrend.xyaxis",
                    "Hot streak - winning 80%+ of recent games!",
                    DesignSystem.Colors.success
                )
            } else if recentForm <= 0.2 {
                return (
                    "lightbulb.fill",
                    "Time to adjust strategy - fresh approach needed",
                    DesignSystem.Colors.primary
                )
            }
        }

        // Check close games performance
        if totalGames >= 5 {
            let closeGameRate = Double(closeGamesCount) / Double(totalGames)
            if closeGameRate >= 0.5 {
                return (
                    "target",
                    "Thriving in pressure - 50%+ games decided by 2 points",
                    DesignSystem.Colors.primary
                )
            }
        }

        // Check best win margin
        if let bestMargin = bestWinMargin, bestMargin >= 6 {
            return (
                "crown.fill",
                "Dominant performance - biggest win by \(bestMargin) points!",
                DesignSystem.Colors.warning
            )
        }

        // Check overall win rate
        if totalGames >= 3 {
            if winRate >= 0.7 {
                return (
                    "star.fill", "Excellent form - winning 70%+ of your games!",
                    DesignSystem.Colors.success
                )
            } else if winRate >= 0.5 {
                return (
                    "scale.3d",
                    "Balanced competitor - even match record shows growth",
                    DesignSystem.Colors.primary
                )
            } else {
                return (
                    "graduationcap.fill",
                    "Building fundamentals - every game teaches valuable lessons",
                    DesignSystem.Colors.primary
                )
            }
        }

        // Default for new players
        return (
            "play.circle.fill",
            "Welcome to pickleball! Track your journey and improvement",
            DesignSystem.Colors.primary
        )
    }

    public var body: some View {
        let insight = primaryInsight

        HStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: insight.icon)
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(
                    DesignSystem.Colors.primary.gradient
                )
                .shadow(
                    color: DesignSystem.Colors.primary.opacity(0.3),
                    radius: 3,
                    x: 0,
                    y: 2
                )
                .frame(width: 24, height: 24)

            Text(insight.message)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(DesignSystem.Spacing.lg)
        .glassEffect(
            .regular.tint(
                DesignSystem.Colors.containerFillSecondary.opacity(0.2)
            ),
            in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
        )
    }

    public init(games: [Game]) {
        self.games = games
    }
}

#Preview("Hot Streak Player") {
    GameInsightsCard(games: PreviewGameData.hotStreakPlayerGames)
        .padding()
}

#Preview("New Player") {
    GameInsightsCard(games: PreviewGameData.newPlayerGames)
        .padding()
}

#Preview("Competitive Player") {
    GameInsightsCard(games: PreviewGameData.competitivePlayerGames)
        .padding()
}

#Preview("Dominant Player") {
    GameInsightsCard(games: PreviewGameData.dominantPlayerGames)
        .padding()
}

#Preview("Empty State") {
    GameInsightsCard(games: PreviewGameData.emptyGames)
        .padding()
}
