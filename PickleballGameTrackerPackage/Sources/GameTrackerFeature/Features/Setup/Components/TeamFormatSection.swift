import GameTrackerCore
import SwiftUI

@MainActor
struct TeamFormatSection: View {
  let gameType: GameType
  @Binding var selectedTeamSize: Int
  let teamSizeOptions: [TeamSizeOption]

  var body: some View {
    Section("Team Format") {
      Picker("Team Size", selection: $selectedTeamSize) {
        ForEach(teamSizeOptions, id: \.size) { option in
          Text(option.displayName).tag(option.size)
        }
      }
      .pickerStyle(.menu)
      .tint(Color.accentColor)
    }
  }
}


