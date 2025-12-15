import Foundation

public enum SyncTransportError: Error, Sendable {
  case notSupported
  case companionUnavailable
  case activationBackpressure
  case reachabilityUnavailable
  case envelopeSessionMismatch
}

public enum SyncInvariantError: Error, Sendable {
  case mismatchedGameContext(expected: UUID, got: UUID)
}


