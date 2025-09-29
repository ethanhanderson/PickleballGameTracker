import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct WinRateDetailView: View {
  @Environment(\.modelContext) private var modelContext
  let filters: StatisticsFilters

  @State private var summaryText: String = "—%"

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Text("Win Rate")
          .font(.largeTitle)

        KPIRow(title: "Overall", value: summaryText)
        StatChartPlaceholder(title: "Win rate (7d)", points: trend7)
        StatChartPlaceholder(title: "Win rate (30d)", points: trend30)

        StatFilterSummary(filters: filters)
      }
      .padding()
      .task(id: filters, compute)
    }
    .navigationTitle("Win Rate")
    .navigationBarTitleDisplayMode(.inline)
  }

  @State private var trend7: [TrendPoint] = []
  @State private var trend30: [TrendPoint] = []

  private func compute() {
    let aggregator = StatisticsAggregator(modelContext: modelContext)
    do {
      let result = try aggregator.computeWinRate(
        gameId: filters.gameId,
        gameTypeId: filters.gameTypeId
      )
      let percent = Int(round(result.winRate * 100))
      summaryText = "\(percent)% (\(result.wins)/\(result.totalGames))"
      trend7 = try aggregator.computeWinRateTrend(days: 7, gameTypeId: filters.gameTypeId)
      trend30 = try aggregator.computeWinRateTrend(days: 30, gameTypeId: filters.gameTypeId)
    } catch {
      Log.error(error, event: .loadFailed, metadata: ["phase": "computeWinRate"])
      summaryText = "—%"
      trend7 = []
      trend30 = []
    }
  }
}

#Preview("With Live Game Data") {
  NavigationStack {
    WinRateDetailView(filters: .init(gameId: nil, gameTypeId: GameType.recreational.rawValue))
  }
  .minimalPreview(environment: PreviewEnvironment.componentWithGame())
}

#Preview("With Basic Data") {
  NavigationStack {
    WinRateDetailView(filters: .init(gameId: nil, gameTypeId: GameType.recreational.rawValue))
  }
  .minimalPreview(environment: PreviewEnvironment.component())
}
