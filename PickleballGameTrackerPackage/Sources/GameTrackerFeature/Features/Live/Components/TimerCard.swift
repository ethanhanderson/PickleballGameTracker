import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct TimerCard: View {
  @Bindable var game: Game
  @Environment(LiveGameStateManager.self) private var activeGameStateManager
  let formattedElapsedTime: String
  let isTimerPaused: Bool
  let isGameActive: Bool
  let isResetting: Bool
  let isToggling: Bool
  let pulseAnimation: Bool
  let resetTrigger: Bool
  let playPauseTrigger: Bool
  let onResetTimer: () -> Void
  let onToggleTimer: () -> Void

  private var gameTypeColor: Color {
    activeGameStateManager.currentGameTypeColor ?? Color.accentColor
  }

  private var timerIconColor: Color {
    isTimerPaused ? .gray : gameTypeColor
  }
  private var timerBackgroundColor: Color {
    isTimerPaused ? .gray : gameTypeColor
  }

  private var shouldShowControls: Bool {
    // Only show timer controls when game is in playing state and not completed
    game.gameState == .playing && !game.isCompleted
  }

  var body: some View {
    HStack(spacing: DesignSystem.Spacing.md) {
      // Reset Button - Only visible when game is playing
      if shouldShowControls {
        Button(action: onResetTimer) {
          Image(systemName: "arrow.counterclockwise")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(timerIconColor.gradient)
            .opacity((isResetting || isToggling) ? 0.5 : 1.0)
            .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
            .symbolEffect(.rotate, value: resetTrigger)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isResetting || isToggling)
        .accessibilityIdentifier("TimerCard.resetButton")
      }

      Spacer()

      // Center Timer Display Button
      if shouldShowControls {
        Button(action: onToggleTimer) {
          HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "timer")
              .font(.system(size: 20, weight: .semibold))
              .foregroundStyle(timerIconColor.gradient)
              .opacity(isToggling ? 0.5 : 1.0)
              .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
            Text(formattedElapsedTime)
              .font(.system(.title2, design: .monospaced))
              .fontWeight(.semibold)
              .foregroundStyle(.primary)
          }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isToggling)
        .accessibilityIdentifier("TimerCard.centerToggleButton")
      } else {
        // Game paused - show timer but not interactive
        HStack(spacing: DesignSystem.Spacing.sm) {
          Image(systemName: "timer")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(Color.gray.gradient)
            .opacity(0.7)
          Text(formattedElapsedTime)
            .font(.system(.title2, design: .monospaced))
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
        }
      }

      Spacer()

      // Right Play/Pause Button - Only visible when game is playing
      if shouldShowControls {
        Button(action: onToggleTimer) {
          Image(systemName: isTimerPaused ? "play.fill" : "pause.fill")
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(timerIconColor.gradient)
            .opacity(isToggling ? 0.5 : 1.0)
            .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
            .symbolEffect(.bounce, value: playPauseTrigger)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isToggling)
        .accessibilityIdentifier("TimerCard.rightToggleButton")
      }
    }
    .padding(.horizontal, DesignSystem.Spacing.lg)
    .padding(.vertical, DesignSystem.Spacing.md)
    .glassEffect(.regular.tint(timerBackgroundColor.opacity(0.35)), in: Capsule())
    .opacity(pulseAnimation ? 0.6 : 1.0)
    .animation(.easeInOut(duration: 0.3), value: pulseAnimation)
  }
}

#Preview("Live Game Timer") {
  TimerCard(
    game: PreviewGameData.earlyGame,
    formattedElapsedTime: "02:05.67",
    isTimerPaused: false,
    isGameActive: true,
    isResetting: false,
    isToggling: false,
    pulseAnimation: false,
    resetTrigger: false,
    playPauseTrigger: false,
    onResetTimer: {},
    onToggleTimer: {}
  )
  .padding()
  .minimalPreview(environment: PreviewEnvironment.componentWithGame())
}

#Preview("Basic Timer") {
  TimerCard(
    game: PreviewGameData.earlyGame,
    formattedElapsedTime: "02:05.67",
    isTimerPaused: false,
    isGameActive: true,
    isResetting: false,
    isToggling: false,
    pulseAnimation: false,
    resetTrigger: false,
    playPauseTrigger: false,
    onResetTimer: {},
    onToggleTimer: {}
  )
  .padding()
  .minimalPreview(environment: PreviewEnvironment.component())
}

#Preview("Timer Paused") {
  TimerCard(
    game: PreviewGameData.trainingGame,
    formattedElapsedTime: "01:07.23",
    isTimerPaused: true,
    isGameActive: true,
    isResetting: false,
    isToggling: false,
    pulseAnimation: false,
    resetTrigger: false,
    playPauseTrigger: false,
    onResetTimer: {},
    onToggleTimer: {}
  )
  .padding()
  .minimalPreview(environment: PreviewEnvironment.component())
}

#Preview("Game Paused") {
  TimerCard(
    game: PreviewGameData.pausedGame,
    formattedElapsedTime: "01:07.23",
    isTimerPaused: true,
    isGameActive: false,
    isResetting: false,
    isToggling: false,
    pulseAnimation: false,
    resetTrigger: false,
    playPauseTrigger: false,
    onResetTimer: {},
    onToggleTimer: {}
  )
  .padding()
  .minimalPreview(environment: PreviewEnvironment.component())
}

#Preview("Game Completed") {
  TimerCard(
    game: PreviewGameData.completedGame,
    formattedElapsedTime: "03:45.78",
    isTimerPaused: true,
    isGameActive: false,
    isResetting: false,
    isToggling: false,
    pulseAnimation: false,
    resetTrigger: false,
    playPauseTrigger: false,
    onResetTimer: {},
    onToggleTimer: {}
  )
  .padding()
  .minimalPreview(environment: PreviewEnvironment.component())
}
