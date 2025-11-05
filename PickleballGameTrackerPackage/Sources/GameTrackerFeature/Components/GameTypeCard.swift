import GameTrackerCore
import SwiftUI

@MainActor
struct GameTypeCard: View {
  let gameType: GameType
  let fillsWidth: Bool

  private let playersLabel: LocalizedStringResource = LocalizedStringResource(
    "players_label",
    defaultValue: "Players"
  )
  private let levelLabel: LocalizedStringResource = LocalizedStringResource(
    "level_label",
    defaultValue: "Level"
  )

  public init(
    gameType: GameType,
    fillsWidth: Bool = false
  ) {
    self.gameType = gameType
    self.fillsWidth = fillsWidth
  }

  public var body: some View {
    VStack(spacing: DesignSystem.Spacing.sm) {
      HStack(alignment: .center, spacing: DesignSystem.Spacing.md) {
        VStack(spacing: DesignSystem.Spacing.sm) {
          HStack(alignment: .center, spacing: DesignSystem.Spacing.md) {
            Image(systemName: gameType.iconName)
              .font(.system(size: DesignSystem.Spacing.lg, weight: .medium))
              .foregroundStyle(gameType.color)
              .frame(width: 32, height: 32)

            Text(gameType.displayName)
              .font(.headline)
              .fontWeight(.semibold)
              .foregroundStyle(.primary)
              .multilineTextAlignment(.leading)
              .frame(maxWidth: .infinity, alignment: .leading)
          }

          Text(gameType.description)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        Image(systemName: "chevron.right")
          .font(.system(size: DesignSystem.Spacing.md, weight: .semibold))
          .foregroundStyle(.secondary)
      }
      .padding(.bottom, DesignSystem.Spacing.md)

      HStack(spacing: DesignSystem.Spacing.lg) {
        GameDetailItem(
          icon: "person.2.fill",
          iconSize: DesignSystem.Spacing.md,
          label: playersLabel,
          value: gameType.playerCountValue
        )

        GameDetailItem(
          icon: "clock.fill",
          iconSize: DesignSystem.Spacing.md,
          label: LocalizedStringResource("time_label", defaultValue: "Minutes"),
          value: gameType.estimatedTimeValue
        )

        GameDetailItem(
          icon: "star.fill",
          iconSize: DesignSystem.Spacing.md,
          label: levelLabel,
          value: "\(Int(gameType.difficultyFillProgress * 100))%",
          levelValue: gameType.difficultyFillProgress,
          levelIconSize: DesignSystem.Spacing.md
        )
      }
    }
    .tint(.primary)
    .frame(
      width: fillsWidth ? nil : 220,
      height: fillsWidth ? nil : 180,
      alignment: .topLeading
    )
    .frame(
      maxWidth: fillsWidth ? .infinity : nil,
      alignment: .topLeading
    )
    .padding(.horizontal, DesignSystem.Spacing.lg)
    .padding(.top, DesignSystem.Spacing.lg)
    .padding(.bottom, DesignSystem.CornerRadius.xl)
    .glassEffect(
        .regular.tint(gameType.color.opacity(0.2)),
      in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xxl)
    )
    .contentShape(.rect)
    .accessibilityElement(children: .combine)
    .accessibilityLabel(a11yLabelText)
  }
}

@MainActor
private struct GameDetailItem: View {
  let icon: String
  let iconSize: CGFloat
  let label: LocalizedStringResource
  let value: String
  var levelValue: Double?
  var levelIconSize: CGFloat?

  init(
    icon: String,
    iconSize: CGFloat,
    label: LocalizedStringResource,
    value: String,
    levelValue: Double? = nil,
    levelIconSize: CGFloat? = nil
  ) {
    self.icon = icon
    self.iconSize = iconSize
    self.label = label
    self.value = value
    self.levelValue = levelValue
    self.levelIconSize = levelIconSize
  }

  var body: some View {
    VStack(spacing: DesignSystem.Spacing.xs) {
      iconView

      labelView

      if let levelValue = levelValue, let levelIconSize = levelIconSize {
        levelIndicatorView(levelValue: levelValue, iconSize: levelIconSize)
      } else {
        valueView
      }
    }
    .frame(maxWidth: .infinity)
  }

  private var iconView: some View {
    Image(systemName: icon)
      .font(.system(size: iconSize, weight: .medium))
      .foregroundStyle(.secondary)
  }

  private var labelView: some View {
    Text(label)
      .font(.caption)
      .fontWeight(.semibold)
      .foregroundStyle(.secondary)
  }

  private var valueView: some View {
    Text(value)
      .font(.headline)
      .fontWeight(.bold)
      .fontDesign(.rounded)
      .foregroundStyle(.primary)
      .monospacedDigit()
  }

  private func levelIndicatorView(levelValue: Double, iconSize: CGFloat) -> some View {
    Image(systemName: "chart.bar.fill", variableValue: levelValue)
      .font(.system(size: iconSize, weight: .bold))
      .foregroundStyle(.primary)
  }
}

extension GameTypeCard {
  fileprivate var a11yLabelText: Text {
    let s =
      "\(gameType.displayName). \(gameType.description). Players \(gameType.playerCountValue), \(gameType.timeUnitLabel) \(gameType.estimatedTimeValue), Level"
    return Text(verbatim: s)
  }
}

// MARK: - Preview

#Preview {
  @Previewable @State var selectedGameType = GameType.allCases.randomElement() ?? .recreational

  return GameTypeCard(
    gameType: selectedGameType,
    fillsWidth: false
  )
  .frame(width: 280, height: 200)
}

