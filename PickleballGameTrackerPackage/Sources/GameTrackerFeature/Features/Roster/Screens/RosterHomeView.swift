//
//  RosterHomeView.swift
//  Pickleball Score Tracking
//
//  Created by Agent on 8/15/25.
//

import CorePackage
import SwiftData
import SwiftUI

struct RosterHomeView: View {
  @Namespace var animation
  @Environment(\.modelContext) private var modelContext
  @State private var manager = PlayerTeamManager()

  init(manager: PlayerTeamManager = PlayerTeamManager()) {
    _manager = State(initialValue: manager)
  }

  var body: some View {
    NavigationStack {
      Group {
        if manager.players.isEmpty && manager.teams.isEmpty {
          ScrollView {
            VStack {
              CustomContentUnavailableView(
                icon: "person.2.slash",
                title: "No players or teams yet",
                description:
                  "Add players and create teams to get started."
              )
            }
            .padding(.top, DesignSystem.Spacing.sm)
            .padding(.horizontal, DesignSystem.Spacing.md)
          }
          .scrollClipDisabled()
        } else {
          ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
              if !manager.players.isEmpty {
                RosterSectionView(
                  title: "Players",
                  items: Array(manager.players)
                ) { player in
                  let identity: RosterIdentityCard.Identity = .player(
                    player,
                    teamCount: teamCount(for: player)
                  )
                  IdentityNavigationRow(identity: identity)
                }
              }

              if !manager.teams.isEmpty {
                RosterSectionView(
                  title: "Teams",
                  items: Array(manager.teams)
                ) { team in
                  let identity: RosterIdentityCard.Identity = .team(team)
                  IdentityNavigationRow(identity: identity)
                }
              }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
          }
        }
      }
      .navigationTitle("Roster")
      .containerBackground(
        DesignSystem.Colors.navigationBrandGradient,
        for: .navigation
      )
      .toolbar {
        ToolbarItem {
          Menu {
            Button(
              "New Player",
              systemImage: "person.fill.badge.plus",
              action: onNewPlayer
            )
            .tint(DesignSystem.Colors.primary)

            Button(
              "New Team",
              systemImage: "person.2.badge.plus.fill",
              action: onNewTeam
            )
            .tint(DesignSystem.Colors.primary)
          } label: {
            Label("Create new", systemImage: "plus")
          }
        }
        .matchedTransitionSource(
          id: "sheet",
          in: animation
        )

        ToolbarSpacer()

        ToolbarItem {
          NavigationLink {
            RosterArchiveView(manager: manager)
          } label: {
            Label("View Archive", systemImage: "archivebox")
          }
          .tint(DesignSystem.Colors.primary)
        }
      }
      .navigationDestination(for: RosterDestination.self) { destination in
        switch destination {
        case .identity(let identity):
          RosterIdentityDetailView(
            identity: identity,
            manager: manager
          )
        }
      }
    }
    .sheet(isPresented: $showPlayerSheet) {
      RosterIdentityEditorView(
        identity: editingPlayer.map { .player($0) }
          ?? .player(nil),
        manager: manager
      )
      .navigationTransition(.zoom(sourceID: "sheet", in: animation))
    }
    .sheet(isPresented: $showTeamSheet) {
      RosterIdentityEditorView(
        identity: editingTeam.map { .team($0) }
          ?? .team(nil),
        manager: manager
      )
      .navigationTransition(.zoom(sourceID: "sheet", in: animation))
    }
    .navigationTint()
    .task { @MainActor in
      manager.refreshAll()
    }
  }

  // Compute the number of teams a player belongs to for richer card context
  private func teamCount(for player: PlayerProfile) -> Int? {
    let count = manager.teams.filter { team in
      team.players.contains(where: { $0.id == player.id })
    }.count
    return count
  }

  private func onNewPlayer() {
    Log.event(.actionTapped, level: .info, message: "roster → newPlayer")
    // Navigate to create sheet
    presentCreatePlayerSheet()
  }

  private func onNewTeam() {
    Log.event(.actionTapped, level: .info, message: "roster → newTeam")
    presentCreateTeamSheet()
  }

  // Route no longer used with value-based navigation; keep for compatibility if needed
  fileprivate enum Route: Hashable {
    case player(PlayerProfile)
    case team(TeamProfile)
  }

  @State private var showPlayerSheet: Bool = false
  @State private var editingPlayer: PlayerProfile?
  @State private var showTeamSheet: Bool = false
  @State private var editingTeam: TeamProfile?

  private func presentCreatePlayerSheet() {
    editingPlayer = nil
    showPlayerSheet = true
  }

  private func presentEditPlayerSheet(_ player: PlayerProfile) {
    editingPlayer = player
    showPlayerSheet = true
  }

  private func presentCreateTeamSheet() {
    editingTeam = nil
    showTeamSheet = true
  }

  private func presentEditTeamSheet(_ team: TeamProfile) {
    editingTeam = team
    showTeamSheet = true
  }

}

private struct PlayersSectionView: View {
  let players: [PlayerProfile]
  let teamCountFor: (PlayerProfile) -> Int?

  var body: some View {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
      Text("Players")
        .font(DesignSystem.Typography.title3)
        .foregroundColor(DesignSystem.Colors.textPrimary)

      VStack(spacing: DesignSystem.Spacing.lg) {
        ForEach(players, id: \.id) { player in
          let identity: RosterIdentityCard.Identity = .player(
            player,
            teamCount: teamCountFor(player)
          )
          IdentityNavigationRow(identity: identity)
        }
      }
    }
    .padding()
    .glassEffect(
      .regular.tint(
        DesignSystem.Colors.containerFillSecondary.opacity(0.2)
      ),
      in: RoundedRectangle(
        cornerRadius: DesignSystem.CornerRadius.cardRounded
      )
    )
  }
}

private struct TeamsSectionView: View {
  let teams: [TeamProfile]

  var body: some View {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
      Text("Teams")
        .font(DesignSystem.Typography.title3)
        .foregroundColor(DesignSystem.Colors.textPrimary)

      VStack(spacing: DesignSystem.Spacing.lg) {
        ForEach(teams, id: \.id) { team in
          let identity: RosterIdentityCard.Identity = .team(team)
          IdentityNavigationRow(identity: identity)
        }
      }
    }
    .padding()
    .glassEffect(
      .regular.tint(
        DesignSystem.Colors.containerFillSecondary.opacity(0.2)
      ),
      in: RoundedRectangle(
        cornerRadius: DesignSystem.CornerRadius.cardRounded
      )
    )
  }
}

// MARK: - Roster Destinations
enum RosterDestination: Hashable {
  case identity(RosterIdentityCard.Identity)
}

// MARK: - Navigation Row Wrapper
@MainActor
private struct IdentityNavigationRow: View {
  let identity: RosterIdentityCard.Identity

  var body: some View {
    NavigationLink(value: RosterDestination.identity(identity)) {
      RosterIdentityCard(identity: identity)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("roster.row.\(identity.id.uuidString)")
  }
}

private struct PlayerDetailView: View {
  let player: PlayerProfile

  var body: some View {
    ScrollView {
      VStack(spacing: DesignSystem.Spacing.lg) {
        // Player avatar
        Group {
          if let data = player.avatarImageData,
            let uiImage = UIImage(data: data)
          {
            Image(uiImage: uiImage)
              .resizable()
              .scaledToFill()
          } else {
            Image(
              systemName: player.iconSymbolName ?? "person.fill"
            )
            .font(.system(size: 80))
            .foregroundStyle(DesignSystem.Colors.primary)
          }
        }
        .frame(width: 120, height: 120)
        .background(DesignSystem.Colors.secondaryLight)
        .clipShape(Circle())

        // Player info
        VStack(spacing: DesignSystem.Spacing.md) {
          Text(player.name)
            .font(DesignSystem.Typography.title1)
            .foregroundStyle(DesignSystem.Colors.textPrimary)

          let skillLevel =
            switch player.skillLevel {
            case .beginner: "Beginner"
            case .intermediate: "Intermediate"
            case .advanced: "Advanced"
            case .expert: "Expert"
            case .unknown: "Skill Level Unknown"
            }

          Text(skillLevel)
            .font(DesignSystem.Typography.body)
            .foregroundStyle(DesignSystem.Colors.textSecondary)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(DesignSystem.Colors.neutralSurface)
            .clipShape(Capsule())
        }

        // Player stats placeholder
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
          Text("Player Statistics")
            .font(DesignSystem.Typography.title3)
            .foregroundStyle(DesignSystem.Colors.textPrimary)

          HStack {
            StatCard(title: "Games Played", value: "0")
            StatCard(title: "Win Rate", value: "0%")
          }

          HStack {
            StatCard(title: "Points Scored", value: "0")
            StatCard(title: "Teams", value: "0")
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding(DesignSystem.Spacing.lg)
    }
    .navigationTitle(player.name)
    .navigationBarTitleDisplayMode(.inline)
  }
}

private struct TeamDetailView: View {
  let team: TeamProfile

  var body: some View {
    ScrollView {
      VStack(spacing: DesignSystem.Spacing.lg) {
        // Team avatar
        Group {
          if let data = team.avatarImageData,
            let uiImage = UIImage(data: data)
          {
            Image(uiImage: uiImage)
              .resizable()
              .scaledToFill()
          } else {
            Image(
              systemName: team.iconSymbolName ?? "person.2.fill"
            )
            .font(.system(size: 80))
            .foregroundStyle(DesignSystem.Colors.primary)
          }
        }
        .frame(width: 120, height: 120)
        .background(DesignSystem.Colors.secondaryLight)
        .clipShape(Circle())

        // Team info
        VStack(spacing: DesignSystem.Spacing.md) {
          Text(team.name)
            .font(DesignSystem.Typography.title1)
            .foregroundStyle(DesignSystem.Colors.textPrimary)

          Text("\(team.players.count) players")
            .font(DesignSystem.Typography.body)
            .foregroundStyle(DesignSystem.Colors.textSecondary)
        }

        // Team members
        if !team.players.isEmpty {
          VStack(
            alignment: .leading,
            spacing: DesignSystem.Spacing.md
          ) {
            Text("Team Members")
              .font(DesignSystem.Typography.title3)
              .foregroundStyle(DesignSystem.Colors.textPrimary)

            VStack(spacing: DesignSystem.Spacing.sm) {
              ForEach(team.players) { player in
                HStack(spacing: DesignSystem.Spacing.md) {
                  Group {
                    if let data = player.avatarImageData,
                      let uiImage = UIImage(data: data)
                    {
                      Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                    } else {
                      Image(
                        systemName: player
                          .iconSymbolName
                          ?? "person.fill"
                      )
                      .foregroundStyle(
                        DesignSystem.Colors.secondary
                      )
                    }
                  }
                  .frame(width: 40, height: 40)
                  .background(
                    DesignSystem.Colors.secondaryLight
                  )
                  .clipShape(Circle())

                  Text(player.name)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(
                      DesignSystem.Colors.textPrimary
                    )

                  Spacer()
                }
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.neutralSurface)
                .clipShape(
                  RoundedRectangle(
                    cornerRadius: DesignSystem.CornerRadius
                      .md
                  )
                )
              }
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }

        // Team stats placeholder
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
          Text("Team Statistics")
            .font(DesignSystem.Typography.title3)
            .foregroundStyle(DesignSystem.Colors.textPrimary)

          HStack {
            StatCard(title: "Games Played", value: "0")
            StatCard(title: "Win Rate", value: "0%")
          }

          HStack {
            StatCard(title: "Total Points", value: "0")
            StatCard(title: "Avg Score", value: "0.0")
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding(DesignSystem.Spacing.lg)
    }
    .navigationTitle(team.name)
    .navigationBarTitleDisplayMode(.inline)
  }
}

private struct StatCard: View {
  let title: String
  let value: String

  var body: some View {
    VStack(spacing: DesignSystem.Spacing.xs) {
      Text(value)
        .font(DesignSystem.Typography.title2)
        .foregroundStyle(DesignSystem.Colors.textPrimary)

      Text(title)
        .font(DesignSystem.Typography.caption)
        .foregroundStyle(DesignSystem.Colors.textSecondary)
    }
    .frame(maxWidth: .infinity)
    .padding(DesignSystem.Spacing.md)
    .background(DesignSystem.Colors.neutralSurface)
    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
  }
}

#Preview("Empty") {
  let container = try! CorePackage.PreviewGameData.createRosterPreviewContainer(
    players: [],
    teams: []
  )
  let manager = PlayerTeamManager(
    storage: SwiftDataStorage(modelContainer: container),
    autoRefresh: false
  )
  return RosterHomeView(manager: manager)
    .modelContainer(container)
}

#Preview("With Players and Teams") {
  let container = try! CorePackage.PreviewGameData.createRosterPreviewContainer()
  let storage = SwiftDataStorage(modelContainer: container)
  let manager = PlayerTeamManager(storage: storage, autoRefresh: false)

  return RosterHomeView(manager: manager)
    .modelContainer(container)
}
