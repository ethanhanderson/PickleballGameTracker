import Foundation

public enum GameTag: String, CaseIterable, Codable, Sendable {
  case singles
  case doubles
  case beginnerFriendly
  case competitive
  case casual
  case shortGame
  case longGame
  case dinkHeavy
  case serveDominant
  case rallyFocused
  case rotationStandard
  case rotationAlternate
  case sideSwitchOften
  case sideSwitchRare
}

public struct RuleFeatureVector: Codable, Sendable, Equatable {
  public let winningScore: Int
  public let winByTwo: Bool
  public let servingRotationRaw: String
  public let sideSwitchingRuleRaw: String
  public let letServes: Bool
  
  public init(
    winningScore: Int,
    winByTwo: Bool,
    servingRotationRaw: String,
    sideSwitchingRuleRaw: String,
    letServes: Bool
  ) {
    self.winningScore = winningScore
    self.winByTwo = winByTwo
    self.servingRotationRaw = servingRotationRaw
    self.sideSwitchingRuleRaw = sideSwitchingRuleRaw
    self.letServes = letServes
  }
}

public struct GameIdentity: Codable, Sendable, Equatable {
  public var tags: [GameTag]
  public var ruleFeatures: RuleFeatureVector
  
  public init(tags: [GameTag], ruleFeatures: RuleFeatureVector) {
    self.tags = tags
    self.ruleFeatures = ruleFeatures
  }
}


