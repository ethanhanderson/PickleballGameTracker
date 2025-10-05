import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct CatalogView: View {
    @Namespace var animation
    @Environment(\.modelContext) private var modelContext
    @State private var navigationState = AppNavigationState()
    @State private var showSettingsSheet = false

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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettingsSheet = true
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                    .accessibilityIdentifier("catalog.settings")
                }
                .matchedTransitionSource(id: "settings", in: animation)
            }
            .navigationDestination(for: GameSectionDestination.self) {
                destination in
                NavigationDestinationFactory.createDestination(
                    for: destination,
                    navigationState: navigationState
                )
            }
        }
        .tint(.accentColor)
        .sheet(isPresented: $showSettingsSheet) {
            NavigationStack { MaintenanceView() }
                .navigationTransition(
                    .zoom(sourceID: "settings", in: animation)
                )
                .tint(.accentColor)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    CatalogView()
        .modelContainer(PreviewContainers.standard())
}
