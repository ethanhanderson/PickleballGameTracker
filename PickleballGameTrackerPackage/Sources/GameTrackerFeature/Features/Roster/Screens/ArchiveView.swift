import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct ArchiveView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(PlayerTeamManager.self) private var manager
  
  @Query(filter: #Predicate<PlayerProfile> { $0.isArchived && !$0.isGuest })
  private var archivedPlayers: [PlayerProfile]
  
  @Query(filter: #Predicate<TeamProfile> { $0.isArchived })
  private var archivedTeams: [TeamProfile]

  init() {}

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
          }
          .contentMargins(.horizontal, DesignSystem.Spacing.md, for: .scrollContent)
          .contentMargins(.top, DesignSystem.Spacing.sm, for: .scrollContent)
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
                    archivedTeams
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
                  ArchivedIdentityCard(identity: identity)
                }
              }

              if !archivedTeams.isEmpty {
                SectionView(
                  title: "Teams",
                  items: archivedTeams
                ) { team in
                  let identity: IdentityCard.Identity =
                    .team(team)
                  ArchivedIdentityCard(identity: identity)
                }
              }
            }
          }
          .contentMargins(.horizontal, DesignSystem.Spacing.md, for: .scrollContent)
          .contentMargins(.vertical, DesignSystem.Spacing.sm, for: .scrollContent)
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
}

#Preview("Empty Archive") {
  let container = PreviewContainers.empty()
  let rosterManager = PreviewContainers.rosterManager(for: container)
  
  ArchiveView()
    .modelContainer(container)
    .environment(rosterManager)
}

#Preview("With Archived Items") {
  let container = PreviewContainers.roster()
  let rosterManager = PreviewContainers.rosterManager(for: container)
  
  ArchiveView()
    .modelContainer(container)
    .environment(rosterManager)
}
