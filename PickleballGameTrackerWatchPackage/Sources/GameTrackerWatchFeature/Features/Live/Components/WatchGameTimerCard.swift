import GameTrackerCore
import SwiftUI

@MainActor
struct WatchGameTimerCard: View {
  @Bindable var game: Game
  let liveGameStateManager: LiveGameStateManager
  let isLuminanceReduced: Bool

  init(
    game: Game,
    liveGameStateManager: LiveGameStateManager,
    isLuminanceReduced: Bool
  ) {
    self.game = game
    self.liveGameStateManager = liveGameStateManager
    self.isLuminanceReduced = isLuminanceReduced
  }

  var body: some View {
    let isPlaying = liveGameStateManager.isGameLive

    HStack(spacing: 4) {
      Image(systemName: "timer")
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(isLuminanceReduced ? .secondary : .primary)

      Text(
        isLuminanceReduced
          ? liveGameStateManager.formattedElapsedTime
          : liveGameStateManager.formattedElapsedTimeWithCentiseconds
      )
      .font(.system(size: 14, weight: .semibold, design: .monospaced))
      .foregroundStyle(isLuminanceReduced ? .secondary : .primary)
    }
    .frame(maxWidth: .infinity)
    .scaleEffect(isPlaying ? 1.0 : 0.95)
    .padding(.horizontal, DesignSystem.Spacing.sm)
    .padding(.vertical, DesignSystem.Spacing.xs)
    .glassEffect()
    .opacity(game.safeIsCompleted ? 0.6 : 1.0)
    .animation(isLuminanceReduced ? nil : .easeInOut(duration: 0.2), value: game.safeIsCompleted)
  }
}

