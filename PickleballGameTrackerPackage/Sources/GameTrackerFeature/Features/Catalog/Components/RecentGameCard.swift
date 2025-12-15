import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct RecentGameCard: View {
  let game: Game

  @Environment(\.modelContext) private var modelContext

  var body: some View {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
      HStack(spacing: DesignSystem.Spacing.md) {
        Image(systemName: game.gameType.iconName)
          .font(.system(size: DesignSystem.Spacing.lg, weight: .medium))
          .foregroundStyle(game.gameType.color)
          .frame(width: 28, height: 28)

        VStack(alignment: .leading, spacing: 2) {
          Text(relativeDate)
            .font(.headline)
            .foregroundStyle(.primary)

          Text(game.gameType.displayName)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }

        Spacer()

        Image(systemName: "chevron.right")
          .font(.system(size: DesignSystem.Spacing.md, weight: .semibold))
          .foregroundStyle(.secondary)
      }

      VStack(alignment: .leading, spacing: 6) {
        Text(sideLine(1))
          .font(.subheadline)
          .foregroundStyle(.primary)
          .lineLimit(1)

        Text(sideLine(2))
          .font(.subheadline)
          .foregroundStyle(.primary)
          .lineLimit(1)
      }

      HStack(spacing: DesignSystem.Spacing.md) {
        ruleIcon("plus.circle.fill", enabled: game.winByTwo)
        ruleIcon("checkmark.circle.fill", enabled: game.kitchenRule)
        ruleIcon("arrow.clockwise.circle.fill", enabled: game.doubleBounceRule)
        Image(systemName: "arrow.triangle.2.circlepath")
          .foregroundStyle(.secondary)
        Image(systemName: "arrow.left.arrow.right")
          .foregroundStyle(.secondary)
      }
      .font(.system(size: DesignSystem.Spacing.md, weight: .semibold))
    }
    .padding(.horizontal, DesignSystem.Spacing.lg)
    .padding(.vertical, DesignSystem.Spacing.md)
    .glassEffect(
      .regular.tint(game.gameType.color.opacity(0.18)),
      in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
    )
    .contentShape(.rect)
  }

  private var relativeDate: String {
    let date = game.completedDate ?? game.createdDate
    return RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
  }

  private func sideLine(_ side: Int) -> String {
    if game.participantMode == .teams {
      let team = (side == 1) ? game.resolveSide1Team(context: modelContext)?.name : game.resolveSide2Team(context: modelContext)?.name
      let label = side == 1 ? "A" : "B"
      return "\(label): \(team ?? (side == 1 ? game.effectivePlayerLabel1 : game.effectivePlayerLabel2))"
    } else {
      let players = (side == 1) ? game.resolveSide1Players(context: modelContext) : game.resolveSide2Players(context: modelContext)
      let names = players?.map { $0.name }.joined(separator: " & ")
      let label = side == 1 ? "A" : "B"
      return "\(label): \(names ?? (side == 1 ? game.effectivePlayerLabel1 : game.effectivePlayerLabel2))"
    }
  }

  private func ruleIcon(_ name: String, enabled: Bool) -> some View {
    Image(systemName: name)
      .foregroundStyle(.secondary)
      .opacity(enabled ? 1.0 : 0.3)
  }
}


