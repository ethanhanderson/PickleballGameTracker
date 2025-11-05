import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct RosterView: View {
    @Namespace var animation
    @State private var navigationState = AppNavigationState()
    @Environment(PlayerTeamManager.self) private var manager
    @State private var showPlayerSheet = false
    @State private var showTeamSheet = false
    @State private var showArchiveSheet = false
    @State private var globalNav = GlobalNavigationState.shared
    
    @Query(filter: #Predicate<PlayerProfile> { !$0.isArchived && !$0.isGuest })
    private var players: [PlayerProfile]
    
    @Query(filter: #Predicate<TeamProfile> { !$0.isArchived })
    private var teams: [TeamProfile]

    init() {}

    var body: some View {
        NavigationStack(path: $navigationState.navigationPath) {
            Group {
                if players.isEmpty && teams.isEmpty {
                    ScrollView {
                        VStack {
                            EmptyStateView(
                                icon: "person.2.slash",
                                title: "No players or teams yet",
                                description:
                                    "Add players and create teams to get started."
                            )
                        }
                    }
                    .contentMargins(.horizontal, DesignSystem.Spacing.md, for: .scrollContent)
                    .contentMargins(.top, DesignSystem.Spacing.sm, for: .scrollContent)
                    .scrollClipDisabled()
                } else {
                    ScrollView {
                        VStack(spacing: DesignSystem.Spacing.lg) {
                            if !players.isEmpty {
                                SectionContainer(title: "Players") {
                                    VStack(spacing: DesignSystem.Spacing.lg) {
                                        ForEach(players, id: \.id) {
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
                                                identity: identity,
                                                navigationState: navigationState
                                            )
                                        }
                                    }
                                }
                            }

                            if !teams.isEmpty {
                                SectionContainer(title: "Teams") {
                                    VStack(spacing: DesignSystem.Spacing.lg) {
                                        ForEach(teams, id: \.id) {
                                            team in
                                            let identity:
                                                IdentityCard.Identity =
                                                    .team(team)
                                            IdentityNavigationRow(
                                                identity: identity,
                                                navigationState: navigationState
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .contentMargins(.horizontal, DesignSystem.Spacing.md, for: .scrollContent)
                    .contentMargins(.vertical, DesignSystem.Spacing.sm, for: .scrollContent)
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
                    IdentityDetailView(identity: identity)
                }
            }
        }
        .sheet(isPresented: $showPlayerSheet) {
            IdentityEditorView(identity: .player(nil))
            .navigationTransition(.zoom(sourceID: "sheet", in: animation))
        }
        .onChange(of: showPlayerSheet) { _, isPresented in
            if isPresented {
                globalNav.registerSheet("rosterPlayer")
            } else {
                globalNav.unregisterSheet("rosterPlayer")
            }
        }
        .sheet(isPresented: $showTeamSheet) {
            IdentityEditorView(identity: .team(nil))
            .navigationTransition(.zoom(sourceID: "sheet", in: animation))
        }
        .onChange(of: showTeamSheet) { _, isPresented in
            if isPresented {
                globalNav.registerSheet("rosterTeam")
            } else {
                globalNav.unregisterSheet("rosterTeam")
            }
        }
        .sheet(isPresented: $showArchiveSheet) {
            ArchiveView()
                .navigationTransition(.zoom(sourceID: "archive", in: animation))
        }
        .onChange(of: showArchiveSheet) { _, isPresented in
            if isPresented {
                globalNav.registerSheet("rosterArchive")
            } else {
                globalNav.unregisterSheet("rosterArchive")
            }
        }
    }

    private func teamCount(for player: PlayerProfile) -> Int? {
        let count = teams.filter { team in
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
    let navigationState: AppNavigationState

    var body: some View {
        NavigationLink(value: RosterDestination.identity(identity)) {
            IdentityCard(identity: identity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            TapGesture().onEnded {
                navigationState.trackRosterNavigation(.identity(identity))
            }
        )
        .accessibilityIdentifier("roster.row.\(identity.id.uuidString)")
    }
}

#Preview("With Players and Teams") {
    let container = PreviewContainers.roster()
    let rosterManager = PreviewContainers.rosterManager(for: container)
    
    RosterView()
        .modelContainer(container)
        .environment(rosterManager)
        .tint(.green)
}

#Preview("Empty") {
    let container = PreviewContainers.empty()
    let rosterManager = PreviewContainers.rosterManager(for: container)
    
    RosterView()
        .modelContainer(container)
        .environment(rosterManager)
        .tint(.green)
}
