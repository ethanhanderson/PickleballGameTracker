import Foundation
import SwiftData
import Testing

@testable import PickleballGameTrackerCorePackage

@Suite("Statistics Aggregator (v0.3)")
struct StatisticsAggregatorTests {

  // MARK: - Helpers

  @MainActor
  private func makeCompletedGame(
    type: GameType,
    score1: Int,
    score2: Int,
    completedOn date: Date = Date()
  ) -> Game {
    let game = Game(gameType: type, score1: score1, score2: score2)
    game.completeGame(at: date)
    return game
  }

  // MARK: - Win Rate

  @Test("Win rate across all completed games")
  @MainActor
  func testWinRateAll() throws {
    let context = SwiftDataContainer.shared.modelContainer.mainContext

    // Clear data
    try context.delete(model: Game.self)

    // Insert 3 completed games: 2 wins for team1, 1 loss
    let g1 = makeCompletedGame(type: .recreational, score1: 11, score2: 8)
    let g2 = makeCompletedGame(type: .recreational, score1: 7, score2: 11)
    let g3 = makeCompletedGame(type: .tournament, score1: 15, score2: 13)
    context.insert(g1)
    context.insert(g2)
    context.insert(g3)
    try context.save()

    let aggregator = StatisticsAggregator(modelContext: context)
    let summary = try aggregator.computeWinRate()

    #expect(summary.totalGames == 3)
    #expect(summary.wins == 2)
    #expect(abs(summary.winRate - (2.0 / 3.0)) < 0.0001)
  }

  @Test("Win rate filtered by gameType id")
  @MainActor
  func testWinRateFilteredByGameType() throws {
    let context = SwiftDataContainer.shared.modelContainer.mainContext

    // Clear
    try context.delete(model: Game.self)

    // recreational: 1 win, 1 loss; tournament: 1 win
    context.insert(makeCompletedGame(type: .recreational, score1: 11, score2: 9))
    context.insert(makeCompletedGame(type: .recreational, score1: 6, score2: 11))
    context.insert(makeCompletedGame(type: .tournament, score1: 15, score2: 10))
    try context.save()

    let aggregator = StatisticsAggregator(modelContext: context)
    let recOnly = try aggregator.computeWinRate(
      gameId: nil, gameTypeId: GameType.recreational.rawValue)

    #expect(recOnly.totalGames == 2)
    #expect(recOnly.wins == 1)
    #expect(abs(recOnly.winRate - 0.5) < 0.0001)
  }

  @Test("Win rate filtered by specific game id")
  @MainActor
  func testWinRateFilteredByGameId() throws {
    let context = SwiftDataContainer.shared.modelContainer.mainContext

    // Clear
    try context.delete(model: Game.self)

    // Create multiple completed games
    let target = makeCompletedGame(type: .recreational, score1: 11, score2: 1)
    let other = makeCompletedGame(type: .recreational, score1: 3, score2: 11)
    context.insert(target)
    context.insert(other)
    try context.save()

    let aggregator = StatisticsAggregator(modelContext: context)
    let summary = try aggregator.computeWinRate(gameId: target.id.uuidString)

    #expect(summary.totalGames == 1)
    #expect(summary.wins == 1)
    #expect(summary.winRate == 1.0)
  }

  @Test("Win rate returns zero with no completed games")
  @MainActor
  func testWinRateNoCompletedGames() throws {
    let context = SwiftDataContainer.shared.modelContainer.mainContext
    try context.delete(model: Game.self)

    // Insert active (not completed) games
    let g1 = Game(gameType: .recreational, score1: 5, score2: 4)
    let g2 = Game(gameType: .recreational, score1: 7, score2: 8)
    context.insert(g1)
    context.insert(g2)
    try context.save()

    let aggregator = StatisticsAggregator(modelContext: context)
    let summary = try aggregator.computeWinRate()
    #expect(summary.totalGames == 0)
    #expect(summary.wins == 0)
    #expect(summary.winRate == 0.0)
  }

  // MARK: - Trend

  @Test("Win rate trend over recent days")
  @MainActor
  func testWinRateTrend() throws {
    let context = SwiftDataContainer.shared.modelContainer.mainContext
    try context.delete(model: Game.self)

    let cal = Calendar.current
    let today = cal.startOfDay(for: Date())
    let d1 = cal.date(byAdding: .day, value: -2, to: today) ?? today
    let d2 = cal.date(byAdding: .day, value: -1, to: today) ?? today
    let d3 = today

    // Day 1: 1 completed loss
    context.insert(makeCompletedGame(type: .recreational, score1: 8, score2: 11, completedOn: d1))
    // Day 2: 2 completed games, 1 win / 1 loss → 0.5
    context.insert(makeCompletedGame(type: .recreational, score1: 11, score2: 7, completedOn: d2))
    context.insert(makeCompletedGame(type: .recreational, score1: 6, score2: 11, completedOn: d2))
    // Day 3: 1 completed win
    context.insert(makeCompletedGame(type: .recreational, score1: 11, score2: 3, completedOn: d3))
    try context.save()

    let aggregator = StatisticsAggregator(modelContext: context)
    let trend = try aggregator.computeWinRateTrend(days: 3)

    #expect(trend.count == 3)
    // Expect values approximately [0.0, 0.5, 1.0]
    #expect(abs(trend[0].value - 0.0) < 0.0001)
    #expect(abs(trend[1].value - 0.5) < 0.0001)
    #expect(abs(trend[2].value - 1.0) < 0.0001)
  }

  // MARK: - Point Differential Trend

  @Test("Point differential trend over recent days")
  @MainActor
  func testPointDifferentialTrend() throws {
    let context = SwiftDataContainer.shared.modelContainer.mainContext
    try context.delete(model: Game.self)

    let cal = Calendar.current
    let today = cal.startOfDay(for: Date())
    let d1 = cal.date(byAdding: .day, value: -2, to: today) ?? today
    let d2 = cal.date(byAdding: .day, value: -1, to: today) ?? today
    let d3 = today

    // Day 1: loss by 3 → -3
    context.insert(makeCompletedGame(type: .recreational, score1: 8, score2: 11, completedOn: d1))
    // Day 2: win by 4 and loss by 5 → average (-0.5)
    context.insert(makeCompletedGame(type: .recreational, score1: 11, score2: 7, completedOn: d2))
    context.insert(makeCompletedGame(type: .recreational, score1: 6, score2: 11, completedOn: d2))
    // Day 3: win by 8 → +8
    context.insert(makeCompletedGame(type: .recreational, score1: 11, score2: 3, completedOn: d3))
    try context.save()

    let aggregator = StatisticsAggregator(modelContext: context)
    let trend = try aggregator.computePointDifferentialTrend(days: 3)

    #expect(trend.count == 3)
    #expect(abs(trend[0].value - (-3.0)) < 0.0001)
    #expect(abs(trend[1].value - (-0.5)) < 0.0001)
    #expect(abs(trend[2].value - 8.0) < 0.0001)
  }

  // MARK: - Streaks

  @Test("Streaks: current and longest win streak")
  @MainActor
  func testStreaks() throws {
    let context = SwiftDataContainer.shared.modelContainer.mainContext
    try context.delete(model: Game.self)

    let cal = Calendar.current
    let base = cal.startOfDay(for: Date())
    func day(_ offset: Int) -> Date { cal.date(byAdding: .day, value: -offset, to: base) ?? base }

    // Sequence (oldest → newest): W, W, L, W  => longest=2, current=1
    context.insert(
      makeCompletedGame(type: .recreational, score1: 11, score2: 9, completedOn: day(3)))
    context.insert(
      makeCompletedGame(type: .recreational, score1: 15, score2: 10, completedOn: day(2)))
    context.insert(
      makeCompletedGame(type: .recreational, score1: 5, score2: 11, completedOn: day(1)))
    context.insert(
      makeCompletedGame(type: .recreational, score1: 11, score2: 7, completedOn: day(0)))
    try context.save()

    let aggregator = StatisticsAggregator(modelContext: context)
    let s = try aggregator.computeStreaks()
    #expect(s.longestWinStreak == 2)
    #expect(s.currentWinStreak == 1)
  }
}
