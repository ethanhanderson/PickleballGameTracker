import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct IdentityDetailView: View {
    let identity: IdentityCard.Identity
    @Query private var allTeams: [TeamProfile]
    @Environment(\.dismiss) private var dismiss
    @Environment(PlayerTeamManager.self) private var manager

    init(identity: IdentityCard.Identity) {
        self.identity = identity
    }

    // Navigation title state (animates in on scroll)
    @State private var showNavigationTitle = false

    // Sheet state
    @State private var showEditSheet = false
    @State private var showAddToTeamSheet = false
    @State private var showShareSheet = false
    @State private var showDeleteConfirmation = false
    @State private var showRestoreConfirmation = false

    // MARK: - Theme Colors

    /// Primary theme color based on the identity's avatar
    private var themeColor: Color {
        // Archived identities theme in gray; icon/avatar color remains unchanged via AvatarView
        if isArchived { return Color(UIColor.systemGray) }
        return identity.themeColor
    }

    private var themeBackgroundColor: Color { identity.themeBackgroundColor }

    private var themeGradient: LinearGradient { identity.themeGradient }

    private var themeNavigationGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.accentColor.opacity(0.4), Color.accentColor.opacity(0.2),
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// Whether the current identity is archived
    private var isArchived: Bool {
        switch identity {
        case .player(let player, _):
            return player.isArchived
        case .team(let team):
            return team.isArchived
        }
    }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
        GeometryReader { geometry in
          header
            .onChange(of: geometry.frame(in: .named("scroll")).maxY)
          { _, newValue in
            withAnimation(.easeInOut(duration: 0.2)) {
              showNavigationTitle = newValue <= -35
            }
          }
        }
        .frame(height: 60)

        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
          switch identity {
          case .player(let player, _):
            playerSections(player)
          case .team(let team):
            teamSections(team)
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .contentMargins(.horizontal, DesignSystem.Spacing.lg, for: .scrollContent)
    .contentMargins(.top, DesignSystem.Spacing.lg, for: .scrollContent)
    .contentMargins(.bottom, DesignSystem.Spacing.lg, for: .scrollContent)
    .coordinateSpace(name: "scroll")
        .navigationBarTitleDisplayMode(.inline)
        .viewContainerBackground(color: themeColor)
        .toolbar {
            if isArchived == false {
                ToolbarItem {
                    Button {
                        onEdit()
                    } label: {
                        Label("Edit", systemImage: "square.and.pencil")
                    }
                    .tint(themeColor)
                }

                ToolbarItem {
                    if case .player = identity {
                        Button {
                            onAddToTeam()
                        } label: {
                            Label("Add to Team", systemImage: "plus")
                        }
                        .tint(themeColor)
                    }
                }

                ToolbarSpacer()

                ToolbarItem {
                    Menu {
                        Button {
                            onShare()
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .fontWeight(.semibold)
                        }
                        .tint(.primary)

                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label("Archive", systemImage: "archivebox")
                                .fontWeight(.semibold)
                        }
                        .tint(.red)
                    } label: {
                        Label("More", systemImage: "ellipsis")
                    }
                    .tint(themeColor)
                }
            } else {
                ToolbarSpacer()

                ToolbarItem {
                    Button {
                        onRestore()
                    } label: {
                        Label("Restore", systemImage: "arrow.counterclockwise")
                    }
                    .tint(.green)
                }
            }

            ToolbarItem(placement: .principal) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Group {
                        switch identity {
                        case .player(let player, _):
                            AvatarView(player: player, style: .small)
                        case .team(let team):
                            AvatarView(team: team, style: .small)
                        }
                    }

                    Text(identity.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                .padding(.top, DesignSystem.Spacing.sm)
                .opacity(showNavigationTitle ? 1.0 : 0.0)
                .offset(y: showNavigationTitle ? 0 : 4)
                .animation(
                    .easeInOut(duration: 0.2),
                    value: showNavigationTitle
                )
            }
        }
        .sheet(isPresented: $showEditSheet) {
            IdentityEditorView(identity: IdentityEditorView.Identity(from: identity))
        }
        .sheet(isPresented: $showAddToTeamSheet) {
            if case .player(let player, _) = identity {
                AddPlayerToTeamView(player: player)
                    .presentationDetents([.medium, .large])
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareIdentityView(identity: identity)
        }
        .alert(
            "Archive \(identity.displayName)?",
            isPresented: $showDeleteConfirmation
        ) {
            Button("Archive", role: .destructive) {
                onConfirmDelete()
            }
        } message: {
            Text(
                "\(identity.displayName) will be archived and hidden from your active roster. You can restore \(identity.displayName.lowercased()) later from the Archive view."
            )
        }
        .tint(.primary)
        .alert(
            "Restore \(identity.displayName)?",
            isPresented: $showRestoreConfirmation
        ) {
            Button("Restore", role: .destructive) {
                onConfirmRestore()
            }
        } message: {
            Text(
                "\(identity.displayName) will be restored to your active roster and will be available for new games."
            )
        }
        .tint(.primary)
    }

    // MARK: - Actions
    private func onEdit() {
        Log.event(
            .actionTapped,
            level: .info,
            message: "identity.edit.start",
            metadata: ["identityId": identity.id.uuidString]
        )
        showEditSheet = true
    }

    private func onAddToTeam() {
        Log.event(
            .actionTapped,
            level: .info,
            message: "identity.addToTeam.start",
            metadata: ["identityId": identity.id.uuidString]
        )
        showAddToTeamSheet = true
    }

    private func onShare() {
        Log.event(
            .actionTapped,
            level: .info,
            message: "identity.share.start",
            metadata: ["identityId": identity.id.uuidString]
        )
        showShareSheet = true
    }

    private func onDelete() {
        Log.event(
            .actionTapped,
            level: .info,
            message: "identity.archive.start",
            metadata: ["identityId": identity.id.uuidString]
        )
        showDeleteConfirmation = true
    }

    private func onRestore() {
        Log.event(
            .actionTapped,
            level: .info,
            message: "identity.restore.start",
            metadata: ["identityId": identity.id.uuidString]
        )
        showRestoreConfirmation = true
    }

    private func onConfirmDelete() {
        Log.event(
            .actionTapped,
            level: .info,
            message: "identity.archive.confirmed",
            metadata: ["identityId": identity.id.uuidString]
        )

        do {
            switch identity {
            case .player(let player, _):
                try manager.archivePlayer(player)
            case .team(let team):
                try manager.archiveTeam(team)
            }
            dismiss()
        } catch {
            Log.event(
                .saveFailed,
                level: .error,
                message: "identity.archive.failed",
                metadata: [
                    "identityId": identity.id.uuidString,
                    "error": String(describing: error),
                ]
            )
        }
    }

    private func onConfirmRestore() {
        Log.event(
            .actionTapped,
            level: .info,
            message: "identity.restore.confirmed",
            metadata: ["identityId": identity.id.uuidString]
        )

        do {
            switch identity {
            case .player(let player, _):
                try manager.restorePlayer(player)
            case .team(let team):
                try manager.restoreTeam(team)
            }
            dismiss()
        } catch {
            Log.event(
                .saveFailed,
                level: .error,
                message: "identity.restore.failed",
                metadata: [
                    "identityId": identity.id.uuidString,
                    "error": String(describing: error),
                ]
            )
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            avatar
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                if isArchived {
                    archivedBadge
                }
                Text(identity.displayName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                if case .player(let player, _) = identity {
                    HStack(spacing: DesignSystem.Spacing.md) {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(
                                systemName: "chart.bar.fill",
                                variableValue: skillFillProgress(
                                    player.skillLevel
                                )
                            )
                            .font(.system(size: 16, weight: .semibold))
                            Text(skillLabel(player.skillLevel))
                        }

                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "hand.raised.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text(handednessLabel(player.preferredHand))
                        }
                    }
                    .font(.headline)
                    .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("rosterIdentity.header")
    }

    private var avatar: some View {
        Group {
            switch identity {
            case .player(let player, _):
                AvatarView(
                    player: player,
                    style: .detail,
                    isArchived: player.isArchived
                )
            case .team(let team):
                AvatarView(
                    team: team,
                    style: .detail,
                    isArchived: team.isArchived
                )
            }
        }
    }

    private var archivedBadge: some View {
        Text("ARCHIVED")
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(Color(UIColor.systemBackground))
            .foregroundStyle(.secondary)
            .clipShape(Capsule())
            .accessibilityIdentifier("rosterIdentity.archivedBadge")
    }

    // MARK: - Sections
    private func playerSections(_ player: PlayerProfile) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            statsSection(
                title: "Statistics",
                items: [
                    ("sportscourt", "Games Played", "0"),
                    ("trophy.fill", "Wins", "0"),
                    ("xmark.circle.fill", "Losses", "0"),
                    ("percent", "Win Rate", "0%"),
                    ("sum", "Avg Points", "0.0"),
                    ("chart.line.uptrend.xyaxis", "Avg Point Diff", "0.0"),
                ]
            )
            .padding(.top, DesignSystem.Spacing.md)
            .accessibilityIdentifier("rosterIdentity.player.stats")

            let teams = teamsFor(player)
            if !teams.isEmpty {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("Teams")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    VStack(spacing: DesignSystem.Spacing.sm) {
                        ForEach(teams) { team in
                            NavigationLink {
                                IdentityDetailView(identity: .team(team))
                            } label: {
                                IdentityCard(identity: .team(team))
                                    .padding(DesignSystem.Spacing.md)
                                    .glassEffect(
                                        .regular.tint(
                                            Color(UIColor.secondarySystemFill)
                                                .opacity(0.5)
                                        ),
                                        in: RoundedRectangle(
                                            cornerRadius: DesignSystem
                                                .CornerRadius.xl
                                        )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .accessibilityIdentifier("rosterIdentity.player.teams")
            }
        }
    }

    private func teamSections(_ team: TeamProfile) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            if !team.players.isEmpty {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("Players")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    VStack(spacing: DesignSystem.Spacing.md) {
                        ForEach(team.players) { member in
                            NavigationLink {
                                IdentityDetailView(identity: .player(member, teamCount: nil))
                            } label: {
                                IdentityCard(
                                    identity: .player(member, teamCount: nil)
                                )
                                .padding(DesignSystem.Spacing.md)
                                .glassEffect(
                                    .regular.tint(
                                        Color(UIColor.secondarySystemFill)
                                            .opacity(0.5)
                                    ),
                                    in: RoundedRectangle(
                                        cornerRadius: DesignSystem.CornerRadius
                                            .xl
                                    )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .accessibilityIdentifier("rosterIdentity.team.members")
            }

            statsSection(
                title: "Statistics",
                items: [
                    ("sportscourt", "Games Played", "0"),
                    ("trophy.fill", "Wins", "0"),
                    ("xmark.circle.fill", "Losses", "0"),
                    ("percent", "Win Rate", "0%"),
                    ("sum", "Avg Points", "0.0"),
                    ("chart.line.uptrend.xyaxis", "Avg Point Diff", "0.0"),
                ]
            )
            .padding(.top, DesignSystem.Spacing.md)
            .accessibilityIdentifier("rosterIdentity.team.stats")
        }
    }

    // MARK: - Components

    private func statsSection(
        title: String,
        items: [(String, String, String)]
    ) -> some View {
        StatsSection(title: title, items: items, themeColor: themeColor)
    }

    private func statCard(_ item: (String, String, String)) -> some View {
        StatCard(
            symbolName: item.0,
            title: item.1,
            value: item.2,
            themeColor: themeColor
        )
    }

    private func teamsFor(_ player: PlayerProfile) -> [TeamProfile] {
        allTeams.filter { team in
            team.players.contains(where: { $0.id == player.id })
        }
    }

    private func skillFillProgress(_ level: PlayerSkillLevel) -> Double {
        switch level {
        case .beginner: return 0.25
        case .intermediate: return 0.5
        case .advanced: return 0.75
        case .expert: return 1.0
        case .unknown: return 0.0
        }
    }

    // MARK: - Labels
    private func skillLabel(_ level: PlayerSkillLevel) -> String {
        switch level {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .expert: return "Expert"
        case .unknown: return "Skill Unspecified"
        }
    }

    private func handednessLabel(_ hand: PlayerHandedness) -> String {
        switch hand {
        case .right: return "Right"
        case .left: return "Left"
        case .unknown: return "Unspecified"
        }
    }
}

// MARK: - Previews

#Preview("Active Players") {
    let container = PreviewContainers.roster()
    let rosterManager = PreviewContainers.rosterManager(for: container)

    let players = try! container.mainContext.fetch(
        FetchDescriptor<PlayerProfile>(predicate: #Predicate { !$0.isArchived })
    )
    let teams = try! container.mainContext.fetch(
        FetchDescriptor<TeamProfile>(predicate: #Predicate { !$0.isArchived })
    )
    let selectedPlayer = players.first!
    let teamCount = PreviewGameData.teamCount(for: selectedPlayer, in: teams)

    NavigationStack {
        IdentityDetailView(identity: .player(selectedPlayer, teamCount: teamCount))
    }
    .modelContainer(container)
    .environment(rosterManager)
}

#Preview("Active Teams") {
    let container = PreviewContainers.roster()
    let rosterManager = PreviewContainers.rosterManager(for: container)

    let teams = try! container.mainContext.fetch(
        FetchDescriptor<TeamProfile>(predicate: #Predicate { !$0.isArchived })
    )
    let selectedTeam = teams.first!

    NavigationStack {
        IdentityDetailView(identity: .team(selectedTeam))
    }
    .modelContainer(container)
    .environment(rosterManager)
}

// MARK: - Archived Identity Previews

#Preview("Archived Players") {
    let container = PreviewContainers.roster()
    let rosterManager = PreviewContainers.rosterManager(for: container)

    let context = container.mainContext
    let players = try! context.fetch(FetchDescriptor<PlayerProfile>())
    let teams = try! context.fetch(FetchDescriptor<TeamProfile>())

    let archivedPlayer =
        players.first(where: { $0.isArchived })
        ?? {
            let player = players.first!
            player.isArchived = true
            return player
        }()

    let teamCount = PreviewGameData.teamCount(for: archivedPlayer, in: teams)

    return NavigationStack {
        IdentityDetailView(identity: .player(archivedPlayer, teamCount: teamCount))
    }
    .modelContainer(container)
    .environment(rosterManager)
}

#Preview("Archived Teams") {
    let container = PreviewContainers.roster()
    let rosterManager = PreviewContainers.rosterManager(for: container)

    let context = container.mainContext
    let teams = try! context.fetch(FetchDescriptor<TeamProfile>())

    let archivedTeam =
        teams.first(where: { $0.isArchived })
        ?? {
            let team = teams.first!
            team.isArchived = true
            return team
        }()

    return NavigationStack {
        IdentityDetailView(identity: .team(archivedTeam))
    }
    .modelContainer(container)
    .environment(rosterManager)
}
