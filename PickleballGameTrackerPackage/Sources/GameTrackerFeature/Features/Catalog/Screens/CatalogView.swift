import GameTrackerCore
import SwiftUI
import SwiftData

@MainActor
struct CatalogView: View {
    @State private var navigationState = AppNavigationState()
    @Environment(PersonalizationEngine.self) private var personalizationEngine
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var sections: [CatalogSectionDescriptor] = []

    var body: some View {
        NavigationStack(path: $navigationState.navigationPath) {
            ScrollView {
                LazyVStack(spacing: DesignSystem.Spacing.xl) {
                    ForEach(sections, id: \.id) { section in
                        CatalogSection(
                            title: section.title,
                            destination: .sectionDetail(section.title, section.gameTypes)
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
            .task {
                // Build dynamic sections on appear
                personalizationEngine.recalculate(context: modelContext)
                sections = personalizationEngine.buildSections(context: modelContext)
            }
            .onChange(of: scenePhase) { _, newValue in
                if newValue == .active {
                    personalizationEngine.recalculate(context: modelContext)
                    sections = personalizationEngine.buildSections(context: modelContext)
                }
            }
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

#Preview("Catalog • Cold Start") {
    let p = PersonalizationPreviewFactory.build(profile: .coldStart)
    CatalogView()
        .tint(.green)
        .modelContainer(p.container)
        .environment(p.engine)
}

#Preview("Catalog • Singles Heavy") {
    let p = PersonalizationPreviewFactory.build(profile: .singlesHeavy)
    CatalogView()
        .tint(.green)
        .modelContainer(p.container)
        .environment(p.engine)
}

#Preview("Catalog • Doubles Heavy") {
    let p = PersonalizationPreviewFactory.build(profile: .doublesHeavy)
    CatalogView()
        .tint(.green)
        .modelContainer(p.container)
        .environment(p.engine)
}

#Preview("Catalog • Beginner Friendly") {
    let p = PersonalizationPreviewFactory.build(profile: .beginnerFriendly)
    CatalogView()
        .tint(.green)
        .modelContainer(p.container)
        .environment(p.engine)
}

#Preview("Catalog • Competitive") {
    let p = PersonalizationPreviewFactory.build(profile: .competitive)
    CatalogView()
        .tint(.green)
        .modelContainer(p.container)
        .environment(p.engine)
}

#Preview("Catalog • Mixed Recent") {
    let p = PersonalizationPreviewFactory.build(profile: .mixedRecent)
    CatalogView()
        .tint(.green)
        .modelContainer(p.container)
        .environment(p.engine)
}
