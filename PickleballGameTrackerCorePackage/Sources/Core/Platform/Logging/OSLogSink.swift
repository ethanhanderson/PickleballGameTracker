import Foundation
import OSLog

public final class OSLogSink: LogSink {
  private let subsystem = "com.ehandev.picklescore"
  private let loggers: [LogCategory: Logger]

  public init() {
    var dict: [LogCategory: Logger] = [:]
    for category in LogCategory.allCases {
      dict[category] = Logger(subsystem: subsystem, category: category.rawValue)
    }
    self.loggers = dict
  }

  public func write(_ entry: LogEntry) {
    let logger = loggers[entry.event.category] ?? Logger(subsystem: subsystem, category: "app")
    let message = formatted(entry)
    switch entry.level {
    case .trace, .debug:
      logger.debug("\(message, privacy: .public)")
    case .info:
      logger.info("\(message, privacy: .public)")
    case .warn:
      logger.log("\(message, privacy: .public)")
    case .error:
      logger.error("\(message, privacy: .public)")
    case .critical:
      logger.fault("\(message, privacy: .public)")
    }
  }

  private func formatted(_ entry: LogEntry) -> String {
    var parts: [String] = []
    parts.append(entry.event.name)
    parts.append("lvl=\(entry.level.description)")
    if let gameId = entry.context.gameId {
      parts.append("game=\(gameId.uuidString.prefix(8))")
    }
    if let session = entry.context.gameSessionId {
      parts.append("session=\(session.uuidString.prefix(8))")
    }
    if let msg = entry.message, !msg.isEmpty { parts.append(msg) }
    if let metadata = entry.metadata, !metadata.isEmpty {
      for (k, v) in metadata { parts.append("\(k)=\(v)") }
    }
    return parts.joined(separator: " ")
  }
}


