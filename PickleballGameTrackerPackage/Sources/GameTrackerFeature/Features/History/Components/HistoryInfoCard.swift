import GameTrackerCore
import SwiftUI

/// A card component for displaying simple information in game history views.
struct HistoryInfoCard: View {
  let title: String
  let value: String

  init(title: String, value: String) {
    self.title = title
    self.value = value
  }

  var body: some View {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
      Text(title)
        .font(.caption)
        .foregroundStyle(.secondary)
      Text(value)
        .font(.body)
        .fontWeight(.semibold)
        .foregroundStyle(.primary)
    }
    .padding(DesignSystem.Spacing.sm)
    .background(Color.gray.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
  }
}
