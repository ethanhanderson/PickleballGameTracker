import Foundation

public enum LogCategory: String, Sendable, Codable, CaseIterable {
  case game
  case storage
  case sync
  case ui
  case app
  case watch
  case error
}

public struct LogEvent: Sendable, Codable, Hashable {
  public let name: String
  public let category: LogCategory

  public init(_ name: String, category: LogCategory) {
    self.name = name
    self.category = category
  }
}

public extension LogEvent {
  // Game
  static let gameCreated = LogEvent("gameCreated", category: .game)
  static let scoreIncrement = LogEvent("scoreIncrement", category: .game)
  static let scoreDecrement = LogEvent("scoreDecrement", category: .game)
  static let serverSwitched = LogEvent("serverSwitched", category: .game)
  static let sidesSwitched = LogEvent("sidesSwitched", category: .game)
  static let gameCompleted = LogEvent("gameCompleted", category: .game)
  static let gameResumed = LogEvent("gameResumed", category: .game)
  static let gamePaused = LogEvent("gamePaused", category: .game)

  // Storage
  static let saveStarted = LogEvent("saveStarted", category: .storage)
  static let saveSucceeded = LogEvent("saveSucceeded", category: .storage)
  static let saveFailed = LogEvent("saveFailed", category: .storage)
  static let loadStarted = LogEvent("loadStarted", category: .storage)
  static let loadSucceeded = LogEvent("loadSucceeded", category: .storage)
  static let loadFailed = LogEvent("loadFailed", category: .storage)
  static let deleteRequested = LogEvent("deleteRequested", category: .storage)
  static let deleteSucceeded = LogEvent("deleteSucceeded", category: .storage)
  static let deleteFailed = LogEvent("deleteFailed", category: .storage)

  // Sync
  static let syncQueued = LogEvent("syncQueued", category: .sync)
  static let syncStarted = LogEvent("syncStarted", category: .sync)
  static let syncSucceeded = LogEvent("syncSucceeded", category: .sync)
  static let syncFailed = LogEvent("syncFailed", category: .sync)
  static let realtimeEvent = LogEvent("realtimeEvent", category: .sync)

  // UI
  static let viewAppear = LogEvent("viewAppear", category: .ui)
  static let viewDisappear = LogEvent("viewDisappear", category: .ui)
  static let actionTapped = LogEvent("actionTapped", category: .ui)

  // App
  static let appLaunch = LogEvent("appLaunch", category: .app)
  static let appTerminate = LogEvent("appTerminate", category: .app)
  static let settingsChanged = LogEvent("settingsChanged", category: .app)
}


