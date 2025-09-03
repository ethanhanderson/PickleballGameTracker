//
//  RosterArchiveView.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 12/16/24.
//

import CorePackage
import SwiftData
import SwiftUI

@MainActor
struct RosterArchiveView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var manager = PlayerTeamManager()

  init(manager: PlayerTeamManager = PlayerTeamManager()) {
    _manager = State(initialValue: manager)
  }

  var body: some View {
    Group {
      if archivedPlayers.isEmpty && archivedTeams.isEmpty {
        ScrollView {
          VStack {
            CustomContentUnavailableView(
              icon: "archivebox",
              title: "No archived items",
              description:
                "Archived players and teams will appear here."
            )
          }
          .padding(.top, DesignSystem.Spacing.sm)
          .padding(.horizontal, DesignSystem.Spacing.md)
        }
        .scrollClipDisabled()
      } else {
        ScrollView {
          VStack(spacing: DesignSystem.Spacing.lg) {
            if !archivedPlayers.isEmpty {
              RosterSectionView(
                title: "Players",
                items: archivedPlayers
              ) { player in
                let teamCount =
                  manager
                  .loadArchivedTeams()
                  .filter { team in
                    team.players.contains(where: { $0.id == player.id })
                  }
                  .count
                let identity: RosterIdentityCard.Identity = .player(
                  player,
                  teamCount: teamCount
                )
                ArchivedIdentityRow(
                  identity: identity,
                  manager: manager
                )
              }
            }

            if !archivedTeams.isEmpty {
              RosterSectionView(
                title: "Teams",
                items: archivedTeams
              ) { team in
                let identity: RosterIdentityCard.Identity = .team(team)
                ArchivedIdentityRow(
                  identity: identity,
                  manager: manager
                )
              }
            }
          }
          .padding(.horizontal, DesignSystem.Spacing.md)
          .padding(.vertical, DesignSystem.Spacing.sm)
        }
      }
    }
    .navigationTitle("Archive")
    .containerBackground(
      DesignSystem.Colors.navigationBrandGradient,
      for: .navigation
    )
    .navigationBarTitleDisplayMode(.large)
    // No need to refresh - archive view uses computed properties that load archived items on demand
  }

  private var archivedPlayers: [PlayerProfile] {
    manager.loadArchivedPlayers()
  }

  private var archivedTeams: [TeamProfile] {
    manager.loadArchivedTeams()
  }

}

// ArchivedIdentityRow moved to Features/Roster/Components/ArchivedIdentityRow.swift

#Preview("Empty Archive") {
  let container = try! CorePackage.PreviewGameData.createRosterPreviewContainer(
    players: [],
    teams: []
  )
  let manager = PlayerTeamManager(
    storage: SwiftDataStorage(modelContainer: container),
    autoRefresh: false
  )
  return RosterArchiveView(manager: manager)
    .modelContainer(container)
}

#Preview("With Archived Items") {
  let container = try! CorePackage.PreviewGameData.createRosterPreviewContainer()
  let storage = SwiftDataStorage(modelContainer: container)
  let manager = PlayerTeamManager(storage: storage, autoRefresh: false)

  return RosterArchiveView(manager: manager)
    .modelContainer(container)
}
