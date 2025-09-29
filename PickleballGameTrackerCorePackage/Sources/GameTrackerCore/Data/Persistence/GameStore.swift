import Foundation
import SwiftData

@MainActor
public struct GameStore: Sendable {

  // MARK: - Supporting Types

  /// Options for sorting game summaries
  public enum SummarySortOption: Sendable {
    case dateCompleted
    case duration
    case pointDifferential
  }
  private let repo: SwiftDataRepository<Game>
  private let summaryRepo: SwiftDataRepository<GameSummary>

  public init(context: ModelContext) {
    self.repo = SwiftDataRepository<Game>(context: context)
    self.summaryRepo = SwiftDataRepository<GameSummary>(context: context)
  }

  // MARK: - Create

  @MainActor
  @discardableResult
  public func create(gameType: GameType) throws -> Game {
    let game = Game(gameType: gameType)
    try repo.insert(game)
    try repo.save()
    return game
  }

  @MainActor
  @discardableResult
  public func create(variation: GameVariation) throws -> Game {
    let game = Game(gameVariation: variation)
    try repo.insert(game)
    try repo.save()
    return game
  }

  // MARK: - Save / Update

  public func save(_ game: Game) throws {
    try repo.save()
  }

  @MainActor
  public func update(_ game: Game) throws {
    game.lastModified = Date()
    try repo.save()
  }

  // MARK: - Completion & Summary

  @MainActor
  public func complete(_ game: Game, at date: Date = .now) throws {
    guard game.isCompleted == false else { return }
    game.completeGame(at: date)

    let winningTeam: Int = game.score1 >= game.score2 ? 1 : 2
    let pointDifferential = abs(game.score1 - game.score2)
    let duration = game.duration ?? date.timeIntervalSince(game.createdDate)
    let summary = GameSummary(
      gameId: game.id,
      gameTypeId: game.gameType.rawValue,
      completedDate: game.completedDate ?? date,
      winningTeam: winningTeam,
      pointDifferential: pointDifferential,
      duration: duration,
      totalRallies: game.totalRallies
    )

    try summaryRepo.insert(summary)
    try repo.save()
  }

  // MARK: - Delete

  public func delete(_ game: Game) throws {
    try repo.delete(game)
    try repo.save()
  }

  // MARK: - Queries

  @MainActor
  public func recentActive(limit: Int = 20) throws -> [Game] {
    // Fetch all games and filter/sort in memory to avoid KeyPath Sendable issues
    let fd = FetchDescriptor<Game>()
    let allGames = try repo.fetch(fd)
    let activeGames = allGames.filter { !$0.isArchived && !$0.isCompleted }
    let sortedGames = activeGames.sorted { $0.lastModified > $1.lastModified }
    return Array(sortedGames.prefix(limit))
  }

  public func recentCompleted(limit: Int = 50) throws -> [GameSummary] {
    var fd = FetchDescriptor<GameSummary>(
      sortBy: [SortDescriptor(\.completedDate, order: .reverse)]
    )
    fd.fetchLimit = limit
    return try summaryRepo.fetch(fd)
  }

  // MARK: - Summary List API

  /// Load summaries with optional filtering and sorting
  public func loadSummaries(
    limit: Int? = nil,
    offset: Int = 0,
    gameType: GameType? = nil,
    sortBy: SummarySortOption = .dateCompleted,
    ascending: Bool = false
  ) throws -> [GameSummary] {
    var predicate: Predicate<GameSummary> = #Predicate { _ in true }

    // Apply game type filter if specified
    if let gameType = gameType {
      predicate = #Predicate { $0.gameTypeId == gameType.rawValue }
    }

    var sortDescriptors: [SortDescriptor<GameSummary>] = []
    switch sortBy {
    case .dateCompleted:
      sortDescriptors = [SortDescriptor(\.completedDate, order: ascending ? .forward : .reverse)]
    case .duration:
      sortDescriptors = [SortDescriptor(\.duration, order: ascending ? .forward : .reverse)]
    case .pointDifferential:
      sortDescriptors = [SortDescriptor(\.pointDifferential, order: ascending ? .forward : .reverse)]
    }

    var fd = FetchDescriptor<GameSummary>(
      predicate: predicate,
      sortBy: sortDescriptors
    )

    if let limit = limit {
      fd.fetchLimit = limit
      fd.fetchOffset = offset
    }

    return try summaryRepo.fetch(fd)
  }

  /// Hydrate a full Game object from a GameSummary by gameId
  @MainActor
  public func hydrateGame(from summary: GameSummary) throws -> Game? {
    // Capture value to avoid macro/key-path expression mismatches
    let targetId = summary.gameId
    let fd = FetchDescriptor<Game>(
      predicate: #Predicate<Game> { $0.id == targetId }
    )
    return try repo.fetch(fd).first
  }

  /// Hydrate a full Game object directly by game ID
  @MainActor
  public func hydrateGame(id: UUID) throws -> Game? {
    let fd = FetchDescriptor<Game>(
      predicate: #Predicate<Game> { $0.id == id }
    )
    return try repo.fetch(fd).first
  }

  /// Get a game summary by game ID
  public func getSummary(for gameId: UUID) throws -> GameSummary? {
    let fd = FetchDescriptor<GameSummary>(
      predicate: #Predicate<GameSummary> { $0.gameId == gameId }
    )
    return try summaryRepo.fetch(fd).first
  }
}
