import GameTrackerCore
import SwiftUI

@MainActor
struct StatCard: View {
  let symbolName: String
  let title: String
  let value: String
  let themeColor: Color

  var body: some View {
    VStack(spacing: DesignSystem.Spacing.xs) {
      Image(systemName: symbolName)
        .font(.system(size: 20, weight: .medium))
        .foregroundStyle(themeColor)
        .shadow(color: themeColor.opacity(0.3), radius: 3, x: 0, y: 2)

      Text(title)
        .font(.caption)
        .fontWeight(.medium)
        .foregroundStyle(.secondary)

      Text(value)
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(.primary)
    }
    .frame(maxWidth: .infinity)
    .padding(DesignSystem.Spacing.md)
    .glassEffect(
      .regular.tint(
        Color.gray.opacity(0.15).opacity(0.5)
      ),
      in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
    )
  }
}
