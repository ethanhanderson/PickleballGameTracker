import GameTrackerCore
import SwiftUI

@MainActor
struct GameMetricRow: View {
  let icon: String
  let title: String
  let value: String

  var body: some View {
    HStack(spacing: DesignSystem.Spacing.sm) {
      Image(systemName: icon)
        .foregroundStyle(.secondary)
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.caption)
          .foregroundStyle(.secondary)
        Text(value)
          .font(.body.weight(.semibold))
          .foregroundStyle(.primary)
      }
    }
  }
}
