import CorePackage
import SwiftData
import SwiftUI

@MainActor
struct RosterListContainer<Item: Identifiable, Row: View>: View {
  let title: String
  let items: [Item]
  let onArchive: ((Item) -> Void)?
  let onEdit: ((Item) -> Void)?
  let row: (Item) -> Row

  init(
    title: String,
    items: [Item],
    onArchive: ((Item) -> Void)? = nil,
    onEdit: ((Item) -> Void)? = nil,
    @ViewBuilder row: @escaping (Item) -> Row
  ) {
    self.title = title
    self.items = items
    self.onArchive = onArchive
    self.onEdit = onEdit
    self.row = row
  }

  var body: some View {
    Section {
      ForEach(items) { item in
        row(item)
          .listRowBackground(DesignSystem.Colors.neutralSurface)
          .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if let onArchive {
              Button(role: .destructive) {
                onArchive(item)
              } label: {
                Label("Archive", systemImage: "archivebox")
              }
            }
            if let onEdit {
              Button {
                onEdit(item)
              } label: {
                Label("Edit", systemImage: "pencil")
              }
            }
          }
      }
    } header: {
      Text(title)
        .font(DesignSystem.Typography.title3)
        .foregroundColor(DesignSystem.Colors.textPrimary)
    }
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

  return List {
    RosterListContainer(
      title: "Players",
      items: players,
      onArchive: { _ in },
      onEdit: { _ in }
    ) { player in
      RosterIdentityCard(identity: .player(player, teamCount: 2))
    }

    RosterListContainer(
      title: "Teams",
      items: teams,
      onArchive: { _ in },
      onEdit: { _ in }
    ) { team in
      RosterIdentityCard(identity: .team(team))
    }
  }
  .scrollContentBackground(.hidden)
}
