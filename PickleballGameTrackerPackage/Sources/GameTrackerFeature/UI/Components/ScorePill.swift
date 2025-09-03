import CorePackage
import SwiftUI

@MainActor
struct ScorePill: View {
  let scoreText: String
  let fontSize: CGFloat
  let scale: CGFloat
  let opacity: Double

  init(score: Int, fontSize: CGFloat = 76, scale: CGFloat, opacity: Double) {
    self.scoreText = String(score)
    self.fontSize = fontSize
    self.scale = scale
    self.opacity = opacity
  }

  var body: some View {
    Text(scoreText)
      .font(.system(size: fontSize, weight: .bold, design: .rounded))
      .foregroundStyle(.primary)
      .padding(.bottom, DesignSystem.Spacing.xl)
      .minimumScaleFactor(0.6)
      .lineLimit(1)
      .contentTransition(.numericText())
      .scaleEffect(scale)
      .opacity(opacity)
  }
}


