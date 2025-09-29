//
//  GameTypeDetails.swift
//

import GameTrackerCore
import SwiftUI

public struct GameTypeDetails: View {
  let gameType: GameType

  public var body: some View {
    HStack(spacing: DesignSystem.Spacing.md) {
      GameDetailInfoCard(
        title: "Players",
        value: gameType.playerCountValue,
        gradient: gameType.color.gradient,
        size: .regular,
        iconSystemName: "person.2.fill",
        style: .iconLabelValue,
        accessibilityIdentifier: "gameType.details.players"
      )

      GameDetailInfoCard(
        title: "Minutes",
        value: gameType.estimatedTimeValue,
        gradient: gameType.color.gradient,
        size: .regular,
        iconSystemName: "clock.fill",
        style: .iconLabelValue,
        accessibilityIdentifier: "gameType.details.minutes"
      )

      GameDetailInfoCard(
        title: "Level",
        gradient: gameType.color.gradient,
        size: .regular,
        iconSystemName: "gauge.with.dots.needle.bottom.50percent",
        style: .iconLabelValue,
        accessibilityIdentifier: "gameType.details.level"
      ) {
        Image(systemName: "chart.bar.fill", variableValue: gameType.difficultyFillProgress)
          .foregroundStyle(.primary)
      }
    }
  }
}

#Preview("Recreational Type Details") {
  GameTypeDetails(gameType: PreviewGameData.midGame.gameType)
    .padding()
    .accentColor(.green)
}
