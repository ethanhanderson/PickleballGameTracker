import SharedGameCore
import SwiftUI

struct ScoreControlsView: View {
  @Bindable var game: Game
  let activeGameStateManager: ActiveGameStateManager
  let onScorePoint: (Int) -> Void
  let onDecrementScore: (Int) -> Void
  let onToggleTimer: () -> Void
  let onResetTimer: () -> Void

  // Timer animation state passed from parent
  let isResetting: Bool
  let isToggling: Bool
  let pulseAnimation: Bool
  let resetTrigger: Bool
  let playPauseTrigger: Bool

  @State private var gamePointBreathing = false

  var body: some View {
    VStack(spacing: DesignSystem.Spacing.sm) {
      timerControlsView()

      HStack(spacing: DesignSystem.Spacing.sm) {
        teamScoreSection(
          teamNumber: 1,
          teamName: game.effectivePlayerLabel1,
          score: game.score1,
          color: DesignSystem.Colors.scorePlayer1,
          isServing: game.currentServer == 1 && !game.isCompleted
        )

        teamScoreSection(
          teamNumber: 2,
          teamName: game.effectivePlayerLabel2,
          score: game.score2,
          color: DesignSystem.Colors.scorePlayer2,
          isServing: game.currentServer == 2 && !game.isCompleted
        )
      }
      .animation(
        .spring(response: 0.3, dampingFraction: 0.8),
        value: game.score1
      )
      .animation(
        .spring(response: 0.3, dampingFraction: 0.8),
        value: game.score2
      )
      .animation(
        .spring(response: 0.3, dampingFraction: 0.8),
        value: game.currentServer
      )
    }
  }

  // MARK: - Timer Controls

  @ViewBuilder
  private func timerControlsView() -> some View {
    let shouldShowControls = activeGameStateManager.isGameActive && !game.isCompleted
    let isTimerPaused = !activeGameStateManager.isTimerRunning

    HStack(spacing: DesignSystem.Spacing.sm) {
      if shouldShowControls {
        Button(action: {
          onResetTimer()
        }) {
          Image(systemName: "arrow.counterclockwise")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(
              isTimerPaused ? .gray : DesignSystem.Colors.primary
            )
            .symbolEffect(.rotate, value: resetTrigger)
        }
        .buttonStyle(.plain)
        .disabled(isResetting || isToggling)
        .transition(.opacity.combined(with: .scale))
      }

      Spacer()

      if shouldShowControls {
        Button(action: {
          onToggleTimer()
        }) {
          HStack(spacing: 4) {
            Image(systemName: "timer")
              .font(.system(size: 12, weight: .semibold))
              .foregroundColor(
                isTimerPaused
                  ? .gray : DesignSystem.Colors.primary
              )

            Text(
              activeGameStateManager
                .formattedElapsedTimeWithCentiseconds
            )
            .font(
              .system(
                size: 14,
                weight: .semibold,
                design: .monospaced
              )
            )
            .foregroundColor(DesignSystem.Colors.textPrimary)
          }
        }
        .buttonStyle(.plain)
        .disabled(isToggling)
      } else {
        HStack(spacing: 4) {
          Image(systemName: "timer")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.gray)

          Text(
            activeGameStateManager
              .formattedElapsedTimeWithCentiseconds
          )
          .font(
            .system(
              size: 14,
              weight: .semibold,
              design: .monospaced
            )
          )
          .foregroundColor(DesignSystem.Colors.textSecondary)
        }
      }

      Spacer()

      if shouldShowControls {
        Button(action: {
          onToggleTimer()
        }) {
          Image(
            systemName: isTimerPaused ? "play.fill" : "pause.fill"
          )
          .font(.system(size: 12, weight: .semibold))
          .foregroundColor(
            isTimerPaused ? .gray : DesignSystem.Colors.primary
          )
          .symbolEffect(.bounce, value: playPauseTrigger)
        }
        .buttonStyle(.plain)
        .disabled(isToggling)
        .transition(.opacity.combined(with: .scale))
      }
    }
    .padding(.horizontal, DesignSystem.Spacing.sm)
    .padding(.vertical, DesignSystem.Spacing.xs)
    .glassEffect()
    .opacity(pulseAnimation ? 0.6 : 1.0)
    .animation(.easeInOut(duration: 0.3), value: pulseAnimation)
    .animation(.easeInOut(duration: 0.2), value: shouldShowControls)
  }

  // MARK: - Helper Functions

  private func isWinner(teamNumber: Int) -> Bool {
    guard game.isCompleted else { return false }
    let team1Score = game.score1
    let team2Score = game.score2
    return teamNumber == 1 ? (team1Score > team2Score) : (team2Score > team1Score)
  }

  private func teamScoreSection(
    teamNumber: Int,
    teamName: String,
    score: Int,
    color: Color,
    isServing: Bool
  ) -> some View {
    VStack(spacing: DesignSystem.Spacing.sm) {
      Text(teamName)
        .font(.caption)
        .fontWeight(.semibold)

      ZStack {
        VStack {
          Text("\(score)")
            .font(
              .system(size: 36, weight: .bold, design: .rounded)
            )
            .foregroundColor(color)
            .monospacedDigit()
            .contentTransition(.numericText())

          if score == 0 {
            Text("Tap")
              .font(.caption2)
              .fontWeight(.semibold)
              .foregroundColor(.secondary.opacity(0.6))
              .transition(.opacity)
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())

        if isServing {
          VStack {
            Text("SERVING")
              .font(.system(size: 10, weight: .semibold))
              .padding(.horizontal, DesignSystem.Spacing.xs)
              .padding(.vertical, 2)
              .glassEffect(.regular.tint(color.opacity(0.2)))

            Spacer()
          }
          .padding(.top, DesignSystem.Spacing.sm)
        }

        if score >= 10 && !game.isCompleted {
          VStack {
            Spacer()
            Text("GAME POINT")
              .font(.system(size: 10, weight: .semibold))
              .padding(.horizontal, DesignSystem.Spacing.xs)
              .padding(.vertical, 2)
              .glassEffect(.regular.tint(color.opacity(0.2)))
              .opacity(gamePointBreathing ? 0.6 : 1.0)
              .animation(
                .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: gamePointBreathing
              )
              .onAppear { gamePointBreathing = true }
              .onDisappear { gamePointBreathing = false }
          }
          .padding(.bottom, DesignSystem.Spacing.sm)
        } else if game.isCompleted && isWinner(teamNumber: teamNumber) {
          VStack {
            Spacer()
            Text("WINNER")
              .font(.system(size: 11, weight: .heavy))
              .padding(.horizontal, DesignSystem.Spacing.sm)
              .padding(.vertical, 3)
              .glassEffect(.regular.tint(color.opacity(0.3)))
              .scaleEffect(1.1)
          }
          .padding(.bottom, DesignSystem.Spacing.sm)
        }
      }
      .frame(maxWidth: .infinity)
      .frame(maxHeight: .infinity)
      .padding(.horizontal, DesignSystem.Spacing.xs)
      .glassEffect(
        .regular.tint(color.opacity(0.5)).interactive(),
        in: .rect(cornerRadius: 16.0)
      )
      .disabled(game.isCompleted || !activeGameStateManager.isGameActive)
      .onTapGesture {
        guard !game.isCompleted && activeGameStateManager.isGameActive else { return }
        onScorePoint(teamNumber)
        WKInterfaceDevice.current().play(.click)
      }
      .onTapGesture(count: 2) {
        guard !game.isCompleted && activeGameStateManager.isGameActive else { return }
        guard score > 0 else { return }
        onDecrementScore(teamNumber)
        WKInterfaceDevice.current().play(.click)
      }
      .gesture(
        DragGesture()
          .onEnded { value in
            guard !game.isCompleted && activeGameStateManager.isGameActive else { return }
            if value.translation.height < -30 {
              onScorePoint(teamNumber)
              WKInterfaceDevice.current().play(.click)
            } else if value.translation.height > 30 && score > 0 {
              onDecrementScore(teamNumber)
              WKInterfaceDevice.current().play(.click)
            }
          }
      )
      .scaleEffect(game.isCompleted || !activeGameStateManager.isGameActive ? 0.95 : 1.0)
      .opacity(game.isCompleted || !activeGameStateManager.isGameActive ? 0.6 : 1.0)
      .animation(.easeInOut(duration: 0.2), value: game.isCompleted)
      .animation(.easeInOut(duration: 0.2), value: activeGameStateManager.isGameActive)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}


