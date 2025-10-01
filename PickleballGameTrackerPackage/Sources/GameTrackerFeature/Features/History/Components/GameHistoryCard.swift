//
//  GameHistoryRow.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 7/9/25.
//

import GameTrackerCore
import SwiftUI

public struct GameHistoryCard: View {
    let game: Game
    let onTapped: (() -> Void)?

    public init(game: Game, onTapped: (() -> Void)? = nil) {
        self.game = game
        self.onTapped = onTapped
    }

    public var body: some View {
        Button(action: { onTapped?() }) {
            mainCard
        }
        .buttonStyle(.plain)
        .navigationButtonAccessibility(label: "Open Completed Game")
    }

    // MARK: - View Components

    private var mainCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            headerRow
            participantsRow
            infoRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.md)
        .glassEffect(
            .regular.tint(
                {
                    switch game.gameType {
                    case .recreational: Color.blue
                    case .tournament: Color.green
                    case .training: Color.purple
                    case .social: Color.orange
                    case .custom: Color.red
                    }
                }()
            ),
            in: RoundedRectangle(
                cornerRadius: DesignSystem.CornerRadius.xxl,
                style: .continuous
            )
        )
    }

    // MARK: - Header Row (Icon, Name/Title, Caret)

    private var headerRow: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            gameIcon
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(primaryTitle)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                Text(secondaryTitle)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.white.opacity(0.7))
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.7))
                .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
        }
    }

    private var gameIcon: some View {
        Image(systemName: game.gameType.iconName)
            .font(.system(size: 24, weight: .medium))
            .foregroundStyle(Color.white)
            .shadow(color: .black.opacity(0.20), radius: 3, x: 0, y: 1)
            .frame(width: 32, height: 32)
    }

    private var primaryTitle: String {
        if let name = game.gameVariation?.name, name.isEmpty == false {
            return name
        }
        return game.gameType.displayName
    }

    private var secondaryTitle: String {
        if let name = game.gameVariation?.name, name.isEmpty == false {
            return game.gameType.displayName
        }
        return compactFormattedDate
    }

    private var compactFormattedDate: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDate(game.createdDate, inSameDayAs: now) {
            formatter.dateFormat = "h:mm a"
            return "Today \(formatter.string(from: game.createdDate))"
        } else if calendar.isDate(
            game.createdDate,
            inSameDayAs: calendar.date(byAdding: .day, value: -1, to: now)
                ?? now
        ) {
            return "Yesterday"
        } else if calendar.dateInterval(of: .weekOfYear, for: now)?.contains(
            game.createdDate
        ) == true {
            formatter.dateFormat = "EEE"
            return formatter.string(from: game.createdDate)
        } else if calendar.component(.year, from: game.createdDate)
            == calendar.component(.year, from: now)
        {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: game.createdDate)
        } else {
            formatter.dateFormat = "MM/dd/yy"
            return formatter.string(from: game.createdDate)
        }
    }

    // MARK: - Participants Row

    private var participantsRow: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.8))
            Text(participantsDisplay)
                .font(.subheadline)
                .fontWeight(.semibold)
                .fontDesign(.rounded)
                .foregroundStyle(Color.white)
                .lineLimit(1)
        }
    }

    private var participantsDisplay: String {
        let names = game.teamsWithLabels.map { $0.teamName }
        if names.count == 2, names != ["Team 1", "Team 2"] {
            return "\(names[0]) vs \(names[1])"
        }
        return "\(game.effectivePlayerLabel1) vs \(game.effectivePlayerLabel2)"
    }

    // MARK: - Info Row

    private var infoRow: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            if game.isCompleted {
                infoItem(icon: "trophy.fill", value: winnerText)
                infoItem(
                    icon: "clock.fill",
                    value: game.formattedDuration ?? "—"
                )
                infoItem(icon: "number", value: game.formattedScore)
                if game.totalRallies > 0 {
                    infoItem(
                        icon: "arrow.triangle.2.circlepath",
                        value: "\(game.totalRallies)"
                    )
                }
            } else {
                infoItem(icon: "chart.bar.fill", value: "In Progress")
                infoItem(icon: "number", value: game.formattedScore)
            }
        }
    }

    private func infoItem(icon: String, value: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.7))
                .frame(width: 16)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .fontDesign(.rounded)
                .foregroundStyle(Color.white)
                .lineLimit(1)
        }
    }

    private var winnerText: String {
        if game.isCompleted, let winner = game.winner {
            switch winner {
            case game.effectivePlayerLabel1: return "P1"
            case game.effectivePlayerLabel2: return "P2"
            default: return "Tie"
            }
        } else {
            return "\(abs(game.score1 - game.score2))"
        }
    }
}

#Preview("Game History Cards") {
    VStack(spacing: DesignSystem.Spacing.md) {
        GameHistoryCard(game: CompletedGameFactory.recentCompetitiveWin())
        GameHistoryCard(game: CompletedGameFactory.dominantVictory())
        GameHistoryCard(game: CompletedGameFactory.tournamentMatch())
    }
    .padding()
}
