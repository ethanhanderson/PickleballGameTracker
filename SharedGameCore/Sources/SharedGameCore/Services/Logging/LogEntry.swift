import Foundation

public struct LogEntry: Sendable, Codable, Hashable {
  public let id: UUID
  public let timestamp: Date
  public let level: LogLevel
  public let event: LogEvent
  public let message: String?
  public let context: LogContext
  public let metadata: [String: String]?

  public init(
    id: UUID = UUID(),
    timestamp: Date = Date(),
    level: LogLevel,
    event: LogEvent,
    message: String? = nil,
    context: LogContext,
    metadata: [String: String]? = nil
  ) {
    self.id = id
    self.timestamp = timestamp
    self.level = level
    self.event = event
    self.message = message
    self.context = context
    self.metadata = metadata
  }
}


