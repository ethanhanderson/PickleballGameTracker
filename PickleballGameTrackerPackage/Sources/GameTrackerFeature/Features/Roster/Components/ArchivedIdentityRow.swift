import GameTrackerCore
import SwiftUI

@MainActor
struct ArchivedIdentityRow: View {
  let identity: IdentityCard.Identity

  var body: some View {
    NavigationLink {
      IdentityDetailView(identity: identity)
    } label: {
      IdentityCard(identity: identity)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("archive.row.\(identity.id.uuidString)")
  }
}
