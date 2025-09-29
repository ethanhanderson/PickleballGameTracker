import GameTrackerCore
import SwiftUI

@MainActor
struct ShareIdentityView: View {
  let identity: IdentityCard.Identity
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      VStack(spacing: DesignSystem.Spacing.lg) {
        // Identity preview
        VStack(spacing: DesignSystem.Spacing.md) {
          IdentityCard(identity: identity)
            .padding(DesignSystem.Spacing.lg)
            .glassEffect(
              .regular.tint(
                Color.gray.opacity(0.15).opacity(0.2)
              ),
              in: RoundedRectangle(
                cornerRadius: DesignSystem.CornerRadius.xl
              )
            )

          Text("Share \(identity.displayName)")
            .font(.title2)
            .foregroundStyle(.primary)
        }

        // Share options
        VStack(spacing: DesignSystem.Spacing.md) {
          ShareLink(
            item: shareText,
            subject: Text("Check out this \(identityType)")
          ) {
            Label("Share via Messages", systemImage: "message.fill")
          }
          .buttonStyle(.borderedProminent)
          .tint(.accentColor)

          ShareLink(
            item: shareText,
            subject: Text("Check out this \(identityType)")
          ) {
            Label("Share via Other Apps", systemImage: "square.and.arrow.up.fill")
          }
          .buttonStyle(.bordered)
        }

        Spacer()
      }
      .padding(DesignSystem.Spacing.lg)
      .navigationTitle("Share")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
  }

  private var identityType: String {
    switch identity {
    case .player: return "player"
    case .team: return "team"
    }
  }

  private var shareText: String {
    let baseText = """
      Check out \(identity.displayName) from my pickleball roster!

      \(identity.secondaryText)
      """

    switch identity {
    case .player(let player, _):
      return """
        \(baseText)

        Skill Level: \(player.skillLevel.displayName)
        Preferred Hand: \(player.preferredHand.displayName)
        """ + (player.notes.map { "\nNotes: \($0)" } ?? "")

    case .team(let team):
      let playerNames = team.players.map { $0.name }.joined(separator: ", ")
      return """
        \(baseText)

        Players: \(playerNames)
        """ + (team.notes.map { "\nNotes: \($0)" } ?? "")
    }
  }
}

extension PlayerSkillLevel {
  var displayName: String {
    switch self {
    case .beginner: return "Beginner"
    case .intermediate: return "Intermediate"
    case .advanced: return "Advanced"
    case .expert: return "Expert"
    case .unknown: return "Unknown"
    }
  }
}

extension PlayerHandedness {
  var displayName: String {
    switch self {
    case .right: return "Right"
    case .left: return "Left"
    case .unknown: return "Unknown"
    }
  }
}
