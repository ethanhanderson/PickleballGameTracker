//
//  GameHistoryRow.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 7/9/25.
//

import CorePackage
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
          .foregroundColor(DesignSystem.Colors.textOnColorMuted)
          .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
          .padding(.leading, DesignSystem.Spacing.sm)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, DesignSystem.Spacing.lg)
    .padding(.vertical, DesignSystem.Spacing.md)
    .glassEffect(
      .regular.tint(DesignSystem.Colors.gameType(game.gameType)),
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
          .font(DesignSystem.Typography.headline)
          .fontWeight(.bold)
          .foregroundColor(DesignSystem.Colors.textOnColor)
          .lineLimit(1)

        Text(compactFormattedDate)
          .font(DesignSystem.Typography.caption)
          .fontWeight(.medium)
          .foregroundColor(DesignSystem.Colors.textOnColorMuted)
          .lineLimit(1)
      }
    }
  }

  private var gameIcon: some View {
    Image(systemName: game.gameType.iconName)
      .font(.system(size: 24, weight: .medium))
      .foregroundStyle(DesignSystem.Colors.textOnColor)
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
          .font(DesignSystem.Typography.caption2)
          .fontWeight(.semibold)
          .foregroundColor(.white.opacity(0.8))

        scoreDisplay(
          score: game.score1,
          isWinning: game.score1 > game.score2
        )
      }

      VStack(spacing: DesignSystem.Spacing.xs) {
        Text(game.gameType.shortPlayerLabel2)
          .font(DesignSystem.Typography.caption2)
          .fontWeight(.semibold)
          .foregroundColor(.white.opacity(0.8))

        scoreDisplay(
          score: game.score2,
          isWinning: game.score2 > game.score1
        )
      }
    }
  }

  private func scoreDisplay(score: Int, isWinning: Bool) -> some View {
    Text("\(score)")
      .font(DesignSystem.Typography.title1)
      .fontWeight(.bold)
      .fontDesign(.rounded)
      .foregroundColor(isWinning ? DesignSystem.Colors.textOnColor : DesignSystem.Colors.textOnColorMuted)
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
        .foregroundColor(DesignSystem.Colors.textOnColorMuted)
        .frame(width: 16)

      Text(value)
        .font(DesignSystem.Typography.subheadline)
        .fontWeight(.semibold)
        .fontDesign(.rounded)
        .foregroundColor(DesignSystem.Colors.textOnColor)
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
