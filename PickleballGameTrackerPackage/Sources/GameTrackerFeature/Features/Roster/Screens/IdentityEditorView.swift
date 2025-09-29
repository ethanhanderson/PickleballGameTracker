import GameTrackerCore
import PhotosUI
import SwiftData
import SwiftUI

@MainActor
struct IdentityEditorView: View {
  enum Identity: Equatable {
    case player(PlayerProfile?)
    case team(TeamProfile?)

    init(from rosterIdentity: IdentityCard.Identity) {
      switch rosterIdentity {
      case .player(let player, _):
        self = .player(player)
      case .team(let team):
        self = .team(team)
      }
    }

    var isCreate: Bool {
      switch self {
      case .player(let player): return player == nil
      case .team(let team): return team == nil
      }
    }

    var title: String {
      switch self {
      case .player: return isCreate ? "New Player" : "Edit Player"
      case .team: return isCreate ? "New Team" : "Edit Team"
      }
    }

    var symbolPlaceholder: String {
      switch self {
      case .player: return "SF Symbol name (e.g., person.fill)"
      case .team: return "SF Symbol name (e.g., person.2.fill)"
      }
    }
  }

  enum AvatarType: String, CaseIterable {
    case photo = "Photo"
    case icon = "Icon"

    var systemImage: String {
      switch self {
      case .photo: return "photo"
      case .icon: return "star.fill"
      }
    }
  }

  @Environment(\.dismiss) private var dismiss

  let identity: Identity
  let manager: PlayerTeamManager

  // Curated list of SF symbols for players/teams
  private let iconOptions: [String] = [
    "person.fill",
    "person.2.fill",
    "figure.walk",
    "figure.run",
    "figure.tennis",
    "figure.badminton",
    "figure.soccer",
    "figure.basketball",
    "figure.baseball",
    "figure.golf",
    "figure.mind.and.body",
    "figure.fitness",
    "figure.strengthtraining.traditional",
    "figure.pool.swim",
    "figure.bowling",
    "figure.archery",
    "figure.fencing",
    "star.fill",
    "star.circle.fill",
    "heart.fill",
    "hand.thumbsup.fill",
    "flame.fill",
    "bolt.fill",
    "trophy.fill",
    "medal.fill",
    "crown.fill",
    "gamecontroller.fill",
    "sportscourt.fill",
    "tennis.racket",
    "basketball.fill",
    "football.fill",
    "baseball.fill",
    "soccerball",
    "volleyball.fill",
    "beachball.fill",
    "paddle",
  ]

  @State private var name: String = ""
  @State private var notes: String = ""

  // Player-specific state
  @State private var skillLevel: PlayerSkillLevel = .beginner
  @State private var preferredHand: PlayerHandedness = .right

  // Team-specific state
  @State private var selectedPlayerIds: Set<UUID> = []

  // Avatar state
  @State private var avatarType: AvatarType = .icon
  @State private var selectedPhotoData: Data?
  @State private var selectedPhotoItem: PhotosPickerItem?
  @State private var selectedIconName: String = ""
  @State private var selectedIconColor: Color = .green
  @State private var showingCamera: Bool = false

  @State private var showValidationError: Bool = false
  @FocusState private var nameFocused: Bool

  init(identity: Identity, manager: PlayerTeamManager) {
    self.identity = identity
    self.manager = manager
  }

  private var saveDisabled: Bool {
    name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  private var placeholderText: String {
    switch identity {
    case .player:
      return
        "Add notes about this player (e.g., playing style, strengths, favorite strategies, or personal notes)"
    case .team:
      return
        "Add notes about this team (e.g., team dynamics, preferred formations, match strategies, or team goals)"
    }
  }

  private var isTeam: Bool {
    if case .team = identity { return true } else { return false }
  }

  // MARK: - View Sections
  @ViewBuilder
  private var detailsSection: some View {
    Section("Details") {
      TextField("Name", text: $name)
        .focused($nameFocused)
      if showValidationError && saveDisabled {
        Text("Name is required").foregroundStyle(.red)
      }

      if case .player = identity {
        Picker("Skill level", selection: $skillLevel) {
          Text("Beginner").tag(PlayerSkillLevel.beginner)
          Text("Intermediate").tag(PlayerSkillLevel.intermediate)
          Text("Advanced").tag(PlayerSkillLevel.advanced)
          Text("Expert").tag(PlayerSkillLevel.expert)
        }
        .pickerStyle(.menu)
        .tint(.accentColor)
        .accessibilityLabel("Skill level selection")

        VStack(
          alignment: .leading,
          spacing: DesignSystem.Spacing.sm
        ) {
          Text("Preferred Hand")
            .font(.body)
            .foregroundStyle(.primary)

          Picker("Preferred hand", selection: $preferredHand) {
            Text("Right").tag(PlayerHandedness.right)
            Text("Left").tag(PlayerHandedness.left)
          }
          .pickerStyle(.segmented)
          .labelsVisibility(.visible)
          .accessibilityLabel("Preferred hand selection")
        }
      }
    }
  }

  private var colorOptions: [Color] {
    [
      Color.blue,
      Color.green,
      Color.red,
      Color.orange,
      Color.purple,
      Color.pink,
      Color.yellow,
      Color.teal,
      Color.indigo,
      Color.brown
    ]
  }

  private func colorSelectionButton(for color: Color) -> some View {
    ZStack {
      Circle()
        .fill(color)
        .frame(width: 46, height: 46)
        .overlay(
          selectedIconColor == color
            ? AnyView(colorSelectionOverlay)
            : AnyView(EmptyView())
        )
    }
    .onTapGesture { selectedIconColor = color }
    .accessibilityLabel("Select color theme")
    .accessibilityAddTraits(selectedIconColor == color ? .isSelected : [])
  }

  private var colorSelectionOverlay: some View {
    Circle()
      .fill(.ultraThinMaterial)
      .frame(width: 46, height: 46)
      .overlay(
        Image(systemName: "checkmark")
          .font(.system(size: 22, weight: .bold))
          .foregroundStyle(selectedIconColor.opacity(0.8))
      )
      .transition(.scale.combined(with: .opacity))
      .animation(.easeInOut(duration: 0.12), value: selectedIconColor)
  }

  private var colorSelectionScrollView: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: DesignSystem.Spacing.md) {
        ForEach(colorOptions, id: \.self) { color in
          colorSelectionButton(for: color)
        }
      }
    }
  }

  @ViewBuilder
  private var avatarSection: some View {
    Section("Avatar") {
      VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
        Text("Color Theme")
          .font(.body)
          .fontWeight(.semibold)
          .foregroundStyle(.primary)

        colorSelectionScrollView
      }
      .listRowSeparator(.visible, edges: .bottom)

      Picker("Avatar Type", selection: $avatarType) {
        ForEach(AvatarType.allCases, id: \.self) { type in
          Label(type.rawValue, systemImage: type.systemImage)
            .tag(type)
        }
      }
      .pickerStyle(.segmented)
      .listRowSeparator(.hidden)
      .accessibilityLabel("Avatar type selection")
      switch avatarType {
      case .photo:
        PhotoAvatarContent(
          selectedPhotoData: $selectedPhotoData,
          selectedPhotoItem: $selectedPhotoItem,
          showingCamera: $showingCamera
        )
      case .icon:
        IconAvatarContent(
          selectedIconName: $selectedIconName,
          selectedIconColor: $selectedIconColor,
          iconOptions: iconOptions
        )
      }
    }
  }

  @ViewBuilder
  private var teamMembersSection: some View {
    Section("Members") {
      if manager.players.isEmpty {
        Text("No players yet — add players first from the Roster")
          .foregroundStyle(.secondary)
      } else {
        ForEach(manager.players, id: \.id) { player in
          SelectablePlayerRow(
            name: player.name,
            isSelected: selectedPlayerIds.contains(player.id),
            onToggle: { toggleSelection(for: player.id) }
          )
        }
      }
    }
  }

  @ViewBuilder
  private var notesSection: some View {
    Section("Notes") {
      ZStack(alignment: .topLeading) {
        TextEditor(text: $notes)
          .frame(minHeight: 100)
        if notes.isEmpty {
          Text(placeholderText)
            .foregroundStyle(.secondary)
            .padding(.top, 8)
            .padding(.leading, 4)
        }
      }
    }
  }

  var body: some View {
    NavigationStack {
      ZStack {
        Form {
          detailsSection
          avatarSection
          if isTeam { teamMembersSection }
          notesSection
        }
        .scrollDismissesKeyboard(.interactively)
      }
      .navigationTitle(identity.title)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button(action: { onCancel() }) {
            Label("Cancel", systemImage: "xmark")
          }
          .accessibilityLabel("Cancel")
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(action: { onSave() }) {
            Label("Save", systemImage: "checkmark")
          }
          .buttonStyle(.glassProminent)
          .tint(.accentColor)
          .accessibilityLabel("Save")
          .disabled(saveDisabled)
        }
      }
    }
    .onAppear { populateFromIdentityIfNeeded() }
    .fullScreenCover(isPresented: $showingCamera) {
      CameraPicker(selectedImageData: $selectedPhotoData)
        .ignoresSafeArea()
    }
  }

  func toggleSelection(for id: UUID) {
    if selectedPlayerIds.contains(id) {
      selectedPlayerIds.remove(id)
    } else {
      selectedPlayerIds.insert(id)
    }
  }

  func populateFromIdentityIfNeeded() {
    switch identity {
    case .player(let player):
      if let player = player {
        name = player.name
        notes = player.notes ?? ""
        skillLevel =
          player.skillLevel == .unknown
          ? .beginner : player.skillLevel
        preferredHand =
          player.preferredHand == .unknown
          ? .right : player.preferredHand

        if let avatarData = player.avatarImageData {
          avatarType = .photo
          selectedPhotoData = avatarData
        } else if let iconName = player.iconSymbolName {
          avatarType = .icon
          selectedIconName = iconName
          selectedIconColor = player.iconTintColorValue ?? .green
        }
      } else {
        nameFocused = true
        skillLevel = .beginner
        preferredHand = .right
        avatarType = .icon
        selectedIconName = "person.fill"
        selectedIconColor = .green
      }

    case .team(let team):
      if let team = team {
        name = team.name
        notes = team.notes ?? ""
        selectedPlayerIds = Set(team.players.map { $0.id })

        if let avatarData = team.avatarImageData {
          avatarType = .photo
          selectedPhotoData = avatarData
        } else if let iconName = team.iconSymbolName {
          avatarType = .icon
          selectedIconName = iconName
          selectedIconColor = team.iconTintColorValue ?? .green
        }
      } else {
        nameFocused = true
        avatarType = .icon
        selectedIconName = "person.2.fill"
        selectedIconColor = .green
      }
    }
  }

  func onCancel() {
    let message =
      switch identity {
      case .player:
        identity.isCreate
          ? "player.create.cancel" : "player.edit.cancel"
      case .team:
        identity.isCreate ? "team.create.cancel" : "team.edit.cancel"
      }
    Log.event(.actionTapped, level: .info, message: message)
    dismiss()
  }

  func onSave() {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      showValidationError = true
      return
    }

    switch identity {
    case .player(let existingPlayer):
      handlePlayerSave(name: trimmed, existingPlayer: existingPlayer)

    case .team(let existingTeam):
      handleTeamSave(name: trimmed, existingTeam: existingTeam)
    }
  }

  func handlePlayerSave(name: String, existingPlayer: PlayerProfile?) {
    if let player = existingPlayer {
      do {
        Log.event(
          .saveStarted,
          level: .info,
          message: "player.edit.start",
          metadata: ["playerId": player.id.uuidString]
        )
        try manager.updatePlayer(player) { p in
          p.name = name
          p.notes = notes.isEmpty ? nil : notes
          p.skillLevel = skillLevel
          p.preferredHand = preferredHand

          switch avatarType {
          case .photo:
            p.avatarImageData = selectedPhotoData
            p.iconSymbolName = nil
            p.accentColor = nil
          case .icon:
            p.avatarImageData = nil
            p.iconSymbolName = selectedIconName.isEmpty ? nil : selectedIconName
            p.accentColor = selectedIconName.isEmpty ? nil : selectedIconColor
          }
        }
        Log.event(
          .saveSucceeded,
          level: .info,
          message: "player.edit.succeeded",
          metadata: ["playerId": player.id.uuidString]
        )
        dismiss()
      } catch {
        Log.event(
          .saveFailed,
          level: .warn,
          message: "player.edit.failed",
          metadata: [
            "playerId": player.id.uuidString,
            "error": String(describing: error),
          ]
        )
      }
    } else {
      do {
        Log.event(
          .saveStarted,
          level: .info,
          message: "player.create.start"
        )
        _ = try manager.createPlayer(name: name) { player in
          player.notes = notes.isEmpty ? nil : notes
          player.skillLevel = skillLevel
          player.preferredHand = preferredHand

          switch avatarType {
          case .photo:
            player.avatarImageData = selectedPhotoData
            player.iconSymbolName = nil
            player.accentColor = nil
          case .icon:
            player.avatarImageData = nil
            player.iconSymbolName = selectedIconName.isEmpty ? nil : selectedIconName
            player.accentColor = selectedIconName.isEmpty ? nil : selectedIconColor
          }
        }
        Log.event(
          .saveSucceeded,
          level: .info,
          message: "player.create.succeeded"
        )
        dismiss()
      } catch {
        Log.event(
          .saveFailed,
          level: .warn,
          message: "player.create.failed",
          metadata: ["error": String(describing: error)]
        )
      }
    }
  }

  func handleTeamSave(name: String, existingTeam: TeamProfile?) {
    let selectedPlayers: [PlayerProfile] = manager.players.filter {
      selectedPlayerIds.contains($0.id)
    }

    // Duplicate team detection removed

    if let team = existingTeam {
      do {
        Log.event(
          .saveStarted,
          level: .info,
          message: "team.edit.start",
          metadata: ["teamId": team.id.uuidString]
        )
        try manager.updateTeam(team) { t in
          t.name = name
          t.notes = notes.isEmpty ? nil : notes
          t.players = selectedPlayers

          switch avatarType {
          case .photo:
            t.avatarImageData = selectedPhotoData
            t.iconSymbolName = nil
            t.accentColor = nil
          case .icon:
            t.avatarImageData = nil
            t.iconSymbolName = selectedIconName.isEmpty ? nil : selectedIconName
            t.accentColor = selectedIconName.isEmpty ? nil : selectedIconColor
          }
        }
        Log.event(
          .saveSucceeded,
          level: .info,
          message: "team.edit.succeeded",
          metadata: ["teamId": team.id.uuidString]
        )
        dismiss()
      } catch {
        Log.event(
          .saveFailed,
          level: .warn,
          message: "team.edit.failed",
          metadata: [
            "teamId": team.id.uuidString,
            "error": String(describing: error),
          ]
        )
      }
    } else {
      do {
        Log.event(
          .saveStarted,
          level: .info,
          message: "team.create.start"
        )
        let team = try manager.createTeam(
          name: name,
          players: selectedPlayers
        )
        team.notes = notes.isEmpty ? nil : notes

        switch avatarType {
        case .photo:
          team.avatarImageData = selectedPhotoData
          team.iconSymbolName = nil
          team.accentColor = nil
        case .icon:
          team.avatarImageData = nil
          team.iconSymbolName = selectedIconName.isEmpty ? nil : selectedIconName
          team.accentColor = selectedIconName.isEmpty ? nil : selectedIconColor
        }
        try manager.updateTeam(team) { _ in }
        Log.event(
          .saveSucceeded,
          level: .info,
          message: "team.create.succeeded",
          metadata: ["teamId": team.id.uuidString]
        )
        dismiss()
      } catch {
        Log.event(
          .saveFailed,
          level: .warn,
          message: "team.create.failed",
          metadata: ["error": String(describing: error)]
        )
      }
    }
  }

}

// MARK: - Previews

#Preview("Create Player") {
  let setup = PreviewEnvironmentSetup.createMinimal()
  NavigationStack {
    IdentityEditorView(
      identity: .player(nil),
      manager: setup.rosterManager!
    )
  }
  .minimalPreview(environment: setup.environment)
}

#Preview("Create Team") {
  let setup = PreviewEnvironmentSetup.createMinimal()
  NavigationStack {
    IdentityEditorView(
      identity: .team(nil),
      manager: setup.rosterManager!
    )
  }
  .minimalPreview(environment: setup.environment)
}

#Preview("Edit Team") {
  let setup = PreviewEnvironmentSetup.createMinimal()
  NavigationStack {
    IdentityEditorView(
      identity: .team(nil), // Will be populated with actual team from roster
      manager: setup.rosterManager!
    )
  }
  .minimalPreview(environment: setup.environment)
}
