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
  @State private var showDuplicateAlert: Bool = false
  @State private var duplicateNames: [String] = []
  @State private var pendingSaveAfterDuplicateWarning: Bool = false
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

  private var duplicateAlertMessage: Text {
    let namesSuffix =
      duplicateNames.isEmpty
      ? ""
      : " (e.g., \(duplicateNames.joined(separator: ", ")))"
    return Text("A team with the same members\(namesSuffix) already exists.")
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
    .alert(
      "Team already exists",
      isPresented: $showDuplicateAlert,
      actions: {
        Button("Create Anyway", role: .destructive) {
          proceedAfterDuplicateWarning()
        }
        Button("Cancel", role: .cancel) {
          pendingSaveAfterDuplicateWarning = false
        }
      },
      message: { duplicateAlertMessage }
    )
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

    // Check for duplicates only when creating a new team
    if existingTeam == nil {
      let dups = manager.findDuplicateTeams(
        candidates: selectedPlayers,
        name: name
      )
      if !dups.isEmpty && !pendingSaveAfterDuplicateWarning {
        duplicateNames = dups.map { $0.name }
        pendingSaveAfterDuplicateWarning = true
        showDuplicateAlert = true
        return
      }
    }

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

  func proceedAfterDuplicateWarning() {
    showDuplicateAlert = false
    onSave()
  }
}

// MARK: - Avatar Subviews

@MainActor
private struct PhotoAvatarContent: View {
  @Binding var selectedPhotoData: Data?
  @Binding var selectedPhotoItem: PhotosPickerItem?
  @Binding var showingCamera: Bool

  var body: some View {
    HStack {
      Spacer()
      Group {
        if let photoData = selectedPhotoData, let uiImage = UIImage(data: photoData) {
          Image(uiImage: uiImage)
            .resizable()
            .scaledToFill()
            .frame(width: 96, height: 96)
            .clipShape(Circle())
            .overlay(
              Circle().stroke(DesignSystem.Colors.surfaceSecondary.opacity(0.3), lineWidth: 2)
            )
            .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 4)
            .transition(.opacity)
        } else {
          Circle()
            .fill(DesignSystem.Colors.surfaceSecondary.opacity(0.3))
            .frame(width: 96, height: 96)
            .overlay(
              Image(systemName: "photo.fill")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(DesignSystem.Colors.textSecondary.opacity(0.6))
            )
            .transition(.opacity)
        }
      }
      .animation(.easeInOut(duration: 0.15), value: selectedPhotoData)
      .accessibilityLabel("Photo preview")
      Spacer()
    }

    // Remove photo button - only shown when photo is selected
    if selectedPhotoData != nil {
      Button(action: {
        selectedPhotoData = nil
        selectedPhotoItem = nil
      }) {
        HStack {
          Image(systemName: "trash.fill")
            .foregroundStyle(.red)
          Text("Remove Photo")
            .foregroundStyle(.red)
          Spacer()
        }
      }
      .accessibilityLabel("Remove selected photo")
    }

    let buttonTitle = (selectedPhotoData != nil) ? "Change Photo" : "Choose Photo"
    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
      HStack {
        Image(systemName: "photo.badge.plus.fill")
        Text(buttonTitle)
        Spacer()
        Image(systemName: "chevron.right")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(DesignSystem.Colors.textSecondary)
      }
      .foregroundStyle(DesignSystem.Colors.textPrimary)
    }
    .accessibilityLabel("Select photo for avatar")
    .onChange(of: selectedPhotoItem, initial: false) { _, newItem in
      if let newItem = newItem {
        Task {
          if let data = try? await newItem.loadTransferable(type: Data.self),
            let image = UIImage(data: data),
            let resizedData = image.jpegData(compressionQuality: 0.8)
          {
            await MainActor.run { selectedPhotoData = resizedData }
          }
        }
      } else {
        selectedPhotoData = nil
      }
    }

    Button(action: { showingCamera = true }) {
      HStack {
        Image(systemName: "camera.viewfinder")
        Text("Take Photo")
        Spacer()
        Image(systemName: "chevron.right")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(DesignSystem.Colors.textSecondary)
      }
      .foregroundStyle(DesignSystem.Colors.textPrimary)
    }
    .accessibilityLabel("Take photo with camera")
  }
}

@MainActor
private struct IconAvatarContent: View {
  @Binding var selectedIconName: String
  @Binding var selectedIconColor: DesignSystem.AppleSystemColor
  let iconOptions: [String]

  var body: some View {
    VStack(alignment: .center, spacing: DesignSystem.Spacing.lg) {
      Group {
        if !selectedIconName.isEmpty {
          Image(systemName: selectedIconName)
            .font(.system(size: 44, weight: .semibold))
            .foregroundStyle(selectedIconColor.color)
            .shadow(color: selectedIconColor.color.opacity(0.6), radius: 3)
            .transition(.opacity)
        } else {
          Image(systemName: "person.fill")
            .font(.system(size: 44, weight: .semibold))
            .foregroundStyle(DesignSystem.Colors.primary.gradient)
            .shadow(color: DesignSystem.Colors.primary.opacity(0.6), radius: 3)
            .transition(.opacity)
        }
      }
      .animation(.easeInOut(duration: 0.15), value: selectedIconName)
      .animation(.easeInOut(duration: 0.15), value: selectedIconColor)
      .frame(width: 96, height: 96)
      .background(
        Circle()
          .fill(
            selectedIconName.isEmpty
              ? DesignSystem.Colors.primary.opacity(0.15).gradient
              : selectedIconColor.color.opacity(0.15).gradient
          )
          .transition(.opacity)
          .animation(.easeInOut(duration: 0.15), value: selectedIconColor)
      )
      .accessibilityLabel("Icon preview")

      VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
        Text("Icon")
          .font(DesignSystem.Typography.body)
          .fontWeight(.semibold)
          .foregroundStyle(DesignSystem.Colors.textPrimary)

        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: DesignSystem.Spacing.md) {
            ForEach(iconOptions, id: \.self) { iconName in
              ZStack {
                Circle()
                  .fill(
                    selectedIconName == iconName
                      ? selectedIconColor.color.opacity(0.2)
                      : DesignSystem.Colors.surfaceSecondary.opacity(0.3)
                  )
                  .frame(width: 46, height: 46)

                Image(systemName: iconName)
                  .resizable()
                  .scaledToFit()
                  .frame(width: 22, height: 22)
                  .foregroundStyle(
                    selectedIconName == iconName
                      ? selectedIconColor.color
                      : DesignSystem.Colors.textSecondary
                  )
              }
              .overlay(
                selectedIconName == iconName
                  ? Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 46, height: 46)
                    .overlay(
                      Image(systemName: "checkmark")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(selectedIconColor.color.opacity(0.8))
                    )
                    .transition(.scale.combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.12), value: selectedIconName)
                  : nil
              )
              .onTapGesture { selectedIconName = iconName }
              .accessibilityLabel("Select \(iconName) icon")
              .accessibilityAddTraits(selectedIconName == iconName ? .isSelected : [])
            }
          }
        }
      }

      VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
        Text("Color")
          .font(DesignSystem.Typography.body)
          .fontWeight(.semibold)
          .foregroundStyle(DesignSystem.Colors.textPrimary)

        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: DesignSystem.Spacing.md) {
            ForEach(DesignSystem.AppleSystemColor.allCases, id: \.self) { color in
              ZStack {
                Circle()
                  .fill(color.color)
                  .frame(width: 46, height: 46)
                  .overlay(
                    selectedIconColor == color
                      ? Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 46, height: 46)
                        .overlay(
                          Image(systemName: "checkmark")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(selectedIconColor.color.opacity(0.8))
                        )
                        .transition(.scale.combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.12), value: selectedIconColor)
                      : nil
                  )
              }
              .onTapGesture { selectedIconColor = color }
              .accessibilityLabel("Select \(color.displayName) color")
              .accessibilityAddTraits(selectedIconColor == color ? .isSelected : [])
            }
          }
        }
      }
    }
  }
}

// MARK: - Camera Picker

@MainActor
struct CameraPicker: UIViewControllerRepresentable {
  @Binding var selectedImageData: Data?
  @Environment(\.dismiss) private var dismiss

  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.sourceType = .camera
    picker.cameraCaptureMode = .photo
    picker.cameraDevice = .rear
    picker.showsCameraControls = true
    picker.delegate = context.coordinator
    return picker
  }

  func updateUIViewController(
    _ uiViewController: UIImagePickerController,
    context: Context
  ) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, UIImagePickerControllerDelegate,
    UINavigationControllerDelegate
  {
    let parent: CameraPicker

    init(_ parent: CameraPicker) {
      self.parent = parent
    }

    func imagePickerController(
      _ picker: UIImagePickerController,
      didFinishPickingMediaWithInfo info: [UIImagePickerController
        .InfoKey: Any]
    ) {
      if let image = info[.originalImage] as? UIImage,
        let imageData = image.jpegData(compressionQuality: 0.8)
      {
        parent.selectedImageData = imageData
      }
      parent.dismiss()
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      parent.dismiss()
    }
  }
}

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
