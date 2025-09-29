import GameTrackerCore
import SwiftUI

struct ServingSettingsSection: View {
  @Bindable var game: Game
  let disabled: Bool
  let onSwitchServer: () -> Void
  let onSetServerTeam1: () -> Void
  let onSetServerTeam2: () -> Void

  var body: some View {
    Section {
      Button(action: onSwitchServer) {
        Label("Switch Server", systemImage: "arrow.2.squarepath")
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(.primary)
      }
      .disabled(disabled)

      Button(action: onSetServerTeam1) {
        HStack {
          Label("Team 1 Serves", systemImage: "1.circle.fill")
            .font(.system(size: 14, weight: .medium))
          Spacer()
          if game.currentServer == 1 {
            Image(systemName: "checkmark")
              .font(.system(size: 12, weight: .semibold))
              .foregroundStyle(Color.accentColor)
          }
        }
        .foregroundStyle(game.currentServer == 1 ? Color.accentColor : .primary)
      }
      .disabled(disabled || game.currentServer == 1)

      Button(action: onSetServerTeam2) {
        HStack {
          Label("Team 2 Serves", systemImage: "2.circle.fill")
            .font(.system(size: 14, weight: .medium))
          Spacer()
          if game.currentServer == 2 {
            Image(systemName: "checkmark")
              .font(.system(size: 12, weight: .semibold))
              .foregroundStyle(Color.accentColor)
          }
        }
        .foregroundStyle(game.currentServer == 2 ? Color.accentColor : .primary)
      }
      .disabled(disabled || game.currentServer == 2)
    } header: {
      Text("Serving")
        .font(.caption)
        .foregroundStyle(.white)
    } footer: {
      if !disabled {
        Text(
          "Current server: \(game.currentServer == 1 ? game.effectivePlayerLabel1 : game.effectivePlayerLabel2)"
        )
        .font(.caption2)
        .foregroundStyle(.secondary)
      }
    }
  }
}
