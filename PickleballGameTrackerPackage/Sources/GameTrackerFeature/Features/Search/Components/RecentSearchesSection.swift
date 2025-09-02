import CorePackage
import SwiftUI

struct RecentSearchesSection: View {
  let recentSearches: [GameType]
  let onGameTypeTapped: (GameType) -> Void
  let onDeleteFromHistory: (GameType) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
      Text("Recently Viewed Games")
        .font(DesignSystem.Typography.headline)
        .fontWeight(.semibold)
        .foregroundColor(DesignSystem.Colors.textPrimary)
        .frame(maxWidth: .infinity, alignment: .leading)

      List {
        ForEach(recentSearches, id: \.self) { gameType in
          Button {
            onGameTypeTapped(gameType)
          } label: {
            GameOptionCard(
              gameType: gameType,
              isEnabled: true,
              fillsWidth: true
            )
          }
          .buttonStyle(.plain)
          .listRowSeparator(.hidden)
          .listRowBackground(DesignSystem.Colors.clear)
          .listRowInsets(
            EdgeInsets(top: 0, leading: 0, bottom: DesignSystem.Spacing.md, trailing: 0)
          )
          .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
          .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
              onDeleteFromHistory(gameType)
            } label: {
              Image(systemName: "trash")
            }
            .frame(height: 180)
          }
        }
      }
      .listStyle(.plain)
      .frame(height: CGFloat(recentSearches.count) * 196)  // Card height + medium spacing
    }
  }
}

#Preview("Recent Searches Section") {
  RecentSearchesSection(
    recentSearches: [.training, .recreational, .tournament],
    onGameTypeTapped: { _ in },
    onDeleteFromHistory: { _ in }
  )
  .padding()
}
