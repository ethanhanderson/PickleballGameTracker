import CorePackage
import SwiftData
import SwiftUI

@MainActor
struct RosterIdentityDetailView: View {
  let identity: RosterIdentityCard.Identity
  let manager: PlayerTeamManager
  @Query private var allTeams: [TeamProfile]
  @Environment(\.dismiss) private var dismiss
  @Environment(SwiftDataGameManager.self) private var gameManager
  @Environment(ActiveGameStateManager.self) private var activeGameStateManager

  init(identity: RosterIdentityCard.Identity, manager: PlayerTeamManager) {
    self.identity = identity
    self.manager = manager
  }

  // Navigation title state (animates in on scroll)
  @State private var showNavigationTitle = false

  // Sheet state
  @State private var showEditSheet = false
  @State private var showAddToTeamSheet = false
  @State private var showShareSheet = false
  @State private var showDeleteConfirmation = false
  @State private var showRestoreConfirmation = false
  @State private var showStartGameSheet = false
  @State private var showMergeSheet = false

  // MARK: - Theme Colors

  /// Primary theme color based on the identity's avatar
  private var themeColor: Color {
    // Archived identities theme in gray; icon/avatar color remains unchanged via AvatarView
    if isArchived { return DesignSystem.Colors.paused }
    return identity.themeColor
  }

  /// Background color with theme tint
  private var themeBackgroundColor: Color {
    identity.themeBackgroundColor
  }

  /// Theme gradient for accents
  private var themeGradient: LinearGradient {
    identity.themeGradient
  }

  /// Navigation background gradient using theme color
  private var themeNavigationGradient: LinearGradient {
    DesignSystem.Colors.navigationGradient(color: themeColor)
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
        // Header with scroll tracking (mirror GameDetailView)
        GeometryReader { geometry in
          header
            .onChange(of: geometry.frame(in: .named("scroll")).maxY) { _, newValue in
              withAnimation(.easeInOut(duration: 0.2)) {
                showNavigationTitle = newValue <= -35
              }
            }
        }
        .frame(height: 60)
        .padding(.horizontal, DesignSystem.Spacing.lg)

        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
          switch identity {
          case .player(let player, _):
            identityInfoCards()
            playerSections(player)
          case .team(let team):
            // Hide info cards for teams
            teamSections(team)
          }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.bottom, DesignSystem.Spacing.lg)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.top, DesignSystem.Spacing.lg)
    }
    .coordinateSpace(name: "scroll")
    .navigationBarTitleDisplayMode(.inline)
    .containerBackground(
      themeNavigationGradient,
      for: .navigation
    )
    .toolbar {
      if isArchived == false {
        ToolbarItem {
          Button {
            onStartGameTapped()
          } label: {
            Label("Start Game", systemImage: "play.circle.fill")
          }
          .tint(themeColor)
          .accessibilityIdentifier("rosterIdentity.startGame")
        }

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

            Button {
              onMerge()
            } label: {
              Label("Merge With…", systemImage: "square.filled.on.square")
                .fontWeight(.semibold)
            }
            .tint(.primary)
            .accessibilityIdentifier("rosterIdentity.mergeButton")

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
              AvatarView(player: player, style: .navigation)
            case .team(let team):
              AvatarView(team: team, style: .navigation)
            }
          }

          Text(identity.displayName)
            .font(DesignSystem.Typography.headline)
            .fontWeight(.semibold)
            .foregroundColor(DesignSystem.Colors.textPrimary)
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
      RosterIdentityEditorView(
        identity: RosterIdentityEditorView.Identity(from: identity),
        manager: manager
      )
    }
    .sheet(isPresented: $showStartGameSheet) {
      NavigationStack {
        GameDetailView(
          gameType: suggestedGameTypeForIdentity(),
          onStartGame: { variation in
            Task { @MainActor in
              do {
                let newGame = try await gameManager.createGame(variation: variation)
                activeGameStateManager.setCurrentGame(newGame)
                Log.event(
                  .viewAppear,
                  level: .info,
                  message: "Roster → started game",
                  context: .current(gameId: newGame.id),
                  metadata: ["source": "RosterDetail", "identityId": identity.id.uuidString]
                )
                dismiss()
              } catch {
                Log.error(
                  error,
                  event: .saveFailed,
                  metadata: ["phase": "rosterStartGame"]
                )
              }
            }
          }
        )
      }
      .navigationTint()
    }
    .sheet(isPresented: $showMergeSheet) {
      NavigationStack {
        MergeTargetPicker(identity: identity, manager: manager) {
          dismiss()
        }
      }
    }
    .sheet(isPresented: $showAddToTeamSheet) {
      if case .player(let player, _) = identity {
        AddPlayerToTeamView(player: player, manager: manager)
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

  private func onStartGameTapped() {
    Log.event(
      .actionTapped,
      level: .info,
      message: "identity.startGame.start",
      metadata: ["identityId": identity.id.uuidString]
    )
    showStartGameSheet = true
  }

  private func onMerge() {
    Log.event(
      .actionTapped,
      level: .info,
      message: "identity.merge.start",
      metadata: ["identityId": identity.id.uuidString]
    )
    showMergeSheet = true
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
          .foregroundStyle(DesignSystem.Colors.textPrimary)
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
      .font(DesignSystem.Typography.caption)
      .fontWeight(.bold)
      .padding(.horizontal, DesignSystem.Spacing.sm)
      .padding(.vertical, DesignSystem.Spacing.xs)
      .background(DesignSystem.Colors.neutralSurface)
      .foregroundStyle(.secondary)
      .clipShape(Capsule())
      .accessibilityIdentifier("rosterIdentity.archivedBadge")
  }

  // MARK: - Sections
  private func playerSections(_ player: PlayerProfile) -> some View {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
      // Details section moved to top - skill/hand cards are now in identityInfoCards()

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
      .accessibilityIdentifier("rosterIdentity.player.stats")

      // Teams this player is in (after stats)
      let teams = teamsFor(player)
      if !teams.isEmpty {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
          Text("Teams")
            .font(DesignSystem.Typography.title3)
            .foregroundStyle(DesignSystem.Colors.textPrimary)

          VStack(spacing: DesignSystem.Spacing.sm) {
            ForEach(teams) { team in
              NavigationLink {
                RosterIdentityDetailView(
                  identity: .team(team),
                  manager: manager
                )
              } label: {
                RosterIdentityCard(identity: .team(team))
                  .padding(DesignSystem.Spacing.md)
                  .glassEffect(
                    .regular.tint(
                      DesignSystem.Colors
                        .containerFillSecondary.opacity(
                          0.5
                        )
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
      // Members (after info cards, before stats)
      if !team.players.isEmpty {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
          Text("Players")
            .font(DesignSystem.Typography.title3)
            .foregroundStyle(DesignSystem.Colors.textPrimary)

          VStack(spacing: DesignSystem.Spacing.md) {
            ForEach(team.players) { member in
              NavigationLink {
                RosterIdentityDetailView(
                  identity: .player(member, teamCount: nil),
                  manager: manager
                )
              } label: {
                RosterIdentityCard(
                  identity: .player(member, teamCount: nil)
                )
                .padding(DesignSystem.Spacing.md)
                .glassEffect(
                  .regular.tint(
                    DesignSystem.Colors
                      .containerFillSecondary.opacity(0.5)
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
      .accessibilityIdentifier("rosterIdentity.team.stats")
    }
  }

  // MARK: - Components
  @ViewBuilder
  private func identityInfoCards() -> some View {
    HStack(spacing: DesignSystem.Spacing.md) {
      switch identity {
      case .player(let player, let teamCount):
        // Skill card (was Level)
        IdentityInfoCard(title: "Skill", gradient: themeGradient) {
          Image(
            systemName: "chart.bar.fill",
            variableValue: skillFillProgress(player.skillLevel)
          )
          .font(.system(size: 18, weight: .bold))
          .foregroundStyle(.primary)
        }

        // Hand card
        IdentityInfoCard(title: "Hand", gradient: themeGradient) {
          handIconView(player.preferredHand)
        }

        // Teams card (moved to end)
        IdentityInfoCard(title: "Teams", gradient: themeGradient) {
          Text("\(teamCount ?? 0)")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.primary)
        }

      case .team(let team):
        // Players card
        IdentityInfoCard(title: "Players", gradient: themeGradient) {
          Text("\(team.players.count)")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.primary)
        }

        // Game Type card
        IdentityInfoCard(title: "Game Type", gradient: themeGradient) {
          Text(team.suggestedGameType?.displayName ?? "—")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.primary)
        }

        // Level card (based on suggested game type if available)
        IdentityInfoCard(title: "Level", gradient: themeGradient) {
          Image(
            systemName: "chart.bar.fill",
            variableValue: team.suggestedGameType?
              .difficultyFillProgress ?? 0.0
          )
          .font(.system(size: 18, weight: .bold))
          .foregroundStyle(.primary)
        }
      }
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

  @ViewBuilder
  private func handIconView(_ hand: PlayerHandedness) -> some View {
    HandIconView(hand: hand)
  }
  private func infoChip(title: String, value: String) -> some View {
    HStack(spacing: DesignSystem.Spacing.xs) {
      Text(title)
        .font(DesignSystem.Typography.caption)
        .foregroundStyle(DesignSystem.Colors.textSecondary)
      Text(value)
        .font(DesignSystem.Typography.body)
        .foregroundStyle(DesignSystem.Colors.textPrimary)
    }
    .padding(.horizontal, DesignSystem.Spacing.md)
    .padding(.vertical, DesignSystem.Spacing.xs)
    .background(DesignSystem.Colors.neutralSurface)
    .clipShape(Capsule())
  }

  private func statsSection(
    title: String,
    items: [(String, String, String)]
  ) -> some View {
    StatsSection(title: title, items: items, themeColor: themeColor)
  }

  private func statCard(_ item: (String, String, String)) -> some View {
    RosterStatCard(
      symbolName: item.0,
      title: item.1,
      value: item.2,
      themeColor: themeColor
    )
  }

  private func chunk<T>(_ array: [T], size: Int) -> [[T]] {
    guard size > 0 else { return [] }
    var result: [[T]] = []
    var index = 0
    while index < array.count {
      let end = min(index + size, array.count)
      result.append(Array(array[index..<end]))
      index += size
    }
    return result
  }

  private func teamsFor(_ player: PlayerProfile) -> [TeamProfile] {
    allTeams.filter { team in
      team.players.contains(where: { $0.id == player.id })
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

// MARK: - Helpers
extension RosterIdentityDetailView {
  fileprivate func suggestedGameTypeForIdentity() -> GameType {
    switch identity {
    case .player:
      return .recreational
    case .team(let team):
      return team.suggestedGameType ?? .recreational
    }
  }
}

// MARK: - Merge Target Picker
@MainActor
private struct MergeTargetPicker: View {
  let identity: RosterIdentityCard.Identity
  let manager: PlayerTeamManager
  let onComplete: () -> Void

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    List {
      switch identity {
      case .player(let player, _):
        Section("Merge Player Into") {
          let candidates = manager.players.filter { $0.id != player.id && $0.isArchived == false }
          if candidates.isEmpty {
            Text("No candidates available").foregroundStyle(.secondary)
          } else {
            ForEach(candidates, id: \.id) { target in
              Button {
                mergePlayer(source: player, into: target)
              } label: {
                HStack {
                  Text(target.name)
                  Spacer()
                  Text(target.skillLevel == .unknown ? "" : label(for: target.skillLevel))
                    .foregroundStyle(.secondary)
                }
              }
              .accessibilityIdentifier("merge.player.\(player.id.uuidString).into.\(target.id.uuidString)")
            }
          }
        }
      case .team(let team):
        Section("Merge Team Into") {
          let candidates = manager.teams.filter { $0.id != team.id && $0.isArchived == false }
          if candidates.isEmpty {
            Text("No candidates available").foregroundStyle(.secondary)
          } else {
            ForEach(candidates, id: \.id) { target in
              Button {
                mergeTeam(source: team, into: target)
              } label: {
                HStack {
                  Text(target.name)
                  Spacer()
                  Text("\(target.players.count) players").foregroundStyle(.secondary)
                }
              }
              .accessibilityIdentifier("merge.team.\(team.id.uuidString).into.\(target.id.uuidString)")
            }
          }
        }
      }
    }
    .navigationTitle("Merge With…")
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") { dismiss() }
      }
    }
  }

  private func label(for level: PlayerSkillLevel) -> String {
    switch level {
    case .beginner: return "Beginner"
    case .intermediate: return "Intermediate"
    case .advanced: return "Advanced"
    case .expert: return "Expert"
    case .unknown: return ""
    }
  }

  private func mergePlayer(source: PlayerProfile, into target: PlayerProfile) {
    do {
      try manager.mergePlayer(source: source, into: target)
      dismiss()
      onComplete()
    } catch {
      Log.error(error, event: .saveFailed, metadata: ["action": "mergePlayer"])
    }
  }

  private func mergeTeam(source: TeamProfile, into target: TeamProfile) {
    do {
      try manager.mergeTeam(source: source, into: target)
      dismiss()
      onComplete()
    } catch {
      Log.error(error, event: .saveFailed, metadata: ["action": "mergeTeam"])
    }
  }
}

// MARK: - Previews

extension RosterIdentityDetailView {
  /// Preview data for cycling through different identities
  fileprivate static var previewData:
    (
      players: [PlayerProfile], teams: [TeamProfile],
      archivedPlayers: [PlayerProfile],
      archivedTeams: [TeamProfile]
    )
  {
    let activePlayers = PreviewGameData.samplePlayers
    let activeTeams = PreviewGameData.sampleTeams

    // Create archived versions using the same instances (preserve relationships)
    let archivedPlayers = activePlayers.map { player in
      // Create a copy but preserve the ID for relationship integrity
      let archived = PlayerProfile(
        id: player.id,  // Keep the same ID
        name: player.name,
        avatarImageData: player.avatarImageData,
        iconSymbolName: player.iconSymbolName,
        iconTintColor: player.iconTintColor,
        skillLevel: player.skillLevel,
        preferredHand: player.preferredHand
      )
      archived.isArchived = true
      return archived
    }

    let archivedTeams = activeTeams.map { team in
      // Create a copy but preserve the ID and use archived players
      let archived = TeamProfile(
        id: team.id,  // Keep the same ID
        name: team.name,
        avatarImageData: team.avatarImageData,
        iconSymbolName: team.iconSymbolName,
        iconTintColor: team.iconTintColor,
        players: team.players.map { player in
          // Use the archived version of this player
          archivedPlayers.first(where: { $0.id == player.id }) ?? player
        },
        suggestedGameType: team.suggestedGameType
      )
      archived.isArchived = true
      return archived
    }

    return (
      players: activePlayers, teams: activeTeams,
      archivedPlayers: archivedPlayers,
      archivedTeams: archivedTeams
    )
  }

  /// Creates a preview manager with the given data
  fileprivate static func createPreviewManager(
    players: [PlayerProfile] = [],
    teams: [TeamProfile] = []
  ) -> PlayerTeamManager {
    let schema = Schema([
      Game.self, GameVariation.self, GameSummary.self, PlayerProfile.self,
      TeamProfile.self,
      GameTypePreset.self,
    ])
    let config = ModelConfiguration(
      schema: schema,
      isStoredInMemoryOnly: true
    )
    let container = try! ModelContainer(
      for: schema,
      configurations: [config]
    )
    let context = container.mainContext

    for player in players {
      context.insert(player)
    }
    for team in teams {
      context.insert(team)
    }
    try! context.save()

    let storage = SwiftDataStorage(modelContainer: container)
    return PlayerTeamManager(storage: storage, autoRefresh: false)
  }
}

// MARK: - Active Identity Previews

#Preview("Active Players") {
  let data = RosterIdentityDetailView.previewData
  let manager = RosterIdentityDetailView.createPreviewManager(
    players: data.players,
    teams: data.teams
  )

  // Cycle through all active players
  let playerIndex = Int.random(in: 0..<data.players.count)
  let selectedPlayer = data.players[playerIndex]
  let teamCount = data.teams.filter { team in
    team.players.contains(where: { $0.id == selectedPlayer.id })
  }.count

  NavigationStack {
    RosterIdentityDetailView(
      identity: .player(selectedPlayer, teamCount: teamCount),
      manager: manager
    )
  }
  .modelContainer(try! PreviewGameData.createRosterPreviewContainer())
}

#Preview("Active Teams") {
  let data = RosterIdentityDetailView.previewData
  let manager = RosterIdentityDetailView.createPreviewManager(
    players: data.players,
    teams: data.teams
  )

  // Cycle through all active teams
  let teamIndex = Int.random(in: 0..<data.teams.count)
  let selectedTeam = data.teams[teamIndex]

  NavigationStack {
    RosterIdentityDetailView(
      identity: .team(selectedTeam),
      manager: manager
    )
  }
  .modelContainer(try! PreviewGameData.createRosterPreviewContainer())
}

// MARK: - Archived Identity Previews

#Preview("Archived Players") {
  let data = RosterIdentityDetailView.previewData
  let manager = RosterIdentityDetailView.createPreviewManager(
    players: data.archivedPlayers,
    teams: data.archivedTeams
  )

  // Cycle through all archived players
  let playerIndex = Int.random(in: 0..<data.archivedPlayers.count)
  let selectedPlayer = data.archivedPlayers[playerIndex]
  let teamCount = data.archivedTeams.filter { team in
    team.players.contains(where: { $0.id == selectedPlayer.id })
  }.count

  NavigationStack {
    RosterIdentityDetailView(
      identity: .player(selectedPlayer, teamCount: teamCount),
      manager: manager
    )
  }
  .modelContainer(try! PreviewGameData.createRosterPreviewContainer())
}

#Preview("Archived Teams") {
  let data = RosterIdentityDetailView.previewData
  let manager = RosterIdentityDetailView.createPreviewManager(
    players: data.archivedPlayers,
    teams: data.archivedTeams
  )

  // Cycle through all archived teams
  let teamIndex = Int.random(in: 0..<data.archivedTeams.count)
  let selectedTeam = data.archivedTeams[teamIndex]

  NavigationStack {
    RosterIdentityDetailView(
      identity: .team(selectedTeam),
      manager: manager
    )
  }
  .modelContainer(try! PreviewGameData.createRosterPreviewContainer())
}
