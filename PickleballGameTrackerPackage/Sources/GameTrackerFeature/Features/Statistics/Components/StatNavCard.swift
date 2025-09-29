import GameTrackerCore
import SwiftUI

@MainActor
struct StatNavCard: View {
  let title: String
  let subtitle: String
  let systemImage: String

  var body: some View {
    HStack(spacing: DesignSystem.Spacing.md) {
      Image(systemName: systemImage)
        .font(.headline)
        .foregroundStyle(.secondary)
        .frame(width: 28)
      VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
        Text(title)
          .font(.body)
          .foregroundStyle(.primary)
        Text(subtitle)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer(minLength: 0)
      Image(systemName: "chevron.right")
        .font(.subheadline)
        .foregroundStyle(.gray)
    }
    .padding(DesignSystem.Spacing.md)
    .background(
      RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl, style: .continuous)
        .fill(Color.gray.opacity(0.15))
    )
  }
}
