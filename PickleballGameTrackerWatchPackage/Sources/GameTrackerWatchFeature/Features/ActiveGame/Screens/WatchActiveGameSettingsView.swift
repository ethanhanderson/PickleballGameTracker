//
//  WatchActiveGameSettingsView.swift
//  Pickleball Score Tracking Watch App
//
//  Created by Ethan Anderson on 7/9/25.
//

import CorePackage
import SwiftData
import SwiftUI

struct WatchActiveGameSettingsView: View {
  @Bindable var game: Game
  let gameManager: SwiftDataGameManager
  let activeGameStateManager: ActiveGameStateManager

  @Environment(\.dismiss) private var dismiss

  // Local settings state - would ideally be persisted via @AppStorage
  @AppStorage("watchSoundEnabled") private var soundEnabled = true
  @AppStorage("watchHapticEnabled") private var hapticEnabled = true
  @AppStorage("watchTimerVisible") private var timerVisible = true
  @AppStorage("watchServingIndicatorVisible") private var servingIndicatorVisible = true
  @AppStorage("watchHapticIntensity") private var hapticIntensity = 1.0

  // Haptic feedback triggers
  @State private var switchClickTrigger = false
  @State private var switchSuccessTrigger = false
  @State private var switchFailureTrigger = false
  @State private var setServerClickTrigger = false
  @State private var setServerSuccessTrigger = false
  @State private var setServerFailureTrigger = false

  var body: some View {
    NavigationStack {
      List {
        AudioSettingsSection(soundEnabled: $soundEnabled)
        HapticSettingsSection(hapticEnabled: $hapticEnabled, hapticIntensity: $hapticIntensity)
        DisplaySettingsSection(
          timerVisible: $timerVisible, servingIndicatorVisible: $servingIndicatorVisible)
        ServingSettingsSection(
          game: game,
          disabled: game.isCompleted,
          onSwitchServer: switchServer,
          onSetServerTeam1: { setServerToTeam(1) },
          onSetServerTeam2: { setServerToTeam(2) }
        )
      }
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
      .sensoryFeedback(.success, trigger: switchSuccessTrigger)
      .sensoryFeedback(.error, trigger: switchFailureTrigger)
      .sensoryFeedback(.success, trigger: setServerSuccessTrigger)
      .sensoryFeedback(.error, trigger: setServerFailureTrigger)
    }
  }

  // MARK: - Audio Section

  // MARK: - Actions

  private func switchServer() {
    guard !game.isCompleted else { return }

    Task {
      do {
        try await gameManager.switchServer(in: game)

        // Provide feedback
        if soundEnabled {
          // Sound feedback would be handled separately if needed
        }
        if hapticEnabled {
          switchSuccessTrigger.toggle()
        }
      } catch {
        Log.error(
          error,
          event: .serverSwitched,
          context: .current(gameId: game.id),
          metadata: ["action": "switchServer", "platform": "watchOS"]
        )
        if soundEnabled {
          // Sound feedback would be handled separately if needed
        }
        if hapticEnabled {
          switchFailureTrigger.toggle()
        }
      }
    }
  }

  private func setServerToTeam(_ team: Int) {
    guard !game.isCompleted && game.currentServer != team else { return }

    Task {
      do {
        try await gameManager.setServer(to: team, in: game)

        // Provide feedback
        if soundEnabled {
          // Sound feedback would be handled separately if needed
        }
        if hapticEnabled {
          setServerSuccessTrigger.toggle()
        }
      } catch {
        Log.error(
          error,
          event: .serverSwitched,
          context: .current(gameId: game.id),
          metadata: ["action": "setServer", "team": String(team), "platform": "watchOS"]
        )
        if soundEnabled {
          // Sound feedback would be handled separately if needed
        }
        if hapticEnabled {
          setServerFailureTrigger.toggle()
        }
      }
    }
  }
}

// MARK: - Previews

#Preview("Settings View") {
  WatchActiveGameSettingsView(
    game: PreviewGameData.midGame,
    gameManager: PreviewGameData.gameManager,
    activeGameStateManager: ActiveGameStateManager.shared
  )
  .modelContainer(try! PreviewGameData.createPreviewContainer(with: [PreviewGameData.midGame]))
}

#Preview("Settings - Completed Game") {
  WatchActiveGameSettingsView(
    game: PreviewGameData.completedGame,
    gameManager: PreviewGameData.gameManager,
    activeGameStateManager: ActiveGameStateManager.shared
  )
  .modelContainer(
    try! PreviewGameData.createPreviewContainer(with: [PreviewGameData.completedGame]))
}
