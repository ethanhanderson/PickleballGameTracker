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
    @Namespace var animation
    @Environment(\.modelContext) private var modelContext
    @Environment(SwiftDataGameManager.self) private var gameManager
    private static let completedSort: [SortDescriptor<GameSummary>] = [
        SortDescriptor(\.completedDate, order: .reverse)
    ]
    @Query(
        sort: Self.completedSort
    ) private var completedSummaries: [GameSummary]

    @State private var navigationState = AppNavigationState()
    @State private var selectedFilter: GameFilter = .all  // Logical default: show all games
    @State private var selectedGrouping: GroupingOption = .none  // Logical default: chronological order
    @State private var showArchiveSheet = false
    @State private var hiddenGameIds: Set<UUID> = []
    @State private var deletionObserver: (any NSObjectProtocol)? = nil

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

        // Hide games pending deletion
        games.removeAll { hiddenGameIds.contains($0.id) }

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
                                ForEach(filteredGames, id: \.id) { game in
                                    NavigationLink(
                                        value:
                                            GameHistoryDestination.gameDetail(
                                                game.id
                                            )
                                    ) {
                                        CompletedGameCard(game: game)
                                    }
                                    .buttonStyle(.plain)
                                    .simultaneousGesture(
                                        TapGesture().onEnded {
                                            navigationState
                                                .trackHistoryNavigation(game.id)
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
            .contentMargins(
                .horizontal,
                DesignSystem.Spacing.md,
                for: .scrollContent
            )
            .contentMargins(.top, DesignSystem.Spacing.sm, for: .scrollContent)
            .navigationTitle("History")
            .viewContainerBackground()
            .toolbar {
                ToolbarItem {
                    MenuPicker(
                        selection: $selectedFilter,
                        options: GameFilter.allFilters,
                        menuTitle: "Filter",
                        menuIcon: "line.3.horizontal.decrease"
                    )
                }

                ToolbarItem {
                    MenuPicker(
                        selection: $selectedGrouping,
                        options: Array(GroupingOption.allCases),
                        menuTitle: "Grouping",
                        menuIcon: "square.grid.2x2"
                    )
                }

                ToolbarSpacer()

                ToolbarItem {
                    Button {
                        showArchiveSheet = true
                    } label: {
                        Label("View Archive", systemImage: "archivebox")
                    }
                    .accessibilityIdentifier("NavLink.History.archiveList")
                    .matchedTransitionSource(id: "archive", in: animation)
                }
            }
            .navigationDestination(for: GameHistoryDestination.self) {
                destination in
                switch destination {
                case .gameDetail(let gameId):
                    if hiddenGameIds.contains(gameId) {
                        EmptyView()
                    } else if let game = try? modelContext.fetch(
                        FetchDescriptor<Game>(
                            predicate: #Predicate { $0.id == gameId }
                        )
                    ).first {
                        CompletedGameDetailView(game: game)
                    } else {
                        // Guard against navigating to missing games without showing fallback
                        EmptyView()
                    }
                case .archiveList:
                    EmptyView()
                }
            }
        }
        .task {
            // Observe delete requests and process them after navigation back
            deletionObserver = HistoryDeletionRequestBus.observeDeleteRequests { id in
                Task { @MainActor in
                    hiddenGameIds.insert(id)
                    await handleDeletion(id)
                }
            }
        }
        .onDisappear {
            if let token = deletionObserver {
                NotificationCenter.default.removeObserver(token)
                deletionObserver = nil
            }
        }
        .sheet(isPresented: $showArchiveSheet) {
            NavigationStack {
                ArchivedGamesView()
                    .navigationDestination(for: GameHistoryDestination.self) {
                        destination in
                        switch destination {
                        case .gameDetail(let gameId):
                            if hiddenGameIds.contains(gameId) {
                                EmptyView()
                            } else if let game = try? modelContext.fetch(
                                FetchDescriptor<Game>(
                                    predicate: #Predicate { $0.id == gameId }
                                )
                            ).first {
                                CompletedGameDetailView(game: game)
                            } else {
                                EmptyView()
                            }
                        case .archiveList:
                            EmptyView()
                        }
                    }
            }
            .navigationTransition(.zoom(sourceID: "archive", in: animation))
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

// MARK: - Deletion Handling

extension HistoryView {
    private func handleDeletion(_ id: UUID) async {
        do {
            if let game = try? modelContext.fetch(
                FetchDescriptor<Game>(
                    predicate: #Predicate { $0.id == id }
                )
            ).first {
                try await gameManager.deleteGame(game)
            }
        } catch {
            // If deletion fails, unhide so user can try again
            hiddenGameIds.remove(id)
            Log.error(error, event: .saveFailed, context: .current(gameId: id), metadata: ["phase": "history.delete"])        
        }
    }
}

// MARK: - Components

private protocol PickerOption: Identifiable, Hashable {
    var displayName: String { get }
    var systemImage: String { get }
}

extension GameFilter: PickerOption {}
extension GroupingOption: PickerOption {}

@MainActor
private struct MenuPicker<Selection: PickerOption>: View {
    @Binding var selection: Selection
    let options: [Selection]
    let menuTitle: String
    let menuIcon: String

    init(
        selection: Binding<Selection>,
        options: [Selection],
        menuTitle: String,
        menuIcon: String,
    ) {
        self._selection = selection
        self.options = options
        self.menuTitle = menuTitle
        self.menuIcon = menuIcon
    }

    var body: some View {
        Menu {
            Picker(selection: $selection, label: EmptyView()) {
                ForEach(options) { option in
                    Label(
                        option.displayName,
                        systemImage: option.systemImage
                    )
                    .labelReservedIconWidth(46)
                    .tag(option)
                }
            }
            .tint(.primary)
        } label: {
            Label(menuTitle, systemImage: menuIcon)
                .labelStyle(.iconOnly)
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
                    ForEach(group.games, id: \.id) { game in
                        NavigationLink(
                            value: GameHistoryDestination.gameDetail(game.id)
                        ) {
                            CompletedGameCard(game: game)
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(
                            TapGesture().onEnded {
                                navigationState.trackHistoryNavigation(game.id)
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
