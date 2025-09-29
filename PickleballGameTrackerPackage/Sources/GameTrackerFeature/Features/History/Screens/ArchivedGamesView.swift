import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct ArchivedGamesView: View {
  @Query private var allGames: [Game]

  private static let sortByCompletedDateDesc: [SortDescriptor<Game>] = [
    SortDescriptor(\.completedDate, order: .reverse)
  ]

  private var archivedGames: [Game] {
    let filtered = allGames.filter { game in
      game.isArchived && game.isCompleted
    }
    return filtered.sorted(using: Self.sortByCompletedDateDesc)
  }

  private var gamesList: [Game] {
    archivedGames
  }

  private var isEmpty: Bool {
    gamesList.isEmpty
  }

  private var gameCards: some View {
    ForEach(gamesList.indices, id: \.self) { index in
      gameCard(for: index)
    }
  }

  private func gameCard(for index: Int) -> some View {
    NavigationLink(value: GameHistoryDestination.gameDetail(gamesList[index].id)) {
      HStack {
        VStack(alignment: .leading) {
          Text(gamesList[index].gameType.displayName)
            .font(.body)
          if let d = gamesList[index].completedDate {
            Text(d.formatted(date: .abbreviated, time: .shortened))
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        Spacer()
        Text(gamesList[index].formattedScore)
          .font(.body)
          .fontWeight(.semibold)
      }
      .padding(.horizontal, DesignSystem.Spacing.md)
      .padding(.vertical, DesignSystem.Spacing.sm)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Color(UIColor.secondarySystemBackground).opacity(0.3))
      .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
    }
    .buttonStyle(.plain)
  }

  private var emptyState: some View {
    EmptyStateView(
      icon: "archivebox",
      title: "No Archived Games",
      description: "Archive completed games to hide them from History."
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.top, 100)
  }

  private var content: some View {
    if isEmpty {
      return AnyView(emptyState)
    } else {
      return AnyView(
        VStack(spacing: DesignSystem.Spacing.md) {
          gameCards
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.md)
      )
    }
  }

  var body: some View {
    ScrollView {
      content
    }
    .navigationTitle("Archive")
    .background(Color(UIColor.systemGroupedBackground))
  }
}
