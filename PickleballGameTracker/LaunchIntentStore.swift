import Foundation
import Observation
import GameTrackerCore

@MainActor
@Observable
final class LaunchIntentStore {
  static let shared = LaunchIntentStore()

  private init() {}

  var pendingSetupGameType: GameType? = nil

  func setPendingSetup(gameType: GameType) {
    pendingSetupGameType = gameType
  }

  func consumePendingSetup() -> GameType? {
    defer { pendingSetupGameType = nil }
    return pendingSetupGameType
  }
}


