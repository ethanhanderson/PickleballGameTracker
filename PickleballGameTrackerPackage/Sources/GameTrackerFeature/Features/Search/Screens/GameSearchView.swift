import GameTrackerCore
import SwiftData
import SwiftUI

// MARK: - Game Search View

@MainActor
struct GameSearchView: View {
  @Environment(\.modelContext) private var modelContext
  @Bindable var navigationState: AppNavigationState

  @State private var searchText = ""
  @State private var searchHistory: [GameType] = []
  private let shouldLoadHistoryOnAppear: Bool

  private let historyStore = GameSearchHistoryStore()

  private var recentSearches: [GameType] {
    Array(searchHistory.prefix(5))  // Show last 5 searches
  }

  private var filteredGameTypes: [GameType] {
    GameTypeSearch.filterGameTypes(searchText: searchText)
  }

  init(
    navigationState: AppNavigationState,
    initialSearchText: String = "",
    initialSearchHistory: [GameType] = [],
    loadHistoryOnAppear: Bool = true
  ) {
    self.navigationState = navigationState
    self._searchText = State(initialValue: initialSearchText)
    self._searchHistory = State(initialValue: initialSearchHistory)
    self.shouldLoadHistoryOnAppear = loadHistoryOnAppear
  }

  var body: some View {
    NavigationStack(path: $navigationState.navigationPath) {
      ScrollView {
        LazyVStack(spacing: DesignSystem.Spacing.md) {
          if searchText.isEmpty {
            VStack(spacing: DesignSystem.Spacing.lg) {
              EmptyStateView(
                icon: "plus.magnifyingglass",
                title: "Discover New Games",
                description: "Search for game types to start playing"
              )

              if !recentSearches.isEmpty {
                RecentlyViewedGameTypesSection(
                  recentSearches: recentSearches,
                  onGameTypeTapped: { gameType in
                    navigationState.navigateToGameDetail(gameType)
                  },
                  onDeleteFromHistory: deleteFromSearchHistory
                )
              }
            }
          } else if !filteredGameTypes.isEmpty {
            GameTypeResultsList(
              filteredGameTypes: filteredGameTypes,
              onGameTypeTapped: { gameType in
              },
              onAddToHistory: addToSearchHistory,
              navigationState: navigationState
            )
            .accessibilityIdentifier("Search.resultsList")
          } else {
            EmptyStateView(
              icon: "minus.magnifyingglass",
              title: "No Games Found",
              description: "Try a different search query"
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityIdentifier("Search.noResults")
          }
        }
      }
      .contentMargins(.horizontal, DesignSystem.Spacing.md, for: .scrollContent)
      .contentMargins(.top, DesignSystem.Spacing.sm, for: .scrollContent)
      .viewContainerBackground()
      .task {
        if shouldLoadHistoryOnAppear {
          searchHistory = await historyStore.load()
        }
      }
      .task(id: searchHistory) {
        await historyStore.save(searchHistory)
      }
      .navigationTitle("Search")
      .navigationBarTitleDisplayMode(.large)
      .searchable(text: $searchText, prompt: "Search game types...")
      .accessibilityIdentifier("Search.searchField")
      .navigationDestination(for: GameSectionDestination.self) { destination in
        NavigationDestinationFactory.createDestination(
          for: destination,
          navigationState: navigationState
        )
      }
    }
    .navigationBarTitleDisplayMode(.inline)
  }

  private func addToSearchHistory(_ gameType: GameType) {
    searchHistory = GameSearchHistoryStore.updatedHistory(afterAdding: gameType, to: searchHistory)
  }

  private func deleteFromSearchHistory(_ gameType: GameType) {
    searchHistory = GameSearchHistoryStore.updatedHistory(
      afterDeleting: gameType, from: searchHistory)
  }
}

// MARK: - Preview

#Preview("Search - Empty State") {
  GameSearchView(
    navigationState: AppNavigationState(),
    initialSearchText: "",
    initialSearchHistory: [],
    loadHistoryOnAppear: false
  )
  .modelContainer(PreviewContainers.empty())
}

#Preview("Search - With Recent Searches") {
  GameSearchView(
    navigationState: AppNavigationState(),
    initialSearchText: "",
    initialSearchHistory: [.training, .recreational, .tournament],
    loadHistoryOnAppear: false
  )
  .modelContainer(PreviewContainers.empty())
  .ignoresSafeArea(.keyboard, edges: .bottom)
}

#Preview("Search - With Roster Data") {
  GameSearchView(
    navigationState: AppNavigationState(),
    initialSearchText: "quick",
    loadHistoryOnAppear: false
  )
  .modelContainer(PreviewContainers.roster())
}

#Preview("Search - With Results") {
  GameSearchView(
    navigationState: AppNavigationState(),
    initialSearchText: "quick",
    loadHistoryOnAppear: false
  )
  .modelContainer(PreviewContainers.standard())
}

#Preview("Search - No Results") {
  GameSearchView(
    navigationState: AppNavigationState(),
    initialSearchText: "xyzzz",
    loadHistoryOnAppear: false
  )
  .modelContainer(PreviewContainers.empty())
}

#Preview("Search - Rich Data") {
  GameSearchView(
    navigationState: AppNavigationState(),
    initialSearchText: "",
    loadHistoryOnAppear: false
  )
  .modelContainer(PreviewContainers.standard())
}
