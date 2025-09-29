import Foundation

public enum CoreError: Error, LocalizedError, Sendable {
  case storage(StorageError)
  case invalidArgument(String)
  case notFound(String)
  case operationFailed(String)

  public var errorDescription: String? {
    switch self {
    case .storage(let underlying):
      return underlying.errorDescription ?? "Storage error"
    case .invalidArgument(let message):
      return "Invalid argument: \(message)"
    case .notFound(let message):
      return "Not found: \(message)"
    case .operationFailed(let message):
      return "Operation failed: \(message)"
    }
  }
}


