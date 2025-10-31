import GameTrackerCore
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

    private var gameStateColor: GameStateColor {
        game.gameState.stateColor
    }

    private var mappedColor: Color {
        switch gameStateColor {
        case .readyToStart: return .blue
        case .attention: return .orange
        case .active: return .green
        case .success: return .green
        case .inactive: return .gray
        }
    }

    var body: some View {
        Button(action: onToggleGame) {
            Label {
                Text(buttonText)
            }             icon: {
                Image(systemName: buttonIcon)
                    .font(.system(size: 20))
                    .foregroundStyle(
                        mappedColor
                    )
            }
            .frame(maxWidth: .infinity)
            .fontWeight(.semibold)
        }
        .controlSize(.large)
        .buttonStyle(.glassProminent)
        .foregroundStyle(.primary)
        .tint(mappedColor.opacity(0.45))
        .disabled(isToggling || isResetting)
        .opacity(1.0)
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
    .environment(\.colorScheme, .light)
}
