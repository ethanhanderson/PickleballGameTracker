import CorePackage
import SwiftUI

@MainActor
struct StatNavCard: View {
  let title: String
  let subtitle: String
  let systemImage: String

  var body: some View {
    HStack(spacing: DesignSystem.Spacing.md) {
      Image(systemName: systemImage)
        .font(DesignSystem.Typography.headline)
        .foregroundStyle(DesignSystem.Colors.textSecondary)
        .frame(width: 28)
      VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
        Text(title)
          .font(DesignSystem.Typography.body)
          .foregroundStyle(DesignSystem.Colors.textPrimary)
        Text(subtitle)
          .font(DesignSystem.Typography.caption)
          .foregroundStyle(DesignSystem.Colors.textSecondary)
      }
      Spacer(minLength: 0)
      Image(systemName: "chevron.right")
        .font(DesignSystem.Typography.subheadline)
        .foregroundStyle(DesignSystem.Colors.textTertiary)
    }
    .padding(DesignSystem.Spacing.cardPadding)
    .background(
      RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.cardRounded, style: .continuous)
        .fill(DesignSystem.Colors.containerFillSecondary)
    )
  }
}
