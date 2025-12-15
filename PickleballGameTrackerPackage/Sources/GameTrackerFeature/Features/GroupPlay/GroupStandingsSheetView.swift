import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct GroupStandingsSheetView: View {
  @Environment(\.dismiss) private var dismiss
  @Bindable var session: GroupPlaySession
  
  init(session: GroupPlaySession) {
    self._session = Bindable(wrappedValue: session)
  }
  
  var body: some View {
    Group {
      if session.modelContext == nil {
        Color.clear
          .task { dismiss() }
      } else {
        NavigationStack {
          List {
            Section("Standings") {
              if session.standings.isEmpty {
                Text("No results yet")
                  .foregroundStyle(.secondary)
              } else {
                ForEach(session.standings, id: \.id) { entry in
                  HStack {
                    VStack(alignment: .leading) {
                      Text(abbreviated(entry.entryId))
                        .font(.body)
                      Text("W \(entry.wins) - L \(entry.losses)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(entry.pointsFor) - \(entry.pointsAgainst)")
                      .font(.body.monospacedDigit())
                  }
                }
              }
            }
          }
          .navigationTitle("Standings")
          .toolbar {
            ToolbarItem(placement: .cancellationAction) {
              Button("Close") { dismiss() }
            }
          }
        }
      }
    }
    .onChange(of: session.modelContext == nil) { _, detached in
      if detached { dismiss() }
    }
  }
  
  private func abbreviated(_ id: UUID) -> String {
    let s = id.uuidString.uppercased()
    return String(s.prefix(4)) + "…" + String(s.suffix(4))
  }
}


