import GameTrackerCore
import SwiftUI

@MainActor
struct GameInsightRow: View {
  let iconName: String
  let message: String
  let iconGradient: AnyGradient
  let backgroundOpacity: Double

  init(
    iconName: String,
    message: String,
    iconGradient: AnyGradient = Color.accentColor.gradient,
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
          color: .accentColor.opacity(0.3),
          radius: 3,
          x: 0,
          y: 2
        )
        .frame(width: 24, height: 24)

      Text(message)
        .font(.body)
        .foregroundStyle(.primary)
        .multilineTextAlignment(.leading)

      Spacer()
    }
    .padding(DesignSystem.Spacing.lg)
    .glassEffect(
      .regular.tint(
        Color.gray.opacity(0.15).opacity(backgroundOpacity)
      ),
      in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
    )
  }
}

#Preview {
  GameInsightRow(
    iconName: "trophy.fill",
    message: "You've won 5 games in a row!",
    iconGradient: Color.green.gradient
  )
  .padding()
  .tint(.green)
}
