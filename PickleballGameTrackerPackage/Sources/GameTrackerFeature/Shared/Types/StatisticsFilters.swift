import Foundation

/// Filters used to scope statistic computations across views.
public struct StatisticsFilters: Hashable, Sendable {
  public var gameId: String?
  public var gameTypeId: String?

  public init(gameId: String?, gameTypeId: String?) {
    self.gameId = gameId
    self.gameTypeId = gameTypeId
  }
}
