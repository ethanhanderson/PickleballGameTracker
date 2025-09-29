import GameTrackerCore
import Foundation

actor GameSearchHistoryStore {
  private let searchHistoryKey = "GameSearchHistory"

  nonisolated static func updatedHistory(afterAdding gameType: GameType, to current: [GameType])
    -> [GameType]
  {
    var history = current
    history.removeAll { $0 == gameType }
    history.insert(gameType, at: 0)
    if history.count > 10 {
      history = Array(history.prefix(10))
    }
    return history
  }

  nonisolated static func updatedHistory(afterDeleting gameType: GameType, from current: [GameType])
    -> [GameType]
  {
    var history = current
    history.removeAll { $0 == gameType }
    return history
  }

  func load() -> [GameType] {
    let rawValues = UserDefaults.standard.stringArray(forKey: searchHistoryKey) ?? []
    return rawValues.compactMap { GameType(rawValue: $0) }
  }

  func save(_ history: [GameType]) {
    let rawValues = history.map { $0.rawValue }
    UserDefaults.standard.set(rawValues, forKey: searchHistoryKey)
  }
}
