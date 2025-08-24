import PickleballGameTrackerCorePackage
import SwiftUI

/// Lightweight line chart placeholder used across statistics detail views.
/// Renders a titled card with an optional simple line path for provided points.
struct StatChartPlaceholder: View {
  let title: String
  var points: [TrendPoint] = []

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(DesignSystem.Typography.body)
      ZStack(alignment: .bottomLeading) {
        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.cardRounded)
          .fill(DesignSystem.Colors.containerFillSecondary)
          .frame(height: 160)
        if !points.isEmpty {
          GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let maxV = max(points.map { $0.value }.max() ?? 1, 0.01)
            let step = w / CGFloat(max(points.count - 1, 1))
            Path { p in
              for (idx, pt) in points.enumerated() {
                let x = CGFloat(idx) * step
                let y = h - CGFloat(pt.value) / CGFloat(maxV) * h
                if idx == 0 {
                  p.move(to: CGPoint(x: x, y: y))
                } else {
                  p.addLine(to: CGPoint(x: x, y: y))
                }
              }
            }
            .stroke(DesignSystem.Colors.primary, lineWidth: 2)
          }
          .frame(height: 160)
          .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.cardRounded))
        }
      }
    }
  }
}
