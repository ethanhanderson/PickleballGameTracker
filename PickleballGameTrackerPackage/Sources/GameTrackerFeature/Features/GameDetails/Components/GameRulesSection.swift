//
//  GameRulesSection.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 7/9/25.
//

import CorePackage
import SwiftUI

public struct GameRulesSection: View {
  let gameType: GameType
  @Binding var winningScore: Int
  @Binding var winByTwo: Bool
  @Binding var kitchenRule: Bool
  @Binding var doubleBounceRule: Bool
  @Binding var letServes: Bool
  @Binding var servingRotation: ServingRotation
  @Binding var sideSwitchingRule: SideSwitchingRule
  @Binding var hasTimeLimit: Bool

  public init(
    gameType: GameType,
    winningScore: Binding<Int>,
    winByTwo: Binding<Bool>,
    kitchenRule: Binding<Bool>,
    doubleBounceRule: Binding<Bool>,
    letServes: Binding<Bool>,
    servingRotation: Binding<ServingRotation>,
    sideSwitchingRule: Binding<SideSwitchingRule>,
    hasTimeLimit: Binding<Bool>
  ) {
    self.gameType = gameType
    self._winningScore = winningScore
    self._winByTwo = winByTwo
    self._kitchenRule = kitchenRule
    self._doubleBounceRule = doubleBounceRule
    self._letServes = letServes
    self._servingRotation = servingRotation
    self._sideSwitchingRule = sideSwitchingRule
    self._hasTimeLimit = hasTimeLimit
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
      Text("Game Rules")
        .font(DesignSystem.Typography.title3)
        .fontWeight(.semibold)
        .foregroundColor(DesignSystem.Colors.textPrimary)

      VStack(spacing: DesignSystem.Spacing.md) {
        HStack(spacing: DesignSystem.Spacing.md) {
          RuleInfoCard(
            title: "Winning Score",
            iconName: "target",
            gradient: DesignSystem.Colors.gameType(gameType).gradient
          ) {
            Text("\(winningScore)")
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(.primary)
          }

          RuleInfoCard(
            title: "Win by Two",
            iconName: winByTwo ? "plus.circle.fill" : "minus.circle.fill",
            gradient: DesignSystem.Colors.gameType(gameType).gradient
          ) {
            Text(winByTwo ? "Yes" : "No")
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(.primary)
          }
        }

        HStack(spacing: DesignSystem.Spacing.md) {
          RuleInfoCard(
            title: "Kitchen Rule",
            iconName: kitchenRule ? "checkmark.circle.fill" : "xmark.circle.fill",
            gradient: DesignSystem.Colors.gameType(gameType).gradient
          ) {
            Text(kitchenRule ? "Yes" : "No")
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(.primary)
          }

          RuleInfoCard(
            title: "Double Bounce",
            iconName: doubleBounceRule ? "arrow.clockwise.circle.fill" : "xmark.circle.fill",
            gradient: DesignSystem.Colors.gameType(gameType).gradient
          ) {
            Text(doubleBounceRule ? "Yes" : "No")
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(.primary)
          }
        }

        HStack(spacing: DesignSystem.Spacing.md) {
          RuleInfoCard(
            title: "Serving",
            iconName: "arrow.triangle.2.circlepath",
            gradient: DesignSystem.Colors.gameType(gameType).gradient
          ) {
            Text(servingRotation == .standard ? "Standard" : "Custom")
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(.primary)
          }

          RuleInfoCard(
            title: "Side Switch",
            iconName: "arrow.left.arrow.right",
            gradient: DesignSystem.Colors.gameType(gameType).gradient
          ) {
            Text(sideSwitchingRule == .at6Points ? "At 6" : "Custom")
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(.primary)
          }
        }
      }
    }
  }
}

#Preview("Default Rules") {
  GameRulesSection(
    gameType: .recreational,
    winningScore: .constant(11),
    winByTwo: .constant(true),
    kitchenRule: .constant(true),
    doubleBounceRule: .constant(true),
    letServes: .constant(false),
    servingRotation: .constant(.standard),
    sideSwitchingRule: .constant(.at6Points),
    hasTimeLimit: .constant(false)
  )
  .padding()
}
