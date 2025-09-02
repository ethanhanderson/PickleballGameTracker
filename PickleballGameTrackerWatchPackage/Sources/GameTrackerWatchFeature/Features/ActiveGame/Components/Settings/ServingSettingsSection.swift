import CorePackage
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
          .foregroundColor(.primary)
      }
      .disabled(disabled)

      Button(action: onSetServerTeam1) {
        HStack {
          Label("Team 1 Serves", systemImage: "1.circle")
            .font(.system(size: 14, weight: .medium))
          Spacer()
          if game.currentServer == 1 {
            Image(systemName: "checkmark")
              .font(.system(size: 12, weight: .semibold))
              .foregroundColor(DesignSystem.Colors.primary)
          }
        }
        .foregroundColor(game.currentServer == 1 ? DesignSystem.Colors.primary : .primary)
      }
      .disabled(disabled || game.currentServer == 1)

      Button(action: onSetServerTeam2) {
        HStack {
          Label("Team 2 Serves", systemImage: "2.circle")
            .font(.system(size: 14, weight: .medium))
          Spacer()
          if game.currentServer == 2 {
            Image(systemName: "checkmark")
              .font(.system(size: 12, weight: .semibold))
              .foregroundColor(DesignSystem.Colors.primary)
          }
        }
        .foregroundColor(game.currentServer == 2 ? DesignSystem.Colors.primary : .primary)
      }
      .disabled(disabled || game.currentServer == 2)
    } header: {
      Text("Serving")
        .font(.caption)
        .foregroundColor(.white)
    } footer: {
      if !disabled {
        Text(
          "Current server: \(game.currentServer == 1 ? game.effectivePlayerLabel1 : game.effectivePlayerLabel2)"
        )
        .font(.caption2)
        .foregroundColor(.secondary)
      }
    }
  }
}
