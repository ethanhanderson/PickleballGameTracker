import Foundation
import SwiftData
import GameTrackerCore

@Model
final class GameUsage {
  @Attribute(.unique) var gameTypeId: String
  var lastPlayedAt: Date?
  
  // Frequency windows
  var playCountTotal: Int
  var playCount7d: Int
  var playCount21d: Int
  
  // Derived scores
  var decayedRecency: Double
  var decayedFrequency: Double
  var relevancyScore: Double
  var popularityScore: Double
  
  // Stored identity fields (primitive) for portability
  var tagsRaw: [String]
  var identityWinningScore: Int
  var identityWinByTwo: Bool
  var identityServingRotationRaw: String
  var identitySideSwitchingRuleRaw: String
  var identityLetServes: Bool
  
  init(gameTypeId: String, identity: GameIdentity) {
    self.gameTypeId = gameTypeId
    self.lastPlayedAt = nil
    self.playCountTotal = 0
    self.playCount7d = 0
    self.playCount21d = 0
    self.decayedRecency = 0
    self.decayedFrequency = 0
    self.relevancyScore = 0
    self.popularityScore = 0
    self.tagsRaw = identity.tags.map(\.rawValue)
    self.identityWinningScore = identity.ruleFeatures.winningScore
    self.identityWinByTwo = identity.ruleFeatures.winByTwo
    self.identityServingRotationRaw = identity.ruleFeatures.servingRotationRaw
    self.identitySideSwitchingRuleRaw = identity.ruleFeatures.sideSwitchingRuleRaw
    self.identityLetServes = identity.ruleFeatures.letServes
  }
}

// MARK: - Identity bridge

extension GameUsage {
  var identity: GameIdentity {
    let tags: [GameTag] = tagsRaw.compactMap { GameTag(rawValue: $0) }
    let servingRotation = ServingRotation(rawValue: identityServingRotationRaw) ?? .standard
    let sideSwitching = SideSwitchingRule(rawValue: identitySideSwitchingRuleRaw) ?? .never
    let features = RuleFeatureVector(winningScore: identityWinningScore, winByTwo: identityWinByTwo, servingRotationRaw: servingRotation.rawValue, sideSwitchingRuleRaw: sideSwitching.rawValue, letServes: identityLetServes)
    return GameIdentity(tags: tags, ruleFeatures: features)
  }
}


