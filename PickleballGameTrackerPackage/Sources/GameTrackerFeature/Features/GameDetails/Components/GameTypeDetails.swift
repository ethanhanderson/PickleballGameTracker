//
//  GameTypeDetails.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 7/9/25.
//

import PickleballGameTrackerCorePackage
import SwiftUI

public struct GameTypeDetails: View {
  let gameType: GameType

  public var body: some View {
    HStack(spacing: DesignSystem.Spacing.md) {
      // Players card
      VStack(spacing: DesignSystem.Spacing.xs) {
        Image(systemName: "person.2.fill")
          .font(.system(size: 20, weight: .medium))
          .foregroundStyle(DesignSystem.Colors.gameType(gameType).gradient)
          .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)

        Text("Players")
          .font(DesignSystem.Typography.caption)
          .fontWeight(.medium)
          .foregroundStyle(.secondary)

        Text(gameType.playerCountValue)
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.primary)
      }
      .frame(maxWidth: .infinity)
      .padding(DesignSystem.Spacing.md)
      .glassEffect(
        .regular.tint(DesignSystem.Colors.gameType(gameType).opacity(0.4)),
        in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
      )

      // Play Time card
      VStack(spacing: DesignSystem.Spacing.xs) {
        Image(systemName: "clock.fill")
          .font(.system(size: 20, weight: .medium))
          .foregroundStyle(DesignSystem.Colors.gameType(gameType).gradient)
          .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)

        Text(gameType.timeUnitLabel)
          .font(DesignSystem.Typography.caption)
          .fontWeight(.medium)
          .foregroundStyle(.secondary)

        Text(gameType.estimatedTimeValue)
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.primary)
      }
      .frame(maxWidth: .infinity)
      .padding(DesignSystem.Spacing.md)
      .glassEffect(
        .regular.tint(DesignSystem.Colors.gameType(gameType).opacity(0.4)),
        in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
      )

      // Skill Level card
      VStack(spacing: DesignSystem.Spacing.xs) {
        Image(systemName: "star.fill")
          .font(.system(size: 20, weight: .medium))
          .foregroundStyle(DesignSystem.Colors.gameType(gameType).gradient)
          .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)

        Text("Level")
          .font(DesignSystem.Typography.caption)
          .fontWeight(.medium)
          .foregroundStyle(.secondary)

        Image(
          systemName: "chart.bar.fill",
          variableValue: gameType.difficultyFillProgress
        )
        .font(.system(size: 18, weight: .bold))
        .foregroundStyle(.primary)
      }
      .frame(maxWidth: .infinity)
      .padding(DesignSystem.Spacing.md)
      .glassEffect(
        .regular.tint(DesignSystem.Colors.gameType(gameType).opacity(0.4)),
        in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
      )
    }
  }
}

#Preview("Recreational Type Details") {
  GameTypeDetails(gameType: .recreational)
    .padding()
}
