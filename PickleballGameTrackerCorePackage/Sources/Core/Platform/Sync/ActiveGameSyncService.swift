//
//  ActiveGameSyncService.swift
//  SharedGameCore
//
//  Cross-device synchronization service using WatchConnectivity
//  Handles real-time game state and history synchronization between iOS and watchOS
//

import Foundation
import SwiftData
import SwiftUI

#if os(iOS) || os(watchOS)
  import WatchConnectivity

  /// Service responsible for synchronizing active game state between iOS and watchOS devices
  /// Uses WatchConnectivity for real-time bi-directional communication
  public actor ActiveGameSyncService: ObservableObject {

    // MARK: - Singleton

    public static let shared = ActiveGameSyncService()

    // MARK: - Published Properties

    @MainActor
    @Published public private(set) var syncState: SyncState = .disconnected

    @MainActor
    @Published public private(set) var lastError: (any Error)? = nil

    @MainActor
    @Published public private(set) var isSyncEnabled: Bool = false

    // MARK: - Private Properties

    private var wcSession: WCSession?
    private var delegate: WatchConnectivityDelegate?

    // Throttling for outbound messages
    private var lastSentAt: Date = .distantPast
    private let throttleInterval: TimeInterval = 0.25  // 4 Hz max

    // Callbacks for receiving data
    private var onActiveGameReceived: (@Sendable (ActiveGameStateDTO) -> Void)?
    private var onHistoryReceived: (@Sendable ([HistoryGameDTO]) -> Void)?
    private var onHistoryRequested: (@Sendable () -> Void)?

    // MARK: - Initialization

    private init() {
      Log.event(.syncStarted, level: .debug, message: "ActiveGameSyncService initialized")
    }

    // MARK: - Configuration

    /// Configure the sync service with callback handlers.
    /// - Parameters:
    ///   - onActiveGameReceived: Called when a new active game state arrives.
    ///   - onHistoryReceived: Called when a batch of completed games is received.
    ///   - onHistoryRequested: Called when the peer requests game history.
    public func configure(
      onActiveGameReceived: @escaping @Sendable (ActiveGameStateDTO) -> Void,
      onHistoryReceived: @escaping @Sendable ([HistoryGameDTO]) -> Void,
      onHistoryRequested: @escaping @Sendable () -> Void
    ) async {
      self.onActiveGameReceived = onActiveGameReceived
      self.onHistoryReceived = onHistoryReceived
      self.onHistoryRequested = onHistoryRequested

      await setupWatchConnectivity()
    }

    /// Enable or disable sync functionality.
    @MainActor
    public func setSyncEnabled(_ enabled: Bool) {
      isSyncEnabled = enabled
      Log.event(.syncStarted, level: .debug, message: enabled ? "Sync enabled" : "Sync disabled")
    }

    // MARK: - Public Methods

    /// Send active game state to the paired device.
    /// - Throws: `SyncError` for connectivity or encoding failures.
    public func sendActiveGameState(_ dto: ActiveGameStateDTO) async throws {
      let syncEnabled = await MainActor.run { isSyncEnabled }
      guard syncEnabled else { return }

      // Throttle messages to prevent spam
      let now = Date()
      guard now.timeIntervalSince(lastSentAt) >= throttleInterval else {
        Log.event(.syncQueued, level: .debug, message: "Throttling active game state message")
        return
      }
      lastSentAt = now

      let message = SyncMessage.activeGameState(dto)
      try await sendMessage(message)

      Log.event(.syncSucceeded, level: .debug, context: .current(gameId: dto.gameId))
    }

    /// Request game history from the paired device.
    /// - Throws: `SyncError` for connectivity failures.
    public func requestGameHistory() async throws {
      let syncEnabled = await MainActor.run { isSyncEnabled }
      guard syncEnabled else { return }

      let message = SyncMessage.historyRequest
      try await sendMessage(message)

      Log.event(.syncStarted, level: .debug, message: "Requested game history")
    }

    /// Send a batch of completed games to the paired device.
    /// - Throws: `SyncError` for connectivity or encoding failures.
    public func sendGameHistory(_ games: [HistoryGameDTO]) async throws {
      let syncEnabled = await MainActor.run { isSyncEnabled }
      guard syncEnabled else { return }

      let message = SyncMessage.historyBatch(games)
      try await sendMessage(message)

      Log.event(
        .syncSucceeded, level: .debug, message: "Sent game history batch",
        metadata: ["count": String(games.count)])
    }

    // MARK: - Private Methods

    private func setupWatchConnectivity() async {
      guard WCSession.isSupported() else {
        await MainActor.run {
          syncState = .error
          lastError = SyncError.watchConnectivityNotSupported
        }
        return
      }

      await MainActor.run {
        syncState = .connecting
      }

      let session = WCSession.default
      let delegate = WatchConnectivityDelegate(syncService: self)

      wcSession = session
      self.delegate = delegate

      session.delegate = delegate
      session.activate()

      Log.event(.syncStarted, level: .debug, message: "WC session activated")
    }

    private func sendMessage(_ message: SyncMessage) async throws {
      guard let session = wcSession,
        session.activationState == .activated
      else {
        throw SyncError.sessionNotAvailable
      }

      #if os(iOS)
        guard session.isWatchAppInstalled else {
          throw SyncError.deviceNotReachable
        }
      #endif

      let encoder = JSONEncoder()
      let data = try encoder.encode(message)

      if session.isReachable {
        // Send immediately if reachable
        try await withCheckedThrowingContinuation {
          (continuation: CheckedContinuation<Void, Error>) in
          session.sendMessageData(
            data,
            replyHandler: { _ in
              continuation.resume()
            },
            errorHandler: { error in
              continuation.resume(throwing: error)
            })
        }
      } else {
        // Queue for later delivery
        session.transferUserInfo(["message": data])
      }
    }

    // MARK: - Message Processing

    nonisolated func processReceivedMessage(_ data: Data) {
      Task {
        do {
          let decoder = JSONDecoder()
          let message = try decoder.decode(SyncMessage.self, from: data)
          await handleMessage(message)
        } catch {
          await MainActor.run {
            lastError = error
          }
          Log.error(error, event: .syncFailed)
        }
      }
    }

    private func handleMessage(_ message: SyncMessage) async {
      switch message {
      case .activeGameState(let dto):
        onActiveGameReceived?(dto)
        Log.event(
          .syncSucceeded, level: .debug, context: .current(gameId: dto.gameId),
          metadata: ["event": "activeGameState"])

      case .historyRequest:
        onHistoryRequested?()
        Log.event(.syncSucceeded, level: .debug, message: "Received history request")

      case .historyBatch(let games):
        onHistoryReceived?(games)
        Log.event(
          .syncSucceeded, level: .debug, message: "Received history batch",
          metadata: ["count": String(games.count)])

      case .ack:
        Log.event(.syncSucceeded, level: .debug, message: "Received acknowledgment")
      }
    }

    // MARK: - Session State Updates

    nonisolated func updateSyncState(_ newState: SyncState) {
      Task { @MainActor [newState] in
        syncState = newState
      }
    }

    nonisolated func updateLastError(_ error: (any Error)?) {
      Task { @MainActor in
        lastError = error
      }
    }
  }

  // MARK: - Sync State

  extension ActiveGameSyncService {
    public enum SyncState: String, CaseIterable, Sendable {
      case disconnected = "disconnected"
      case connecting = "connecting"
      case connected = "connected"
      case error = "error"

      public var displayName: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting"
        case .connected: return "Connected"
        case .error: return "Error"
        }
      }

      public var iconName: String {
        switch self {
        case .disconnected: return "circle"
        case .connecting: return "circle.dotted"
        case .connected: return "circle.fill"
        case .error: return "exclamationmark.circle"
        }
      }
    }
  }

  // MARK: - WatchConnectivity Delegate

  private class WatchConnectivityDelegate: NSObject, WCSessionDelegate {
    private weak var syncService: ActiveGameSyncService?

    init(syncService: ActiveGameSyncService) {
      self.syncService = syncService
      super.init()
    }

    func session(
      _ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState,
      error: (any Error)?
    ) {
      let newState: ActiveGameSyncService.SyncState

      switch activationState {
      case .activated:
        newState = Self.computeConnectivityState(for: session)
      case .inactive:
        newState = .disconnected
      case .notActivated:
        newState = .error
      @unknown default:
        newState = .error
      }

      syncService?.updateSyncState(newState)
      syncService?.updateLastError(error)

      Log.event(
        .syncStarted, level: .debug, message: "WC Session activated",
        metadata: [
          "state": String(activationState.rawValue), "reachable": String(session.isReachable),
        ])
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
      let newState = Self.computeConnectivityState(for: session)
      syncService?.updateSyncState(newState)

      Log.event(
        .syncStarted, level: .debug, message: "WC Reachability changed",
        metadata: ["reachable": String(session.isReachable)])
    }

    func session(
      _ session: WCSession, didReceiveMessageData messageData: Data,
      replyHandler: @escaping (Data) -> Void
    ) {
      syncService?.processReceivedMessage(messageData)

      // Send acknowledgment
      let ack = SyncMessage.ack
      if let ackData = try? JSONEncoder().encode(ack) {
        replyHandler(ackData)
      }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
      if let messageData = userInfo["message"] as? Data {
        syncService?.processReceivedMessage(messageData)
      }
    }

    #if os(iOS)
      func sessionDidBecomeInactive(_ session: WCSession) {
        syncService?.updateSyncState(.disconnected)
        Log.event(.syncFailed, level: .debug, message: "WC Session became inactive")
      }

      func sessionDidDeactivate(_ session: WCSession) {
        syncService?.updateSyncState(.disconnected)
        // After deactivation (e.g., switching watches), you must activate again
        session.activate()
        Log.event(.syncFailed, level: .debug, message: "WC Session deactivated")
      }

      func sessionWatchStateDidChange(_ session: WCSession) {
        // Update state when pairing/installation changes and ensure activation
        let newState = Self.computeConnectivityState(for: session)
        syncService?.updateSyncState(newState)
        if session.activationState != .activated {
          session.activate()
        }
        Log.event(
          .syncStarted,
          level: .debug,
          message: "WC Watch state changed",
          metadata: [
            "paired": String(session.isPaired),
            "installed": String(session.isWatchAppInstalled),
          ]
        )
      }
    #endif
  }

  // MARK: - Connectivity State Helpers
  extension WatchConnectivityDelegate {
    fileprivate static func computeConnectivityState(for session: WCSession)
      -> ActiveGameSyncService.SyncState
    {
      // If immediately reachable, we are definitely connected
      if session.isReachable { return .connected }
      #if os(iOS)
        // On iOS, treat paired + installed as connected (even if not currently reachable)
        if session.isPaired && session.isWatchAppInstalled { return .connected }
        return .disconnected
      #else
        // On watchOS, treat presence of companion app as connected
        if session.isCompanionAppInstalled { return .connected }
        return .disconnected
      #endif
    }
  }

// MARK: - Sync Errors (defined in SyncTypes.swift)

#else

  // MARK: - Stub Implementation for Other Platforms

  @MainActor
  public class ActiveGameSyncService: ObservableObject {
    public static let shared = ActiveGameSyncService()

    public enum SyncState: String, CaseIterable, Sendable {
      case disconnected = "disconnected"
      case connecting = "connecting"
      case connected = "connected"
      case error = "error"

      public var displayName: String { "Not Available" }
      public var iconName: String { "circle.slash" }
    }

    @MainActor
    public private(set) var syncState: SyncState = .disconnected

    @MainActor
    public private(set) var lastError: (any Error)? = nil

    @MainActor
    public private(set) var isSyncEnabled: Bool = false

    private init() {}

    public func configure(
      onActiveGameReceived: @escaping @Sendable (ActiveGameStateDTO) -> Void,
      onHistoryReceived: @escaping @Sendable ([HistoryGameDTO]) -> Void,
      onHistoryRequested: @escaping @Sendable () -> Void
    ) async {}

    @MainActor
    public func setSyncEnabled(_ enabled: Bool) {
      self.isSyncEnabled = enabled
    }

    public func sendActiveGameState(_ dto: ActiveGameStateDTO) async throws {}
    public func requestGameHistory() async throws {}
    public func sendGameHistory(_ games: [HistoryGameDTO]) async throws {}
  }

#endif
