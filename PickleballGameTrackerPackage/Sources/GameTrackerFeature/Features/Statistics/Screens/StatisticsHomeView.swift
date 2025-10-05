import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct StatisticsHomeView: View {
  var gameId: String? = nil
  var gameTypeId: String? = nil
  @State private var navigationState = AppNavigationState()

  var body: some View {
    NavigationStack(path: $navigationState.navigationPath) {
      ScrollView {
        VStack(spacing: 24) {
          // Results
          GroupedSection(title: "Results") {
            NavigationLink(value: StatDetailDestination.winRate(filters: filters)) {
              StatNavCard(title: "Win rate", subtitle: "Overall", systemImage: "medal")
            }
            .simultaneousGesture(
              TapGesture().onEnded {
                navigationState.trackStatNavigation(.winRate(filters: filters))
              }
            )
            .accessibilityIdentifier("NavLink.Statistics.winRate")
          }

          // Serving
          GroupedSection(title: "Serving") {
            NavigationLink(value: StatDetailDestination.serveWin(filters: filters)) {
              StatNavCard(
                title: "Serve win %", subtitle: "Points won on serve",
                systemImage: "rectangle.portrait.and.arrow.right")
            }
            .simultaneousGesture(
              TapGesture().onEnded {
                navigationState.trackStatNavigation(.serveWin(filters: filters))
              }
            )
            .accessibilityIdentifier("NavLink.Statistics.serveWin")
          }

          // Trends
          GroupedSection(title: "Trends") {
            NavigationLink(value: StatDetailDestination.trends(filters: filters)) {
              StatNavCard(
                title: "Win rate (7/30d)", subtitle: "Trend",
                systemImage: "chart.line.uptrend.xyaxis")
            }
            .simultaneousGesture(
              TapGesture().onEnded {
                navigationState.trackStatNavigation(.trends(filters: filters))
              }
            )
            .accessibilityIdentifier("NavLink.Statistics.trends")
          }

          // Streaks
          GroupedSection(title: "Streaks") {
            NavigationLink(value: StatDetailDestination.streaks(filters: filters)) {
              StatNavCard(title: "Current streak", subtitle: "Wins in a row", systemImage: "flame")
            }
            .simultaneousGesture(
              TapGesture().onEnded {
                navigationState.trackStatNavigation(.streaks(filters: filters))
              }
            )
            .accessibilityIdentifier("NavLink.Statistics.streaks")
          }

          // Deep-link context preview (optional)
          if let gameId {
            Text("Prefilter: gameId = \(gameId)")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          if let gameTypeId {
            Text("Prefilter: gameType = \(gameTypeId)")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }
      .contentMargins(.horizontal, DesignSystem.Spacing.md, for: .scrollContent)
      .contentMargins(.vertical, 16, for: .scrollContent)
      .navigationTitle("Statistics")
      .viewContainerBackground()
      .navigationDestination(for: StatDetailDestination.self) { destination in
        switch destination {
        case .winRate(let filters):
          WinRateDetailView(filters: filters)
        case .serveWin(let filters):
          ServeWinDetailView(filters: filters)
        case .trends(let filters):
          TrendsDetailView(filters: filters)
        case .streaks(let filters):
          StreaksDetailView(filters: filters)
        }
      }
      .task(id: gameId ?? "\(gameTypeId ?? "")") {
        if gameId != nil || gameTypeId != nil {
          navigationState.navigateToStatDetail(.winRate(filters: filters))
        } else {
          navigationState.popToRoot()
        }
      }
    }
    .tint(.accentColor)
  }

  private var filters: StatisticsFilters {
    StatisticsFilters(gameId: gameId, gameTypeId: gameTypeId)
  }
}

#Preview("With Live Game Data") {
  StatisticsHomeView()
    .modelContainer(PreviewContainers.standard())
}

#Preview("Deep Link Context") {
  StatisticsHomeView(gameId: "demo-game-id", gameTypeId: "singles")
    .modelContainer(PreviewContainers.standard())
}

#Preview("Empty State") {
  StatisticsHomeView()
    .modelContainer(PreviewContainers.empty())
}

#Preview("Rich Statistics Data") {
  StatisticsHomeView()
    .modelContainer(PreviewContainers.standard())
}
