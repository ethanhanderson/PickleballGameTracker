import SharedGameCore
import SwiftUI

struct SearchResultsList: View {
  let filteredGameTypes: [GameType]
  let onGameTypeTapped: (GameType) -> Void
  let onAddToHistory: (GameType) -> Void
  @Bindable var navigationState: AppNavigationState

  var body: some View {
    ForEach(filteredGameTypes, id: \.self) { gameType in
      NavigationLink(value: GameSectionDestination.gameDetail(gameType)) {
        GameOptionCard(
          gameType: gameType,
          isEnabled: true,
          fillsWidth: true
        )
      }
      .simultaneousGesture(
        TapGesture().onEnded {
          onAddToHistory(gameType)
          navigationState.trackGameDetailNavigation(gameType)
        }
      )
    }
  }
}

#Preview("Search Results List") {
  SearchResultsList(
    filteredGameTypes: [.training, .recreational, .tournament],
    onGameTypeTapped: { _ in },
    onAddToHistory: { _ in },
    navigationState: AppNavigationState()
  )
  .padding()
}
