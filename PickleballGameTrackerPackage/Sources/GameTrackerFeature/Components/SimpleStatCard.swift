import GameTrackerCore
import SwiftUI

@MainActor
struct SimpleStatCard: View {
  let title: String
  let value: String

  var body: some View {
    VStack(spacing: DesignSystem.Spacing.xs) {
      Text(value)
        .font(.title2)
        .foregroundStyle(.primary)

      Text(title)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(DesignSystem.Spacing.md)
    .background(Color.gray.opacity(0.1))
    .clipShape(
      RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
    )
  }
}


