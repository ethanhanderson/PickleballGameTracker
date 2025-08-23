import SharedGameCore
import SwiftUI

/// Displays the active statistics filters in a compact list.
struct StatFilterSummary: View {
  let filters: StatisticsFilters
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Filters")
        .font(DesignSystem.Typography.body)
      if let gameId = filters.gameId {
        Text("gameId: \(gameId)")
          .font(DesignSystem.Typography.caption)
          .foregroundStyle(.secondary)
      }
      if let gameTypeId = filters.gameTypeId {
        Text("gameType: \(gameTypeId)")
          .font(DesignSystem.Typography.caption)
          .foregroundStyle(.secondary)
      }
    }
  }
}
