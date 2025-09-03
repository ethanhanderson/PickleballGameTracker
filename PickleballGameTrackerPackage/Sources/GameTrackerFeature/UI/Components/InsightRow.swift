import CorePackage
import SwiftUI

@MainActor
struct InsightRow: View {
  let iconName: String
  let message: String
  let iconGradient: AnyGradient
  let backgroundOpacity: Double

  init(
    iconName: String,
    message: String,
    iconGradient: AnyGradient = DesignSystem.Colors.primary.gradient,
    backgroundOpacity: Double = 0.2
  ) {
    self.iconName = iconName
    self.message = message
    self.iconGradient = iconGradient
    self.backgroundOpacity = backgroundOpacity
  }

  var body: some View {
    HStack(spacing: DesignSystem.Spacing.lg) {
      Image(systemName: iconName)
        .font(.system(size: 32, weight: .medium))
        .foregroundStyle(iconGradient)
        .shadow(
          color: DesignSystem.Colors.primary.opacity(0.3),
          radius: 3,
          x: 0,
          y: 2
        )
        .frame(width: 24, height: 24)

      Text(message)
        .font(DesignSystem.Typography.body)
        .foregroundColor(DesignSystem.Colors.textPrimary)
        .multilineTextAlignment(.leading)

      Spacer()
    }
    .padding(DesignSystem.Spacing.lg)
    .glassEffect(
      .regular.tint(
        DesignSystem.Colors.containerFillSecondary.opacity(backgroundOpacity)
      ),
      in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
    )
  }
}


