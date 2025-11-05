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
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: game.gameType.iconName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(game.gameType.color)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(game.gameType.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text(formattedDate)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .center) {
                HStack(alignment: .center) {
                    VStack(
                        alignment: .leading,
                        spacing: DesignSystem.Spacing.sm
                    ) {
                        side1Avatar

                        Text(formattedParticipantName(for: 1))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                    }
                    
                    Spacer(minLength: DesignSystem.Spacing.md)

                    Text("\(game.score1)")
                        .font(
                            .system(size: 44, weight: .bold, design: .rounded)
                        )
                        .foregroundStyle(
                            game.score1 > game.score2
                                ? .primary : Color.primary.opacity(0.5)
                        )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !gameDuration.isEmpty {
                    Spacer(minLength: DesignSystem.Spacing.xl)

                    Text(gameDuration)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Spacer(minLength: DesignSystem.Spacing.xl)
                } else {
                    Spacer()
                }

                HStack(alignment: .center) {
                    Text("\(game.score2)")
                        .font(
                            .system(size: 44, weight: .bold, design: .rounded)
                        )
                        .foregroundStyle(
                            game.score2 > game.score1
                                ? .primary : Color.primary.opacity(0.5)
                        )
                    
                    Spacer(minLength: DesignSystem.Spacing.md)

                    VStack(
                        alignment: .trailing,
                        spacing: DesignSystem.Spacing.sm
                    ) {
                        side2Avatar

                        Text(formattedParticipantName(for: 2))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.trailing)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.lg)
        .glassEffect(
            .regular.tint(
                game.gameType.color.opacity(0.05)
            ),
            in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
        )
        .contentShape(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
        )
        .accessibilityLabel("Game card")
        .accessibilityHint("Tap to open completed game details")
    }

    private var side1Avatar: some View {
        Group {
            switch game.participantMode {
            case .players:
                if let players = game.resolveSide1Players(
                    context: modelContext
                ),
                    let firstPlayer = players.first
                {
                    AvatarView(
                        player: firstPlayer,
                        style: .small,
                        isArchived: firstPlayer.isArchived
                    )
                } else {
                    fallbackAvatar(symbolName: "person.fill", teamNumber: 1)
                }
            case .teams:
                if let team = game.resolveSide1Team(context: modelContext) {
                    AvatarView(
                        team: team,
                        style: .small,
                        isArchived: team.isArchived
                    )
                } else {
                    fallbackAvatar(symbolName: "person.2.fill", teamNumber: 1)
                }
            }
        }
    }

    private var side2Avatar: some View {
        Group {
            switch game.participantMode {
            case .players:
                if let players = game.resolveSide2Players(
                    context: modelContext
                ),
                    let firstPlayer = players.first
                {
                    AvatarView(
                        player: firstPlayer,
                        style: .small,
                        isArchived: firstPlayer.isArchived
                    )
                } else {
                    fallbackAvatar(symbolName: "person.fill", teamNumber: 2)
                }
            case .teams:
                if let team = game.resolveSide2Team(context: modelContext) {
                    AvatarView(
                        team: team,
                        style: .small,
                        isArchived: team.isArchived
                    )
                } else {
                    fallbackAvatar(symbolName: "person.2.fill", teamNumber: 2)
                }
            }
        }
    }

    private func fallbackAvatar(symbolName: String, teamNumber: Int)
        -> some View
    {
        AvatarView(
            configuration: .init(
                symbolName: symbolName,
                tintColor: game.teamTintColor(
                    for: teamNumber,
                    context: modelContext
                ),
                style: .small
            )
        )
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

    private var gameDuration: String {
        if let formatted = game.formattedDuration {
            return formatted
        }

        if let completedDate = game.completedDate {
            let duration = completedDate.timeIntervalSince(game.createdDate)
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }

        return ""
    }

    private func formattedParticipantName(for sideNumber: Int) -> String {
        let players: [PlayerProfile]

        switch game.participantMode {
        case .players:
            if sideNumber == 1 {
                players = game.resolveSide1Players(context: modelContext) ?? []
            } else {
                players = game.resolveSide2Players(context: modelContext) ?? []
            }
        case .teams:
            if sideNumber == 1 {
                players =
                    game.resolveSide1Team(context: modelContext)?.players ?? []
            } else {
                players =
                    game.resolveSide2Team(context: modelContext)?.players ?? []
            }
        }

        guard !players.isEmpty else {
            return sideNumber == 1
                ? game.effectivePlayerLabel1 : game.effectivePlayerLabel2
        }

        let names = players.map { $0.name }
        if names.count == 1 {
            return names[0]
        } else if names.count >= 2 {
            return "\(names[0]) &\n\(names[1])"
        }

        return names.joined(separator: " &\n")
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
            ForEach(Array(games.prefix(5))) { game in
                CompletedGameCard(game: game)
            }
        }
        .padding()
    }
    .modelContainer(container)
}

#Preview("Single Game") {
    let container = PreviewContainers.history()
    let games = try! container.mainContext.fetch(
        FetchDescriptor<Game>(
            predicate: #Predicate { $0.isCompleted },
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
    )

    if let randomGame = games.randomElement() {
        CompletedGameCard(game: randomGame)
            .padding()
            .modelContainer(container)
    } else {
        Text("No games available")
            .padding()
            .modelContainer(container)
    }
}
