import GameTrackerCore
import SwiftUI

@MainActor
struct SelectablePlayerRow: View {
  let name: String
  let isSelected: Bool
  let onToggle: () -> Void

  var body: some View {
    Button(action: onToggle) {
      HStack(spacing: DesignSystem.Spacing.sm) {
        Image(systemName: "person.crop.circle")
          .foregroundStyle(Color.accentColor)
        Text(name)
        Spacer()
        if isSelected {
          Image(systemName: "checkmark")
            .foregroundStyle(Color.accentColor)
        }
      }
    }
    .buttonStyle(.plain)
  }
}
