import GameTrackerCore
//
//  WatchLiveSettingsView.swift
//  Pickleball Score Tracking Watch App
//
//  Created by Ethan Anderson on 7/9/25.
//

import SwiftData
import SwiftUI

@MainActor
struct WatchLiveSettingsView: View {
  @Bindable var game: Game
  let gameManager: SwiftDataGameManager
  let liveGameStateManager: LiveGameStateManager

  @Environment(\.dismiss) private var dismiss

  @AppStorage("watchHapticEnabled") private var hapticEnabled = true

  var body: some View {
    Group {
      if game.modelContext == nil {
        Color.clear
          .task { dismiss() }
      } else {
        NavigationStack {
          List {
            Section {
              Toggle("Haptic Feedback", isOn: $hapticEnabled)
                .font(.system(size: 14, weight: .medium))
            } header: {
              Text("Haptics")
                .font(.caption)
                .foregroundStyle(.white)
            }
          }
          .navigationTitle("Settings")
          .navigationBarTitleDisplayMode(.inline)
        }
      }
    }
    .onChange(of: game.modelContext == nil) { _, detached in
      if detached { dismiss() }
    }
  }
}

// MARK: - Previews

#Preview("Settings View") {
  let container = PreviewContainers.liveGame()
  let (gameManager, liveGameManager) = PreviewContainers.managers(for: container)
  
  WatchLiveSettingsView(
    game: PreviewGameData.midGame,
    gameManager: gameManager,
    liveGameStateManager: liveGameManager
  )
  .modelContainer(container)
}

#Preview("Settings - Completed Game") {
  let container = PreviewContainers.standard()
  let (gameManager, liveGameManager) = PreviewContainers.managers(for: container)
  
  WatchLiveSettingsView(
    game: PreviewGameData.completedGame,
    gameManager: gameManager,
    liveGameStateManager: liveGameManager
  )
  .modelContainer(container)
}
