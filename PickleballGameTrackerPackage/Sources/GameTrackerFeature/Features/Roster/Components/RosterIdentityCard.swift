import CorePackage
import SwiftData
import SwiftUI

@MainActor
struct RosterIdentityCard: View {
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
        switch player.skillLevel {
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
        let count = team.teamSize
        return "\(count) player\(count == 1 ? "" : "s")"
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

    var iconTintColor: DesignSystem.AppleSystemColor {
      switch self {
      case .player(let player, _):
        return player.iconTintColor ?? .blue
      case .team(let team):
        return team.iconTintColor ?? .green
      }
    }

    /// Theme color for the identity - used for UI theming
    var themeColor: Color {
      if isArchived {
        return DesignSystem.Colors.paused
      }
      return iconTintColor.color
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
          .font(DesignSystem.Typography.title3)
          .foregroundColor(DesignSystem.Colors.textPrimary)

        Text(identity.secondaryText)
          .font(DesignSystem.Typography.subheadline)
          .foregroundColor(DesignSystem.Colors.textSecondary)
      }
      Spacer()
      Image(systemName: "chevron.right")
        .font(.system(size: 16, weight: .semibold))
        .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.6))
        .accessibilityHidden(true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .contentShape(.rect)
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
  // Use fresh local model instances to avoid stale SwiftData references
  let player = PlayerProfile(name: "Ethan", skillLevel: .advanced, preferredHand: .right)
  return RosterIdentityCard(
    identity: .player(player, teamCount: 3)
  )
  .padding()
}

#Preview("Team — Doubles") {
  // Use fresh local model instances to avoid stale SwiftData references
  let p1 = PlayerProfile(name: "Ethan", skillLevel: .advanced, preferredHand: .right)
  let p2 = PlayerProfile(name: "Reed", skillLevel: .intermediate, preferredHand: .right)
  let team = TeamProfile(name: "Ethan & Reed", players: [p1, p2])
  return RosterIdentityCard(
    identity: .team(team)
  )
  .padding()
}
