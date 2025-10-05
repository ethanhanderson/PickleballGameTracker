import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct ServeWinDetailView: View {
  @Environment(\.modelContext) private var modelContext
  let filters: StatisticsFilters
  @State private var overallText: String = "—%"

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Text("Serve Win %")
          .font(.largeTitle)

        KPIRow(title: "Overall", value: overallText)
        StatChartPlaceholder(title: "Serve win % over time")
        StatFilterSummary(filters: filters)
      }
      .task(id: filters) { await compute() }
    }
    .contentMargins(.all, 16, for: .scrollContent)
    .navigationTitle("Serve Win %")
    .navigationBarTitleDisplayMode(.inline)
  }

  private func compute() async {
    let aggregator = StatisticsAggregator(modelContext: modelContext)
    do {
      let result = try aggregator.computeServeWinRate(
        gameId: filters.gameId, gameTypeId: filters.gameTypeId)
      let percent = Int(round(result.serveWinRate * 100))
      overallText = "\(percent)% (\(result.pointsWonOnServe)/\(result.totalServePoints))"
    } catch {
      Log.error(error, event: .loadFailed, metadata: ["phase": "computeServeWin"])
      overallText = "—%"
    }
  }
}

#Preview("With Live Game Data") {
  NavigationStack {
    ServeWinDetailView(filters: .init(gameId: nil, gameTypeId: GameType.recreational.rawValue))
  }
  .modelContainer(PreviewContainers.standard())
}

#Preview("With Basic Data") {
  NavigationStack {
    ServeWinDetailView(filters: .init(gameId: nil, gameTypeId: GameType.recreational.rawValue))
  }
  .modelContainer(PreviewContainers.minimal())
}
