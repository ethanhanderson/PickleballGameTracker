import PickleballGameTrackerCorePackage
import SwiftUI

struct CustomContentUnavailableView: View {
  let icon: String
  let title: String
  let description: String

  init(
    icon: String,
    title: String,
    description: String
  ) {
    self.icon = icon
    self.title = title
    self.description = description
  }

  var body: some View {
    ContentUnavailableView {
      VStack(spacing: DesignSystem.Spacing.md) {
        Image(systemName: icon)
          .font(.system(size: 48, weight: .bold))
          .foregroundStyle(DesignSystem.Colors.primary.gradient)

        Text(title)
          .font(DesignSystem.Typography.title2)
          .fontWeight(.semibold)
          .foregroundColor(DesignSystem.Colors.textPrimary)
      }
    } description: {
      Text(description)
        .font(DesignSystem.Typography.body)
        .foregroundColor(DesignSystem.Colors.textSecondary)
        .multilineTextAlignment(.center)
    }
    .padding(DesignSystem.Spacing.sm)
    .glassEffect(
      .regular.tint(DesignSystem.Colors.containerFillSecondary.opacity(0.2)),
      in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.cardRounded, style: .continuous))
  }

  private var enhancedIconGradient: LinearGradient {
    LinearGradient(
      colors: [
        DesignSystem.Colors.primary.opacity(0.9),
        DesignSystem.Colors.primary.opacity(0.6),
      ],
      startPoint: .top,
      endPoint: .bottom
    )
  }

  private var enhancedBackground: some View {
    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.cardRounded)
      .fill(
        LinearGradient(
          colors: [
            DesignSystem.Colors.surfaceSecondary,
            DesignSystem.Colors.surfaceTertiary,
          ],
          startPoint: .top,
          endPoint: .bottom
        )
      )
      .stroke(.thinMaterial, lineWidth: 1)
  }
}

// MARK: - Previews

#Preview("No Game History") {
  CustomContentUnavailableView(
    icon: "clock.badge.questionmark",
    title: "No Game History",
    description: "Start playing games to see your history here"
  )
  .padding()
}

#Preview("Search Discovery") {
  CustomContentUnavailableView(
    icon: "magnifyingglass",
    title: "Discover New Games",
    description: "Search for game types to start playing"
  )
  .padding()
}

#Preview("No Results Found") {
  CustomContentUnavailableView(
    icon: "line.3.horizontal.decrease.circle",
    title: "No Games Found",
    description: "Try adjusting your filter to see more games"
  )
  .padding()
}
