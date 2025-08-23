import SharedGameCore
import SwiftUI

struct GameOptionCard: View {
  let gameType: GameType
  let isEnabled: Bool
  let fillsWidth: Bool
  let action: (() -> Void)?

  private let iconLargeSize: CGFloat = 24
  private let iconSmallSize: CGFloat = 16
  private let levelIconSize: CGFloat = 18
  private let headerBottomPadding: CGFloat =
    DesignSystem.Spacing.sm + DesignSystem.Spacing.xs
  private let horizontalPadding: CGFloat = 22
  private let topPadding: CGFloat = 18
  private let bottomPadding: CGFloat = 20

  private let playersLabel: LocalizedStringResource = LocalizedStringResource(
    "players_label",
    defaultValue: "Players"
  )
  private let levelLabel: LocalizedStringResource = LocalizedStringResource(
    "level_label",
    defaultValue: "Level"
  )

  private var isInteractive: Bool { action != nil }

  public init(
    gameType: GameType,
    isEnabled: Bool = true,
    fillsWidth: Bool = false,
    action: (() -> Void)? = nil
  ) {
    self.gameType = gameType
    self.isEnabled = isEnabled
    self.fillsWidth = fillsWidth
    self.action = action
  }

  public init(
    gameType: GameType,
    isEnabled: Bool,
    fillsWidth: Bool = false
  ) {
    self.init(
      gameType: gameType,
      isEnabled: isEnabled,
      fillsWidth: fillsWidth,
      action: nil
    )
  }

  public var body: some View {
    let cardContent =
      cardView
      .contentShape(.rect)
      .opacity(isEnabled ? 1.0 : 0.6)
      .accessibilityElement(children: .combine)
      .accessibilityAddTraits(isInteractive ? .isButton : [])
      .accessibilityLabel(a11yLabelText)

    if let action = action {
      Button(action: action) {
        cardContent
      }
      .buttonStyle(.plain)
      .disabled(!isEnabled)
    } else {
      cardContent
    }
  }

  @ViewBuilder
  private var cardView: some View {
    VStack(spacing: DesignSystem.Spacing.sm) {
      HStack(alignment: .center, spacing: DesignSystem.Spacing.md) {
        VStack(spacing: DesignSystem.Spacing.sm) {
          HStack(alignment: .center, spacing: DesignSystem.Spacing.md) {
            Image(systemName: gameType.iconName)
              .font(.system(size: iconLargeSize, weight: .medium))
              .foregroundStyle(.white.gradient)
              .shadow(
                color: .black.opacity(0.20),
                radius: 3,
                x: 0,
                y: 1
              )
              .frame(width: 32, height: 32)

            Text(gameType.displayName)
              .font(DesignSystem.Typography.headline)
              .fontWeight(.bold)
              .foregroundColor(.white)
              .multilineTextAlignment(.leading)
              .frame(maxWidth: .infinity, alignment: .leading)
          }

          Text(gameType.description)
            .font(DesignSystem.Typography.subheadline)
            .foregroundColor(.white.opacity(0.9))
            .multilineTextAlignment(.leading)
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        Image(systemName: "chevron.right")
          .font(.system(size: iconSmallSize, weight: .semibold))
          .foregroundColor(.white.opacity(isInteractive ? 0.6 : 0.3))
          .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
      }
      .padding(.bottom, headerBottomPadding)

      HStack(spacing: DesignSystem.Spacing.lg) {
        MetricColumn(
          icon: "person.2.fill",
          iconSize: iconSmallSize,
          label: playersLabel,
          value: gameType.playerCountValue
        )

        MetricColumn(
          icon: "clock.fill",
          iconSize: iconSmallSize,
          label: LocalizedStringResource("time_label", defaultValue: "Minutes"),
          value: gameType.estimatedTimeValue
        )

        LevelMetricColumn(
          icon: "star.fill",
          iconSize: iconSmallSize,
          label: levelLabel,
          levelValue: gameType.difficultyFillProgress,
          levelIconSize: levelIconSize
        )
      }
    }
    .frame(
      width: fillsWidth ? nil : 220,
      height: fillsWidth ? nil : 180,
      alignment: .topLeading
    )
    .frame(
      maxWidth: fillsWidth ? .infinity : nil,
      alignment: .topLeading
    )
    .padding(.horizontal, horizontalPadding)
    .padding(.top, topPadding)
    .padding(.bottom, bottomPadding)
    .glassEffect(
      .regular.tint(DesignSystem.Colors.gameType(gameType)),
      in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.cardRounded, style: .continuous)
    )
  }
}

private struct MetricColumn: View {
  let icon: String
  let iconSize: CGFloat
  let label: LocalizedStringResource
  let value: String

  var body: some View {
    VStack(spacing: DesignSystem.Spacing.xs) {
      Image(systemName: icon)
        .font(.system(size: iconSize, weight: .medium))
        .foregroundColor(.white.opacity(0.8))
        .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)

      Text(label)
        .font(DesignSystem.Typography.caption)
        .fontWeight(.semibold)
        .foregroundColor(.white.opacity(0.7))

      Text(value)
        .font(DesignSystem.Typography.headline)
        .fontWeight(.bold)
        .fontDesign(.rounded)
        .foregroundColor(.white)
        .monospacedDigit()
    }
    .frame(maxWidth: .infinity)
  }
}

private struct LevelMetricColumn: View {
  let icon: String
  let iconSize: CGFloat
  let label: LocalizedStringResource
  let levelValue: Double
  let levelIconSize: CGFloat

  var body: some View {
    VStack(spacing: DesignSystem.Spacing.xs) {
      Image(systemName: icon)
        .font(.system(size: iconSize, weight: .medium))
        .foregroundColor(.white.opacity(0.8))
        .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)

      Text(label)
        .font(DesignSystem.Typography.caption)
        .fontWeight(.semibold)
        .foregroundColor(.white.opacity(0.7))

      Image(systemName: "chart.bar.fill", variableValue: levelValue)
        .font(.system(size: levelIconSize, weight: .bold))
        .foregroundColor(.white)
    }
    .frame(maxWidth: .infinity)
  }
}

extension GameOptionCard {
  fileprivate var a11yLabelText: Text {
    let s =
      "\(gameType.displayName). \(gameType.description). Players \(gameType.playerCountValue), \(gameType.timeUnitLabel) \(gameType.estimatedTimeValue), Level"
    return Text(verbatim: s)
  }
}
