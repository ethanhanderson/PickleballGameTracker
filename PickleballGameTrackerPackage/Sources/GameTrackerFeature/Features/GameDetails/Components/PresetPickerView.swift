//
//  PresetPickerView.swift
//  Pickleball Score Tracking
//
//  Created by Agent on 8/15/25.
//

import SharedGameCore
import SwiftData
import SwiftUI

struct PresetPickerView: View {
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
                  .foregroundStyle(DesignSystem.Colors.primary)
                VStack(alignment: .leading, spacing: 2) {
                  Text(preset.name)
                    .font(DesignSystem.Typography.body)
                  if let t1 = preset.team1, let t2 = preset.team2 {
                    Text("\(t1.name) vs \(t2.name)")
                      .font(DesignSystem.Typography.caption)
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
    .task { await manager.refreshAll() }
  }
}

#Preview("Presets for Recreational") {
  let container = try! PreviewGameData.createFullPreviewContainer()
  return NavigationStack {
    PresetPickerView(gameType: .recreational) { _ in }
  }
  .modelContainer(container)
}
