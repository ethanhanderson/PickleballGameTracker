import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct GameParticipantCard: View {
  let displayName: String
  let teamNumber: Int
  let color: Color

  init(displayName: String, teamNumber: Int, color: Color) {
    self.displayName = displayName
    self.teamNumber = teamNumber
    self.color = color
  }

  var body: some View {
    HStack(spacing: DesignSystem.Spacing.md) {
      avatar
      VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
        Text(displayName)
          .font(.title3)
          .foregroundStyle(.primary)

        Text("Team \(teamNumber)")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      Spacer()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .contentShape(.rect)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(displayName), Team \(teamNumber)")
    .accessibilityIdentifier("gameParticipant.card.\(teamNumber)")
  }

  private var avatar: some View {
    ZStack {
      Circle()
        .fill(color.opacity(0.2))
        .frame(width: 40, height: 40)
      Text("\(teamNumber)")
        .font(.headline)
        .fontWeight(.semibold)
        .foregroundStyle(color)
    }
  }
}

#Preview("Game Participant Card") {
  GameParticipantCard(
    displayName: "Ethan & Sarah",
    teamNumber: 1,
    color: .blue
  )
  .padding()
}
