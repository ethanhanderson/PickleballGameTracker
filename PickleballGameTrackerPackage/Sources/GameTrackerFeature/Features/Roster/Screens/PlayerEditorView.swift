//
//  PlayerEditorView.swift
//  Pickleball Score Tracking
//
//  Created by Agent on 8/16/25.
//

import PickleballGameTrackerCorePackage
import SwiftData
import SwiftUI

@MainActor
struct PlayerEditorView: View {
  enum Mode: Equatable {
    case create
    case edit(PlayerProfile)
  }

  @Environment(\.dismiss) private var dismiss

  let mode: Mode
  let manager: PlayerTeamManager

  @State private var name: String = ""
  @State private var notes: String = ""
  @State private var iconSymbolName: String = ""
  @State private var iconTintHex: String = ""
  @State private var skillLevel: PlayerSkillLevel = .unknown
  @State private var preferredHand: PlayerHandedness = .unknown

  @State private var showValidationError: Bool = false
  @FocusState private var nameFocused: Bool

  init(mode: Mode, manager: PlayerTeamManager) {
    self.mode = mode
    self.manager = manager
    // Initial values populated in body via onAppear to avoid @State init limits
  }

  private var isCreate: Bool {
    if case .create = mode { return true }
    return false
  }

  private var title: String {
    isCreate ? "New Player" : "Edit Player"
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
        symbolPlaceholder: "SF Symbol name (e.g., person.fill)"
      )

      Section("Attributes (optional)") {
        Picker("Skill level", selection: $skillLevel) {
          Text("Unknown").tag(PlayerSkillLevel.unknown)
          Text("Beginner").tag(PlayerSkillLevel.beginner)
          Text("Intermediate").tag(PlayerSkillLevel.intermediate)
          Text("Advanced").tag(PlayerSkillLevel.advanced)
          Text("Expert").tag(PlayerSkillLevel.expert)
        }
        Picker("Preferred hand", selection: $preferredHand) {
          Text("Unknown").tag(PlayerHandedness.unknown)
          Text("Right").tag(PlayerHandedness.right)
          Text("Left").tag(PlayerHandedness.left)
          Text("Ambidextrous").tag(PlayerHandedness.ambidextrous)
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
  }

  private func populateFromModeIfNeeded() {
    if case .edit(let player) = mode {
      name = player.name
      notes = player.notes ?? ""
      iconSymbolName = player.iconSymbolName ?? ""
      iconTintHex = player.iconTintHex ?? ""
      skillLevel = player.skillLevel
      preferredHand = player.preferredHand
    } else {
      nameFocused = true
    }
  }

  private func onCancel() {
    Log.event(
      .actionTapped, level: .info, message: isCreate ? "player.create.cancel" : "player.edit.cancel"
    )
    dismiss()
  }

  private func onSave() {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      showValidationError = true
      return
    }

    switch mode {
    case .create:
      do {
        Log.event(.saveStarted, level: .info, message: "player.create.start")
        _ = try manager.createPlayer(name: trimmed) { player in
          player.notes = notes.isEmpty ? nil : notes
          player.iconSymbolName = iconSymbolName.isEmpty ? nil : iconSymbolName
          player.iconTintHex = iconTintHex.isEmpty ? nil : iconTintHex
          player.skillLevel = skillLevel
          player.preferredHand = preferredHand
        }
        Log.event(.saveSucceeded, level: .info, message: "player.create.succeeded")
        dismiss()
      } catch {
        Log.event(
          .saveFailed, level: .warn, message: "player.create.failed",
          metadata: ["error": String(describing: error)])
      }

    case .edit(let player):
      do {
        Log.event(
          .saveStarted, level: .info, message: "player.edit.start",
          metadata: ["playerId": player.id.uuidString])
        try manager.updatePlayer(player) { p in
          p.name = trimmed
          p.notes = notes.isEmpty ? nil : notes
          p.iconSymbolName = iconSymbolName.isEmpty ? nil : iconSymbolName
          p.iconTintHex = iconTintHex.isEmpty ? nil : iconTintHex
          p.skillLevel = skillLevel
          p.preferredHand = preferredHand
        }
        Log.event(
          .saveSucceeded, level: .info, message: "player.edit.succeeded",
          metadata: ["playerId": player.id.uuidString])
        dismiss()
      } catch {
        Log.event(
          .saveFailed, level: .warn, message: "player.edit.failed",
          metadata: ["playerId": player.id.uuidString, "error": String(describing: error)])
      }
    }
  }
}

#Preview("Create") {
  _ = try! PreviewGameData.createPreviewContainer(with: [])
  return NavigationStack { PlayerEditorView(mode: .create, manager: PlayerTeamManager()) }
}

#Preview("Edit") {
  _ = try! PreviewGameData.createPreviewContainer(with: [])
  let manager = PlayerTeamManager()
  let player = try! manager.createPlayer(name: "Taylor") { p in
    p.notes = "Lefty dinker"
    p.iconSymbolName = "person.fill"
    p.iconTintHex = "#34C759"
    p.skillLevel = .intermediate
    p.preferredHand = .left
  }
  return NavigationStack {
    PlayerEditorView(mode: .edit(player), manager: manager)
  }
}
