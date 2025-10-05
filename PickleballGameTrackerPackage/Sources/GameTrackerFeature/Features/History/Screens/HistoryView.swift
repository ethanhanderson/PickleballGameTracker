//
//  GameHistoryView.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 7/9/25.
//

import Foundation
import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    private static let completedSort: [SortDescriptor<GameSummary>] = [
        SortDescriptor(\.completedDate, order: .reverse)
    ]
    @Query(
        sort: Self.completedSort
    ) private var completedSummaries: [GameSummary]

    @State private var navigationState = AppNavigationState()
    @State private var selectedFilter: GameFilter = .all  // Logical default: show all games
    @State private var selectedGrouping: GroupingOption = .none  // Logical default: chronological order

    // MARK: - Computed Properties

    private var completedGames: [Game] {
        let ids: [UUID] = completedSummaries.map { $0.gameId }
        guard ids.isEmpty == false else { return [] }

        let idSet = Set(ids)
        let predicate: Predicate<Game> = #Predicate { game in
            idSet.contains(game.id) && game.isArchived == false
        }

        var descriptor = FetchDescriptor<Game>(predicate: predicate)
        descriptor.fetchLimit = 200

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
        NavigationStack(path: $navigationState.navigationPath) {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.md) {
                    if completedGames.isEmpty {
                        EmptyStateView(
                            icon: "clock.badge.questionmark",
                            title: "No Game History",
                            description:
                                "Start playing games to see your history here"
                        )
                    } else if filteredGames.isEmpty && selectedFilter != .all {
                        EmptyStateView(
                            icon: "line.3.horizontal.decrease.circle",
                            title: "No Games Found",
                            description:
                                "Try adjusting your filter to see more games"
                        )
                    } else {
                        if selectedGrouping == .none {
                            VStack(spacing: DesignSystem.Spacing.md) {
                                ForEach(filteredGames.indices, id: \.self) { index in
                                        NavigationLink(
                                            value: GameHistoryDestination.gameDetail(filteredGames[index].id)
                                        ) {
                                            CompletedGameCard(game: filteredGames[index])
                                        }
                                    .buttonStyle(.plain)
                                    .simultaneousGesture(
                                        TapGesture().onEnded {
                                            navigationState.trackHistoryNavigation(filteredGames[index].id)
                                        }
                                    )
                                }
                            }
                        } else {
                            GameHistoryGroupedList(
                                groupedGames: groupedGames,
                                selectedGrouping: selectedGrouping,
                                navigationState: navigationState
                            )
                        }
                    }
                }
                .scrollClipDisabled()
            }
            .contentMargins(.horizontal, DesignSystem.Spacing.md, for: .scrollContent)
            .contentMargins(.top, DesignSystem.Spacing.sm, for: .scrollContent)
            .navigationTitle("History")
            .viewContainerBackground()
            .toolbar {
                ToolbarItem {
                    HistoryFilterMenu(selectedFilter: $selectedFilter)
                }

                ToolbarItem {
                    HistoryGroupingMenu(selectedGrouping: $selectedGrouping)
                }

                ToolbarSpacer()

                ToolbarItem {
                    NavigationLink(value: GameHistoryDestination.archiveList) {
                        Label("View Archive", systemImage: "archivebox")
                    }
                    .accessibilityIdentifier("NavLink.History.archiveList")
                }
            }
            .navigationDestination(for: GameHistoryDestination.self) {
                destination in
                switch destination {
                case .gameDetail(let gameId):
                    if let game = try? modelContext.fetch(
                        FetchDescriptor<Game>(
                            predicate: #Predicate { $0.id == gameId }
                        )
                    ).first {
                        CompletedGameDetailView(game: game)
                    } else {
                        EmptyStateView(
                            icon: "exclamationmark.triangle.fill",
                            title: "Game Not Found",
                            description: "This game could not be loaded."
                        )
                    }
                case .archiveList:
                    ArchivedGamesView()
                }
            }
        }
    }

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
        let grouped = Dictionary(grouping: games) {
            formatter.string(from: $0.lastModified)
        }
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

// MARK: - Local Components (History)

@MainActor
private struct HistoryFilterMenu: View {
    @Binding var selectedFilter: GameFilter

    var body: some View {
        Menu {
            Section("General") {
                filterButton(for: .all)
            }

            Section("Game Types") {
                ForEach(GameCatalog.allGameTypes, id: \.self) { gameType in
                    filterButton(for: .gameType(gameType))
                }
            }

            Section("Results") {
                filterButton(for: .wins)
                filterButton(for: .losses)
            }
        } label: {
            Image(
                systemName: selectedFilter == .all
                    ? "line.3.horizontal.decrease" : "line.3.horizontal.decrease.circle.fill"
            )
        }
    }

    private func filterButton(for filter: GameFilter) -> some View {
        Button {
            selectedFilter = filter
        } label: {
            HStack {
                if selectedFilter == filter {
                    Image(systemName: "checkmark")
                }
                Text(filter.displayName)
            }
        }
    }
}

@MainActor
private struct HistoryGroupingMenu: View {
    @Binding var selectedGrouping: GroupingOption

    var body: some View {
        Menu {
            ForEach(GroupingOption.allCases) { option in
                groupingButton(for: option)
            }
        } label: {
            Image(
                systemName: selectedGrouping == .none ? "square.grid.2x2" : "square.grid.2x2.fill"
            )
        }
    }

    private func groupingButton(for option: GroupingOption) -> some View {
        Button {
            selectedGrouping = option
        } label: {
            Label(
                option.displayName,
                systemImage: selectedGrouping == option ? "checkmark.circle.fill" : option.systemImage
            )
        }
    }
}

@MainActor
private struct GameHistoryGroupedList: View {
    let groupedGames: [GroupedGames]
    let selectedGrouping: GroupingOption
    let navigationState: AppNavigationState

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ForEach(groupedGames.indices, id: \.self) { groupIndex in
                let group = groupedGames[groupIndex]

                Section {
                    ForEach(group.games.indices, id: \.self) { gameIndex in
                        NavigationLink(
                            value: GameHistoryDestination.gameDetail(group.games[gameIndex].id)
                        ) {
                            CompletedGameCard(game: group.games[gameIndex])
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(
                            TapGesture().onEnded {
                                navigationState.trackHistoryNavigation(group.games[gameIndex].id)
                            }
                        )
                    }
                } header: {
                    if shouldShowHeader(for: group) {
                        HStack {
                            Text(group.title)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(.top, DesignSystem.Spacing.lg)
    }

    private func shouldShowHeader(for group: GroupedGames) -> Bool {
        selectedGrouping != .none && !group.title.isEmpty
    }
}


// MARK: - Previews

#Preview("Main") {
    HistoryView()
        .tint(.green)
        .modelContainer(PreviewContainers.history())
}

#Preview("Empty") {
    HistoryView()
        .tint(.green)
        .modelContainer(PreviewContainers.empty())
}
