//
//  GameHistoryView.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 7/9/25.
//

// Import the history types we need
import Foundation
import PickleballGameTrackerCorePackage
import SwiftData
import SwiftUI

// MARK: - Supporting Types

enum GroupingOption: String, CaseIterable, Identifiable {
  case none = "none"
  case gameType = "gameType"
  case date = "date"
  case winnerLose = "winnerLose"

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .none: return "No Grouping"
    case .gameType: return "Game Type"
    case .date: return "Date"
    case .winnerLose: return "Win/Loss"
    }
  }

  var description: String {
    switch self {
    case .none: return "Show all games in chronological order"
    case .gameType: return "Group games by type (Singles, Doubles, Traditional)"
    case .date: return "Group games by date played"
    case .winnerLose: return "Group games by whether you won or lost"
    }
  }

  var systemImage: String {
    switch self {
    case .none: return "list.bullet"
    case .gameType: return "gamecontroller.fill"
    case .date: return "calendar"
    case .winnerLose: return "trophy.fill"
    }
  }
}

enum GameFilter: Identifiable, Hashable {
  case all
  case gameType(GameType)
  case wins
  case losses

  var id: String {
    switch self {
    case .all: return "all"
    case .gameType(let type): return "gameType_\(type.rawValue)"
    case .wins: return "wins"
    case .losses: return "losses"
    }
  }

  var displayName: String {
    switch self {
    case .all: return "All Games"
    case .gameType(let type): return type.displayName
    case .wins: return "Wins"
    case .losses: return "Losses"
    }
  }

  // Static computed property for all available filters
  static var allFilters: [GameFilter] {
    var filters: [GameFilter] = [.all]

    // Add game type filters from catalog
    filters.append(contentsOf: GameCatalog.allGameTypes.map { .gameType($0) })

    // Add result filters
    filters.append(contentsOf: [.wins, .losses])

    return filters
  }
}

struct GroupedGames: Identifiable {
  var id: String { title }
  let title: String
  let games: [Game]
}

@MainActor
struct GameHistoryView: View {
  @Environment(\.modelContext) private var modelContext
  private static let completedUnarchivedFilter: Predicate<Game> = #Predicate {
    $0.isCompleted && !$0.isArchived
  }
  private static let sortByLastModifiedDesc: [SortDescriptor<Game>] = [
    SortDescriptor(\.lastModified, order: .reverse)
  ]
  @Query(
    filter: Self.completedUnarchivedFilter,
    sort: Self.sortByLastModifiedDesc
  ) private var completedGames: [Game]

  @State private var selectedFilter: GameFilter = .all  // Logical default: show all games
  @State private var selectedGrouping: GroupingOption = .none  // Logical default: chronological order
  @State private var path: [GameHistoryDestination] = []

  // MARK: - Computed Properties

  private var filteredGames: [Game] {
    var games = completedGames

    // Apply selected filter
    games = applySelectedFilter(to: games)

    return games
  }

  private var groupedGames: [GroupedGames] {
    let games = filteredGames

    switch selectedGrouping {
    case .none:
      return []
    case .gameType:
      return groupGamesByType(games)
    case .date:
      return groupGamesByDate(games)
    case .winnerLose:
      return groupGamesByResult(games)
    }
  }

  // MARK: - Body

  var body: some View {
    NavigationStack(path: $path) {
      // Navigation to Completed Game detail
      ScrollView {
        VStack(spacing: DesignSystem.Spacing.md) {
          if completedGames.isEmpty {
            VStack {
              CustomContentUnavailableView(
                icon: "clock.badge.questionmark",
                title: "No Game History",
                description: "Start playing games to see your history here"
              )
            }
            .padding(.top, 30)
          } else if filteredGames.isEmpty && selectedFilter != .all {
            VStack {
              CustomContentUnavailableView(
                icon: "line.3.horizontal.decrease.circle",
                title: "No Games Found",
                description: "Try adjusting your filter to see more games"
              )
            }
            .padding(.top, 30)
          } else {
            GameHistoryContent(
              completedGames: completedGames,
              filteredGames: filteredGames,
              groupedGames: groupedGames,
              selectedGrouping: selectedGrouping,
              onGameTapped: { game in
                Log.event(
                  .actionTapped, level: .info, message: "history → completed",
                  context: .current(gameId: game.id))
                path.append(GameHistoryDestination.gameDetail(game))
              }
            )
          }
        }
        .scrollClipDisabled()
        .padding(.horizontal, DesignSystem.Spacing.md)
      }
      .navigationTitle("History")
      .containerBackground(DesignSystem.Colors.navigationBrandGradient, for: .navigation)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          HStack(spacing: DesignSystem.Spacing.sm) {
            HistoryFilterMenu(selectedFilter: $selectedFilter)
            HistoryGroupingMenu(selectedGrouping: $selectedGrouping)
            NavigationLink(value: GameHistoryDestination.archiveList) {
              Label("View Archive", systemImage: "archivebox")
            }
            .accessibilityIdentifier("NavLink.History.archiveList")
          }
        }
      }
    }
    .navigationDestination(for: GameHistoryDestination.self) { destination in
      switch destination {
      case .gameDetail(let game):
        CompletedGameDetailView(game: game)
      case .archiveList:
        ArchivedGamesView()
      }
    }
  }

  // MARK: - View Components

  // Filter/grouping menus extracted to components

  // MARK: - Helper Methods

  /// Applies the selected filter to the list of games
  private func applySelectedFilter(to games: [Game]) -> [Game] {
    switch selectedFilter {
    case .all:
      return games
    case .gameType(let type):
      return games.filter { $0.gameType == type }
    case .wins:
      return games.filter { game in
        guard let winner = game.winner else { return false }
        return winner == game.effectivePlayerLabel1
      }
    case .losses:
      return games.filter { game in
        guard let winner = game.winner else { return false }
        return winner == game.effectivePlayerLabel2
      }
    }
  }

  /// Groups games by their type
  private func groupGamesByType(_ games: [Game]) -> [GroupedGames] {
    let grouped = Dictionary(grouping: games) { $0.gameType.displayName }
    return createSortedGroups(from: grouped) { $0.title < $1.title }
  }

  /// Groups games by the date they were played
  private func groupGamesByDate(_ games: [Game]) -> [GroupedGames] {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    let grouped = Dictionary(grouping: games) { formatter.string(from: $0.lastModified) }
    return createSortedGroups(from: grouped) { $0.title > $1.title }
  }

  /// Groups games by win/loss result
  private func groupGamesByResult(_ games: [Game]) -> [GroupedGames] {
    let grouped = Dictionary(grouping: games) { game in
      guard let winner = game.winner else { return "Ties" }
      return winner == game.effectivePlayerLabel1 ? "Wins" : "Losses"
    }
    return createSortedGroups(from: grouped) { $0.title < $1.title }
  }

  /// Creates sorted groups from a dictionary of grouped games
  private func createSortedGroups(
    from grouped: [String: [Game]],
    sortedBy sortPredicate: (GroupedGames, GroupedGames) -> Bool
  ) -> [GroupedGames] {
    return grouped.compactMap { key, value in
      let sortedGames = value.sorted { $0.lastModified > $1.lastModified }
      return GroupedGames(title: key, games: sortedGames)
    }.sorted(by: sortPredicate)
  }
}

// MARK: - Preview Support

extension GameHistoryView {
  /// Creates a sample game for preview purposes
  fileprivate static func createSampleGame(
    gameType: GameType,
    score1: Int,
    score2: Int,
    isCompleted: Bool = true
  ) -> Game {
    let game = Game(gameType: gameType)
    game.score1 = score1
    game.score2 = score2
    game.isCompleted = isCompleted
    if isCompleted {
      game.completedDate = Date()
    }
    return game
  }

  /// Creates a sample container with test data using in-memory storage for previews
  static func createPreviewContainer(withGames: Bool = true) -> some View {
    let container = SwiftDataContainer.createPreviewContainer()
    let context = container.mainContext

    if withGames {
      let sampleGames = [
        createSampleGame(gameType: .training, score1: 11, score2: 7),
        createSampleGame(gameType: .recreational, score1: 11, score2: 9),
        createSampleGame(gameType: .tournament, score1: 15, score2: 13),
      ]

      sampleGames.forEach { context.insert($0) }

      // Save the sample data to the in-memory container
      do {
        try context.save()
      } catch {
        Log.error(error, event: .saveFailed, metadata: ["phase": "previewSave"])
      }
    }

    return GameHistoryView()
      .modelContainer(container)
  }
}

// MARK: - Previews

#Preview("With Games") {
  GameHistoryView()
    .modelContainer(try! PreviewGameData.createFullPreviewContainer())
}

#Preview("Empty State") {
  GameHistoryView()
    .modelContainer(try! PreviewGameData.createPreviewContainer(with: []))
}
