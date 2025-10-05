//
//  GameHistoryRow.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 7/9/25.
//

import GameTrackerCore
import SwiftData
import SwiftUI

public struct CompletedGameCard: View {
    let game: Game
    @Environment(\.modelContext) private var modelContext

    public init(game: Game) {
        self.game = game
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: game.gameType.iconName)
                    .font(.system(size: 24, weight: .medium))
                    .shadow(color: .black.opacity(0.20), radius: 3, x: 0, y: 1)
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(game.gameType.displayName)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(formattedDate)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.7))
            }
            
            HStack(spacing: DesignSystem.Spacing.md) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Text(participantName(at: 0))
                        .font(.headline)
                        .fontWeight(game.score1 > game.score2 ? .semibold : .medium)
                        .foregroundStyle(Color.white.opacity(game.score1 > game.score2 ? 1.0 : 0.6))

                    Text("\(game.score1)")
                        .font(.system(size: 26, weight: game.score1 > game.score2 ? .semibold : .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(game.score1 > game.score2 ? 1.0 : 0.6))
                }

                HStack(spacing: DesignSystem.Spacing.sm) {
                    Text(participantName(at: 1))
                        .font(.headline)
                        .fontWeight(game.score2 > game.score1 ? .semibold : .medium)
                        .foregroundStyle(Color.white.opacity(game.score2 > game.score1 ? 1.0 : 0.6))

                    Text("\(game.score2)")
                        .font(.system(size: 26, weight: game.score2 > game.score1 ? .semibold : .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(game.score2 > game.score1 ? 1.0 : 0.6))
                }

                Spacer()
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.lg)
        .glassEffect(
            .regular.tint(game.gameType.color).interactive(),
            in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xxl)
        )
        .contentShape(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xxl)
        )
        .accessibilityLabel("Game card")
        .accessibilityHint("Tap to open completed game details")
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        let now = Date()

        formatter.dateFormat = "h:mm a"
        let timeString = formatter.string(from: game.createdDate)

        if calendar.isDate(game.createdDate, inSameDayAs: now) {
            return "Today \(timeString)"
        } else if calendar.isDate(
            game.createdDate,
            inSameDayAs: calendar.date(byAdding: .day, value: -1, to: now)
                ?? now
        ) {
            return "Yesterday \(timeString)"
        } else if calendar.dateInterval(of: .weekOfYear, for: now)?.contains(
            game.createdDate
        ) == true {
            formatter.dateFormat = "EEE"
            return "\(formatter.string(from: game.createdDate)) \(timeString)"
        } else if calendar.component(.year, from: game.createdDate)
            == calendar.component(.year, from: now)
        {
            formatter.dateFormat = "MMM d"
            return "\(formatter.string(from: game.createdDate)) \(timeString)"
        } else {
            formatter.dateFormat = "MM/dd/yy"
            return "\(formatter.string(from: game.createdDate)) \(timeString)"
        }
    }

    private func participantName(at index: Int) -> String {
        let names = game.teamsWithLabels(context: modelContext).map { $0.teamName }
        if names.count > index, names[index] != "Team \(index + 1)" {
            return names[index]
        }
        return index == 0 ? game.effectivePlayerLabel1 : game.effectivePlayerLabel2
    }

}

#Preview {
    let container = PreviewContainers.history()
    let games = try! container.mainContext.fetch(
        FetchDescriptor<Game>(
            predicate: #Predicate { $0.isCompleted },
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
    )

    ScrollView {
        VStack(spacing: DesignSystem.Spacing.md) {
            ForEach(games) { game in
                CompletedGameCard(game: game)
            }
        }
        .padding()
    }
    .modelContainer(container)
}
