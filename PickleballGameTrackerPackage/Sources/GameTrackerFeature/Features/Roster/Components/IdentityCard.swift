import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct IdentityCard: View {
  enum Identity: Hashable {
    case player(PlayerProfile, teamCount: Int? = nil)
    case team(TeamProfile)

    var id: UUID {
      switch self {
      case .player(let player, _): return player.id
      case .team(let team): return team.id
      }
    }

    var displayName: String {
      switch self {
      case .player(let player, _): return player.name
      case .team(let team): return team.name
      }
    }

    var secondaryText: String {
      switch self {
      case .player(let player, let teamCount):
        let skill: String
        let skillLevel: PlayerSkillLevel = player.skillLevel
        switch skillLevel {
        case .beginner: skill = "Beginner"
        case .intermediate: skill = "Intermediate"
        case .advanced: skill = "Advanced"
        case .expert: skill = "Expert"
        case .unknown: skill = "Skill Unspecified"
        }
        if let teams = teamCount {
          return "\(skill) • \(teams) team\(teams == 1 ? "" : "s")"
        } else {
          return skill
        }
      case .team(let team):
        let playerNames = team.players.map { $0.name }
        if playerNames.isEmpty {
          return "No players"
        } else if playerNames.count <= 3 {
          return playerNames.joined(separator: ", ")
        } else {
          let count = team.teamSize
          return "\(count) players"
        }
      }
    }

    var avatarImage: Image? {
      switch self {
      case .player(let player, _):
        if let data = player.avatarImageData,
          let ui = UIImage(data: data)
        {
          return Image(uiImage: ui)
        }
        return nil
      case .team(let team):
        if let data = team.avatarImageData, let ui = UIImage(data: data) {
          return Image(uiImage: ui)
        }
        return nil
      }
    }

    var symbolName: String {
      switch self {
      case .player(let player, _):
        return player.iconSymbolName ?? "person.fill"
      case .team(let team):
        return team.iconSymbolName ?? "person.2.fill"
      }
    }

    var iconTintColor: Color {
      switch self {
      case .player(let player, _):
        return player.iconTintColorValue ?? .blue
      case .team(let team):
        return team.iconTintColorValue ?? .green
      }
    }

    /// Theme color for the identity - used for UI theming
    var themeColor: Color {
      if isArchived {
        return Color.gray
      }
      return iconTintColor
    }

    /// Theme color with opacity for backgrounds
    var themeBackgroundColor: Color {
      themeColor.opacity(0.08)
    }

    /// Theme gradient for accents
    var themeGradient: LinearGradient {
      LinearGradient(
        colors: [themeColor.opacity(0.8), themeColor],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    }

    /// Whether this identity has a custom icon avatar (not default)
    var hasCustomIcon: Bool {
      switch self {
      case .player(let player, _):
        return player.iconSymbolName != nil
      case .team(let team):
        return team.iconSymbolName != nil
      }
    }

    var isArchived: Bool {
      switch self {
      case .player(let player, _):
        return player.isArchived
      case .team(let team):
        return team.isArchived
      }
    }
  }

  let identity: Identity

  init(identity: Identity) {
    self.identity = identity
  }

  var body: some View {
    HStack(spacing: DesignSystem.Spacing.md) {
      avatar
      VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
        Text(identity.displayName)
          .font(.title3)
          .foregroundStyle(.primary)

        Text(identity.secondaryText)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      Spacer()
      Image(systemName: "chevron.right")
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(.secondary.opacity(0.6))
        .accessibilityHidden(true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .contentShape(.rect)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(identity.displayName), \(identity.secondaryText)")
    .accessibilityIdentifier("roster.card.\(identity.id.uuidString)")
  }

  private var avatar: some View {
    Group {
      switch identity {
      case .player(let player, _):
        AvatarView(player: player, style: .card, isArchived: player.isArchived)
      case .team(let team):
        AvatarView(team: team, style: .card, isArchived: team.isArchived)
      }
    }
  }
}

#Preview("Player — Competitive") {
  let ctx = try! PreviewGameData.makeRosterPreviewContext()
  let player = ctx.players.first!
  let teams = ctx.teams
  let teamCount = teams.filter { team in
    team.players.contains(where: { $0.id == player.id })
  }.count
  return IdentityCard(
    identity: .player(player, teamCount: teamCount)
  )
  .padding()
  .modelContainer(ctx.container)
}

#Preview("Team — Doubles") {
  let ctx = try! PreviewGameData.makeRosterPreviewContext()
  let team = ctx.teams.first { $0.players.count == 2 } ?? ctx.teams.first!
  return IdentityCard(
    identity: .team(team)
  )
  .padding()
  .modelContainer(ctx.container)
}
