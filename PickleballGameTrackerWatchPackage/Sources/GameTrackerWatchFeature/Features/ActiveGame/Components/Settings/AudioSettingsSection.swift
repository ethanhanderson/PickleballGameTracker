import GameTrackerCore
import SwiftUI

struct AudioSettingsSection: View {
  @Binding var soundEnabled: Bool

  var body: some View {
    Section {
      Toggle("Sound Effects", isOn: $soundEnabled)
        .font(.system(size: 14, weight: .medium))
    } header: {
      Text("Audio")
        .font(.caption)
        .foregroundStyle(.white)
    }
  }
}


