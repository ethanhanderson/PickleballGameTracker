import GameTrackerCore
import SwiftUI

@MainActor
struct GameTypeCard: View {
  let gameType: GameType

  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: gameType.iconName)
        .font(.system(size: 40, weight: .medium))
        .foregroundStyle(gameType.color.opacity(0.8).gradient)
        .shadow(
          color: gameType.color.opacity(0.3),
          radius: 2,
          x: 0,
          y: 1
        )

      Text(gameType.displayName)
        .font(.title3)
        .fontWeight(.bold)
        .foregroundStyle(.white)
        .multilineTextAlignment(.center)
        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

      HStack(spacing: 8) {
        HStack(spacing: 2) {
          Image(systemName: "person.2.fill")
            .font(.system(size: 13))
            .foregroundStyle(gameType.color)
            .opacity(0.6)
          Text(gameType.playerCountValue)
            .font(.caption2)
            .fontWeight(.medium)
        }

        HStack(spacing: 2) {
          Image(systemName: "clock.fill")
            .font(.system(size: 13))
            .foregroundStyle(gameType.color)
            .opacity(0.6)
          Text("\(gameType.estimatedTimeValue)m")
            .font(.caption2)
            .fontWeight(.medium)
        }

        HStack(spacing: 2) {
          Image(systemName: "star.fill")
            .font(.system(size: 13))
            .foregroundStyle(gameType.color)
            .opacity(0.6)
          Image(
            systemName: "chart.bar.fill",
            variableValue: gameType.difficultyFillProgress
          )
          .font(.caption2)
        }
      }
      .foregroundStyle(.white.opacity(0.8))
      .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
    }
    .frame(maxHeight: .infinity, alignment: .top)
    .padding(8)
  }
}
