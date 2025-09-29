import GameTrackerCore
import SwiftUI

@MainActor
struct CurrentGameDisplaySection: View {
  let gameType: GameType
  let selectedTeamSize: Int
  let selectedPlayers: [PlayerProfile]
  let selectedTeam1: TeamProfile?
  let selectedTeam2: TeamProfile?

  var body: some View {
    Section("Current Game") {
      VStack(spacing: DesignSystem.Spacing.sm) {
        PlayerTeamRectangle(
          selectedPlayers: selectedPlayers,
          selectedTeam: selectedTeam1,
          teamSize: selectedTeamSize,
          isFirstPlayer: true
        )
        .frame(maxWidth: .infinity)

        Text("vs")
          .font(.body)
          .foregroundStyle(.secondary)

        PlayerTeamRectangle(
          selectedPlayers: selectedPlayers,
          selectedTeam: selectedTeam2,
          teamSize: selectedTeamSize,
          isFirstPlayer: false
        )
        .frame(maxWidth: .infinity)
      }
    }
  }
}

@MainActor
struct PlayerTeamRectangle: View {
  let selectedPlayers: [PlayerProfile]
  let selectedTeam: TeamProfile?
  let teamSize: Int
  let isFirstPlayer: Bool

  private var displayPlayer: PlayerProfile? {
    guard teamSize == 1 else { return nil }
    if isFirstPlayer {
      return selectedPlayers.first
    } else {
      return selectedPlayers.dropFirst().first
    }
  }

  var body: some View {
    VStack {
      if teamSize == 1 {
        if let player = displayPlayer {
          HStack(spacing: DesignSystem.Spacing.sm) {
            AvatarView(player: player, style: .small)
            Text(player.name)
              .font(.subheadline)
              .fontWeight(.semibold)
              .foregroundStyle(.black)
              .lineLimit(1)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(DesignSystem.Spacing.sm)
          .background(Color.gray.opacity(0.2).opacity(0.6))
          .clipShape(Capsule())
        } else {
          HStack(spacing: DesignSystem.Spacing.sm) {
            ZStack {
              Circle()
                .fill(Color.gray.opacity(0.8))
                .frame(width: 38, height: 38)
              Image(systemName: "person.fill")
                .font(.system(size: 18))
                .foregroundStyle(.white)
            }
            Text("Select Player")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(DesignSystem.Spacing.sm)
          .background(Color.gray.opacity(0.2).opacity(0.3))
          .clipShape(Capsule())
        }
      } else {
        if let team = selectedTeam {
          HStack(spacing: DesignSystem.Spacing.sm) {
            AvatarView(team: team, style: .small)
            Text(team.name)
              .font(.subheadline)
              .fontWeight(.semibold)
              .foregroundStyle(.black)
              .multilineTextAlignment(.leading)
              .lineLimit(nil)
              .fixedSize(horizontal: false, vertical: true)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(DesignSystem.Spacing.sm)
          .background(Color.gray.opacity(0.2).opacity(0.6))
          .clipShape(Capsule())
        } else {
          HStack(spacing: DesignSystem.Spacing.sm) {
            ZStack {
              Circle()
                .fill(Color.gray.opacity(0.8))
                .frame(width: 38, height: 38)
              Image(systemName: "person.2.fill")
                .font(.system(size: 18))
                .foregroundStyle(.white)
            }
            Text("Select Team")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(DesignSystem.Spacing.sm)
          .background(Color.gray.opacity(0.2).opacity(0.3))
          .clipShape(Capsule())
        }
      }
    }
  }
}


