import GameTrackerCore
import SwiftUI

struct EmptyStateView: View {
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
          .foregroundStyle(Color.accentColor.gradient)

        Text(title)
          .font(.title2)
          .fontWeight(.semibold)
          .foregroundStyle(.primary)
      }
    } description: {
      Text(description)
        .font(.body)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .padding(DesignSystem.Spacing.sm)
    .glassEffect(
      .regular.tint(Color.gray.opacity(0.15).opacity(0.2)),
      in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl, style: .continuous))
  }

  private var enhancedIconGradient: LinearGradient {
    LinearGradient(
      colors: [
        .accentColor.opacity(0.9),
        .accentColor.opacity(0.6),
      ],
      startPoint: .top,
      endPoint: .bottom
    )
  }

  private var enhancedBackground: some View {
    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
      .fill(
        LinearGradient(
          colors: [
            Color.gray.opacity(0.2),
            Color.gray.opacity(0.3),
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
  EmptyStateView(
    icon: "clock.badge.questionmark",
    title: "No Game History",
    description: "Start playing games to see your history here"
  )
  .padding()
  .accentColor(.green)
}

#Preview("Search Discovery") {
  EmptyStateView(
    icon: "magnifyingglass",
    title: "Discover New Games",
    description: "Search for game types to start playing"
  )
  .padding()
  .accentColor(.green)
}

#Preview("No Results Found") {
  EmptyStateView(
    icon: "line.3.horizontal.decrease.circle",
    title: "No Games Found",
    description: "Try adjusting your filter to see more games"
  )
  .padding()
  .accentColor(.green)
}

#Preview("No Players Available") {
  EmptyStateView(
    icon: "person.2.slash",
    title: "No Players Available",
    description: "Add players to your roster to start games"
  )
  .padding()
  .accentColor(.green)
}

#Preview("Empty Statistics") {
  EmptyStateView(
    icon: "chart.bar",
    title: "No Statistics Available",
    description: "Play some games to see your statistics here"
  )
  .padding()
  .accentColor(.green)
}
