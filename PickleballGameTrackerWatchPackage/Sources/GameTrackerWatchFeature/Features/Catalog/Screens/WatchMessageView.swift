import SwiftUI
import GameTrackerCore

@MainActor
struct WatchMessageView: View {
    let icon: String
    let message: String
    let showSpinner: Bool
    let color: Color

    init(
        icon: String,
        message: String,
        showSpinner: Bool = false,
        color: Color = .secondary
    ) {
        self.icon = icon
        self.message = message
        self.showSpinner = showSpinner
        self.color = color
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(color)

            Text(message)
                .font(.headline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            if showSpinner {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .padding()
    }
}

#Preview("Disconnected") {
    WatchMessageView(
        icon: "iphone.slash",
        message: "Not connected to iPhone",
        color: .orange
    )
}

#Preview("Connecting") {
    WatchMessageView(
        icon: "iphone",
        message: "Connecting to iPhone…",
        showSpinner: true,
        color: .blue
    )
}
