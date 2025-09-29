//
//  GameHistoryRow.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 7/9/25.
//

import GameTrackerCore
import SwiftUI

public struct GameHistoryCard: View {
  let game: Game
  let onTapped: (() -> Void)?

  public init(game: Game, onTapped: (() -> Void)? = nil) {
    self.game = game
    self.onTapped = onTapped
  }

  public var body: some View {
    Button(action: { onTapped?() }) {
      mainCard
    }
    .buttonStyle(.plain)
    .navigationButtonAccessibility(label: "Open Completed Game")
  }

  // MARK: - View Components

  private var mainCard: some View {
    ZStack {
      centerScoreDisplay
        .padding(.leading)

      HStack(alignment: .center) {
        leftSideContent
        Spacer()
        rightSideContent
        Image(systemName: "chevron.right")
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(Color.white.opacity(0.7))
          .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
          .padding(.leading, DesignSystem.Spacing.sm)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, DesignSystem.Spacing.lg)
    .padding(.vertical, DesignSystem.Spacing.md)
    .glassEffect(
      .regular.tint(
        {
          switch game.gameType {
          case .recreational: Color.blue
          case .tournament: Color.green
          case .training: Color.purple
          case .social: Color.orange
          case .custom: Color.red
          }
        }()
      ),
      in: RoundedRectangle(
        cornerRadius: DesignSystem.CornerRadius.xxl,
        style: .continuous
      )
    )
  }

  // MARK: - Left Side Content

  private var leftSideContent: some View {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
      gameIcon

      VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
        Text(game.gameType.displayName)
          .font(.headline)
          .fontWeight(.bold)
          .foregroundStyle(Color.white)
          .lineLimit(1)

        Text(compactFormattedDate)
          .font(.caption)
          .fontWeight(.medium)
          .foregroundStyle(Color.white.opacity(0.7))
          .lineLimit(1)
      }
    }
  }

  private var gameIcon: some View {
    Image(systemName: game.gameType.iconName)
      .font(.system(size: 24, weight: .medium))
      .foregroundStyle(Color.white)
      .shadow(color: .black.opacity(0.20), radius: 3, x: 0, y: 1)
      .frame(width: 32, height: 32)
  }

  private var compactFormattedDate: String {
    let formatter = DateFormatter()
    let calendar = Calendar.current
    let now = Date()

    if calendar.isDate(game.createdDate, inSameDayAs: now) {
      formatter.dateFormat = "h:mm a"
      return "Today \(formatter.string(from: game.createdDate))"
    } else if calendar.isDate(
      game.createdDate,
      inSameDayAs: calendar.date(byAdding: .day, value: -1, to: now)
        ?? now
    ) {
      return "Yesterday"
    } else if calendar.dateInterval(of: .weekOfYear, for: now)?.contains(
      game.createdDate
    ) == true {
      formatter.dateFormat = "EEE"
      return formatter.string(from: game.createdDate)
    } else if calendar.component(.year, from: game.createdDate)
      == calendar.component(.year, from: now)
    {
      formatter.dateFormat = "MMM d"
      return formatter.string(from: game.createdDate)
    } else {
      formatter.dateFormat = "MM/dd/yy"
      return formatter.string(from: game.createdDate)
    }
  }

  // MARK: - Center Score Display

  private var centerScoreDisplay: some View {
    HStack {
      VStack(spacing: DesignSystem.Spacing.xs) {
        Text(game.gameType.shortPlayerLabel1)
          .font(.caption2)
          .fontWeight(.semibold)
          .foregroundStyle(.white.opacity(0.8))

        scoreDisplay(
          score: game.score1,
          isWinning: game.score1 > game.score2
        )
      }

      VStack(spacing: DesignSystem.Spacing.xs) {
        Text(game.gameType.shortPlayerLabel2)
          .font(.caption2)
          .fontWeight(.semibold)
          .foregroundStyle(.white.opacity(0.8))

        scoreDisplay(
          score: game.score2,
          isWinning: game.score2 > game.score1
        )
      }
    }
  }

  private func scoreDisplay(score: Int, isWinning: Bool) -> some View {
    Text("\(score)")
      .font(.title)
      .fontWeight(.bold)
      .fontDesign(.rounded)
      .foregroundStyle(isWinning ? Color.white : Color.white.opacity(0.7))
      .monospacedDigit()
      .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
      .frame(width: 45, alignment: .center)
  }

  // MARK: - Right Side Content

  private var rightSideContent: some View {
    VStack(alignment: .trailing, spacing: DesignSystem.Spacing.sm) {
      rightStatItem(
        icon: "clock.fill",
        value: game.formattedDuration ?? "—"
      )

      rightStatItem(
        icon: game.isCompleted ? "trophy.fill" : "chart.bar.fill",
        value: winnerText
      )

      if game.totalRallies > 0 {
        rightStatItem(
          icon: "arrow.triangle.2.circlepath",
          value: "\(game.totalRallies)"
        )
      }
    }
  }

  private func rightStatItem(icon: String, value: String) -> some View {
    HStack(spacing: DesignSystem.Spacing.xs) {
      Image(systemName: icon)
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(Color.white.opacity(0.7))
        .frame(width: 16)

      Text(value)
        .font(.subheadline)
        .fontWeight(.semibold)
        .fontDesign(.rounded)
        .foregroundStyle(Color.white)
        .lineLimit(1)
    }
  }

  private var winnerText: String {
    if game.isCompleted, let winner = game.winner {
      switch winner {
      case game.gameType.playerLabel1: return "P1"
      case game.gameType.playerLabel2: return "P2"
      default: return "Tie"
      }
    } else {
      return "\(abs(game.score1 - game.score2))"
    }
  }
}

#Preview("Game History Rows") {
  VStack(spacing: 16) {
    GameHistoryCard(game: PreviewGameData.completedGame)
    GameHistoryCard(game: PreviewGameData.midGame)
    GameHistoryCard(game: PreviewGameData.highScoreGame)
  }
  .padding()
}
