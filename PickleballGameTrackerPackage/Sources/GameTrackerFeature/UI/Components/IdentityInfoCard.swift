import CorePackage
import SwiftUI

@MainActor
struct IdentityInfoCard<Content: View>: View {
  let title: String
  let gradient: LinearGradient
  @ViewBuilder var content: () -> Content

  var body: some View {
    VStack(spacing: DesignSystem.Spacing.xs) {
      Text(title)
        .font(DesignSystem.Typography.caption)
        .fontWeight(.medium)
        .foregroundStyle(.secondary)

      content()
    }
    .frame(maxWidth: .infinity)
    .padding(DesignSystem.Spacing.md)
    .glassEffect(
      .regular.tint(
        DesignSystem.Colors.containerFillSecondary.opacity(0.2)
      ),
      in: RoundedRectangle(
        cornerRadius: DesignSystem.CornerRadius.xl
      )
    )
  }
}


