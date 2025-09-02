import CorePackage
import SwiftUI

struct GameControlsView: View {
  @Bindable var game: Game
  let isGamePaused: Bool
  let isGameInitial: Bool
  let isToggling: Bool
  @Binding var showingCompleteAlert: Bool
  @Binding var showingSettings: Bool
  let onToggleGame: () -> Void

  var body: some View {
    ScrollView {
      VStack(spacing: DesignSystem.Spacing.md) {
        Button(
          gameStatusButtonText,
          systemImage: gameStatusButtonIcon
        ) {
          onToggleGame()
        }
        .buttonStyle(.glass)
        .tint(gameStatusButtonColor)
        .foregroundStyle(.white)
        .opacity(dimOpacity(forDisabled: isGameStatusButtonDisabled))
        .disabled(isGameStatusButtonDisabled)

        Button(
          "End Game",
          systemImage: "flag.checkered",
          role: .destructive
        ) {
          if !game.isCompleted {
            showingCompleteAlert = true
          }
        }
        .buttonStyle(.glass)
        .disabled(isEndGameButtonDisabled)
        .foregroundStyle(.white)
        .opacity(dimOpacity(forDisabled: isEndGameButtonDisabled))

        Button("Settings", systemImage: "gearshape.fill") {
          showingSettings = true
        }
        .buttonStyle(.glass)
        .tint(.gray.opacity(0.6))
        .foregroundStyle(.white)
      }
    }
  }

  // MARK: - Computed Properties

  private var gameStatusButtonText: String {
    if game.isCompleted { return "Finish Game" }
    if !isGamePaused { return "Pause Game" }
    if isInitialState { return "Start Game" }
    return "Resume Game"
  }

  private var gameStatusButtonIcon: String {
    if game.isCompleted { return "flag.pattern.checkered" }
    if isGamePaused || isInitialState { return "play.fill" }
    return "pause.fill"
  }

  private var gameStatusButtonColor: Color {
    if game.isCompleted { return DesignSystem.Colors.success }
    if isInitialState || isGamePaused { return DesignSystem.Colors.gameType(game.gameType) }
    return DesignSystem.Colors.warning
  }

  private var isGameStatusButtonDisabled: Bool {
    if isInitialState { return false }
    return game.isCompleted || isToggling
  }

  private var isEndGameButtonDisabled: Bool {
    game.isCompleted || isInitialState
  }

  private func dimOpacity(forDisabled isDisabled: Bool) -> Double {
    isDisabled ? 0.6 : 1.0
  }

  private var isInitialState: Bool { game.gameState == .initial }
}


