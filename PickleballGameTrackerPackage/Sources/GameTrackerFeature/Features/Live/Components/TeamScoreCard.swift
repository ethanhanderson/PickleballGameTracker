//
//  TeamScoreCard.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 7/9/25.
//

import CorePackage
import SwiftData
import SwiftUI

@MainActor
struct TeamScoreCard: View {
  @Bindable var game: Game
  let teamNumber: Int
  let teamName: String
  let gameManager: SwiftDataGameManager
  let isGameActive: Bool

  @State private var scoreAnimation: Bool = false
  @State private var cardPulse: Bool = false
  @State private var isIncreasing: Bool = true
  @State private var matchPointPulse: Bool = false

  private var teamColor: Color {
    teamNumber == 1
      ? DesignSystem.Colors.scorePlayer1
      : DesignSystem.Colors.scorePlayer2
  }

  private var score: Int {
    teamNumber == 1 ? game.score1 : game.score2
  }

  private var playerCountIcon: String {
    let teamSize = game.effectiveTeamSize
    switch teamSize {
    case 1:
      return "person.fill"
    case 2:
      return "person.2.fill"
    default:
      return "person.3.fill"
    }
  }

  private var isAtMatchPoint: Bool {
    game.isAtMatchPoint(team: teamNumber)
  }

  private var isServing: Bool {
    game.currentServer == teamNumber
  }

  private var isWinningTeam: Bool {
    guard game.isCompleted else { return false }
    return (teamNumber == 1 && game.score1 > game.score2)
      || (teamNumber == 2 && game.score2 > game.score1)
  }

  var body: some View {
    VStack(spacing: DesignSystem.Spacing.sm) {
      // Header with team name and info button
      HStack {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
          HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: playerCountIcon)
              .font(.system(size: 14, weight: .medium))
              .foregroundStyle(teamColor.gradient)

            Text(teamName)
              .font(DesignSystem.Typography.headline)
              .fontWeight(.semibold)
              .foregroundStyle(.primary)
          }

          // Match point badge now overlaid in the score area via ZStack below
        }

        Spacer()

        Button {
          // TODO: Show team info
        } label: {
          Image(systemName: "info.circle")
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.secondary)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityIdentifier("TeamScoreCard.infoButton.team\(teamNumber)")
      }

      ZStack {
        ScorePill(
          score: score,
          scale: scoreAnimation ? (isIncreasing ? 1.15 : 0.9) : (isGameActive ? 1.0 : 0.85),
          opacity: isGameActive ? 1.0 : 0.6
        )
        .animation(.easeInOut(duration: 0.2), value: scoreAnimation)
        .animation(.easeInOut(duration: 0.3), value: isGameActive)

        VStack {
          if isAtMatchPoint && isGameActive {
            MatchPointBadge()
              .opacity(matchPointPulse ? 0.7 : 1.0)
              .onAppear {
                if isAtMatchPoint && isGameActive {
                  matchPointPulse = true
                }
              }
              .onChange(of: isAtMatchPoint) { _, newValue in
                if newValue && isGameActive {
                  matchPointPulse = true
                } else {
                  matchPointPulse = false
                }
              }
              .onChange(of: isGameActive) { _, newValue in
                if !newValue {
                  matchPointPulse = false
                } else if isAtMatchPoint {
                  matchPointPulse = true
                }
              }
          }

          Spacer()

          if game.isCompleted {
            if isWinningTeam {
              WinnerChip(game: game)
            }
          } else if isServing && game.effectiveTeamSize > 1 {
            ServingPlayerBezel(
              game: game,
              teamNumber: teamNumber,
              gameManager: gameManager
            )
            .disabled(isGameActive)
          } else if isServing && game.effectiveTeamSize == 1 {
            ServeIndicator(isServing: true, teamColor: teamColor)
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.top, DesignSystem.Spacing.lg)
    .padding(.bottom, DesignSystem.Spacing.md)
    .padding(.horizontal, DesignSystem.Spacing.lg)
    .glassEffect(
      .regular.tint(DesignSystem.Colors.gameType(game.gameType).opacity(isGameActive ? 0.4 : 0.25)),
      in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.cardRounded, style: .continuous)
    )
    .contentShape(
      RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.cardRounded, style: .continuous)
    )
    .opacity(cardPulse ? 0.7 : 1.0)
    .animation(.easeInOut(duration: 0.15), value: cardPulse)
    .onTapGesture {
      if isGameActive && !game.isCompleted {
        incrementScore()
      }
    }
    .onTapGesture(count: 2) {
      if isGameActive && !game.isCompleted {
        decrementScore()
      }
    }
    .gesture(
      DragGesture(minimumDistance: 20)
        .onEnded { value in
          guard isGameActive && !game.isCompleted else { return }
          let verticalMovement = value.translation.height
          if verticalMovement < -20 {
            // Swipe up - increment
            incrementScore()
          } else if verticalMovement > 20 {
            // Swipe down - decrement
            decrementScore()
          }
        }
    )
    .accessibilityIdentifier("TeamScoreCard.card.team\(teamNumber)")
  }

  // MARK: - Score Management

  private func incrementScore() {
    isIncreasing = true
    triggerScoreAnimation()

    // Delegate scoring to gameManager for proper business logic
    Task {
      do {
        try await gameManager.scorePoint(for: teamNumber, in: game)
      } catch {
        Log.error(
          error,
          event: .gamePaused,
          context: .current(gameId: game.id),
          metadata: ["action": "scorePoint", "team": "\(teamNumber)"]
        )
      }
    }
  }

  private func decrementScore() {
    // Prevent negative scores
    let currentScore = teamNumber == 1 ? game.score1 : game.score2
    guard currentScore > 0 else { return }

    isIncreasing = false
    triggerScoreAnimation()

    // Delegate to gameManager so that active game delegate is notified and sync occurs
    Task {
      do {
        try await gameManager.decrementScore(for: teamNumber, in: game)
      } catch {
        Log.error(
          error,
          event: .gamePaused,
          context: .current(gameId: game.id),
          metadata: [
            "action": "decrementScore", "team": "\(teamNumber)",
          ]
        )
      }
    }
  }

  private func triggerScoreAnimation() {
    // Trigger score scale animation
    withAnimation(.easeInOut(duration: 0.2)) {
      scoreAnimation = true
    }

    // Trigger card background pulse
    withAnimation(.easeInOut(duration: 0.15)) {
      cardPulse = true
    }

    // Reset animations
    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(200))
      scoreAnimation = false

      try? await Task.sleep(for: .milliseconds(50))
      cardPulse = false
    }
  }
}

// MARK: - WinnerChip Component

struct WinnerChip: View {
  @Bindable var game: Game

  var body: some View {
    HStack(spacing: DesignSystem.Spacing.xs) {
      Image(systemName: "crown.fill")
        .font(.system(size: 14, weight: .bold))
        .foregroundColor(.white)

      Text("WINNER")
        .font(.system(size: 12, weight: .bold, design: .rounded))
        .foregroundColor(.white)
    }
    .padding(.horizontal, DesignSystem.Spacing.md)
    .padding(.vertical, DesignSystem.Spacing.sm)
    .glassEffect(.regular.tint(DesignSystem.Colors.gameType(game.gameType).opacity(0.8)))
  }
}

// MARK: - MatchPointBadge Component

private struct MatchPointBadge: View {
  var body: some View {
    HStack(spacing: DesignSystem.Spacing.xs) {
      Image(systemName: "target")
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(.primary)
      Text("MATCH POINT")
        .font(.system(size: 11, weight: .bold, design: .rounded))
        .foregroundStyle(.primary)
    }
    .padding(.horizontal, DesignSystem.Spacing.sm)
    .padding(.vertical, DesignSystem.Spacing.xs)
    .glassEffect(.regular.tint(.white.opacity(0.2)), in: Capsule())
    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: UUID())
  }
}

// MARK: - ServingPlayerBezel Component

struct ServingPlayerBezel: View {
  @Bindable var game: Game
  let teamNumber: Int
  let gameManager: SwiftDataGameManager

  // Local state for the picker
  @State private var selectedPlayer: Int = 1

  var body: some View {
    VStack(spacing: DesignSystem.Spacing.xs) {
      Text("SERVING")
        .font(.system(size: 11, weight: .bold, design: .rounded))
        .foregroundColor(.secondary)
        .tracking(1.0)

      Picker("Serving Player", selection: $selectedPlayer) {
        Text("Player 1")
          .fontWeight(.semibold)
          .tag(1)
        Text("Player 2")
          .fontWeight(.semibold)
          .tag(2)
      }
      .pickerStyle(.segmented)
      .onChange(of: selectedPlayer) { _, newPlayer in
        switchToPlayer(newPlayer)
      }
      .onAppear {
        // Sync local state with game state
        selectedPlayer = game.serverNumber
      }
      .onChange(of: game.serverNumber) { _, newServerNumber in
        // Keep local state in sync with game state changes
        if selectedPlayer != newServerNumber {
          selectedPlayer = newServerNumber
        }
      }
    }
  }

  private func switchToPlayer(_ player: Int) {
    Task {
      do {
        try await gameManager.setServingPlayer(to: player, in: game)
      } catch {
        Log.error(
          error,
          event: .serverSwitched,
          context: .current(gameId: game.id),
          metadata: [
            "action": "setServingPlayer", "player": "\(player)",
          ]
        )
      }
    }
  }
}

#Preview {
  VStack(spacing: DesignSystem.Spacing.md) {
    TeamScoreCard(
      game: PreviewGameData.midGame,
      teamNumber: 1,
      teamName: PreviewGameData.teamNames.team1,
      gameManager: PreviewGameData.gameManager,
      isGameActive: true
    )

    TeamScoreCard(
      game: PreviewGameData.midGame,
      teamNumber: 2,
      teamName: PreviewGameData.teamNames.team2,
      gameManager: PreviewGameData.gameManager,
      isGameActive: true
    )
  }
  .padding()
}

#Preview("Game Paused") {
  VStack(spacing: DesignSystem.Spacing.md) {
    TeamScoreCard(
      game: PreviewGameData.pausedGame,
      teamNumber: 1,
      teamName: PreviewGameData.teamNames.team1,
      gameManager: PreviewGameData.gameManager,
      isGameActive: false
    )

    TeamScoreCard(
      game: PreviewGameData.pausedGame,
      teamNumber: 2,
      teamName: PreviewGameData.teamNames.team2,
      gameManager: PreviewGameData.gameManager,
      isGameActive: false
    )
  }
  .padding()
}

#Preview("Match Point") {
  VStack(spacing: DesignSystem.Spacing.md) {
    TeamScoreCard(
      game: PreviewGameData.matchPointGame,
      teamNumber: 1,
      teamName: PreviewGameData.teamNames.team1,
      gameManager: PreviewGameData.gameManager,
      isGameActive: true
    )

    TeamScoreCard(
      game: PreviewGameData.matchPointGame,
      teamNumber: 2,
      teamName: PreviewGameData.teamNames.team2,
      gameManager: PreviewGameData.gameManager,
      isGameActive: true
    )
  }
  .padding()
}

#Preview("Serving") {
  VStack(spacing: DesignSystem.Spacing.md) {
    TeamScoreCard(
      game: PreviewGameData.team1Player1Serving,
      teamNumber: 1,
      teamName: PreviewGameData.teamNames.team1,
      gameManager: PreviewGameData.gameManager,
      isGameActive: true
    )

    TeamScoreCard(
      game: PreviewGameData.team1Player1Serving,
      teamNumber: 2,
      teamName: PreviewGameData.teamNames.team2,
      gameManager: PreviewGameData.gameManager,
      isGameActive: true
    )
  }
  .padding()
}

#Preview("Completed Game") {
  VStack(spacing: DesignSystem.Spacing.md) {
    TeamScoreCard(
      game: PreviewGameData.completedGame,
      teamNumber: 1,
      teamName: PreviewGameData.teamNames.team1,
      gameManager: PreviewGameData.gameManager,
      isGameActive: false
    )

    TeamScoreCard(
      game: PreviewGameData.completedGame,
      teamNumber: 2,
      teamName: PreviewGameData.teamNames.team2,
      gameManager: PreviewGameData.gameManager,
      isGameActive: false
    )
  }
  .padding()
}
