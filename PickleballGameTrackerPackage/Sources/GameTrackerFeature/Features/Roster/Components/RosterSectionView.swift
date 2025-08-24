import PickleballGameTrackerCorePackage
import SwiftData
import SwiftUI

@MainActor
struct RosterSectionView<Item: Identifiable, Row: View>: View {
  let title: String
  let items: [Item]
  let row: (Item) -> Row

  init(
    title: String,
    items: [Item],
    @ViewBuilder row: @escaping (Item) -> Row
  ) {
    self.title = title
    self.items = items
    self.row = row
  }

  var body: some View {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
      Text(title)
        .font(DesignSystem.Typography.title3)
        .foregroundColor(DesignSystem.Colors.textPrimary)

      VStack(spacing: DesignSystem.Spacing.lg) {
        ForEach(items) { item in
          row(item)
        }
      }
    }
    .padding()
    .glassEffect(
      .regular.tint(DesignSystem.Colors.containerFillSecondary.opacity(0.2)),
      in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.cardRounded))
  }
}

#Preview("Players & Teams") {
  let container = try! PreviewGameData.createRosterPreviewContainer(
    players: PreviewGameData.samplePlayers,
    teams: PreviewGameData.sampleTeams
  )

  return ScrollView {
    VStack(spacing: DesignSystem.Spacing.lg) {
      RosterSectionView(
        title: "Players",
        items: PreviewGameData.samplePlayers
      ) { player in
        RosterIdentityCard(identity: .player(player, teamCount: 2))
      }

      RosterSectionView(
        title: "Teams",
        items: PreviewGameData.sampleTeams
      ) { team in
        RosterIdentityCard(identity: .team(team))
      }
    }
    .padding()
  }
  .modelContainer(container)
}
