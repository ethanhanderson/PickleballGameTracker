import CorePackage
import SwiftUI

@MainActor
struct SectionContainer<Content: View>: View {
  let title: String?
  @ViewBuilder var content: () -> Content

  var body: some View {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
      if let title {
        Text(title)
          .font(DesignSystem.Typography.title3)
          .foregroundColor(DesignSystem.Colors.textPrimary)
      }

      content()
    }
    .padding()
    .glassEffect(
      .regular.tint(
        DesignSystem.Colors.containerFillSecondary.opacity(0.2)
      ),
      in: RoundedRectangle(
        cornerRadius: DesignSystem.CornerRadius.cardRounded
      )
    )
  }
}
