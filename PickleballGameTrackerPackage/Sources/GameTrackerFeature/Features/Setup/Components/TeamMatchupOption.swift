//
//  TeamMatchupOption.swift
//

import GameTrackerCore
import SwiftUI

@MainActor
public struct TeamMatchupOption: View {
  let team1: TeamProfile
  let team2: TeamProfile
  let gameType: GameType
  let teamSize: Int
  let onStartGame: (TeamProfile, TeamProfile) -> Void

  private var requiredPlayersPerTeam: Int { teamSize }
  private var team1Players: [PlayerProfile] { Array(team1.players.prefix(requiredPlayersPerTeam)) }
  private var team2Players: [PlayerProfile] { Array(team2.players.prefix(requiredPlayersPerTeam)) }
  private var team1PlayerNames: String { let names = team1Players.map { $0.name }; return names.isEmpty ? "No players" : names.joined(separator: ", ") }
  private var team2PlayerNames: String { let names = team2Players.map { $0.name }; return names.isEmpty ? "No players" : names.joined(separator: ", ") }

  public var body: some View {
    HStack(alignment: .center, spacing: DesignSystem.Spacing.md) {
      HStack(alignment: .center, spacing: DesignSystem.Spacing.md) {
        TeamDetailView(team: team1, playerNames: team1PlayerNames)
        Text("VS")
          .font(.caption)
          .fontWeight(.semibold)
          .padding(.horizontal, DesignSystem.Spacing.sm)
          .padding(.vertical, DesignSystem.Spacing.xs)
          .background(Capsule().fill(Color.gray.opacity(0.2).opacity(0.8)))
        TeamDetailView(team: team2, playerNames: team2PlayerNames)
      }
      Spacer()
      Button(action: { onStartGame(team1, team2) }) {
        Image(systemName: "play.fill")
          .font(.system(size: 18, weight: .bold))
          .foregroundStyle(.white)
          .frame(width: 26, height: 26)
      }
      .tint(.accentColor)
      .buttonBorderShape(.circle)
      .buttonStyle(.glassProminent)
    }
    .padding(.vertical, DesignSystem.Spacing.sm)
    .contentShape(Rectangle())
  }
}

@MainActor
private struct TeamDetailView: View {
  let team: TeamProfile
  let playerNames: String
  var body: some View {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
      AvatarView(team: team, style: .small)
        .padding(.bottom, DesignSystem.Spacing.xs)
      Text(team.name)
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(.primary)
      Text(playerNames)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }
}


