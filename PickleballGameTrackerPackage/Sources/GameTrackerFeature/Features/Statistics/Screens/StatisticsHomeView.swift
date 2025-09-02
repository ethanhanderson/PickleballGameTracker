import CorePackage
import SwiftData
import SwiftUI

@MainActor
struct StatisticsHomeView: View {
  var gameId: String? = nil
  var gameTypeId: String? = nil

  @State private var navigateToDefaultDetail = false

  var body: some View {
    NavigationStack {
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
              .font(DesignSystem.Typography.caption)
              .foregroundStyle(.secondary)
          }
          if let gameTypeId {
            Text("Prefilter: gameType = \(gameTypeId)")
              .font(DesignSystem.Typography.caption)
              .foregroundStyle(.secondary)
          }
        }
        .padding(.horizontal)
        .padding(.vertical, 16)
      }
      .navigationTitle("Statistics")
      .containerBackground(DesignSystem.Colors.navigationBrandGradient, for: .navigation)
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
        // If opened via deep link with pre-applied filters, default to Win Rate detail without an intermediate sheet
        if (gameId != nil || gameTypeId != nil) && navigateToDefaultDetail == false {
          // Yield to allow NavigationStack to settle before programmatic navigation
          await Task.yield()
          navigateToDefaultDetail = true
        }
      }
      .background(
        // Programmatic navigation trigger
        NavigationLink(
          value: StatDetailDestination.winRate(filters: filters),
          label: { EmptyView() }
        )
        .opacity(0)
      )
    }
    .navigationTint()
  }

  private var filters: StatisticsFilters {
    StatisticsFilters(gameId: gameId, gameTypeId: gameTypeId)
  }
}

// MARK: - Navigation Destinations

enum StatDetailDestination: Hashable {
  case winRate(filters: StatisticsFilters)
  case serveWin(filters: StatisticsFilters)
  case trends(filters: StatisticsFilters)
  case streaks(filters: StatisticsFilters)
}

// MARK: - Filters Value

struct StatisticsFilters: Hashable, Sendable {
  var gameId: String?
  var gameTypeId: String?
}

// Components extracted to `Features/Statistics/Components/GroupedSection.swift` and `StatNavCard.swift`

#Preview("Deep Link Context") {
  StatisticsHomeView(gameId: "demo-game-id", gameTypeId: "singles")
}

#Preview("Empty State") {
  StatisticsHomeView()
    .modelContainer(try! PreviewGameData.createPreviewContainer(with: []))
}
