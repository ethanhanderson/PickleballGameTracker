import Foundation

public protocol LogSink: Sendable {
  func write(_ entry: LogEntry)
}


