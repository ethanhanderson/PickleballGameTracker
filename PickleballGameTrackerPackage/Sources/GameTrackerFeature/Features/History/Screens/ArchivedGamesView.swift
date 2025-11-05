import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct ArchivedGamesView: View {
  @Query(
    filter: #Predicate<Game> { $0.isArchived && $0.isCompleted },
    sort: [SortDescriptor(\.completedDate, order: .reverse)]
  ) private var archivedGames: [Game]

  private var isEmpty: Bool {
    archivedGames.isEmpty
  }

  var body: some View {
    Group {
      if isEmpty {
        ScrollView {
          VStack {
            EmptyStateView(
              icon: "archivebox",
              title: "No Archived Games",
              description: "Archive completed games to hide them from History."
            )
          }
        }
        .contentMargins(.horizontal, DesignSystem.Spacing.md, for: .scrollContent)
        .contentMargins(.top, DesignSystem.Spacing.sm, for: .scrollContent)
        .scrollClipDisabled()
      } else {
        ScrollView {
          VStack(spacing: DesignSystem.Spacing.md) {
            ForEach(archivedGames) { game in
              gameCard(for: game)
            }
          }
        }
        .contentMargins(.horizontal, DesignSystem.Spacing.md, for: .scrollContent)
        .contentMargins(.vertical, DesignSystem.Spacing.md, for: .scrollContent)
      }
    }
    .navigationTitle("Archive")
    .viewContainerBackground()
  }

  private func gameCard(for game: Game) -> some View {
    NavigationLink(value: GameHistoryDestination.gameDetail(game.id)) {
      HStack {
        VStack(alignment: .leading) {
          Text(game.gameType.displayName)
            .font(.body)
          if let d = game.completedDate {
            Text(d.formatted(date: .abbreviated, time: .shortened))
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        Spacer()
        Text(game.formattedScore)
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
}
