import SharedGameCore
import SwiftUI

struct DisplaySettingsSection: View {
  @Binding var timerVisible: Bool
  @Binding var servingIndicatorVisible: Bool

  var body: some View {
    Section {
      Toggle("Timer Display", isOn: $timerVisible)
        .font(.system(size: 14, weight: .medium))

      Toggle("Serving Indicator", isOn: $servingIndicatorVisible)
        .font(.system(size: 14, weight: .medium))
    } header: {
      Text("Display")
        .font(.caption)
        .foregroundColor(.white)
    }
  }
}
