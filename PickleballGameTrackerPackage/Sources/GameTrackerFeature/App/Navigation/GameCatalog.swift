import GameTrackerCore
import Foundation

enum GameCatalog {
  struct CatalogSectionInfo: Hashable, Sendable {
    let title: String
    let gameTypes: [GameType]
    let destination: GameSectionDestination
  }

  static let sections: [CatalogSectionInfo] = [
    CatalogSectionInfo(title: "Quick Start", gameTypes: GameType.quickStartTypes, destination: .quickStart),
    CatalogSectionInfo(title: "All Games", gameTypes: GameType.allTypes, destination: .allGames),
    CatalogSectionInfo(title: "Recommended", gameTypes: GameType.recommendedTypes, destination: .recommended),
    CatalogSectionInfo(title: "Beginner Friendly", gameTypes: GameType.beginnerTypes, destination: .beginnerFriendly),
    CatalogSectionInfo(title: "Advanced Play", gameTypes: GameType.competitiveTypes, destination: .advancedPlay),
    CatalogSectionInfo(title: "Testing", gameTypes: GameType.testingTypes, destination: .testing)
  ]

  static let allGameTypes: [GameType] = GameType.allTypes
}


