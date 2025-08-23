import SharedGameCore
import SwiftData
import SwiftUI

@MainActor
struct StreaksDetailView: View {
  let filters: StatisticsFilters

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Text("Streaks")
          .font(DesignSystem.Typography.largeTitle)
        KPIRow(title: "Current win streak", value: currentText)
        KPIRow(title: "Longest win streak", value: longestText)
        StatFilterSummary(filters: filters)
      }
      .padding()
      .task(id: filters) {
        await compute()
      }
    }
    .navigationTitle("Streaks")
    .navigationBarTitleDisplayMode(.inline)
  }

  @Environment(\.modelContext) private var modelContext
  @State private var currentText: String = "—"
  @State private var longestText: String = "—"

  private func compute() async {
    let aggregator = StatisticsAggregator(modelContext: modelContext)
    do {
      let s = try aggregator.computeStreaks(gameTypeId: filters.gameTypeId)
      currentText = String(s.currentWinStreak)
      longestText = String(s.longestWinStreak)
    } catch {
      Log.error(error, event: .loadFailed, metadata: ["phase": "computeStreaks"])
      currentText = "—"
      longestText = "—"
    }
  }
}

#Preview("With Data") {
  NavigationStack {
    StreaksDetailView(filters: .init(gameId: nil, gameTypeId: GameType.recreational.rawValue))
  }
  .modelContainer(try! PreviewGameData.createFullPreviewContainer())
}

// KPIRow and FilterSummary extracted to shared Statistics components
