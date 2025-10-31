import GameTrackerCore
import SwiftData
import SwiftUI

struct ScoreControlsView: View {
  @Bindable var game: Game
  @Environment(\.modelContext) private var modelContext
  @Environment(\.isLuminanceReduced) private var isLuminanceReduced
  let liveGameStateManager: LiveGameStateManager
  let onScorePoint: (Int) -> Void
  let onDecrementScore: (Int) -> Void
  let onSetServer: ((Int) -> Void)?
  let onHapticFeedback: () -> Void

  // Removed timer controls; display-only

  @State private var gamePointBreathing = false
  @State private var previousScore1: Int = 0
  @State private var previousScore2: Int = 0
  
  // Badge visibility states
  @State private var matchLabelVisible1: Bool = false
  @State private var serveLabelVisible1: Bool = false
  @State private var matchLabelVisible2: Bool = false
  @State private var serveLabelVisible2: Bool = false
  @State private var hasAppeared: Bool = false
  @State private var matchAnimationTick: Int = 0
  @State private var wasJustResumed: Bool = false

  var body: some View {
    VStack(spacing: DesignSystem.Spacing.sm) {
      timerDisplay()

      HStack(spacing: DesignSystem.Spacing.sm) {
        teamScoreSection(
          teamNumber: 1,
          teamName: teamName(for: 1),
          score: game.score1,
          color: game.teamTintColor(for: 1, context: modelContext),
          isServing: game.currentServer == 1 && !game.isCompleted,
          previousScore: previousScore1,
          matchLabelVisible: $matchLabelVisible1,
          serveLabelVisible: $serveLabelVisible1,
          onScoreChange: { newScore in
            previousScore1 = newScore
          }
        )

        teamScoreSection(
          teamNumber: 2,
          teamName: teamName(for: 2),
          score: game.score2,
          color: game.teamTintColor(for: 2, context: modelContext),
          isServing: game.currentServer == 2 && !game.isCompleted,
          previousScore: previousScore2,
          matchLabelVisible: $matchLabelVisible2,
          serveLabelVisible: $serveLabelVisible2,
          onScoreChange: { newScore in
            previousScore2 = newScore
          }
        )
      }
      .animation(
        isLuminanceReduced ? nil : .spring(response: 0.3, dampingFraction: 0.8),
        value: game.score1
      )
      .animation(
        isLuminanceReduced ? nil : .spring(response: 0.3, dampingFraction: 0.8),
        value: game.score2
      )
      .animation(
        isLuminanceReduced ? nil : .spring(response: 0.3, dampingFraction: 0.8),
        value: game.currentServer
      )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .contentShape(.rect)
  }

  // MARK: - Timer Display (read-only)

  @ViewBuilder
  private func timerDisplay() -> some View {
    let isPlaying = liveGameStateManager.isGameLive

    HStack(spacing: 4) {
      Image(systemName: "timer")
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(isLuminanceReduced ? .secondary : .primary)

      Text(isLuminanceReduced
           ? liveGameStateManager.formattedElapsedTime
           : liveGameStateManager.formattedElapsedTimeWithCentiseconds)
        .font(.system(size: 14, weight: .semibold, design: .monospaced))
        .foregroundStyle(isLuminanceReduced ? .secondary : .primary)
    }
    .frame(maxWidth: .infinity)
    .scaleEffect(isPlaying ? 1.0 : 0.95)
    .padding(.horizontal, DesignSystem.Spacing.sm)
    .padding(.vertical, DesignSystem.Spacing.xs)
    .glassEffect()
    .opacity(game.isCompleted ? 0.6 : 1.0)
    .animation(isLuminanceReduced ? nil : .easeInOut(duration: 0.2), value: game.isCompleted)
  }

  // MARK: - Helper Functions

  private func teamName(for teamNumber: Int) -> String {
    let teamConfigs = game.teamsWithLabels(context: modelContext)
    if let config = teamConfigs.first(where: { $0.teamNumber == teamNumber }) {
      return config.teamName
    }
    return teamNumber == 1 ? "Team 1" : "Team 2"
  }
  
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
    isServing: Bool,
    previousScore: Int,
    matchLabelVisible: Binding<Bool>,
    serveLabelVisible: Binding<Bool>,
    onScoreChange: @escaping (Int) -> Void
  ) -> some View {
    let isAtMatchPoint = game.isAtMatchPoint(for: teamNumber)
    let servingIndicatorVisible = game.shouldShowServingIndicator(for: teamNumber)
    let servingAnimate = game.gameState == .playing && !wasJustResumed
    let isWinningTeam = game.isWinningTeam(teamNumber: teamNumber)
    let scoreIsDecreasing = score < previousScore
    
    return VStack(spacing: DesignSystem.Spacing.sm) {
      if game.participantMode == .teams {
        Text(teamName)
          .font(.caption)
          .fontWeight(.semibold)
          .multilineTextAlignment(.center)
          .lineLimit(2)
          .fixedSize(horizontal: false, vertical: true)
          .frame(maxWidth: .infinity)
      } else {
        Text(teamName)
          .font(.caption)
          .fontWeight(.semibold)
          .multilineTextAlignment(.center)
          .lineLimit(1)
      }

      ZStack {
        // Main score display
        Text("\(score)")
          .font(
            .system(
              size: 44,
              weight: .bold,
              design: .rounded
            )
          )
          .foregroundStyle(.primary)
          .monospacedDigit()
          .scaleEffect(liveGameStateManager.isGameLive ? 1.0 : 0.85)
          .opacity(liveGameStateManager.isGameLive ? 1.0 : 0.5)
          .contentTransition(.numericText(countsDown: scoreIsDecreasing))
          .animation(isLuminanceReduced ? nil : .easeInOut(duration: 0.3), value: liveGameStateManager.isGameLive)
          .accessibilityIdentifier(
            "WatchScoreCard.score.team\(teamNumber)"
          )

        // Status indicators in top trailing corner
        VStack {
          HStack {
            Spacer()
            HStack(
              spacing: (matchLabelVisible.wrappedValue || serveLabelVisible.wrappedValue)
                ? DesignSystem.Spacing.xs : 4
            ) {
              WatchStatusIndicatorCapsule(
                icon: "target",
                label: "MATCH POINT",
                tint: color.opacity(0.14),
                visible: isAtMatchPoint,
                animate: !hasAppeared,
                triggerAnimationId: matchAnimationTick,
                accessibilityId: "WatchScoreCard.status.matchPoint.team\(teamNumber)",
                onLabelVisibilityChange: { isVisible in
                  matchLabelVisible.wrappedValue = isVisible
                },
                shouldDefer: {
                  (isServing && !game.isCompleted)
                    && serveLabelVisible.wrappedValue
                }
              )

              WatchStatusIndicatorCapsule(
                icon: "figure.pickleball",
                label: "SERVING",
                tint: color.opacity(0.3),
                visible: servingIndicatorVisible,
                animate: servingAnimate,
                triggerAnimationId: 0,
                accessibilityId: "WatchScoreCard.status.serving.team\(teamNumber)",
                onLabelVisibilityChange: { isVisible in
                  serveLabelVisible.wrappedValue = isVisible
                },
                shouldDefer: {
                  isAtMatchPoint && matchLabelVisible.wrappedValue
                }
              )
            }
            .animation(
              isLuminanceReduced ? nil : .snappy(duration: 0.25, extraBounce: 0.0),
              value: matchLabelVisible.wrappedValue || serveLabelVisible.wrappedValue
            )
            .padding(.top, DesignSystem.Spacing.xs)
            .padding(.trailing, DesignSystem.Spacing.xs)
          }
          Spacer()
        }

        // Winner badge in bottom center
        VStack {
          Spacer()
          HStack {
            Spacer()
            if game.isCompleted, isWinningTeam {
              WatchWinnerChip(game: game, teamTintColor: color)
            }
            Spacer()
          }
          .padding(.bottom, DesignSystem.Spacing.sm)
        }
      }
      .frame(maxWidth: .infinity)
      .frame(maxHeight: .infinity)
      .padding(.horizontal, DesignSystem.Spacing.xs)
      .glassEffect(
        liveGameStateManager.isGameLive
          ? .regular.tint(color.opacity(0.5)).interactive()
          : .regular.tint(color.opacity(0.25)),
        in: .rect(cornerRadius: 16.0)
      )
      .scaleEffect(game.isCompleted ? 0.95 : 1.0)
      .opacity(game.isCompleted ? 0.6 : 1.0)
      .animation(isLuminanceReduced ? nil : .easeInOut(duration: 0.2), value: game.isCompleted)
      .animation(isLuminanceReduced ? nil : .easeInOut(duration: 0.3), value: liveGameStateManager.isGameLive)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .disabled(game.isCompleted)
    .contentShape(.rect)
    .onTapGesture {
      guard !game.isCompleted else { return }
      
      // If not serving, set server first, then score
      if game.currentServer != teamNumber {
        onSetServer?(teamNumber)
      }
      
      // Always score the point
      onScorePoint(teamNumber)
      onHapticFeedback()
      onScoreChange(score + 1)
    }
    .onTapGesture(count: 2) {
      guard !game.isCompleted else { return }
      guard score > 0 else { return }
      onDecrementScore(teamNumber)
      onHapticFeedback()
      onScoreChange(score - 1)
    }
    .gesture(
      DragGesture()
        .onEnded { value in
          guard !game.isCompleted else { return }
          if value.translation.height < -30 {
            onScorePoint(teamNumber)
            onHapticFeedback()
            onScoreChange(score + 1)
          } else if value.translation.height > 30 && score > 0 {
            onDecrementScore(teamNumber)
            onHapticFeedback()
            onScoreChange(score - 1)
          }
        }
    )
      .onAppear {
        previousScore1 = game.score1
        previousScore2 = game.score2
        hasAppeared = true
      }
      .onChange(of: game.score1) { _, newScore in
        previousScore1 = newScore
        if newScore != previousScore1 {
          matchAnimationTick += 1
        }
      }
      .onChange(of: game.score2) { _, newScore in
        previousScore2 = newScore
        if newScore != previousScore2 {
          matchAnimationTick += 1
        }
      }
      .onChange(of: liveGameStateManager.isGameLive) { _, isLive in
        if !isLive {
          wasJustResumed = true
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            wasJustResumed = false
          }
        }
      }
  }
}
