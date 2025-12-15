import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct TimerCard: View {
  @Bindable var game: Game
  @Environment(LiveGameStateManager.self) private var activeGameStateManager
  let formattedElapsedTime: String

  private var gameTypeColor: Color {
    activeGameStateManager.currentGameTypeColor ?? Color.accentColor
  }

  private var timerIconColor: Color { gameTypeColor }
  private var timerBackgroundColor: Color { gameTypeColor }

  private var isPlaying: Bool { game.safeGameState == .playing && !game.safeIsCompleted }

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
    .opacity(game.safeIsCompleted ? 0.6 : 1.0)
    .animation(.easeInOut(duration: 0.2), value: game.safeIsCompleted)
  }
}

#Preview("Live Game Timer") {
  TimerCard(
    game: PreviewGameData.earlyGame,
    formattedElapsedTime: "02:05.67"
  )
  .padding()
  .previewContainer(PreviewEnvironment.liveGame())
}
