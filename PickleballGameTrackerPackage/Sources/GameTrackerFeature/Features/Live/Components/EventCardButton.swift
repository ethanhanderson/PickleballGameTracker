import CorePackage
import SwiftUI

@MainActor
struct EventCardButton: View {
  let eventType: GameEventType
  let tintColor: Color
  let isEnabled: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: DesignSystem.Spacing.sm) {
        // Icon
        Image(systemName: eventType.iconName)
          .font(.system(size: 24, weight: .medium))
          .foregroundStyle(isEnabled ? tintColor : Color.gray)

        // Text
        Text(eventType.displayName)
          .font(DesignSystem.Typography.caption2)
          .foregroundStyle(isEnabled ? Color.primary : Color.gray)
          .multilineTextAlignment(.center)
          .lineLimit(2)
          .fixedSize(horizontal: false, vertical: true)
      }
      .frame(width: 90, height: 90)
      .background(
        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
          .fill(isEnabled ? Color(UIColor.systemBackground) : Color(UIColor.systemGray6))
          .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
      )
      .overlay(
        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
          .stroke(isEnabled ? tintColor.opacity(0.3) : Color.clear, lineWidth: 1)
      )
    }
    .scaleEffect(isEnabled ? 1.0 : 0.95)
    .opacity(isEnabled ? 1.0 : 0.6)
    .disabled(!isEnabled)
    .buttonStyle(PlainButtonStyle())
    .accessibilityLabel(eventType.displayName)
    .accessibilityHint("Log \(eventType.displayName.lowercased()) event")
    .help(eventType.displayName)
  }
}

#Preview {
  VStack(spacing: DesignSystem.Spacing.lg) {
    HStack(spacing: DesignSystem.Spacing.md) {
      EventCardButton(
        eventType: .ballOutOfBounds,
        tintColor: DesignSystem.AppleSystemColor.red.color,
        isEnabled: true,
        action: {}
      )

      EventCardButton(
        eventType: .serviceFault,
        tintColor: DesignSystem.AppleSystemColor.orange.color,
        isEnabled: true,
        action: {}
      )

      EventCardButton(
        eventType: .gamePaused,
        tintColor: DesignSystem.AppleSystemColor.blue.color,
        isEnabled: false,
        action: {}
      )
    }

    HStack(spacing: DesignSystem.Spacing.md) {
      EventCardButton(
        eventType: .ballInKitchenOnServe,
        tintColor: DesignSystem.AppleSystemColor.purple.color,
        isEnabled: true,
        action: {}
      )

      EventCardButton(
        eventType: .injuryTimeout,
        tintColor: DesignSystem.AppleSystemColor.green.color,
        isEnabled: true,
        action: {}
      )
    }
  }
  .padding()
}
