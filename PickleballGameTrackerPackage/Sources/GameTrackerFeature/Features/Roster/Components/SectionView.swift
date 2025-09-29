import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct SectionView<Item: Identifiable, Row: View>: View {
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
        .font(.title3)
        .foregroundStyle(.primary)

      VStack(spacing: DesignSystem.Spacing.lg) {
        ForEach(items) { item in
          row(item)
        }
      }
    }
    .padding()
    .glassEffect(
      .regular.tint(Color.gray.opacity(0.3)),
      in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl))
  }
}

#Preview("Players & Teams") {
  let ctx = try! PreviewGameData.makeRosterPreviewContext()
  ScrollView {
    VStack(spacing: DesignSystem.Spacing.lg) {
      SectionView(
        title: "Players",
        items: ctx.players
      ) { player in
        let count = PreviewGameData.teamCount(for: player, in: ctx.teams)
        IdentityCard(identity: .player(player, teamCount: count))
      }

      SectionView(
        title: "Teams",
        items: ctx.teams
      ) { team in
        IdentityCard(identity: .team(team))
      }
    }
    .padding()
  }
  .modelContainer(ctx.container)
}
