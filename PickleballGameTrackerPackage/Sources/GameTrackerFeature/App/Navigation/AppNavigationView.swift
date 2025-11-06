import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
private struct LiveGameBottomAccessory: View {
    let hasLiveGame: Bool
    let onTap: () -> Void
    
    var body: some View {
        if hasLiveGame {
            LiveGameMiniPreview(onTap: onTap)
        }
    }
}

@MainActor
private struct CustomLiveGameView: View {
    let hasLiveGame: Bool
    let onTap: () -> Void
    
    var body: some View {
        if hasLiveGame {
            InlineMiniPreview(onTap: onTap)
        }
    }
}

@MainActor
public struct AppNavigationView: View {
    @Environment(LiveGameStateManager.self) private var activeGameStateManager
    
    @State private var selectedTab: AppTab = .games

    public init() {}
    
    // Minimal view: setup, deep links, and sheets are coordinated by AppRootView

    public var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                Tab(
                    "Games",
                    systemImage: "rectangle.grid.2x2.fill",
                    value: AppTab.games
                ) {
                    CatalogView()
                        .accessibilityIdentifier("Tab.Games")
                }

                Tab("History", systemImage: "clock", value: AppTab.history) {
                    HistoryView()
                        .accessibilityIdentifier("Tab.History")
                }

                Tab(
                    "Roster",
                    systemImage: "person.2",
                    value: AppTab.roster
                ) {
                    RosterView()
                        .accessibilityIdentifier("Tab.Roster")
                }

                Tab(
                    "Statistics",
                    systemImage: "chart.bar",
                    value: AppTab.statistics
                ) {
                    StatisticsHomeView(
                        gameId: nil,
                        gameTypeId: nil
                    )
                    .accessibilityIdentifier("Tab.Statistics")
                }

                Tab(
                    "Search",
                    systemImage: "magnifyingglass",
                    value: AppTab.search,
                    role: .search
                ) {
                    GameSearchView(
                        navigationState: AppNavigationState()
                    )
                    .accessibilityIdentifier("Tab.Search")
                }
            }
            .applyLiveGameBottomAccessory(
                hasLiveGame: activeGameStateManager.hasLiveGame,
                onTap: {
                    NotificationCenter.default.post(
                        name: Notification.Name("OpenLiveGameRequested"),
                        object: nil
                    )
                }
            )
            .tabBarMinimizeBehavior(.onScrollDown)
        }
    }

}

// MARK: - View Extensions

// withNavigationLifecycle removed to keep AppNavigationView minimal

private extension View {
    func applyLiveGameBottomAccessory(
        hasLiveGame: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        if #available(iOS 26.1, *) {
            return AnyView(
                self.tabViewBottomAccessory(isEnabled: hasLiveGame) {
                    LiveGameBottomAccessory(
                        hasLiveGame: hasLiveGame,
                        onTap: onTap
                    )
                }
            )
        } else if #available(iOS 26.0, *) {
            return AnyView(
                self.tabViewBottomAccessory {
                    LiveGameBottomAccessory(
                        hasLiveGame: hasLiveGame,
                        onTap: onTap
                    )
                }
            )
        } else {
            return AnyView(
                self.safeAreaInset(edge: .bottom) {
                    if hasLiveGame {
                        CustomLiveGameView(
                            hasLiveGame: hasLiveGame,
                            onTap: onTap
                        )
                        .background(.regularMaterial)
                    }
                }
            )
        }
    }
}

// MARK: - Previews

#Preview("Main") {
    let setup = PreviewContainers.liveGameSetup()
    let syncCoordinator = LiveSyncCoordinator(service: NoopSyncService())

    AppNavigationView()
        .tint(.green)
        .modelContainer(setup.container)
        .environment(setup.liveGameManager)
        .environment(setup.gameManager)
        .environment(setup.rosterManager)
        .environment(syncCoordinator)
}

#Preview("Blank") {
    let setup = PreviewContainers.emptySetup()
    let syncCoordinator = LiveSyncCoordinator(service: NoopSyncService())

    AppNavigationView()
        .tint(.green)
        .modelContainer(setup.container)
        .environment(setup.liveGameManager)
        .environment(setup.gameManager)
        .environment(setup.rosterManager)
        .environment(syncCoordinator)
}
