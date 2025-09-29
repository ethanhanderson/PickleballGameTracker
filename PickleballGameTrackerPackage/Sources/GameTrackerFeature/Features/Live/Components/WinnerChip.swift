import GameTrackerCore
import SwiftUI

@MainActor
struct WinnerChip: View {
    @Bindable var game: Game
    let teamTintColor: Color

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: "crown.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(teamTintColor)

            Text("WINNER")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .glassEffect(
            .regular.tint(teamTintColor.opacity(0.4))
        )
    }
}
