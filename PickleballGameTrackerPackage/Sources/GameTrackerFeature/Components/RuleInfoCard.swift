import GameTrackerCore
import SwiftUI

@MainActor
struct RuleInfoCard<Content: View>: View {
  let title: String
  let iconName: String
  let gradient: AnyGradient
  @ViewBuilder var content: () -> Content

  var body: some View {
    VStack(spacing: DesignSystem.Spacing.xs) {
      Image(systemName: iconName)
        .font(.system(size: 20, weight: .medium))
        .foregroundStyle(gradient)
        .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)

      Text(title)
        .font(.caption)
        .fontWeight(.medium)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)

      content()
    }
    .frame(maxWidth: .infinity)
    .padding(DesignSystem.Spacing.md)
    .glassEffect(
      .regular.tint(Color.gray.opacity(0.15).opacity(0.5)),
      in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
    )
  }
}


