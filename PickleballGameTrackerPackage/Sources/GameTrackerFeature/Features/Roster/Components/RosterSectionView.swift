import CorePackage
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
  // Build fresh local models to avoid stale SwiftData references
  let p1 = PlayerProfile(name: "Ethan", skillLevel: .advanced, preferredHand: .right)
  let p2 = PlayerProfile(name: "Reed", skillLevel: .intermediate, preferredHand: .right)
  let p3 = PlayerProfile(name: "Ricky", skillLevel: .beginner, preferredHand: .left)
  let p4 = PlayerProfile(name: "Dave", skillLevel: .expert, preferredHand: .right)
  let players = [p1, p2, p3, p4]
  let t1 = TeamProfile(name: "Ethan & Reed", players: [p1, p2])
  let t2 = TeamProfile(name: "Spin Doctors", players: [p3, p4])
  let teams = [t1, t2]

  return ScrollView {
    VStack(spacing: DesignSystem.Spacing.lg) {
      RosterSectionView(
        title: "Players",
        items: players
      ) { player in
        RosterIdentityCard(identity: .player(player, teamCount: 2))
      }

      RosterSectionView(
        title: "Teams",
        items: teams
      ) { team in
        RosterIdentityCard(identity: .team(team))
      }
    }
    .padding()
  }
}
