import CorePackage
import SwiftUI

@MainActor
struct HistoryFilterMenu: View {
  @Binding var selectedFilter: GameFilter

  var body: some View {
    Menu {
      Section("General") {
        filterButton(for: .all)
      }

      Section("Game Types") {
        ForEach(GameCatalog.allGameTypes, id: \.self) { gameType in
          filterButton(for: .gameType(gameType))
        }
      }

      Section("Results") {
        filterButton(for: .wins)
        filterButton(for: .losses)
      }
    } label: {
      Image(
        systemName: selectedFilter == .all
          ? "line.3.horizontal.decrease" : "line.3.horizontal.decrease.circle.fill"
      )
      .foregroundColor(DesignSystem.Colors.primary)
    }
  }

  private func filterButton(for filter: GameFilter) -> some View {
    Button {
      selectedFilter = filter
    } label: {
      HStack {
        if selectedFilter == filter {
          Image(systemName: "checkmark")
        }
        Text(filter.displayName)
      }
    }
  }
}


