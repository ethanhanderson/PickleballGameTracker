import PickleballGameTrackerCorePackage
import SwiftUI

@MainActor
struct StatNavCard: View {
  let title: String
  let subtitle: String
  let systemImage: String

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: systemImage)
        .font(.system(size: 20, weight: .semibold))
        .foregroundStyle(.secondary)
        .frame(width: 28)
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(DesignSystem.Typography.body)
          .foregroundStyle(.primary)
        Text(subtitle)
          .font(DesignSystem.Typography.caption)
          .foregroundStyle(.secondary)
      }
      Spacer(minLength: 0)
      Image(systemName: "chevron.right")
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(.tertiary)
    }
    .padding(12)
    .background(
      RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.cardRounded, style: .continuous)
        .fill(DesignSystem.Colors.containerFillSecondary)
    )
  }
}
