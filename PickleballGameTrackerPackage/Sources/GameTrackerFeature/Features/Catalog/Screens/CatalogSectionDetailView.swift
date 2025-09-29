import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct CatalogSectionDetailView: View {
  @Bindable var navigationState: AppNavigationState

  private let destination: GameSectionDestination

  init(destination: GameSectionDestination, navigationState: AppNavigationState) {
    self.destination = destination
    self.navigationState = navigationState
  }

  var body: some View {
    ScrollView {
      LazyVStack(spacing: DesignSystem.Spacing.md) {
        ForEach(gameTypesForSection, id: \.self) { gameType in
          NavigationLink(value: GameSectionDestination.gameDetail(gameType)) {
            GameTypeCard(
              gameType: gameType,
              fillsWidth: true
            )
          }
          .accessibilityIdentifier("catalogSection.gameOption.\(gameType.rawValue)")
          .simultaneousGesture(
            TapGesture().onEnded {
              navigationState.trackGameDetailNavigation(gameType)
            }
          )
        }
      }
      .padding(.horizontal, DesignSystem.Spacing.md)
      .padding(.top, DesignSystem.Spacing.md)
    }
    .accessibilityIdentifier("catalogSectionDetail.scroll")
    .navigationTitle(sectionTitle)
    .viewContainerBackground()
  }

  private var sectionTitle: String {
    destination.title
  }

  private var gameTypesForSection: [GameType] {
    destination.gameTypes
  }

}

#Preview("All Game Types") {
  NavigationStack {
    CatalogSectionDetailView(
      destination: .allGames,
      navigationState: AppNavigationState()
    )
  }
  .minimalPreview(environment: PreviewEnvironment.catalog())
}
