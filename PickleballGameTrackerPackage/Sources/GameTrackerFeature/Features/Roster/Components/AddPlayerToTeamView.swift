import GameTrackerCore
import SwiftUI

@MainActor
struct AddPlayerToTeamView: View {
  let player: PlayerProfile
  let manager: PlayerTeamManager
  @Environment(\.dismiss) private var dismiss

  @State private var selectedTeams: Set<UUID> = []
  @State private var showCreateTeamSheet = false

  var body: some View {
    NavigationStack {
      List {
        Section("Add \(player.name) to existing teams") {
          if manager.teams.isEmpty {
            Text("No teams available")
              .foregroundStyle(.secondary)
          } else {
            ForEach(manager.teams) { team in
              TeamRowView(
                team: team,
                player: player,
                isSelected: selectedTeams.contains(team.id),
                isAlreadyMember: team.players.contains(where: { $0.id == player.id }),
                onToggleSelection: toggleTeamSelection
              )
            }
          }
        }

        Section {
          Button {
            showCreateTeamSheet = true
          } label: {
            HStack {
              Image(systemName: "plus.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(Color.accentColor)
              Text("Create New Team")
              Spacer()
              Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(
                  .secondary
                )
            }
          }
          .buttonStyle(.plain)
        }
      }
      .navigationTitle("Add to Team")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel", systemImage: "xmark") {
            dismiss()
          }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done", systemImage: "checkmark") {
            addPlayerToSelectedTeams()
            dismiss()
          }
          .disabled(selectedTeams.isEmpty)
          .fontWeight(.semibold)
        }
      }
      .sheet(isPresented: $showCreateTeamSheet) {
        IdentityEditorView(
          identity: .team(nil),
          manager: manager
        )
      }
    }
  }

  private func toggleTeamSelection(_ teamId: UUID) {
    if selectedTeams.contains(teamId) {
      selectedTeams.remove(teamId)
    } else {
      selectedTeams.insert(teamId)
    }
  }

  private func addPlayerToSelectedTeams() {
    for teamId in selectedTeams {
      if let team = manager.teams.first(where: { $0.id == teamId }) {
        if !team.players.contains(where: { $0.id == player.id }) {
          team.players.append(player)
          team.lastModified = Date()
          do {
            try manager.updateTeam(team) { _ in }
            Log.event(
              .saveSucceeded,
              level: .info,
              message: "player.addedToTeam",
              metadata: [
                "playerId": player.id.uuidString,
                "teamId": team.id.uuidString,
              ]
            )
          } catch {
            Log.event(
              .saveFailed,
              level: .error,
              message: "player.addToTeam.failed",
              metadata: [
                "playerId": player.id.uuidString,
                "teamId": team.id.uuidString,
                "error": String(describing: error),
              ]
            )
          }
        }
      }
    }
  }
}

// MARK: - Team Row View
private struct TeamRowView: View {
  let team: TeamProfile
  let player: PlayerProfile
  let isSelected: Bool
  let isAlreadyMember: Bool
  let onToggleSelection: (UUID) -> Void

  var body: some View {
    Button {
      if !isAlreadyMember {
        onToggleSelection(team.id)
      }
    } label: {
      HStack {
        IdentityCard(identity: .team(team))
          .padding(.vertical, DesignSystem.Spacing.xs)
          .opacity(isAlreadyMember ? 0.6 : 1.0)

        Spacer()

        if isAlreadyMember {
          // Badge indicating player is already in this team
          Text("MEMBER")
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
              Color.gray.opacity(0.8)
            )
            .clipShape(Capsule())
        } else if isSelected {
          Image(systemName: "checkmark")
            .foregroundStyle(Color.accentColor)
        }
      }
    }
    .disabled(isAlreadyMember)
    .buttonStyle(.plain)
  }
}
