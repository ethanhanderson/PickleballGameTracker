import CorePackage
import SwiftUI

@MainActor
struct SimpleStatCard: View {
  let title: String
  let value: String

  var body: some View {
    VStack(spacing: DesignSystem.Spacing.xs) {
      Text(value)
        .font(DesignSystem.Typography.title2)
        .foregroundStyle(DesignSystem.Colors.textPrimary)

      Text(title)
        .font(DesignSystem.Typography.caption)
        .foregroundStyle(DesignSystem.Colors.textSecondary)
    }
    .frame(maxWidth: .infinity)
    .padding(DesignSystem.Spacing.md)
    .background(DesignSystem.Colors.neutralSurface)
    .clipShape(
      RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
    )
  }
}


