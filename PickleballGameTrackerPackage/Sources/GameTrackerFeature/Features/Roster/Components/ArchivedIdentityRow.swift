import CorePackage
import SwiftUI

@MainActor
struct ArchivedIdentityRow: View {
  let identity: RosterIdentityCard.Identity
  let manager: PlayerTeamManager

  var body: some View {
    NavigationLink {
      RosterIdentityDetailView(
        identity: identity,
        manager: manager
      )
    } label: {
      RosterIdentityCard(identity: identity)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("archive.row.\(identity.id.uuidString)")
  }
}


