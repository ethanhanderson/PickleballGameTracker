import GameTrackerCore
import SwiftUI

@MainActor
struct NavigationTitleWithIcon: View {
  let systemImageName: String
  let title: String
  let gradient: AnyGradient
  let show: Bool

  var body: some View {
    HStack(spacing: DesignSystem.Spacing.sm) {
      Image(systemName: systemImageName)
        .font(.system(size: 24, weight: .medium))
        .foregroundStyle(gradient)

      Text(title)
        .font(.headline)
        .fontWeight(.semibold)
        .foregroundStyle(.primary)
    }
    .opacity(show ? 1.0 : 0.0)
    .offset(y: show ? 0 : 4)
    .animation(
      .easeInOut(duration: 0.2),
      value: show
    )
  }
}
