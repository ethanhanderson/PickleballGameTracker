import Foundation

public struct LogContext: Sendable, Codable, Hashable {
  public var gameId: UUID?
  public var gameSessionId: UUID?
  public var userId: UUID?
  public var deviceId: String
  public var platform: String
  public var appVersion: String
  public var build: String
  public var osVersion: String
  public var locale: String

  public init(
    gameId: UUID? = nil,
    gameSessionId: UUID? = nil,
    userId: UUID? = nil,
    deviceId: String,
    platform: String,
    appVersion: String,
    build: String,
    osVersion: String,
    locale: String
  ) {
    self.gameId = gameId
    self.gameSessionId = gameSessionId
    self.userId = userId
    self.deviceId = deviceId
    self.platform = platform
    self.appVersion = appVersion
    self.build = build
    self.osVersion = osVersion
    self.locale = locale
  }
}

public extension LogContext {
  static func current(gameId: UUID? = nil, gameSessionId: UUID? = nil, userId: UUID? = nil) -> LogContext {
    let deviceId = (UUID().uuidString) // ephemeral; replace with persisted identifier if needed later
    #if os(iOS)
    let platform = "iOS"
    #elseif os(watchOS)
    let platform = "watchOS"
    #else
    let platform = "unknown"
    #endif
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
    let locale = Locale.current.identifier
    return LogContext(
      gameId: gameId,
      gameSessionId: gameSessionId,
      userId: userId,
      deviceId: deviceId,
      platform: platform,
      appVersion: appVersion,
      build: build,
      osVersion: osVersion,
      locale: locale
    )
  }
}


