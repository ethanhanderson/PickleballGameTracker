import Foundation

public enum PersonalizationScoring {
  // 7-day emphasis recency
  public static func recencyScore(daysSinceLast: Int?) -> Double {
    guard let days = daysSinceLast else { return 0 }
    return exp(-Double(max(0, days)) / 7.0)
  }
  
  public static func frequencyScore(playCount7d: Int, playCount21d: Int) -> Double {
    return log(1.0 + Double(2 * max(0, playCount7d) + max(0, playCount21d)))
  }
  
  public static func similarity(_ a: GameIdentity, _ b: GameIdentity) -> Double {
    // Tag Jaccard
    let sa = Set(a.tags)
    let sb = Set(b.tags)
    let inter = Double(sa.intersection(sb).count)
    let union = Double(sa.union(sb).count)
    let jaccard = union > 0 ? inter / union : 0
    
    // Feature similarity (normalized)
    let rfA = a.ruleFeatures
    let rfB = b.ruleFeatures
    var featureSim: Double = 0
    let scoreDiff = abs(Double(rfA.winningScore - rfB.winningScore))
    featureSim += max(0, 1 - min(21.0, scoreDiff) / 21.0)
    featureSim += rfA.winByTwo == rfB.winByTwo ? 1 : 0
    featureSim += rfA.servingRotationRaw == rfB.servingRotationRaw ? 1 : 0
    featureSim += rfA.sideSwitchingRuleRaw == rfB.sideSwitchingRuleRaw ? 1 : 0
    featureSim += rfA.letServes == rfB.letServes ? 1 : 0
    featureSim /= 5.0
    
    return 0.6 * jaccard + 0.4 * featureSim
  }
  
  public static func relevancyScore(recency: Double, frequency: Double, similarity: Double, weights: (Double, Double, Double) = (0.55, 0.25, 0.20)) -> Double {
    let (wr, wf, ws) = weights
    return wr * recency + wf * frequency + ws * similarity
  }
}


