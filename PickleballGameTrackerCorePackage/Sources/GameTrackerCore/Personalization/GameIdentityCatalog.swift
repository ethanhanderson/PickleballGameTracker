import Foundation

public enum GameIdentityCatalog {
  public static func identity(for gameType: GameType) -> GameIdentity {
    let rules = gameType.defaultRules
    var tags: [GameTag] = []
    
    if let teamSize = TeamSize(playersPerSide: gameType.defaultTeamSize) {
      switch teamSize {
      case .singles:
        tags.append(.singles)
      case .doubles:
        tags.append(.doubles)
      }
    }
    
    switch rules.servingRotation {
    case .standard:
      tags.append(.rotationStandard)
    default:
      tags.append(.rotationAlternate)
    }
    
    switch rules.sideSwitchingRule {
    case .at6Points:
      tags.append(.sideSwitchOften)
    default:
      tags.append(.sideSwitchRare)
    }
    
    if rules.winningScore <= 11 {
      tags.append(.shortGame)
    } else {
      tags.append(.longGame)
    }
    
    if rules.winByTwo == false {
      tags.append(.beginnerFriendly)
    } else {
      tags.append(.competitive)
    }
    
    let features = RuleFeatureVector(
      winningScore: rules.winningScore,
      winByTwo: rules.winByTwo,
      servingRotationRaw: rules.servingRotation.rawValue,
      sideSwitchingRuleRaw: rules.sideSwitchingRule.rawValue,
      letServes: false
    )
    return GameIdentity(tags: tags, ruleFeatures: features)
  }
}


