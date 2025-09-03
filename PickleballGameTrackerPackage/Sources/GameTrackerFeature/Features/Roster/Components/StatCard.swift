import CorePackage
import SwiftUI

@MainActor
struct RosterStatCard: View {
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
        .font(DesignSystem.Typography.caption)
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
        DesignSystem.Colors.containerFillSecondary.opacity(0.5)
      ),
      in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
    )
  }
}
