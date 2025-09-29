import GameTrackerCore
import SwiftUI

/// Simple KPI row with title on the left and value on the right.
struct KPIRow: View {
  let title: String
  let value: String
  var body: some View {
    HStack {
      Text(title)
        .font(.body)
        .foregroundStyle(.secondary)
      Spacer()
      Text(value)
        .font(.title2)
        .foregroundStyle(.primary)
    }
    .padding(DesignSystem.Spacing.md)
    .background(
      RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl, style: .continuous)
        .fill(Color.gray.opacity(0.15))
    )
  }
}
