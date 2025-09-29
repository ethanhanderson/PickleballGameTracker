import GameTrackerCore
import SwiftUI

@MainActor
struct StatsSection: View {
  let title: String
  let items: [(String, String, String)]
  let themeColor: Color

  var body: some View {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
      Text(title)
        .font(.title3)
        .fontWeight(.semibold)
        .foregroundStyle(.primary)

      VStack(spacing: DesignSystem.Spacing.md) {
        ForEach(Array(chunk(items, size: 2).enumerated()), id: \.offset) { _, row in
          HStack(spacing: DesignSystem.Spacing.md) {
            ForEach(0..<2) { index in
              if index < row.count {
                let item = row[index]
                StatCard(
                  symbolName: item.0,
                  title: item.1,
                  value: item.2,
                  themeColor: themeColor
                )
              } else {
                Color.clear
                  .frame(maxWidth: .infinity)
                  .frame(height: 0)
              }
            }
          }
        }
      }
    }
  }

  private func chunk<T>(_ array: [T], size: Int) -> [[T]] {
    guard size > 0 else { return [] }
    var result: [[T]] = []
    var index = 0
    while index < array.count {
      let end = min(index + size, array.count)
      result.append(Array(array[index..<end]))
      index += size
    }
    return result
  }
}
