import PickleballGameTrackerCorePackage
import Foundation

enum GameCatalog {
  struct GameSection: Hashable, Sendable {
    let title: String
    let gameTypes: [GameType]
    let destination: GameSectionDestination
  }

  static let sections: [GameSection] = [
    GameSection(title: "Quick Start", gameTypes: GameType.quickStartTypes, destination: .quickStart),
    GameSection(title: "All Games", gameTypes: GameType.allTypes, destination: .allGames),
    GameSection(title: "Recommended", gameTypes: GameType.recommendedTypes, destination: .recommended),
    GameSection(title: "Beginner Friendly", gameTypes: GameType.beginnerTypes, destination: .beginnerFriendly),
    GameSection(title: "Advanced Play", gameTypes: GameType.competitiveTypes, destination: .advancedPlay),
    GameSection(title: "Testing", gameTypes: GameType.testingTypes, destination: .testing)
  ]

  static let allGameTypes: [GameType] = GameType.allTypes
}


