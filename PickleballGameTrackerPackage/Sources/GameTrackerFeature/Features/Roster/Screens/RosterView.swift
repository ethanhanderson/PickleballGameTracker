import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct RosterView: View {
    @Namespace var animation
    @State private var manager = PlayerTeamManager()
    @State private var showPlayerSheet = false
    @State private var showTeamSheet = false
    @State private var showArchiveSheet = false

    init(manager: PlayerTeamManager = PlayerTeamManager()) {
        _manager = State(initialValue: manager)
    }

    var body: some View {
        NavigationStack {
            Group {
                if manager.players.isEmpty && manager.teams.isEmpty {
                    ScrollView {
                        VStack {
                            EmptyStateView(
                                icon: "person.2.slash",
                                title: "No players or teams yet",
                                description:
                                    "Add players and create teams to get started."
                            )
                        }
                        .padding(.top, DesignSystem.Spacing.sm)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                    }
                    .scrollClipDisabled()
                } else {
                    ScrollView {
                        VStack(spacing: DesignSystem.Spacing.lg) {
                            if !manager.players.isEmpty {
                                SectionContainer(title: "Players") {
                                    VStack(spacing: DesignSystem.Spacing.lg) {
                                        ForEach(manager.players, id: \.id) {
                                            player in
                                            let identity:
                                                IdentityCard.Identity =
                                                    .player(
                                                        player,
                                                        teamCount: teamCount(
                                                            for: player
                                                        )
                                                    )
                                            IdentityNavigationRow(
                                                identity: identity
                                            )
                                        }
                                    }
                                }
                            }

                            if !manager.teams.isEmpty {
                                SectionContainer(title: "Teams") {
                                    VStack(spacing: DesignSystem.Spacing.lg) {
                                        ForEach(manager.teams, id: \.id) {
                                            team in
                                            let identity:
                                                IdentityCard.Identity =
                                                    .team(team)
                                            IdentityNavigationRow(
                                                identity: identity
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                    }
                }
            }
            .navigationTitle("Roster")
            .toolbarTitleDisplayMode(.inlineLarge)
            .viewContainerBackground()
            .toolbar {
                ToolbarItem {
                    Menu {
                        Button(
                            "New Player",
                            systemImage: "person.fill.badge.plus",
                            action: onNewPlayer
                        )
                        .accessibilityIdentifier("roster.newPlayer")

                        Button(
                            "New Team",
                            systemImage: "person.2.badge.plus.fill",
                            action: onNewTeam
                        )
                        .accessibilityIdentifier("roster.newTeam")
                    } label: {
                        Label("Create new", systemImage: "plus")
                    }
                }
                .matchedTransitionSource(
                    id: "sheet",
                    in: animation
                )

                ToolbarSpacer()

                ToolbarItem {
                    Button {
                        showArchiveSheet = true
                    } label: {
                        Label("View Archive", systemImage: "archivebox")
                    }
                    .accessibilityIdentifier("roster.viewArchive")
                }
                .matchedTransitionSource(
                    id: "archive",
                    in: animation
                )
            }
            .navigationDestination(for: RosterDestination.self) { destination in
                switch destination {
                case .identity(let identity):
                    IdentityDetailView(
                        identity: identity,
                        manager: manager
                    )
                }
            }
        }
        .sheet(isPresented: $showPlayerSheet) {
            IdentityEditorView(
                identity: .player(nil),
                manager: manager
            )
            .navigationTransition(.zoom(sourceID: "sheet", in: animation))
        }
        .sheet(isPresented: $showTeamSheet) {
            IdentityEditorView(
                identity: .team(nil),
                manager: manager
            )
            .navigationTransition(.zoom(sourceID: "sheet", in: animation))
        }
        .sheet(isPresented: $showArchiveSheet) {
            ArchiveView(manager: manager)
                .navigationTransition(.zoom(sourceID: "archive", in: animation))
        }
        .task { @MainActor in
            manager.refreshAll()
        }
        .tint(.accentColor)
    }

    private func teamCount(for player: PlayerProfile) -> Int? {
        let count = manager.teams.filter { team in
            team.players.contains(where: { $0.id == player.id })
        }.count
        return count
    }

    private func onNewPlayer() {
        Log.event(.actionTapped, level: .info, message: "roster → newPlayer")
        presentCreatePlayerSheet()
    }

    private func onNewTeam() {
        Log.event(.actionTapped, level: .info, message: "roster → newTeam")
        presentCreateTeamSheet()
    }

    private func presentCreatePlayerSheet() {
        showPlayerSheet = true
    }

    private func presentCreateTeamSheet() {
        showTeamSheet = true
    }

}

// MARK: - Roster Destinations
enum RosterDestination: Hashable {
    case identity(IdentityCard.Identity)
}

// MARK: - Navigation Row Wrapper
@MainActor
private struct IdentityNavigationRow: View {
    let identity: IdentityCard.Identity

    var body: some View {
        NavigationLink(value: RosterDestination.identity(identity)) {
            IdentityCard(identity: identity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("roster.row.\(identity.id.uuidString)")
    }
}

#Preview("With Players and Teams") {
    let setup = PreviewEnvironmentSetup.createMinimal()
    RosterView(manager: setup.rosterManager!)
        .minimalPreview(environment: setup.environment)
}

#Preview("Empty") {
    let setup = PreviewEnvironmentSetup.createMinimal()
    RosterView(manager: setup.rosterManager!)
        .minimalPreview(environment: setup.environment)
}
