import PickleballGameTrackerCorePackage
import SwiftData
import SwiftUI

@MainActor
struct ArchivedGamesView: View {
  private static let archivedCompletedFilter: Predicate<Game> = #Predicate {
    $0.isArchived && $0.isCompleted
  }
  private static let sortByCompletedDateDesc: [SortDescriptor<Game>] = [
    SortDescriptor(\.completedDate, order: .reverse)
  ]

  @Query(
    filter: Self.archivedCompletedFilter,
    sort: Self.sortByCompletedDateDesc
  ) private var archivedGames: [Game]

  var body: some View {
    List {
      if archivedGames.isEmpty {
        Section {
          CustomContentUnavailableView(
            icon: "archivebox",
            title: "No Archived Games",
            description: "Archive completed games to hide them from History."
          )
          .listRowBackground(Color.clear)
        }
      } else {
        ForEach(archivedGames, id: \.id) { game in
          NavigationLink(value: GameHistoryDestination.gameDetail(game)) {
            HStack {
              VStack(alignment: .leading) {
                Text(game.gameType.displayName)
                  .font(DesignSystem.Typography.body)
                if let d = game.completedDate {
                  Text(d.formatted(date: .abbreviated, time: .shortened))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)
                }
              }
              Spacer()
              Text(game.formattedScore)
                .font(DesignSystem.Typography.bodyEmphasized)
            }
          }
        }
      }
    }
    .navigationTitle("Archive")
  }
}
