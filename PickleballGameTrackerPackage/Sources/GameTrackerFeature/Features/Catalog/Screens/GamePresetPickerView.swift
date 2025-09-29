//
//  GamePresetPickerView.swift
//

import GameTrackerCore
import SwiftData
import SwiftUI

struct GamePresetPickerView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  let gameType: GameType
  let onSelect: (GameTypePreset) -> Void

  @State private var manager = PlayerTeamManager()

  var body: some View {
    List {
      Section(header: Text("Presets for \(gameType.displayName)")) {
        let presets = manager.presets.filter { $0.gameType == gameType }
        if presets.isEmpty {
          Text("No presets yet")
            .foregroundStyle(.secondary)
        } else {
          ForEach(presets, id: \.id) { preset in
            Button {
              onSelect(preset)
              dismiss()
            } label: {
              HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "text.badge.plus")
                  .tint(.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                  Text(preset.name)
                    .font(.body)
                  if let t1 = preset.team1, let t2 = preset.team2 {
                    Text("\(t1.name) vs \(t2.name)")
                      .font(.caption)
                      .foregroundStyle(.secondary)
                  }
                }
              }
            }
          }
        }
      }
    }
    .navigationTitle("Start from Preset")
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Close") { dismiss() }
      }
    }
    .task { manager.refreshAll() }
  }
}


