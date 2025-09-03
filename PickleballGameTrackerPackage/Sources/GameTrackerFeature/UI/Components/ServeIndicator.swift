import CorePackage
import SwiftUI

@MainActor
struct ServeIndicator: View {
  let isServing: Bool
  let teamColor: Color

  var body: some View {
    HStack(spacing: DesignSystem.Spacing.xs) {
      Circle()
        .fill(teamColor)
        .frame(width: 8, height: 8)
      Text("SERVING")
        .font(.system(size: 11, weight: .bold, design: .rounded))
        .foregroundColor(.secondary)
        .tracking(1.0)
    }
    .opacity(isServing ? 1.0 : 0.0)
  }
}
