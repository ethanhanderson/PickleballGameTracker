import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct TimerCard: View {
  @Bindable var game: Game
  @Environment(LiveGameStateManager.self) private var activeGameStateManager
  let formattedElapsedTime: String
  let isTimerPaused: Bool
  let isGameLive: Bool
  let isResetting: Bool
  let isToggling: Bool
  let pulseAnimation: Bool
  let resetTrigger: Bool
  let playPauseTrigger: Bool

  private var gameTypeColor: Color {
    activeGameStateManager.currentGameTypeColor ?? Color.accentColor
  }

  private var timerIconColor: Color { gameTypeColor }
  private var timerBackgroundColor: Color { gameTypeColor }

  private var isPlaying: Bool { game.gameState == .playing && !game.isCompleted }

  var body: some View {
    HStack(spacing: DesignSystem.Spacing.sm) {
      Image(systemName: "timer")
        .font(.system(size: 20, weight: .semibold))
        .foregroundStyle(timerIconColor.gradient)
        .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
      Text(formattedElapsedTime)
        .font(.system(.title2, design: .monospaced))
        .fontWeight(.semibold)
        .foregroundStyle(.primary)
    }
    .frame(maxWidth: .infinity)
    .scaleEffect(isPlaying ? 1.0 : 0.95)
    .padding(.horizontal, DesignSystem.Spacing.lg)
    .padding(.vertical, DesignSystem.Spacing.md)
    .glassEffect(.regular.tint(timerBackgroundColor.opacity(0.35)), in: Capsule())
    .opacity(game.isCompleted ? 0.6 : (pulseAnimation ? 0.6 : 1.0))
    .animation(.easeInOut(duration: 0.3), value: pulseAnimation)
    .animation(.easeInOut(duration: 0.2), value: game.isCompleted)
  }
}

#Preview("Live Game Timer") {
  TimerCard(
    game: PreviewGameData.earlyGame,
    formattedElapsedTime: "02:05.67",
    isTimerPaused: false,
    isGameLive: true,
    isResetting: false,
    isToggling: false,
    pulseAnimation: false,
    resetTrigger: false,
    playPauseTrigger: false
  )
  .padding()
  .modelContainer(PreviewContainers.standard())
}

#Preview("Basic Timer") {
  TimerCard(
    game: PreviewGameData.earlyGame,
    formattedElapsedTime: "02:05.67",
    isTimerPaused: false,
    isGameLive: true,
    isResetting: false,
    isToggling: false,
    pulseAnimation: false,
    resetTrigger: false,
    playPauseTrigger: false
  )
  .padding()
  .modelContainer(PreviewContainers.minimal())
}

#Preview("Timer Paused") {
  TimerCard(
    game: PreviewGameData.trainingGame,
    formattedElapsedTime: "01:07.23",
    isTimerPaused: true,
    isGameLive: true,
    isResetting: false,
    isToggling: false,
    pulseAnimation: false,
    resetTrigger: false,
    playPauseTrigger: false
  )
  .padding()
  .modelContainer(PreviewContainers.minimal())
}

#Preview("Game Paused") {
  TimerCard(
    game: PreviewGameData.pausedGame,
    formattedElapsedTime: "01:07.23",
    isTimerPaused: true,
    isGameLive: false,
    isResetting: false,
    isToggling: false,
    pulseAnimation: false,
    resetTrigger: false,
    playPauseTrigger: false
  )
  .padding()
  .modelContainer(PreviewContainers.minimal())
}

#Preview("Game Completed") {
  TimerCard(
    game: PreviewGameData.completedGame,
    formattedElapsedTime: "03:45.78",
    isTimerPaused: true,
    isGameLive: false,
    isResetting: false,
    isToggling: false,
    pulseAnimation: false,
    resetTrigger: false,
    playPauseTrigger: false
  )
  .padding()
  .modelContainer(PreviewContainers.minimal())
}
