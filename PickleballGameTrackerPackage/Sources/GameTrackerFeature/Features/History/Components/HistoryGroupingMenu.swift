import SharedGameCore
import SwiftUI

@MainActor
struct HistoryGroupingMenu: View {
  @Binding var selectedGrouping: GroupingOption

  var body: some View {
    Menu {
      ForEach(GroupingOption.allCases) { option in
        groupingButton(for: option)
      }
    } label: {
      Image(
        systemName: selectedGrouping == .none ? "square.grid.2x2" : "square.grid.2x2.fill"
      )
      .foregroundColor(.accentColor)
    }
  }

  private func groupingButton(for option: GroupingOption) -> some View {
    Button {
      selectedGrouping = option
    } label: {
      Label(
        option.displayName,
        systemImage: selectedGrouping == option ? "checkmark.circle.fill" : option.systemImage
      )
    }
  }
}


