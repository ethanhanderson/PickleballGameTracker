import Foundation

public final class ConsoleSink: LogSink {
  public init() {}

  public func write(_ entry: LogEntry) {
    let ts = ISO8601DateFormatter().string(from: entry.timestamp)
    var line = "[\(ts)] \(entry.event.category.rawValue.uppercased())/\(entry.level.description) \(entry.event.name)"
    if let gameId = entry.context.gameId {
      line += " game=\(gameId.uuidString.prefix(8))"
    }
    if let session = entry.context.gameSessionId {
      line += " session=\(session.uuidString.prefix(8))"
    }
    if let message = entry.message { line += " msg=\(message)" }
    if let metadata = entry.metadata, !metadata.isEmpty {
      for (k, v) in metadata { line += " \(k)=\(v)" }
    }
    print(line)
  }
}


