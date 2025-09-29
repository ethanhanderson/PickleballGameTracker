import GameTrackerCore
import SwiftUI

struct HapticSettingsSection: View {
  @Binding var hapticEnabled: Bool
  @Binding var hapticIntensity: Double

  var body: some View {
    Section {
      Toggle("Haptic Feedback", isOn: $hapticEnabled)
        .font(.system(size: 14, weight: .medium))

      if hapticEnabled {
        VStack(alignment: .leading, spacing: 4) {
          Text("Intensity")
            .font(.caption)
            .foregroundStyle(.secondary)

          HStack {
            Text("Light")
              .font(.caption2)
              .foregroundStyle(.secondary)

            Slider(value: $hapticIntensity, in: 0.5...2.0, step: 0.5)
              .tint(Color.accentColor)

            Text("Strong")
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
        }
        .padding(.vertical, 2)
      }
    } header: {
      Text("Haptics")
        .font(.caption)
        .foregroundStyle(.white)
    }
  }
}


