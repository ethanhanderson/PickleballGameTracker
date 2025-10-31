//
//  LiveSessionStore.swift
//  GameTrackerCore
//

import Foundation

public struct LiveSessionState: Codable, Sendable, Equatable {
  public let gameId: UUID
  public let elapsedTime: TimeInterval
  public let isTimerRunning: Bool
  public let lastModified: Date

  public init(gameId: UUID, elapsedTime: TimeInterval, isTimerRunning: Bool, lastModified: Date = Date()) {
    self.gameId = gameId
    self.elapsedTime = elapsedTime
    self.isTimerRunning = isTimerRunning
    self.lastModified = lastModified
  }
}

@MainActor
public final class LiveSessionStore: Sendable {
  public static let shared = LiveSessionStore()

  private let userDefaults: UserDefaults
  private let key: String

  public init(userDefaults: UserDefaults = .standard, key: String = "com.ehandev.picklescore.liveSession") {
    self.userDefaults = userDefaults
    self.key = key
  }

  public func save(_ state: LiveSessionState) {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    if let data = try? encoder.encode(state) {
      userDefaults.set(data, forKey: key)
    }
  }

  public func load() -> LiveSessionState? {
    guard let data = userDefaults.data(forKey: key) else { return nil }
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try? decoder.decode(LiveSessionState.self, from: data)
  }

  public func clear() {
    userDefaults.removeObject(forKey: key)
  }
}


