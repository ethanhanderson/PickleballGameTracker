import CorePackage
import SwiftUI

@MainActor
struct HandIconView: View {
  let hand: PlayerHandedness

  var body: some View {
    switch hand {
    case .left:
      Image(systemName: "l.square.fill")
        .font(.system(size: 18, weight: .bold))
        .foregroundStyle(.primary)
    case .right:
      Image(systemName: "r.square.fill")
        .font(.system(size: 18, weight: .bold))
        .foregroundStyle(.primary)
    case .unknown:
      Image(systemName: "questionmark.square.fill")
        .font(.system(size: 18, weight: .bold))
        .foregroundStyle(.primary)
    }
  }
}
