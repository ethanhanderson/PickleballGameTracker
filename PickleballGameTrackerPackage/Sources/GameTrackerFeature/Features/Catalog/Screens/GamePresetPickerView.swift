//
//  GamePresetPickerView.swift
//

import GameTrackerCore
import SwiftData
import SwiftUI

struct GamePresetPickerView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  @Environment(PlayerTeamManager.self) private var manager
  let gameType: GameType
  let onSelect: (GameTypePreset) -> Void
  
  @Query private var allPresets: [GameTypePreset]
  
  private var presets: [GameTypePreset] {
    allPresets.filter { $0.gameType == gameType }
  }

  var body: some View {
    List {
      Section(header: Text("Presets for \(gameType.displayName)")) {
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
  }
}

#Preview {
  let container = PreviewContainers.standard()
  
  GamePresetPickerView(
    gameType: .recreational,
    onSelect: { _ in }
  )
  .modelContainer(container)
  .tint(.green)
}

