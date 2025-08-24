import PickleballGameTrackerCorePackage
import SwiftUI

@MainActor
struct GameMetricRow: View {
  let icon: String
  let title: String
  let value: String

  var body: some View {
    HStack(spacing: DesignSystem.Spacing.sm) {
      Image(systemName: icon)
        .foregroundStyle(DesignSystem.Colors.textSecondary)
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(DesignSystem.Typography.caption)
          .foregroundColor(DesignSystem.Colors.textSecondary)
        Text(value)
          .font(DesignSystem.Typography.bodyEmphasized)
          .foregroundColor(DesignSystem.Colors.textPrimary)
      }
    }
  }
}
