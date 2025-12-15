import Foundation
import GameTrackerCore

struct CatalogSectionDescriptor: Hashable, Sendable {
  let id: String
  let title: String
  let destination: GameSectionDestination
  let gameTypes: [GameType]
  let anchor: GameType?
  
  init(
    id: String,
    title: String,
    destination: GameSectionDestination,
    gameTypes: [GameType],
    anchor: GameType? = nil
  ) {
    self.id = id
    self.title = title
    self.destination = destination
    self.gameTypes = gameTypes
    self.anchor = anchor
  }
}


