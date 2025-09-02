import CorePackage
import SwiftData
import SwiftUI

// MARK: - Game Search View

@MainActor
struct GameSearchView: View {
  let modelContext: ModelContext
  @Bindable var navigationState: AppNavigationState

  @State private var searchText = ""
  @State private var searchHistory: [GameType] = []
  private let shouldLoadHistoryOnAppear: Bool

  private let searchHistoryKey = "GameSearchHistory"

  private var recentSearches: [GameType] {
    Array(searchHistory.prefix(5))  // Show last 5 searches
  }

  private var filteredGameTypes: [GameType] {
    FuzzySearchUtility.filterGameTypes(searchText: searchText)
  }

  init(
    modelContext: ModelContext,
    navigationState: AppNavigationState,
    initialSearchText: String = "",
    initialSearchHistory: [GameType] = [],
    loadHistoryOnAppear: Bool = true
  ) {
    self.modelContext = modelContext
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
            // Empty state when no search
            VStack(spacing: DesignSystem.Spacing.lg) {
              CustomContentUnavailableView(
                icon: "plus.magnifyingglass",
                title: "Discover New Games",
                description: "Search for game types to start playing"
              )

              // Recent searches section
              if !recentSearches.isEmpty {
                RecentSearchesSection(
                  recentSearches: recentSearches,
                  onGameTypeTapped: { gameType in
                    navigationState.navigateToGameDetail(gameType)
                  },
                  onDeleteFromHistory: deleteFromSearchHistory
                )
              }
            }
          } else if !filteredGameTypes.isEmpty {
            SearchResultsList(
              filteredGameTypes: filteredGameTypes,
              onGameTypeTapped: { gameType in
                // Handle game type tap if needed
              },
              onAddToHistory: addToSearchHistory,
              navigationState: navigationState
            )
            .accessibilityIdentifier("Search.resultsList")
          } else {
            // No results state
            CustomContentUnavailableView(
              icon: "minus.magnifyingglass",
              title: "No Games Found",
              description: "Try a different search query"
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityIdentifier("Search.noResults")
          }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.top, DesignSystem.Spacing.sm)
      }
      .containerBackground(DesignSystem.Colors.navigationBrandGradient, for: .navigation)
      .onAppear {
        if shouldLoadHistoryOnAppear {
          loadSearchHistory()
        }
      }
      .navigationTitle("Search")
      .navigationBarTitleDisplayMode(.large)
      .searchable(text: $searchText, prompt: "Search game types...")
      .accessibilityIdentifier("Search.searchField")
      .navigationDestination(for: GameSectionDestination.self) { destination in
        NavigationDestinationFactory.createDestination(
          for: destination,
          modelContext: modelContext,
          navigationState: navigationState
        )
      }
    }
    .navigationTint()
  }

  // MARK: - Search History Management

  private func loadSearchHistory() {
    let rawValues = UserDefaults.standard.stringArray(forKey: searchHistoryKey) ?? []
    searchHistory = rawValues.compactMap { GameType(rawValue: $0) }
  }

  private func saveSearchHistory() {
    let rawValues = searchHistory.map { $0.rawValue }
    UserDefaults.standard.set(rawValues, forKey: searchHistoryKey)
  }

  private func addToSearchHistory(_ gameType: GameType) {
    // Remove if already exists and add to front
    searchHistory.removeAll { $0 == gameType }
    searchHistory.insert(gameType, at: 0)

    // Keep only last 10 searches
    if searchHistory.count > 10 {
      searchHistory = Array(searchHistory.prefix(10))
    }

    saveSearchHistory()
  }

  private func deleteFromSearchHistory(_ gameType: GameType) {
    searchHistory.removeAll { $0 == gameType }
    saveSearchHistory()
  }
}

// MARK: - Preview

#Preview("Search - Empty State") {
  let container = try! PreviewGameData.createPreviewContainer(with: [])
  return GameSearchView(
    modelContext: container.mainContext,
    navigationState: AppNavigationState(),
    initialSearchText: "",
    initialSearchHistory: [],
    loadHistoryOnAppear: false
  )
  .modelContainer(container)
}

#Preview("Search - With Recent Searches") {
  let container = try! PreviewGameData.createPreviewContainer(with: [])
  return GameSearchView(
    modelContext: container.mainContext,
    navigationState: AppNavigationState(),
    initialSearchText: "",
    initialSearchHistory: [.training, .recreational, .tournament],
    loadHistoryOnAppear: false
  )
  .modelContainer(container)
  .ignoresSafeArea(.keyboard, edges: .bottom)
}

#Preview("Search - With Results") {
  let container = try! PreviewGameData.createPreviewContainer(with: [])
  return GameSearchView(
    modelContext: container.mainContext,
    navigationState: AppNavigationState(),
    initialSearchText: "quick",
    loadHistoryOnAppear: false
  )
  .modelContainer(container)
}

#Preview("Search - No Results") {
  let container = try! PreviewGameData.createPreviewContainer(with: [])
  return GameSearchView(
    modelContext: container.mainContext,
    navigationState: AppNavigationState(),
    initialSearchText: "xyzzz",
    loadHistoryOnAppear: false
  )
  .modelContainer(container)
}

// MARK: - Preview Helper Views

// Removed wrapper previews; previews now pass initial state directly into GameSearchView
