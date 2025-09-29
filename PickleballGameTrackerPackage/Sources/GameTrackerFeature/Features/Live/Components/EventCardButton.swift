import GameTrackerCore
import SwiftUI

@MainActor
struct EventCardButton: View {
    let eventType: GameEventType
    let tintColor: Color
    let isEnabled: Bool
    let action: () -> Void
    let customDescription: String?
    let customIconName: String?

    private var displayText: String {
        customDescription ?? eventType.displayName
    }

    private var iconName: String {
        customIconName ?? eventType.iconName
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: iconName)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(tintColor)

                Text(displayText)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
        }
        .controlSize(.large)
        .buttonStyle(.glassProminent)
        .tint(tintColor.opacity(0.2))
        .foregroundStyle(.primary)
        .scaleEffect(isEnabled ? 1.0 : 0.95)
        .opacity(isEnabled ? 1.0 : 0.6)
        .disabled(!isEnabled)
        .accessibilityLabel(displayText)
        .accessibilityHint("Log \(displayText.lowercased()) event")
        .help(displayText)
    }
}

#Preview {
    VStack(spacing: DesignSystem.Spacing.lg) {
        EventCardButton(
            eventType: .ballOutOfBounds,
            tintColor: Color.red,
            isEnabled: true,
            action: {},
            customDescription: nil,
            customIconName: nil
        )

        EventCardButton(
            eventType: .serviceFault,
            tintColor: Color.orange,
            isEnabled: true,
            action: {},
            customDescription: nil,
            customIconName: nil
        )

        EventCardButton(
            eventType: .gamePaused,
            tintColor: Color.blue,
            isEnabled: false,
            action: {},
            customDescription: nil,
            customIconName: nil
        )

        EventCardButton(
            eventType: .ballInKitchenOnServe,
            tintColor: Color.purple,
            isEnabled: true,
            action: {},
            customDescription: nil,
            customIconName: nil
        )

        EventCardButton(
            eventType: .injuryTimeout,
            tintColor: Color.green,
            isEnabled: true,
            action: {},
            customDescription: nil,
            customIconName: nil
        )
    }
    .padding()
}
