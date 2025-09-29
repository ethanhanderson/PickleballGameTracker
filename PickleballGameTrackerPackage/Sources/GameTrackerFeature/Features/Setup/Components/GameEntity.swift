import Foundation
import GameTrackerCore

protocol GameEntity: Identifiable, Hashable {
  var id: UUID { get }
  var name: String { get }
  var displayName: String { get }
  var skillLevelDisplay: String? { get }
}

extension PlayerProfile: GameEntity {
  var displayName: String { name }
  var skillLevelDisplay: String? {
    skillLevel.displayName != "Unknown" ? skillLevel.displayName : nil
  }
}

extension TeamProfile: GameEntity {
  var displayName: String { name }
  var skillLevelDisplay: String? { nil }
}


