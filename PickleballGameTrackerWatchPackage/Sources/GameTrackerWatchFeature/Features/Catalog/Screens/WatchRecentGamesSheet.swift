import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct WatchRecentGamesSheet: View {
  let gameType: GameType
  let onSelect: (Game) -> Void

  @Environment(\.modelContext) private var modelContext

  private static let sort: [SortDescriptor<GameSummary>] = [
    SortDescriptor(\.completedDate, order: .reverse)
  ]
  @Query private var summaries: [GameSummary]

  init(gameType: GameType, onSelect: @escaping (Game) -> Void) {
    self.gameType = gameType
    self.onSelect = onSelect

    let predicate: Predicate<GameSummary> = #Predicate { summary in
      summary.gameTypeId == gameType.rawValue
    }
    self._summaries = Query(filter: predicate, sort: Self.sort)
  }

  var body: some View {
    let games = recentGames()
    return List {
      if games.isEmpty {
        Text("No recent games")
          .foregroundStyle(.secondary)
      } else {
        ForEach(games, id: \.id) { game in
          Button {
            guard game.modelContext != nil else {
              return
            }
            onSelect(game)
          } label: {
            row(for: game)
          }
        }
      }
    }
  }

  @ViewBuilder
  private func row(for game: Game) -> some View {
    if game.modelContext == nil {
      Text("Game unavailable")
        .font(.caption)
        .foregroundStyle(.secondary)
    } else {
      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 6) {
          Image(systemName: game.gameType.iconName)
            .foregroundStyle(.primary)
          Text(RelativeDateTimeFormatter().localizedString(for: game.completedDate ?? game.createdDate, relativeTo: Date()))
            .font(.headline)
        }
        Text(compactParticipants(game))
          .font(.caption2)
          .foregroundStyle(.secondary)
          .lineLimit(2)
        HStack(spacing: 6) {
          Image(systemName: "plus.circle.fill").opacity(game.winByTwo ? 1.0 : 0.3)
          Image(systemName: "checkmark.circle.fill").opacity(game.kitchenRule ? 1.0 : 0.3)
          Image(systemName: "arrow.clockwise.circle.fill").opacity(game.doubleBounceRule ? 1.0 : 0.3)
          Image(systemName: "arrow.triangle.2.circlepath")
          Image(systemName: "arrow.left.arrow.right")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
      }
    }
  }

  private func compactParticipants(_ game: Game) -> String {
    if game.participantMode == .teams {
      let a = game.resolveSide1Team(context: modelContext)?.name ?? game.effectivePlayerLabel1
      let b = game.resolveSide2Team(context: modelContext)?.name ?? game.effectivePlayerLabel2
      return "A: \(a)  ·  B: \(b)"
    } else {
      let a = game.resolveSide1Players(context: modelContext)?.map { $0.name }.joined(separator: " & ") ?? game.effectivePlayerLabel1
      let b = game.resolveSide2Players(context: modelContext)?.map { $0.name }.joined(separator: " & ") ?? game.effectivePlayerLabel2
      return "A: \(a)  ·  B: \(b)"
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
    return fetched
      .filter { $0.modelContext != nil }
      .sorted { (lhs, rhs) in
      let l = order[lhs.id] ?? Int.max
      let r = order[rhs.id] ?? Int.max
      return l < r
    }
  }
}


