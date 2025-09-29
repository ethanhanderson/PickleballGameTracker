import Foundation
import SwiftData

@MainActor
public protocol LiveGameCoordinator: AnyObject {
  var currentGame: Game? { get }
  func setCurrentGame(_ game: Game)
  func incrementServeNumber()
  func triggerServeChangeHaptic()
  func gameStateDidChange(to gameState: GameState)
  func gameDidComplete(_ game: Game)
  func gameDidUpdate(_ game: Game)
  func gameDidDelete(_ game: Game)
  func validateStateConsistency() -> Bool
}


