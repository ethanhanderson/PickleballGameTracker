import GameTrackerCore
import SwiftUI

@MainActor
struct SectionContainer<Content: View>: View {
  let title: String?
  @ViewBuilder var content: () -> Content

  var body: some View {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
      if let title {
        Text(title)
          .font(.title3)
          .fontWeight(.semibold)
          .foregroundStyle(.primary)
      }

      content()
    }
    .padding()
    .glassEffect(
      .regular.tint(
        Color.gray.opacity(0.15).opacity(0.2)
      ),
      in: RoundedRectangle(
        cornerRadius: DesignSystem.CornerRadius.xl
      )
    )
  }
}
