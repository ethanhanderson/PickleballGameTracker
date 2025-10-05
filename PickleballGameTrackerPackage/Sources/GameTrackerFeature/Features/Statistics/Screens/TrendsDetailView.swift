import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct TrendsDetailView: View {
  @Environment(\.modelContext) private var modelContext
  let filters: StatisticsFilters
  @State private var trend7: [TrendPoint] = []
  @State private var trend30: [TrendPoint] = []
  @State private var diff7: [TrendPoint] = []
  @State private var diff30: [TrendPoint] = []

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Text("Trends")
          .font(.largeTitle)
        StatChartPlaceholder(title: "7‑day win rate trend", points: trend7)
        StatChartPlaceholder(title: "30‑day win rate trend", points: trend30)
        StatChartPlaceholder(title: "7‑day point differential (avg)", points: diff7)
        StatChartPlaceholder(title: "30‑day point differential (avg)", points: diff30)
        StatFilterSummary(filters: filters)
      }
      .task(id: filters) { await compute() }
    }
    .contentMargins(.all, 16, for: .scrollContent)
    .navigationTitle("Trends")
    .navigationBarTitleDisplayMode(.inline)
  }

  private func compute() async {
    let aggregator = StatisticsAggregator(modelContext: modelContext)
    do {
      trend7 = try aggregator.computeWinRateTrend(days: 7, gameTypeId: filters.gameTypeId)
      trend30 = try aggregator.computeWinRateTrend(days: 30, gameTypeId: filters.gameTypeId)
      diff7 = try aggregator.computePointDifferentialTrend(days: 7, gameTypeId: filters.gameTypeId)
      diff30 = try aggregator.computePointDifferentialTrend(
        days: 30, gameTypeId: filters.gameTypeId)
    } catch {
      Log.error(error, event: .loadFailed, metadata: ["phase": "computeWinRateTrend"])
      trend7 = []
      trend30 = []
      diff7 = []
      diff30 = []
    }
  }
}

#Preview("With Live Game Data") {
  NavigationStack {
    TrendsDetailView(filters: .init(gameId: nil, gameTypeId: nil))
  }
  .modelContainer(PreviewContainers.standard())
}

#Preview("With Basic Data") {
  NavigationStack {
    TrendsDetailView(filters: .init(gameId: nil, gameTypeId: nil))
  }
  .modelContainer(PreviewContainers.minimal())
}

// Components referenced: `StatChartPlaceholder`, `StatFilterSummary`
