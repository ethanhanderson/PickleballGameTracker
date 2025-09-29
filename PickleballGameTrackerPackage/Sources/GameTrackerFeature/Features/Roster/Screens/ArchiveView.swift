import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct ArchiveView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var manager = PlayerTeamManager()

  init(manager: PlayerTeamManager = PlayerTeamManager()) {
    _manager = State(initialValue: manager)
  }

  var body: some View {
    NavigationStack {
      Group {
        if archivedPlayers.isEmpty && archivedTeams.isEmpty {
          ScrollView {
            VStack {
              EmptyStateView(
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
                SectionView(
                  title: "Players",
                  items: archivedPlayers
                ) { player in
                  let teamCount =
                    manager
                    .loadArchivedTeams()
                    .filter { team in
                      team.players.contains(where: {
                        $0.id == player.id
                      })
                    }
                    .count
                  let identity: IdentityCard.Identity =
                    .player(
                      player,
                      teamCount: teamCount
                    )
                  ArchivedIdentityCard(
                    identity: identity,
                    manager: manager
                  )
                }
              }

              if !archivedTeams.isEmpty {
                SectionView(
                  title: "Teams",
                  items: archivedTeams
                ) { team in
                  let identity: IdentityCard.Identity =
                    .team(team)
                  ArchivedIdentityCard(
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
      .viewContainerBackground()
      .toolbar {
        ToolbarItem {
          Button {
            dismiss()
          } label: {
            Label("Close", systemImage: "xmark")
          }
          .accessibilityLabel("Close archive")
        }
      }
    }
  }

  private var archivedPlayers: [PlayerProfile] {
    manager.loadArchivedPlayers()
  }

  private var archivedTeams: [TeamProfile] {
    manager.loadArchivedTeams()
  }
}

#Preview("Empty Archive") {
  let setup = PreviewEnvironmentSetup.createMinimal()
  ArchiveView(manager: setup.rosterManager!)
    .minimalPreview(environment: setup.environment)
}

#Preview("With Archived Items") {
  let setup = PreviewEnvironmentSetup.createMinimal()
  ArchiveView(manager: setup.rosterManager!)
    .minimalPreview(environment: setup.environment)
}
