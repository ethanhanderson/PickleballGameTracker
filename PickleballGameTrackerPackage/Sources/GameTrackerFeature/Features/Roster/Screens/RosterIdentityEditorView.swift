//
//  RosterIdentityEditorView.swift
//  Pickleball Score Tracking
//
//  Created by Agent on 8/17/25.
//

import CorePackage
import PhotosUI
import SwiftData
import SwiftUI
import UIKit
import UniformTypeIdentifiers

@MainActor
struct RosterIdentityEditorView: View {
  enum Identity: Equatable {
    case player(PlayerProfile?)
    case team(TeamProfile?)

    init(from rosterIdentity: RosterIdentityCard.Identity) {
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
  @State private var selectedIconColor: DesignSystem.AppleSystemColor = .green
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

  // Duplicate detection removed

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
        .tint(DesignSystem.Colors.primary)
        .accessibilityLabel("Skill level selection")

        VStack(
          alignment: .leading,
          spacing: DesignSystem.Spacing.sm
        ) {
          Text("Preferred Hand")
            .font(DesignSystem.Typography.body)
            .foregroundStyle(DesignSystem.Colors.textPrimary)

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

  @ViewBuilder
  private var avatarSection: some View {
    Section("Avatar") {
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
          .labelStyle(.iconOnly)
          .accessibilityLabel("Cancel")
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(action: { onSave() }) {
            Label("Save", systemImage: "checkmark")
          }
          .labelStyle(.iconOnly)
          .buttonStyle(.glassProminent)
          .tint(.green)
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
        // Coerce unknowns to sensible defaults since pickers no longer include Unknown
        skillLevel =
          player.skillLevel == .unknown
          ? .beginner : player.skillLevel
        preferredHand =
          player.preferredHand == .unknown
          ? .right : player.preferredHand

        // Load existing avatar data
        if let avatarData = player.avatarImageData {
          avatarType = .photo
          selectedPhotoData = avatarData
        } else if let iconName = player.iconSymbolName {
          avatarType = .icon
          selectedIconName = iconName
          selectedIconColor = player.iconTintColor ?? .green
        }
      } else {
        // Set defaults for new player
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

        // Load existing avatar data
        if let avatarData = team.avatarImageData {
          avatarType = .photo
          selectedPhotoData = avatarData
        } else if let iconName = team.iconSymbolName {
          avatarType = .icon
          selectedIconName = iconName
          selectedIconColor = team.iconTintColor ?? .green
        }
      } else {
        // Set defaults for new team
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
      // Edit existing player
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

          // Update avatar data
          switch avatarType {
          case .photo:
            p.avatarImageData = selectedPhotoData
            p.iconSymbolName = nil
            p.iconTintColor = nil
          case .icon:
            p.avatarImageData = nil
            p.iconSymbolName =
              selectedIconName.isEmpty ? nil : selectedIconName
            p.iconTintColor =
              selectedIconName.isEmpty ? nil : selectedIconColor
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
      // Create new player
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

          // Set avatar data
          switch avatarType {
          case .photo:
            player.avatarImageData = selectedPhotoData
            player.iconSymbolName = nil
            player.iconTintColor = nil
          case .icon:
            player.avatarImageData = nil
            player.iconSymbolName =
              selectedIconName.isEmpty ? nil : selectedIconName
            player.iconTintColor =
              selectedIconName.isEmpty ? nil : selectedIconColor
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
      // Edit existing team
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

          // Update avatar data
          switch avatarType {
          case .photo:
            t.avatarImageData = selectedPhotoData
            t.iconSymbolName = nil
            t.iconTintColor = nil
          case .icon:
            t.avatarImageData = nil
            t.iconSymbolName =
              selectedIconName.isEmpty ? nil : selectedIconName
            t.iconTintColor =
              selectedIconName.isEmpty ? nil : selectedIconColor
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
      // Create new team
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

        // Set avatar data
        switch avatarType {
        case .photo:
          team.avatarImageData = selectedPhotoData
          team.iconSymbolName = nil
          team.iconTintColor = nil
        case .icon:
          team.avatarImageData = nil
          team.iconSymbolName =
            selectedIconName.isEmpty ? nil : selectedIconName
          team.iconTintColor =
            selectedIconName.isEmpty ? nil : selectedIconColor
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

  // Duplicate alert flow removed
}

// Avatar subviews moved to Components/Avatar

// MARK: - Previews

#Preview("Create Player") {
  _ = try! PreviewGameData.createPreviewContainer(with: [])
  return NavigationStack {
    RosterIdentityEditorView(
      identity: .player(nil),
      manager: PlayerTeamManager()
    )
  }
}

#Preview("Edit Player") {
  _ = try! PreviewGameData.createPreviewContainer(with: [])
  let manager = PlayerTeamManager()
  let player = try! manager.createPlayer(name: "Taylor") { p in
    p.notes = "Lefty dinker"
    p.skillLevel = .intermediate
    p.preferredHand = .left
  }
  return NavigationStack {
    RosterIdentityEditorView(
      identity: .player(player),
      manager: manager
    )
  }
}

#Preview("Create Team") {
  let container = try! PreviewGameData.createPreviewContainer(with: [])
  let context = container.mainContext
  let alice = PlayerProfile(name: "Alice")
  let bob = PlayerProfile(name: "Bob")
  context.insert(alice)
  context.insert(bob)
  try? context.save()
  return NavigationStack {
    RosterIdentityEditorView(
      identity: .team(nil),
      manager: PlayerTeamManager()
    )
  }
}

#Preview("Edit Team") {
  let manager = PlayerTeamManager()
  let alice = try! manager.createPlayer(name: "Alice")
  let bob = try! manager.createPlayer(name: "Bob")
  let team = try! manager.createTeam(name: "Aces", players: [alice, bob])
  return NavigationStack {
    RosterIdentityEditorView(
      identity: .team(team),
      manager: manager
    )
  }
}
