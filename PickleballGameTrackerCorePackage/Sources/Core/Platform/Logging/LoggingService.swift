import Foundation

public actor LoggingService {
  public static let shared = LoggingService()

  private var sinks: [any LogSink] = []
  private var minimumLevel: LogLevel = {
    #if DEBUG
    return .debug
    #else
    return .info
    #endif
  }()

  public init() {}

  public func configure(sinks: [any LogSink], minimumLevel: LogLevel? = nil) {
    self.sinks = sinks
    if let level = minimumLevel { self.minimumLevel = level }
  }

  public func log(
    level: LogLevel,
    event: LogEvent,
    message: String? = nil,
    context: LogContext = .current(),
    metadata: [String: String]? = nil
  ) {
    guard level.rawValue >= minimumLevel.rawValue else { return }
    let entry = LogEntry(level: level, event: event, message: message, context: context, metadata: metadata)
    for sink in sinks { sink.write(entry) }
  }
}

public enum Log {
  public static func event(
    _ event: LogEvent,
    level: LogLevel = {
      #if DEBUG
      .debug
      #else
      .info
      #endif
    }(),
    message: String? = nil,
    context: LogContext = .current(),
    metadata: [String: String]? = nil
  ) {
    Task { await LoggingService.shared.log(level: level, event: event, message: message, context: context, metadata: metadata) }
  }

  public static func error(
    _ error: any Error,
    event: LogEvent,
    context: LogContext = .current(),
    metadata: [String: String]? = nil
  ) {
    var md = metadata ?? [:]
    md["error"] = String(describing: error)
    Task { await LoggingService.shared.log(level: .error, event: event, message: nil, context: context, metadata: md) }
  }
}


