import Foundation

public enum LogLevel: Int, Sendable, Codable, CaseIterable {
  case trace = 0
  case debug = 1
  case info = 2
  case warn = 3
  case error = 4
  case critical = 5
}

extension LogLevel: CustomStringConvertible {
  public var description: String {
    switch self {
    case .trace: return "trace"
    case .debug: return "debug"
    case .info: return "info"
    case .warn: return "warn"
    case .error: return "error"
    case .critical: return "critical"
    }
  }
}
