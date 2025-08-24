import PickleballGameTrackerCorePackage
import SwiftUI

/// Simple KPI row with title on the left and value on the right.
struct KPIRow: View {
  let title: String
  let value: String
  var body: some View {
    HStack {
      Text(title)
        .font(DesignSystem.Typography.body)
      Spacer()
      Text(value)
        .font(DesignSystem.Typography.title2)
    }
    .padding(12)
    .background(
      RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.cardRounded, style: .continuous)
        .fill(DesignSystem.Colors.containerFillSecondary)
    )
  }
}
