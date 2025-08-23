//
//  TeamEditorView.swift
//  Pickleball Score Tracking
//
//  Created by Agent on 8/17/25.
//

import SharedGameCore
import SwiftData
import SwiftUI

@MainActor
struct TeamEditorView: View {
  enum Mode: Equatable {
    case create
    case edit(TeamProfile)
  }

  @Environment(\.dismiss) private var dismiss

  let mode: Mode
  let manager: PlayerTeamManager

  @State private var name: String = ""
  @State private var notes: String = ""
  @State private var iconSymbolName: String = ""
  @State private var iconTintHex: String = ""
  @State private var selectedPlayerIds: Set<UUID> = []

  @State private var showValidationError: Bool = false
  @State private var showDuplicateAlert: Bool = false
  @State private var duplicateNames: [String] = []
  @State private var pendingSaveAfterDuplicateWarning: Bool = false
  @FocusState private var nameFocused: Bool

  init(mode: Mode, manager: PlayerTeamManager) {
    self.mode = mode
    self.manager = manager
  }

  private var isCreate: Bool {
    if case .create = mode { return true }
    return false
  }

  private var title: String {
    isCreate ? "New Team" : "Edit Team"
  }

  private var saveDisabled: Bool {
    name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  var body: some View {
    Form {
      Section("Identity") {
        TextField("Name", text: $name)
          .focused($nameFocused)
        if showValidationError && saveDisabled {
          Text("Name is required").foregroundStyle(.red)
        }
      }

      AppearanceFieldsSection(
        iconSymbolName: $iconSymbolName,
        iconTintHex: $iconTintHex,
        symbolPlaceholder: "SF Symbol name (e.g., person.2.fill)"
      )

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

      Section("Notes (optional)") {
        TextEditor(text: $notes)
          .frame(minHeight: 100)
      }
    }
    .navigationTitle(title)
    .toolbar {
      ToolbarItem(placement: .navigationBarLeading) {
        Button("Cancel") { onCancel() }
      }
      ToolbarItem(placement: .navigationBarTrailing) {
        Button("Save") { onSave() }
          .disabled(saveDisabled)
      }
    }
    .onAppear { populateFromModeIfNeeded() }
    .alert(
      "Possible duplicate team",
      isPresented: $showDuplicateAlert,
      actions: {
        Button("Create Anyway", role: .destructive) { proceedAfterDuplicateWarning() }
        Button("Cancel", role: .cancel) { pendingSaveAfterDuplicateWarning = false }
      },
      message: {
        Text(
          "A team with the same members\(duplicateNames.isEmpty ? "" : " (e.g., \(duplicateNames.joined(separator: ", ")))") already exists."
        )
      }
    )
  }

  private func toggleSelection(for id: UUID) {
    if selectedPlayerIds.contains(id) {
      selectedPlayerIds.remove(id)
    } else {
      selectedPlayerIds.insert(id)
    }
  }

  private func populateFromModeIfNeeded() {
    if case .edit(let team) = mode {
      name = team.name
      notes = team.notes ?? ""
      iconSymbolName = team.iconSymbolName ?? ""
      iconTintHex = team.iconTintHex ?? ""
      selectedPlayerIds = Set(team.players.map { $0.id })
    } else {
      nameFocused = true
    }
  }

  private func onCancel() {
    Log.event(
      .actionTapped, level: .info, message: isCreate ? "team.create.cancel" : "team.edit.cancel")
    dismiss()
  }

  private func onSave() {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      showValidationError = true
      return
    }

    let selectedPlayers: [PlayerProfile] = manager.players.filter {
      selectedPlayerIds.contains($0.id)
    }
    let dups = manager.findDuplicateTeams(candidates: selectedPlayers, name: trimmed)
    if !dups.isEmpty && !pendingSaveAfterDuplicateWarning {
      duplicateNames = dups.map { $0.name }
      pendingSaveAfterDuplicateWarning = true
      showDuplicateAlert = true
      return
    }

    switch mode {
    case .create:
      do {
        Log.event(.saveStarted, level: .info, message: "team.create.start")
        let team = try manager.createTeam(name: trimmed, players: selectedPlayers)
        team.notes = notes.isEmpty ? nil : notes
        team.iconSymbolName = iconSymbolName.isEmpty ? nil : iconSymbolName
        team.iconTintHex = iconTintHex.isEmpty ? nil : iconTintHex
        try manager.updateTeam(team) { _ in }
        Log.event(
          .saveSucceeded, level: .info, message: "team.create.succeeded",
          metadata: ["teamId": team.id.uuidString])
        dismiss()
      } catch {
        Log.event(
          .saveFailed, level: .warn, message: "team.create.failed",
          metadata: ["error": String(describing: error)])
      }

    case .edit(let team):
      do {
        Log.event(
          .saveStarted, level: .info, message: "team.edit.start",
          metadata: ["teamId": team.id.uuidString])
        try manager.updateTeam(team) { t in
          t.name = trimmed
          t.notes = notes.isEmpty ? nil : notes
          t.iconSymbolName = iconSymbolName.isEmpty ? nil : iconSymbolName
          t.iconTintHex = iconTintHex.isEmpty ? nil : iconTintHex
          t.players = selectedPlayers
        }
        Log.event(
          .saveSucceeded, level: .info, message: "team.edit.succeeded",
          metadata: ["teamId": team.id.uuidString])
        dismiss()
      } catch {
        Log.event(
          .saveFailed, level: .warn, message: "team.edit.failed",
          metadata: ["teamId": team.id.uuidString, "error": String(describing: error)])
      }
    }
  }

  private func proceedAfterDuplicateWarning() {
    showDuplicateAlert = false
    onSave()
  }
}

#Preview("Create") {
  let container = try! PreviewGameData.createPreviewContainer(with: [])
  let context = container.mainContext
  let alice = PlayerProfile(name: "Alice")
  let bob = PlayerProfile(name: "Bob")
  context.insert(alice)
  context.insert(bob)
  try? context.save()
  return NavigationStack {
    TeamEditorView(mode: .create, manager: PlayerTeamManager())
  }
}

#Preview("Edit") {
  let container = try! PreviewGameData.createPreviewContainer(with: [])
  let manager = PlayerTeamManager()
  let alice = try! manager.createPlayer(name: "Alice")
  let bob = try! manager.createPlayer(name: "Bob")
  let team = try! manager.createTeam(name: "Aces", players: [alice, bob])
  return NavigationStack { TeamEditorView(mode: .edit(team), manager: manager) }
}
