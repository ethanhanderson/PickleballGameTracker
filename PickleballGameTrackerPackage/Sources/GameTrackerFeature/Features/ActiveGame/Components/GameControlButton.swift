import CorePackage
import SwiftData
import SwiftUI

@MainActor
struct GameControlButton: View {
  @Bindable var game: Game
  let isGamePaused: Bool
  let isGameInitial: Bool
  let isToggling: Bool
  let isResetting: Bool
  let onToggleGame: () -> Void

  private var isGameCompleted: Bool {
    game.isCompleted
  }

  private var buttonText: String {
    if isGameCompleted {
      return "Finish Game"
    } else if !isGamePaused {
      return "Pause Game"
    } else if isGameInitial {
      return "Start Game"
    } else {
      return "Resume Game"
    }
  }

  private var buttonIcon: String {
    if isGameCompleted {
      return "flag.pattern.checkered"
    } else if isGamePaused {
      return "play.fill"
    } else {
      return "pause.fill"
    }
  }

  var body: some View {
    Button(action: onToggleGame) {
      HStack(spacing: DesignSystem.Spacing.sm) {
        Image(systemName: buttonIcon)
          .font(.system(size: 20, weight: .semibold))
          .foregroundStyle(
            (isGameCompleted
              ? DesignSystem.Colors.success : DesignSystem.Colors.gameType(game.gameType)).gradient)

        Text(buttonText)
          .font(DesignSystem.Typography.headline)
          .fontWeight(.semibold)
          .foregroundStyle(.primary)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical)
      .glassEffect(
        .regular.tint(
          (isGameCompleted
            ? DesignSystem.Colors.success : DesignSystem.Colors.gameType(game.gameType)).opacity(
              0.45)),
        in: Capsule()
      )
    }
    .buttonStyle(.plain)
    .disabled(isToggling || isResetting)
    .padding(.horizontal, DesignSystem.Spacing.lg)
    .accessibilityIdentifier("GameControlButton.primary")
    .accessibilityLabel(Text(buttonText))
  }
}

#Preview {
  VStack(spacing: DesignSystem.Spacing.lg) {
    GameControlButton(
      game: PreviewGameData.earlyGame,
      isGamePaused: true,
      isGameInitial: true,
      isToggling: false,
      isResetting: false,
      onToggleGame: {}
    )

    GameControlButton(
      game: PreviewGameData.pausedGame,
      isGamePaused: true,
      isGameInitial: false,
      isToggling: false,
      isResetting: false,
      onToggleGame: {}
    )

    GameControlButton(
      game: PreviewGameData.midGame,
      isGamePaused: false,
      isGameInitial: false,
      isToggling: false,
      isResetting: false,
      onToggleGame: {}
    )

    GameControlButton(
      game: PreviewGameData.completedGame,
      isGamePaused: false,
      isGameInitial: false,
      isToggling: false,
      isResetting: false,
      onToggleGame: {}
    )
  }
  .padding()
}
