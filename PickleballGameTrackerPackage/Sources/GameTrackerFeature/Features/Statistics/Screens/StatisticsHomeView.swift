import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct StatisticsHomeView: View {
  var gameId: String? = nil
  var gameTypeId: String? = nil
  @State private var path: [StatDetailDestination] = []

  var body: some View {
    NavigationStack(path: $path) {
      ScrollView {
        VStack(spacing: 24) {
          // Results
          GroupedSection(title: "Results") {
            NavigationLink(value: StatDetailDestination.winRate(filters: filters)) {
              StatNavCard(title: "Win rate", subtitle: "Overall", systemImage: "medal")
            }
            .accessibilityIdentifier("NavLink.Statistics.winRate")
          }

          // Serving
          GroupedSection(title: "Serving") {
            NavigationLink(value: StatDetailDestination.serveWin(filters: filters)) {
              StatNavCard(
                title: "Serve win %", subtitle: "Points won on serve",
                systemImage: "rectangle.portrait.and.arrow.right")
            }
            .accessibilityIdentifier("NavLink.Statistics.serveWin")
          }

          // Trends
          GroupedSection(title: "Trends") {
            NavigationLink(value: StatDetailDestination.trends(filters: filters)) {
              StatNavCard(
                title: "Win rate (7/30d)", subtitle: "Trend",
                systemImage: "chart.line.uptrend.xyaxis")
            }
            .accessibilityIdentifier("NavLink.Statistics.trends")
          }

          // Streaks
          GroupedSection(title: "Streaks") {
            NavigationLink(value: StatDetailDestination.streaks(filters: filters)) {
              StatNavCard(title: "Current streak", subtitle: "Wins in a row", systemImage: "flame")
            }
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
        .padding(.horizontal)
        .padding(.vertical, 16)
      }
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
          // Navigate directly to default detail when pre-filtered via deep link
          path = [.winRate(filters: filters)]
        } else {
          path.removeAll()
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
    .minimalPreview(environment: PreviewEnvironment.statistics())
}

#Preview("Deep Link Context") {
  StatisticsHomeView(gameId: "demo-game-id", gameTypeId: "singles")
    .minimalPreview(environment: PreviewEnvironment.statistics())
}

#Preview("Empty State") {
  StatisticsHomeView()
    .minimalPreview(environment: PreviewEnvironment.empty())
}

#Preview("Rich Statistics Data") {
  StatisticsHomeView()
    .minimalPreview(environment: PreviewEnvironment.statistics())
}
