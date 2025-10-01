import GameTrackerCore
import SwiftUI

struct GameTypeResultsList: View {
  let filteredGameTypes: [GameType]
  let onGameTypeTapped: (GameType) -> Void
  let onAddToHistory: (GameType) -> Void
  @Bindable var navigationState: AppNavigationState

  var body: some View {
    ForEach(filteredGameTypes, id: \.self) { gameType in
      NavigationLink(value: GameSectionDestination.gameDetail(gameType)) {
        GameTypeCard(
          gameType: gameType,
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
  return GameTypeResultsList(
    filteredGameTypes: PreviewGameData.sampleGameTypes,
    onGameTypeTapped: { _ in },
    onAddToHistory: { _ in },
    navigationState: AppNavigationState()
  )
  .padding()
}
