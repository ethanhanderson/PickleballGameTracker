import SharedGameCore
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
                if let data = team.avatarImageData, let ui = UIImage(data: data)
                {
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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var avatar: some View {
        Group {
            if let image = identity.avatarImage {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: identity.symbolName)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.secondary)

            }
        }
        .frame(width: 58, height: 58)
        .background(
            DesignSystem.Colors.secondaryLight,
            in: .circle
        )
        .accessibilityHidden(true)
    }
}

#Preview("Player — Competitive") {
    let container = try! PreviewGameData.createRosterPreviewContainer()
    let players = PreviewGameData.samplePlayers
    return RosterIdentityCard(
        identity: .player(players.first!, teamCount: 3)
    )
    .padding()
    .modelContainer(container)
}

#Preview("Team — Doubles") {
    let container = try! PreviewGameData.createRosterPreviewContainer()
    let team = PreviewGameData.sampleTeams.first!
    return RosterIdentityCard(
        identity: .team(team)
    )
    .padding()
    .modelContainer(container)
}
