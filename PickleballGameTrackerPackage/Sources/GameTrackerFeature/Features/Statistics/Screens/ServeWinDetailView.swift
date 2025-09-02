import CorePackage
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
          .font(DesignSystem.Typography.largeTitle)

        // KPI
        HStack {
          Text("Overall")
            .font(DesignSystem.Typography.body)
          Spacer()
          Text(overallText)
            .font(DesignSystem.Typography.title2)
        }
        .padding(12)
        .background(
          RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(DesignSystem.Colors.containerFillSecondary)
        )
        StatChartPlaceholder(title: "Serve win % over time")
        StatFilterSummary(filters: filters)
      }
      .padding()
      .task { await compute() }
    }
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

#Preview("With Data") {
  NavigationStack {
    ServeWinDetailView(filters: .init(gameId: nil, gameTypeId: GameType.recreational.rawValue))
  }
  .modelContainer(try! PreviewGameData.createFullPreviewContainer())
}
