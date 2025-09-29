import GameTrackerCore
import SwiftUI

/// A view component for displaying game scores in history views with size options and winner highlighting.
struct HistoryScoreDisplay: View {
  let score: Int
  let label: String
  let color: Color
  let size: Size
  let isWinner: Bool

  enum Size {
    case small, medium, large
  }

  init(score: Int, label: String, color: Color, size: Size = .medium, isWinner: Bool = false) {
    self.score = score
    self.label = label
    self.color = color
    self.size = size
    self.isWinner = isWinner
  }

  var body: some View {
    VStack(spacing: DesignSystem.Spacing.xs) {
      Text(label)
        .font(.caption)
        .foregroundStyle(.secondary)

      Text("\(score)")
        .font(size == .small ? .title2 : size == .medium ? .title : .largeTitle)
        .fontWeight(isWinner ? .bold : .semibold)
        .foregroundStyle(color)
    }
    .frame(minWidth: size == .small ? 60 : size == .medium ? 80 : 100)
    .padding(size == .small ? DesignSystem.Spacing.sm : DesignSystem.Spacing.md)
    .background(
      RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
        .fill(color.opacity(0.1))
        .overlay(
          isWinner ?
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
              .stroke(color, lineWidth: 2)
            : nil
        )
    )
  }
}
