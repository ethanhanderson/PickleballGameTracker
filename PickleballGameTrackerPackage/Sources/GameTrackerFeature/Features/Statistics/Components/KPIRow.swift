import CorePackage
import SwiftUI

/// Simple KPI row with title on the left and value on the right.
struct KPIRow: View {
  let title: String
  let value: String
  var body: some View {
    HStack {
      Text(title)
        .font(DesignSystem.Typography.body)
        .foregroundStyle(DesignSystem.Colors.textSecondary)
      Spacer()
      Text(value)
        .font(DesignSystem.Typography.title2)
        .foregroundStyle(DesignSystem.Colors.textPrimary)
    }
    .padding(DesignSystem.Spacing.cardPadding)
    .background(
      RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.cardRounded, style: .continuous)
        .fill(DesignSystem.Colors.containerFillSecondary)
    )
  }
}
