import Observation
import WatchKit

@MainActor
@Observable
public final class ExtendedRuntimeManager: NSObject {
  public private(set) var isRunning: Bool = false
  public private(set) var lastInvalidationReason: WKExtendedRuntimeSessionInvalidationReason?
  public private(set) var lastError: Error?

  private var session: WKExtendedRuntimeSession?

  public func startFrontmostSessionIfNeeded() {
    if let session, session.state == .running || session.state == .scheduled {
      return
    }

    let newSession = WKExtendedRuntimeSession()
    newSession.delegate = self
    session = newSession
    newSession.start()
  }

  public func stopSessionIfNeeded() {
    guard let session else { return }
    session.invalidate()
    self.session = nil
    isRunning = false
  }
}

extension ExtendedRuntimeManager: WKExtendedRuntimeSessionDelegate {
  public nonisolated func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
    Task { @MainActor [weak self] in
      self?.isRunning = true
      self?.lastInvalidationReason = nil
      self?.lastError = nil
    }
  }

  public nonisolated func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
    Task { @MainActor [weak self] in
      self?.isRunning = false
    }
  }

  public nonisolated func extendedRuntimeSession(
    _ extendedRuntimeSession: WKExtendedRuntimeSession,
    didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
    error: (any Error)?
  ) {
    let sessionIdentifier = ObjectIdentifier(extendedRuntimeSession)
    Task { @MainActor [weak self] in
      self?.isRunning = false
      self?.lastInvalidationReason = reason
      self?.lastError = error
      if let session = self?.session,
         ObjectIdentifier(session) == sessionIdentifier {
        self?.session = nil
      }
    }
  }
}

