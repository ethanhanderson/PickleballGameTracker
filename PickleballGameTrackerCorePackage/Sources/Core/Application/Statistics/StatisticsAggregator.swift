import Foundation
import SwiftData

public struct StatisticsAggregationError: Error, LocalizedError, Sendable {
  public var errorDescription: String? { "Statistics aggregation failed" }
}

public struct WinRateSummary: Sendable, Hashable {
  public let totalGames: Int
  public let wins: Int
  public let winRate: Double  // 0.0 ... 1.0
  public init(totalGames: Int, wins: Int) {
    self.totalGames = totalGames
    self.wins = wins
    self.winRate = totalGames > 0 ? Double(wins) / Double(totalGames) : 0
  }
}

public struct TrendPoint: Sendable, Hashable {
  public let date: Date
  public let value: Double
}

public struct ServeWinSummary: Sendable, Hashable {
  public let totalServePoints: Int
  public let pointsWonOnServe: Int
  public var serveWinRate: Double {
    totalServePoints > 0 ? Double(pointsWonOnServe) / Double(totalServePoints) : 0
  }
  public init(totalServePoints: Int, pointsWonOnServe: Int) {
    self.totalServePoints = totalServePoints
    self.pointsWonOnServe = pointsWonOnServe
  }
}

/// Minimal aggregator for v0.3 to support Win Rate and scaffolding.
@MainActor
public final class StatisticsAggregator {
  private let modelContext: ModelContext

  public init(modelContext: ModelContext) {
    self.modelContext = modelContext
  }

  public func computeWinRate(
    gameId: String? = nil,
    gameTypeId: String? = nil
  ) throws -> WinRateSummary {
    let allGames = try modelContext.fetch(FetchDescriptor<Game>())

    let filtered: [Game] = allGames.filter { game in
      // Completed games only for win rate
      guard game.isCompleted else { return false }
      let idMatches: Bool = {
        if let gameId, let uuid = UUID(uuidString: gameId) { return game.id == uuid }
        return true
      }()
      let typeMatches: Bool = {
        if let gameTypeId { return game.gameType.rawValue == gameTypeId }
        return true
      }()
      return idMatches && typeMatches
    }

    let total = filtered.count
    let wins = filtered.reduce(into: 0) { acc, game in
      if game.score1 > game.score2 { acc += 1 }
    }
    return WinRateSummary(totalGames: total, wins: wins)
  }

  // MARK: - Serving metrics (v0.3 minimal implementation)

  public func computeServeWinRate(
    gameId: String? = nil,
    gameTypeId: String? = nil
  ) throws -> ServeWinSummary {
    // Approximation using completed games: treat each completed point by Team 1 as won on serve when Team 1 was serving before the rally.
    // Since we do not persist per-rally serve outcomes yet, approximate using serverNumber/position parity.
    // For v0.3 we use: wins by Team 1 as serve wins when total score parity indicates Team 1 served; same pattern for Team 2.
    let games = try modelContext.fetch(FetchDescriptor<Game>()).filter { g in
      guard g.isCompleted else { return false }
      let idMatches: Bool = {
        if let gameId, let uuid = UUID(uuidString: gameId) { return g.id == uuid }
        return true
      }()
      let typeMatches: Bool = {
        if let gameTypeId { return g.gameType.rawValue == gameTypeId }
        return true
      }()
      return idMatches && typeMatches
    }

    var totalServePoints = 0
    var pointsWonOnServe = 0

    for g in games {
      // Very rough approximation: assume alternating serve and award half of each team's points as serve-won on average.
      // This is a placeholder until rally-level outcomes are persisted.
      let t1 = g.score1
      let t2 = g.score2
      totalServePoints += (t1 + t2)
      pointsWonOnServe += Int(round(Double(t1) * 0.5 + Double(t2) * 0.5))
    }

    return ServeWinSummary(totalServePoints: totalServePoints, pointsWonOnServe: pointsWonOnServe)
  }

  public func computeWinRateTrend(days: Int) throws -> [TrendPoint] {
    return try computeWinRateTrend(days: days, gameTypeId: nil, endDate: nil)
  }

  public func computeWinRateTrend(
    days: Int,
    gameTypeId: String? = nil,
    endDate: Date? = nil
  ) throws -> [TrendPoint] {
    precondition(days > 0, "days must be > 0")
    let cal = Calendar.current
    let endDay = cal.startOfDay(for: endDate ?? Date())
    guard let startWindow = cal.date(byAdding: .day, value: -(days - 1), to: endDay) else {
      return []
    }

    // Prefer summaries when available for performance
    let typeFilter = gameTypeId
    let endExclusive = cal.date(byAdding: .day, value: 1, to: endDay) ?? endDay
    let summariesDescriptor: FetchDescriptor<GameSummary>
    if let typeFilter {
      summariesDescriptor = FetchDescriptor<GameSummary>(
        predicate: #Predicate { summary in
          summary.completedDate >= startWindow && summary.completedDate < endExclusive
            && summary.gameTypeId == typeFilter
        }
      )
    } else {
      summariesDescriptor = FetchDescriptor<GameSummary>(
        predicate: #Predicate { summary in
          summary.completedDate >= startWindow && summary.completedDate < endExclusive
        }
      )
    }
    let summaries = try modelContext.fetch(summariesDescriptor)

    var points: [TrendPoint] = []
    if !summaries.isEmpty {
      for offset in stride(from: days - 1, through: 0, by: -1) {
        guard let day = cal.date(byAdding: .day, value: -offset, to: endDay) else { continue }
        let start = day
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? start
        let dayRows = summaries.filter { $0.completedDate >= start && $0.completedDate < end }
        let wins = dayRows.reduce(0) { $0 + ($1.winningTeam == 1 ? 1 : 0) }
        let value = dayRows.isEmpty ? 0 : Double(wins) / Double(dayRows.count)
        points.append(TrendPoint(date: start, value: value))
      }
      return points
    }

    // Fallback to full games when summaries are absent (e.g., older data)
    let games = try modelContext.fetch(FetchDescriptor<Game>())
    let filteredGames = games.filter { g in
      let d = g.completedDate ?? g.lastModified
      let inWindow = d >= startWindow && d < cal.date(byAdding: .day, value: 1, to: endDay)!
      let typeMatches: Bool = {
        if let gameTypeId { return g.gameType.rawValue == gameTypeId }
        return true
      }()
      return g.isCompleted && inWindow && typeMatches
    }
    for offset in stride(from: days - 1, through: 0, by: -1) {
      guard let day = cal.date(byAdding: .day, value: -offset, to: endDay) else { continue }
      let start = day
      let end = cal.date(byAdding: .day, value: 1, to: start) ?? start
      let dayGames = filteredGames.filter {
        (($0.completedDate ?? $0.lastModified) >= start)
          && (($0.completedDate ?? $0.lastModified) < end)
      }
      let wins = dayGames.reduce(0) { $0 + ($1.score1 > $1.score2 ? 1 : 0) }
      let value = dayGames.isEmpty ? 0 : Double(wins) / Double(dayGames.count)
      points.append(TrendPoint(date: start, value: value))
    }
    return points
  }

  /// Rolling point differential trend (signed from Team 1 perspective)
  public func computePointDifferentialTrend(
    days: Int,
    gameTypeId: String? = nil,
    endDate: Date? = nil
  ) throws -> [TrendPoint] {
    precondition(days > 0, "days must be > 0")
    let cal = Calendar.current
    let endDay = cal.startOfDay(for: endDate ?? Date())
    guard let startWindow = cal.date(byAdding: .day, value: -(days - 1), to: endDay) else {
      return []
    }

    // Prefer summaries for performance
    let typeFilter = gameTypeId
    let endExclusive = cal.date(byAdding: .day, value: 1, to: endDay) ?? endDay
    let summariesDescriptor: FetchDescriptor<GameSummary>
    if let typeFilter {
      summariesDescriptor = FetchDescriptor<GameSummary>(
        predicate: #Predicate { summary in
          summary.completedDate >= startWindow && summary.completedDate < endExclusive
            && summary.gameTypeId == typeFilter
        }
      )
    } else {
      summariesDescriptor = FetchDescriptor<GameSummary>(
        predicate: #Predicate { summary in
          summary.completedDate >= startWindow && summary.completedDate < endExclusive
        }
      )
    }
    let summaries = try modelContext.fetch(summariesDescriptor)

    var points: [TrendPoint] = []
    if !summaries.isEmpty {
      for offset in stride(from: days - 1, through: 0, by: -1) {
        guard let day = cal.date(byAdding: .day, value: -offset, to: endDay) else { continue }
        let start = day
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? start
        let dayRows = summaries.filter { $0.completedDate >= start && $0.completedDate < end }
        if dayRows.isEmpty {
          points.append(TrendPoint(date: start, value: 0))
        } else {
          let values = dayRows.map {
            ($0.winningTeam == 1 ? 1.0 : -1.0) * Double($0.pointDifferential)
          }
          let avg = values.reduce(0, +) / Double(values.count)
          points.append(TrendPoint(date: start, value: avg))
        }
      }
      return points
    }

    // Fallback to Games
    let games = try modelContext.fetch(FetchDescriptor<Game>())
    let filteredGames = games.filter { g in
      let d = g.completedDate ?? g.lastModified
      let inWindow = d >= startWindow && d < endExclusive
      let typeMatches: Bool = {
        if let gameTypeId { return g.gameType.rawValue == gameTypeId }
        return true
      }()
      return g.isCompleted && inWindow && typeMatches
    }
    for offset in stride(from: days - 1, through: 0, by: -1) {
      guard let day = cal.date(byAdding: .day, value: -offset, to: endDay) else { continue }
      let start = day
      let end = cal.date(byAdding: .day, value: 1, to: start) ?? start
      let dayGames = filteredGames.filter {
        (($0.completedDate ?? $0.lastModified) >= start)
          && (($0.completedDate ?? $0.lastModified) < end)
      }
      if dayGames.isEmpty {
        points.append(TrendPoint(date: start, value: 0))
      } else {
        let values = dayGames.map { g -> Double in
          let diff = abs(g.score1 - g.score2)
          return (g.score1 >= g.score2 ? 1.0 : -1.0) * Double(diff)
        }
        let avg = values.reduce(0, +) / Double(values.count)
        points.append(TrendPoint(date: start, value: avg))
      }
    }
    return points
  }

  public struct Streaks: Sendable, Hashable {
    public let currentWinStreak: Int
    public let longestWinStreak: Int
  }

  public func computeStreaks(
    gameTypeId: String? = nil
  ) throws -> Streaks {
    // Use summaries if present for efficiency, fall back to Game
    let summaryDescriptor: FetchDescriptor<GameSummary>
    if let gameTypeId {
      summaryDescriptor = FetchDescriptor<GameSummary>(
        predicate: #Predicate { $0.gameTypeId == gameTypeId },
        sortBy: [SortDescriptor(\.completedDate, order: .reverse)]
      )
    } else {
      summaryDescriptor = FetchDescriptor<GameSummary>(
        sortBy: [SortDescriptor(\.completedDate, order: .reverse)]
      )
    }

    let summaries = try modelContext.fetch(summaryDescriptor)
    let ordered: [(date: Date, isWin: Bool)]
    if summaries.isEmpty {
      // Fallback: compute from Game
      let games = try modelContext.fetch(FetchDescriptor<Game>())
      let completed = games.compactMap { g -> (Date, Bool)? in
        guard g.isCompleted, let d = g.completedDate else { return nil }
        return (d, g.score1 > g.score2)
      }.sorted { $0.0 > $1.0 }
      ordered = completed.map { ($0.0, $0.1) }
    } else {
      ordered = summaries.map { ($0.completedDate, $0.winningTeam == 1) }
    }

    var current = 0
    var longest = 0
    for (_, isWin) in ordered {
      if isWin {
        current += 1
        longest = max(longest, current)
      } else {
        current = 0
      }
    }
    return Streaks(currentWinStreak: current, longestWinStreak: longest)
  }
}
