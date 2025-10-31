import GameTrackerCore
import SwiftUI

struct GameControlsView: View {
  @Bindable var game: Game
  @Environment(LiveGameStateManager.self) private var liveGameStateManager
  let isGamePaused: Bool
  let isGameInitial: Bool
  let isToggling: Bool
  @Binding var showingCompleteAlert: Bool
  @Binding var showingSettings: Bool
  let onToggleGame: () -> Void

  var body: some View {
    ScrollView {
      VStack(spacing: DesignSystem.Spacing.md) {
        HStack(spacing: DesignSystem.Spacing.md) {
          Button {
            onToggleGame()
          } label: {
            VStack(spacing: DesignSystem.Spacing.xs) {
              Image(systemName: gameStatusButtonIcon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .glassEffect(.regular.tint(gameStatusButtonColor))
              Text(gameStatusButtonShortText)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .opacity(dimOpacity(forDisabled: isGameStatusButtonDisabled))
          }
          .buttonStyle(.plain)
          .disabled(isGameStatusButtonDisabled)

          if !hasWinner {
            Button {
              if !game.isCompleted {
                showingCompleteAlert = true
              }
            } label: {
              VStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "flag.checkered")
                  .font(.title2)
                  .foregroundStyle(.white)
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 12)
                  .glassEffect(.regular.tint(.red.opacity(0.8)))
                Text("End")
                  .font(.caption)
                  .fontWeight(.medium)
                  .foregroundStyle(.white)
              }
              .frame(maxWidth: .infinity)
              .opacity(dimOpacity(forDisabled: isEndGameButtonDisabled))
            }
            .buttonStyle(.plain)
            .disabled(isEndGameButtonDisabled)
          } else {
            Button {
              showingSettings = true
            } label: {
              VStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "gearshape.fill")
                  .font(.title2)
                  .foregroundStyle(.white)
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 12)
                  .glassEffect(.regular.tint(.gray.opacity(0.6)))
                Text("Settings")
                  .font(.caption)
                  .fontWeight(.medium)
                  .foregroundStyle(.white)
              }
              .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
          }
        }

        if !hasWinner {
          HStack(spacing: DesignSystem.Spacing.md) {
            Button {
              showingSettings = true
            } label: {
              VStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "gearshape.fill")
                  .font(.title2)
                  .foregroundStyle(.white)
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 12)
                  .glassEffect(.regular.tint(.gray.opacity(0.6)))
                Text("Settings")
                  .font(.caption)
                  .fontWeight(.medium)
                  .foregroundStyle(.white)
              }
              .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            
            Color.clear
              .frame(maxWidth: .infinity)
          }
        }
      }
      .padding(.horizontal)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .contentShape(.rect)
    .scrollClipDisabled()
    .navigationTitle {
      Text(game.gameType.displayName)
        .foregroundStyle(game.gameType.color)
    }
    .toolbarTitleDisplayMode(.inline)
  }

  // MARK: - Computed Properties

  private var gameStatusButtonText: String {
    if game.isCompleted { return "Finish Game" }
    if isInitialState { return "Start Game" }
    if isGamePaused { return "Resume Game" }
    return "Pause Game"
  }

  private var gameStatusButtonShortText: String {
    if game.isCompleted { return "Finish" }
    if isInitialState { return "Start" }
    if isGamePaused { return "Resume" }
    return "Pause"
  }

  private var gameStatusButtonIcon: String {
    if game.isCompleted { return "flag.pattern.checkered" }
    if isGamePaused || isInitialState { return "play.fill" }
    return "pause.fill"
  }

  private var gameStateColor: GameStateColor {
    game.gameState.stateColor
  }

  private var gameStatusButtonColor: Color {
    switch gameStateColor {
    case .readyToStart: return .blue
    case .attention: return .orange
    case .active: return .green
    case .success: return .green
    case .inactive: return .gray
    }
  }

  private var isGameStatusButtonDisabled: Bool {
    return isToggling
  }

  private var isEndGameButtonDisabled: Bool {
    game.isCompleted
  }

  private func dimOpacity(forDisabled isDisabled: Bool) -> Double {
    isDisabled ? 0.6 : 1.0
  }

  private var isInitialState: Bool { game.gameState == .initial }
  
  private var hasWinner: Bool {
    guard game.isCompleted else { return false }
    return game.score1 != game.score2
  }
}


