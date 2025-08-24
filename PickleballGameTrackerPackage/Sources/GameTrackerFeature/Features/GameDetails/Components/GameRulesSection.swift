//
//  GameRulesSection.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 7/9/25.
//

import PickleballGameTrackerCorePackage
import SwiftUI

public struct GameRulesSection: View {
  @Binding var winningScore: Int
  @Binding var winByTwo: Bool
  @Binding var kitchenRule: Bool
  @Binding var doubleBounceRule: Bool
  @Binding var letServes: Bool
  @Binding var servingRotation: ServingRotation
  @Binding var sideSwitchingRule: SideSwitchingRule
  @Binding var hasTimeLimit: Bool

  public init(
    winningScore: Binding<Int>,
    winByTwo: Binding<Bool>,
    kitchenRule: Binding<Bool>,
    doubleBounceRule: Binding<Bool>,
    letServes: Binding<Bool>,
    servingRotation: Binding<ServingRotation>,
    sideSwitchingRule: Binding<SideSwitchingRule>,
    hasTimeLimit: Binding<Bool>
  ) {
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
          // Winning Score Rule
          VStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: "target")
              .font(.system(size: 20, weight: .medium))
              .foregroundStyle(DesignSystem.Colors.ruleInfo.gradient)
              .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)

            Text("Winning Score")
              .font(DesignSystem.Typography.caption)
              .fontWeight(.medium)
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)

            Text("\(winningScore)")
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(.primary)
          }
          .frame(maxWidth: .infinity)
          .padding(DesignSystem.Spacing.md)
          .glassEffect(
            .regular.tint(DesignSystem.Colors.ruleInfo.opacity(0.4)),
            in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl))

          // Win by Two Rule
          VStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: winByTwo ? "plus.circle.fill" : "minus.circle.fill")
              .font(.system(size: 20, weight: .medium))
              .foregroundStyle(
                (winByTwo ? DesignSystem.Colors.rulePositive : DesignSystem.Colors.ruleCaution)
                  .gradient
              )
              .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)

            Text("Win by Two")
              .font(DesignSystem.Typography.caption)
              .fontWeight(.medium)
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)

            Text(winByTwo ? "Yes" : "No")
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(.primary)
          }
          .frame(maxWidth: .infinity)
          .padding(DesignSystem.Spacing.md)
          .glassEffect(
            .regular.tint(
              (winByTwo ? DesignSystem.Colors.rulePositive : DesignSystem.Colors.ruleCaution)
                .opacity(0.4)),
            in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl))
        }

        HStack(spacing: DesignSystem.Spacing.md) {
          // Kitchen Rule
          VStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: kitchenRule ? "checkmark.circle.fill" : "xmark.circle.fill")
              .font(.system(size: 20, weight: .medium))
              .foregroundStyle(
                (kitchenRule ? DesignSystem.Colors.ruleCaution : DesignSystem.Colors.ruleNegative)
                  .gradient
              )
              .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)

            Text("Kitchen Rule")
              .font(DesignSystem.Typography.caption)
              .fontWeight(.medium)
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)

            Text(kitchenRule ? "Yes" : "No")
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(.primary)
          }
          .frame(maxWidth: .infinity)
          .padding(DesignSystem.Spacing.md)
          .glassEffect(
            .regular.tint(
              (kitchenRule ? DesignSystem.Colors.ruleCaution : DesignSystem.Colors.ruleNegative)
                .opacity(0.4)),
            in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl))

          // Double Bounce Rule
          VStack(spacing: DesignSystem.Spacing.xs) {
            Image(
              systemName: doubleBounceRule ? "arrow.clockwise.circle.fill" : "xmark.circle.fill"
            )
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(
              (doubleBounceRule ? DesignSystem.Colors.tertiary : DesignSystem.Colors.ruleNegative)
                .gradient
            )
            .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)

            Text("Double Bounce")
              .font(DesignSystem.Typography.caption)
              .fontWeight(.medium)
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)

            Text(doubleBounceRule ? "Yes" : "No")
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(.primary)
          }
          .frame(maxWidth: .infinity)
          .padding(DesignSystem.Spacing.md)
          .glassEffect(
            .regular.tint(
              (doubleBounceRule ? DesignSystem.Colors.tertiary : DesignSystem.Colors.ruleNegative)
                .opacity(0.4)),
            in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl))
        }

        HStack(spacing: DesignSystem.Spacing.md) {
          // Serving Rotation Rule
          VStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: "arrow.triangle.2.circlepath")
              .font(.system(size: 20, weight: .medium))
              .foregroundStyle(DesignSystem.Colors.info.gradient)
              .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)

            Text("Serving")
              .font(DesignSystem.Typography.caption)
              .fontWeight(.medium)
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)

            Text(servingRotation == .standard ? "Standard" : "Custom")
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(.primary)
          }
          .frame(maxWidth: .infinity)
          .padding(DesignSystem.Spacing.md)
          .glassEffect(
            .regular.tint(DesignSystem.Colors.info.opacity(0.4)),
            in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl))

          // Side Switching Rule
          VStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: "arrow.left.arrow.right")
              .font(.system(size: 20, weight: .medium))
              .foregroundStyle(DesignSystem.Colors.tertiary.gradient)
              .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)

            Text("Side Switch")
              .font(DesignSystem.Typography.caption)
              .fontWeight(.medium)
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)

            Text(sideSwitchingRule == .at6Points ? "At 6" : "Custom")
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(.primary)
          }
          .frame(maxWidth: .infinity)
          .padding(DesignSystem.Spacing.md)
          .glassEffect(
            .regular.tint(DesignSystem.Colors.tertiary.opacity(0.4)),
            in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl))
        }
      }
    }
  }
}

#Preview("Default Rules") {
  GameRulesSection(
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
