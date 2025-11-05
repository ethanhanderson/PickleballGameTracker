import GameTrackerCore
import SwiftUI

@MainActor
struct CatalogView: View {
    @State private var navigationState = AppNavigationState()

    var body: some View {
        NavigationStack(path: $navigationState.navigationPath) {
            ScrollView {
                LazyVStack(spacing: DesignSystem.Spacing.xl) {
                    ForEach(GameCatalog.sections, id: \.title) { section in
                        CatalogSection(
                            title: section.title,
                            destination: section.destination
                        ) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: DesignSystem.Spacing.md) {
                                    ForEach(section.gameTypes, id: \.self) {
                                        gameType in
                                        NavigationLink(
                                            value:
                                                GameSectionDestination
                                                .gameDetail(gameType)
                                        ) {
                                            GameTypeCard(
                                                gameType: gameType
                                            )
                                        }
                                        .accessibilityIdentifier(
                                            "NavLink.Games.gameType.\(gameType.rawValue)"
                                        )
                                        .simultaneousGesture(
                                            TapGesture().onEnded {
                                                navigationState
                                                    .trackGameDetailNavigation(
                                                        gameType
                                                    )
                                            }
                                        )
                                    }
                                }
                                .scrollTargetLayout()
                            }
                            .contentMargins(.horizontal, DesignSystem.Spacing.md, for: .scrollContent)
                            .scrollTargetBehavior(.viewAligned)
                            .scrollClipDisabled()
                        }
                    }
                }
            }
            .contentMargins(.top, DesignSystem.Spacing.md, for: .scrollContent)
            .scrollClipDisabled()
            .navigationTitle("Games")
            .toolbarTitleDisplayMode(.inlineLarge)
            .viewContainerBackground()
            .navigationDestination(for: GameSectionDestination.self) {
                destination in
                NavigationDestinationFactory.createDestination(
                    for: destination,
                    navigationState: navigationState
                )
            }
        }
    }
}

#Preview {
    CatalogView()
        .tint(.green)
        .modelContainer(PreviewContainers.standard())
}
