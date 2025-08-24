import PickleballGameTrackerCorePackage
import SwiftUI

@MainActor
struct GroupedSection<Content: View>: View {
  let title: String
  @ViewBuilder let content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title)
        .font(DesignSystem.Typography.title2)
        .frame(maxWidth: .infinity, alignment: .leading)
      VStack(spacing: 12) {
        content
      }
    }
  }
}
