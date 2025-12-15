import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct RecentGamesSheet: View {
  let gameType: GameType
  let onSelect: (Game) -> Void
  let onStartNewGame: (() -> Void)?

  @Environment(\.modelContext) private var modelContext

  private static let sort: [SortDescriptor<GameSummary>] = [
    SortDescriptor(\.completedDate, order: .reverse)
  ]

  @Query private var summaries: [GameSummary]

  init(
    gameType: GameType,
    onSelect: @escaping (Game) -> Void,
    onStartNewGame: (() -> Void)? = nil
  ) {
    self.gameType = gameType
    self.onSelect = onSelect
    self.onStartNewGame = onStartNewGame

    let predicate: Predicate<GameSummary> = #Predicate { summary in
      summary.gameTypeId == gameType.rawValue
    }

    self._summaries = Query(filter: predicate, sort: Self.sort)
  }

  var body: some View {
    NavigationStack {
      content
        .navigationTitle("Recent \(gameType.displayName)")
        .navigationBarTitleDisplayMode(.inline)
    }
    .presentationDetents([.medium, .large])
  }

  @ViewBuilder
  private var content: some View {
    let games = recentGames()
    if games.isEmpty {
      VStack(spacing: DesignSystem.Spacing.lg) {
        Image(systemName: "clock.arrow.circlepath")
          .font(.system(size: 34, weight: .medium))
          .foregroundStyle(.secondary)

        Text("No recent games")
          .font(.headline)
          .foregroundStyle(.primary)

        if let onStartNewGame {
          Button(action: onStartNewGame) {
            Label("Start New Game", systemImage: "play.fill")
          }
          .buttonStyle(.glassProminent)
          .tint(Color(UIColor.secondarySystemBackground).opacity(0.4))
          .foregroundStyle(gameType.color)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding()
    } else {
      List {
        ForEach(games, id: \.id) { game in
          Button {
            onSelect(game)
          } label: {
            RecentGameCard(game: game)
          }
          .buttonStyle(.plain)
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
        }
      }
      .listStyle(.plain)
    }
  }

  private func recentGames() -> [Game] {
    let limitedSummaries = Array(summaries.prefix(5))
    guard limitedSummaries.isEmpty == false else { return [] }

    let ids = limitedSummaries.map { $0.gameId }
    let idSet = Set(ids)

    let predicate: Predicate<Game> = #Predicate { g in
      idSet.contains(g.id) && g.isArchived == false
    }
    var descriptor = FetchDescriptor<Game>(predicate: predicate)
    descriptor.fetchLimit = 5

    let fetched: [Game] = (try? modelContext.fetch(descriptor)) ?? []

    let order: [UUID: Int] = Dictionary(
      uniqueKeysWithValues: ids.enumerated().map { ($1, $0) }
    )
    return fetched.sorted { (lhs, rhs) in
      let l = order[lhs.id] ?? Int.max
      let r = order[rhs.id] ?? Int.max
      return l < r
    }
  }
}


