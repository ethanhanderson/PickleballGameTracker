import SharedGameCore
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
    let container = try! PreviewGameData.createRosterPreviewContainer(
        players: PreviewGameData.samplePlayers,
        teams: PreviewGameData.sampleTeams
    )

    return List {
        RosterListContainer(
            title: "Players",
            items: PreviewGameData.samplePlayers,
            onArchive: { _ in },
            onEdit: { _ in }
        ) { player in
            RosterIdentityCard(identity: .player(player, teamCount: 2))
        }

        RosterListContainer(
            title: "Teams",
            items: PreviewGameData.sampleTeams,
            onArchive: { _ in },
            onEdit: { _ in }
        ) { team in
            RosterIdentityCard(identity: .team(team))
        }
    }
    .modelContainer(container)
    .scrollContentBackground(.hidden)
}
