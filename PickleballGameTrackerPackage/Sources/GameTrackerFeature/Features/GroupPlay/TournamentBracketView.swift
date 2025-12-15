import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct TournamentBracketView: View {
  @Bindable var session: GroupPlaySession
  @Environment(\.dismiss) private var dismiss
  
  init(session: GroupPlaySession) {
    self._session = Bindable(wrappedValue: session)
  }
  
  var body: some View {
    Group {
      if session.modelContext == nil {
        Color.clear
          .task { dismiss() }
      } else {
        List {
          Section("First Round") {
            if firstRoundMatches.isEmpty {
              Text("No matches").foregroundStyle(.secondary)
            } else {
              ForEach(firstRoundMatches, id: \.id) { match in
                HStack {
                  Text(sideLabel(match, side: 1))
                  Spacer()
                  Text("vs")
                    .foregroundStyle(.secondary)
                  Spacer()
                  Text(sideLabel(match, side: 2))
                }
              }
            }
          }
        }
      }
    }
    .onChange(of: session.modelContext == nil) { _, detached in
      if detached { dismiss() }
    }
    .navigationTitle("Bracket")
  }
  
  private var firstRoundMatches: [ScheduledMatch] {
    // Current implementation generates one round; show all scheduled
    session.schedule.filter { _ in true }
  }
  
  private func sideLabel(_ m: ScheduledMatch, side: Int) -> String {
    switch m.participantMode {
    case .players:
      let ids = side == 1 ? m.side1PlayerIds : m.side2PlayerIds
      return ids.isEmpty ? "BYE" : "\(ids.count)P"
    case .teams:
      let id = side == 1 ? m.side1TeamId : m.side2TeamId
      return id == nil ? "BYE" : "Team"
    }
  }
}


