import Foundation
import Observation
import SwiftData
import GameTrackerCore

// MARK: - Personalization Engine
// Runs on main actor to interact with SwiftData. Heavy compute parts are small and fast.
@Observable
@MainActor
final class PersonalizationEngine {
  // MARK: Recording
  
  func recordStart(
    context: ModelContext,
    gameType: GameType,
    rules: GameRules?
  ) {
    let usage = loadOrCreateUsage(context: context, gameType: gameType)
    let now = Date()
    usage.lastPlayedAt = now
    usage.playCountTotal += 1
    usage.playCount7d += 1
    usage.playCount21d += 1
    // Refresh derived scores after mutation
    recomputeScores(context: context, now: now)
  }
  
  func recordComplete(
    context: ModelContext,
    gameType: GameType
  ) {
    // For now, treat as a no-op beyond ensuring recalc; can be expanded if needed
    recomputeScores(context: context, now: Date())
  }
  
  // MARK: Sections
  
  func buildSections(context: ModelContext, now: Date = Date()) -> [CatalogSectionDescriptor] {
    let allTypes = GameCatalog.allGameTypes
    let usages = fetchAllUsages(context: context)
    let usageById = Dictionary(uniqueKeysWithValues: usages.map { ($0.gameTypeId, $0) })
    
    // Rank by relevancy
    let ranked = rank(allTypes, usageById: usageById)
    
    // Recently played (<= 21d)
    let recentlyPlayed: [GameType] = allTypes
      .compactMap { gt in
        guard let u = usageById[gt.rawValue], let last = u.lastPlayedAt else { return nil }
        let days = daysSince(date: last, now: now)
        return days <= 21 ? gt : nil
      }
      .sorted { lhs, rhs in
        let l = usageById[lhs.rawValue]?.lastPlayedAt ?? .distantPast
        let r = usageById[rhs.rawValue]?.lastPlayedAt ?? .distantPast
        return l > r
      }
    
    // Quick Start: top by relevancy (favor 7d in scoring)
    var sections: [CatalogSectionDescriptor] = []
    let quickStart = Array(ranked.prefix(8))
    if quickStart.isEmpty == false {
      sections.append(
        CatalogSectionDescriptor(
          id: "Section.QuickStart",
          title: "Quick Start",
          destination: .quickStart,
          gameTypes: quickStart
        )
      )
    }
    
    // Recently Played
    if recentlyPlayed.isEmpty == false {
      sections.append(
        CatalogSectionDescriptor(
          id: "Section.RecentlyPlayed",
          title: "Recently Played",
          destination: .allGames,
          gameTypes: Array(recentlyPlayed.prefix(10))
        )
      )
    }
    
    // Since you played X… (anchors from most relevant in last 7d)
    let topAnchors = topAnchors7d(allTypes: allTypes, usageById: usageById, maxAnchors: 2)
    var alreadyShown = Set(sections.flatMap { $0.gameTypes.map(\.rawValue) })
    
    for anchor in topAnchors {
      let recos = recommendationsSimilar(to: anchor, allTypes: allTypes, usageById: usageById)
        .filter { alreadyShown.contains($0.rawValue) == false }
      if recos.isEmpty == false {
        sections.append(
          CatalogSectionDescriptor(
            id: "Section.Because.\(anchor.rawValue)",
            title: "Since you played \(anchor.displayName)…",
            destination: .recommended,
            gameTypes: Array(recos.prefix(6)),
            anchor: anchor
          )
        )
        alreadyShown.formUnion(recos.map(\.rawValue))
      }
    }
    
    // Games you might like (exclude recently played)
    let liked = recommendForUser(allTypes: allTypes, usageById: usageById)
      .filter { gt in
        guard let u = usageById[gt.rawValue], let last = u.lastPlayedAt else { return true }
        return daysSince(date: last, now: now) > 21
      }
      .filter { alreadyShown.contains($0.rawValue) == false }
    if liked.isEmpty == false {
      sections.append(
        CatalogSectionDescriptor(
          id: "Section.MightLike",
          title: "Games you might like",
          destination: .recommended,
          gameTypes: Array(liked.prefix(8))
        )
      )
      alreadyShown.formUnion(liked.map(\.rawValue))
    }
    
    // Explore variations (simple heuristic: keep top relevant variants not shown)
    let explore = ranked.filter { alreadyShown.contains($0.rawValue) == false }
    if explore.isEmpty == false {
      sections.append(
        CatalogSectionDescriptor(
          id: "Section.Explore",
          title: "Explore variations",
          destination: .allGames,
          gameTypes: Array(explore.prefix(8))
        )
      )
    }
    
    // Browse all (fallback) - always present, ordered by personal relevancy
    sections.append(
      CatalogSectionDescriptor(
        id: "Section.BrowseAll",
        title: "Browse all",
        destination: .allGames,
        gameTypes: ranked
      )
    )
    
    return sections
  }
  
  func rank(_ gameTypes: [GameType], context: ModelContext) -> [GameType] {
    let usages = fetchAllUsages(context: context)
    let byId = Dictionary(uniqueKeysWithValues: usages.map { ($0.gameTypeId, $0) })
    return rank(gameTypes, usageById: byId)
  }
  
  func recommendations(for gameType: GameType, context: ModelContext, max: Int = 8) -> [GameType] {
    let allTypes = GameCatalog.allGameTypes
    let usages = fetchAllUsages(context: context)
    let usageById = Dictionary(uniqueKeysWithValues: usages.map { ($0.gameTypeId, $0) })
    let recos = recommendationsSimilar(to: gameType, allTypes: allTypes, usageById: usageById)
    return Array(recos.prefix(max))
  }
  
  func recalculate(context: ModelContext) {
    recomputeScores(context: context, now: Date())
  }
  
  // MARK: - Internal helpers
  
  private func loadOrCreateUsage(context: ModelContext, gameType: GameType) -> GameUsage {
    if let existing = fetchUsage(context: context, id: gameType.rawValue) {
      return existing
    }
    let identity = GameIdentityCatalog.identity(for: gameType)
    let usage = GameUsage(gameTypeId: gameType.rawValue, identity: identity)
    context.insert(usage)
    return usage
  }
  
  private func fetchUsage(context: ModelContext, id: String) -> GameUsage? {
    let descriptor = FetchDescriptor<GameUsage>(
      predicate: #Predicate { $0.gameTypeId == id }
    )
    return try? context.fetch(descriptor).first
  }
  
  private func fetchAllUsages(context: ModelContext) -> [GameUsage] {
    let descriptor = FetchDescriptor<GameUsage>()
    return (try? context.fetch(descriptor)) ?? []
  }
  
  private func recomputeScores(context: ModelContext, now: Date) {
    let usages = fetchAllUsages(context: context)
    // Popularity normalization based on playCount21d
    let max21 = max(1, usages.map(\.playCount21d).max() ?? 1)
    
    for u in usages {
      let days = u.lastPlayedAt.map { daysSince(date: $0, now: now) }
      let recency = PersonalizationScoring.recencyScore(daysSinceLast: days)
      let frequency = PersonalizationScoring.frequencyScore(playCount7d: u.playCount7d, playCount21d: u.playCount21d)
      let popularity = Double(u.playCount21d) / Double(max21)
      
      u.decayedRecency = recency
      u.decayedFrequency = frequency
      u.popularityScore = popularity
      // Similarity is computed on-demand per candidate; approximated here by identity tag count as a tiny bias
      let identityBias = Double(u.identity.tags.count) / 12.0
      u.relevancyScore = PersonalizationScoring.relevancyScore(recency: recency, frequency: frequency, similarity: identityBias)
    }
  }
  
  private func rank(_ gameTypes: [GameType], usageById: [String: GameUsage]) -> [GameType] {
    gameTypes.sorted { lhs, rhs in
      let l = usageById[lhs.rawValue]?.relevancyScore ?? 0
      let r = usageById[rhs.rawValue]?.relevancyScore ?? 0
      if l == r {
        // stable tie-breaker by rawValue
        return lhs.rawValue < rhs.rawValue
      }
      return l > r
    }
  }
  
  private func topAnchors7d(allTypes: [GameType], usageById: [String: GameUsage], maxAnchors: Int) -> [GameType] {
    allTypes
      .filter { usageById[$0.rawValue]?.playCount7d ?? 0 > 0 }
      .sorted { lhs, rhs in
        let l = usageById[lhs.rawValue]?.playCount7d ?? 0
        let r = usageById[rhs.rawValue]?.playCount7d ?? 0
        return l > r
      }
      .prefix(maxAnchors)
      .map { $0 }
  }
  
  private func recommendationsSimilar(to anchor: GameType, allTypes: [GameType], usageById: [String: GameUsage]) -> [GameType] {
    let anchorId = anchor.rawValue
    guard let anchorUsage = usageById[anchorId] else { return [] }
    let anchorIdentity = anchorUsage.identity
    let playedIds: Set<String> = Set(allTypes.compactMap { gt in
      guard let u = usageById[gt.rawValue], u.playCount21d > 0 else { return nil }
      return gt.rawValue
    })
    return allTypes
      .filter { $0.rawValue != anchorId }
      .filter { playedIds.contains($0.rawValue) == false }
      .sorted { lhs, rhs in
        let sl = PersonalizationScoring.similarity(anchorIdentity, GameIdentityCatalog.identity(for: lhs))
        let sr = PersonalizationScoring.similarity(anchorIdentity, GameIdentityCatalog.identity(for: rhs))
        if sl == sr { return lhs.rawValue < rhs.rawValue }
        return sl > sr
      }
  }
  
  private func recommendForUser(allTypes: [GameType], usageById: [String: GameUsage]) -> [GameType] {
    // Build a pseudo user profile: merge identities of frequently played games (21d)
    let played = allTypes.compactMap { gt -> (GameType, GameUsage)? in
      guard let u = usageById[gt.rawValue], u.playCount21d > 0 else { return nil }
      return (gt, u)
    }
    // If no data, return default catalog order
    guard played.isEmpty == false else { return GameCatalog.allGameTypes }
    
    // Weight by 7d*2 + 21d
    var tagScores: [GameTag: Double] = [:]
    var count: Double = 0
    for (_, u) in played {
      let weight = Double(2 * u.playCount7d + u.playCount21d)
      for tag in u.identity.tags {
        tagScores[tag, default: 0] += weight
      }
      count += weight
    }
    // Normalize tag preferences
    if count > 0 {
      for (k, v) in tagScores {
        tagScores[k] = v / count
      }
    }
    
    // Score candidates by similarity to preferred tags and rule proximity
    let preferred = tagScores
    return allTypes.sorted { lhs, rhs in
      let sl = preferenceScore(for: lhs, preferredTags: preferred)
      let sr = preferenceScore(for: rhs, preferredTags: preferred)
      if sl == sr { return lhs.rawValue < rhs.rawValue }
      return sl > sr
    }
  }
  
  // MARK: - Similarity utilities
  
  private func similarity(_ a: GameIdentity, _ b: GameIdentity) -> Double {
    // Jaccard for tags
    let sa = Set(a.tags)
    let sb = Set(b.tags)
    let inter = Double(sa.intersection(sb).count)
    let union = Double(sa.union(sb).count)
    let jaccard = union > 0 ? inter / union : 0
    // Simple feature distance (normalized)
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
  
  private func preferenceScore(for gameType: GameType, preferredTags: [GameTag: Double]) -> Double {
    let identity = GameIdentityCatalog.identity(for: gameType)
    let score = identity.tags.reduce(0.0) { acc, tag in
      acc + (preferredTags[tag] ?? 0)
    }
    return score
  }
  
  private func daysSince(date: Date, now: Date) -> Int {
    let interval = now.timeIntervalSince(date)
    return max(0, Int(interval / (60 * 60 * 24)))
  }
}

// MARK: - Identity mapping

enum GameIdentityCatalog {
  static func identity(for gameType: GameType) -> GameIdentity {
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
    
    // Heuristic tags based on winning score
    if rules.winningScore <= 11 {
      tags.append(.shortGame)
    } else {
      tags.append(.longGame)
    }
    
    // Beginner vs competitive heuristic
    if rules.winByTwo == false {
      tags.append(.beginnerFriendly)
    } else {
      tags.append(.competitive)
    }
    
    let features = RuleFeatureVector(winningScore: rules.winningScore, winByTwo: rules.winByTwo, servingRotationRaw: rules.servingRotation.rawValue, sideSwitchingRuleRaw: rules.sideSwitchingRule.rawValue, letServes: false)
    return GameIdentity(tags: tags, ruleFeatures: features)
  }
}


