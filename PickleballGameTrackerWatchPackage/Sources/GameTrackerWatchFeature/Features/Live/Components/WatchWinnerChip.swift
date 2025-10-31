import GameTrackerCore
import SwiftUI

@MainActor
struct WatchWinnerChip: View {
    @Bindable var game: Game
    let teamTintColor: Color

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "crown.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(teamTintColor)

            Text("WINNER")
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .glassEffect(.regular.tint(teamTintColor.opacity(0.4)))
    }
}
