import GameTrackerCore
import SwiftUI

@MainActor
struct ArchivedIdentityRow: View {
  let identity: IdentityCard.Identity
  let manager: PlayerTeamManager

  var body: some View {
    NavigationLink {
      IdentityDetailView(
        identity: identity,
        manager: manager
      )
    } label: {
      IdentityCard(identity: identity)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("archive.row.\(identity.id.uuidString)")
  }
}
