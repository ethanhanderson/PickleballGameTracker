//
//  WatchConnectivityTransport.swift
//  GameTrackerFeature (iOS)
//

import Foundation
import GameTrackerCore

#if canImport(WatchConnectivity)
import WatchConnectivity

@MainActor
public final class WatchConnectivityTransport: NSObject, SyncService, WCSessionDelegate {
  private let session: WCSession = .default
  private var sessionId: UUID = UUID()
  private var isActivated: Bool = false
  private var pendingSends: [(data: Data, preferContext: Bool)] = []

  public var onReceiveLiveSnapshot: (@Sendable (LiveGameSnapshotDTO) -> Void)?
  public var onReceiveLiveDelta: (@Sendable (LiveGameDeltaDTO) -> Void)?
  public var onReceiveRosterSnapshot: (@Sendable (RosterSnapshotDTO) -> Void)?
  public var onReceiveHistorySummaries: (@Sendable (HistorySummariesDTO) -> Void)?
  public var onReceiveStartConfiguration: (@Sendable (GameStartConfiguration) -> Void)?
  public var onReceiveLiveStatusRequest: (@Sendable () -> Void)?
  public var onReachabilityChanged: (@Sendable (SyncReachability) -> Void)?
  public var onReceiveRosterRequest: (@Sendable () -> Void)?
  public var onReceiveHistoryRequest: (@Sendable () -> Void)?

  public var currentReachability: SyncReachability {
    guard WCSession.isSupported() else { return .unavailable }
    return session.isReachable ? .reachable : .connecting
  }

  public override init() {
    super.init()
  }

  // MARK: Lifecycle
  public func start() async {
    guard WCSession.isSupported() else { return }
    session.delegate = self
    session.activate()
    // Reachability will be reported upon activation completion
    Log.event(
      .loadStarted,
      level: .info,
      message: "wc.start",
      metadata: ["platform": "iOS"]
    )
  }

  public func stop() async {
    // WCSession has no explicit stop; rotate sessionId to partition streams
    sessionId = UUID()
  }

  // MARK: Outbound
  public func sendLiveSnapshot(_ snapshot: LiveGameSnapshotDTO) async throws {
    Log.event(
      .saveStarted,
      level: .debug,
      message: "wc.send.liveSnapshot",
      metadata: ["preferContext": "true", "reachable": String(session.isReachable)]
    )
    try await send(envelopeFor: snapshot, type: .liveSnapshot, preferContext: true)
  }

  public func sendLiveDelta(_ delta: LiveGameDeltaDTO) async throws {
    Log.event(
      .saveStarted,
      level: .debug,
      message: "wc.send.liveDelta",
      metadata: ["preferContext": "false", "reachable": String(session.isReachable)]
    )
    try await send(envelopeFor: delta, type: .liveDelta, preferContext: false)
  }

  public func sendRosterSnapshot(_ roster: RosterSnapshotDTO) async throws {
    Log.event(
      .saveStarted,
      level: .debug,
      message: "wc.send.rosterSnapshot",
      metadata: ["preferContext": "true", "reachable": String(session.isReachable)]
    )
    try await send(envelopeFor: roster, type: .rosterSnapshot, preferContext: true)
  }

  public func sendHistorySummaries(_ summaries: HistorySummariesDTO) async throws {
    Log.event(
      .saveStarted,
      level: .debug,
      message: "wc.send.historySummaries",
      metadata: ["preferContext": "true", "reachable": String(session.isReachable)]
    )
    try await send(envelopeFor: summaries, type: .historySummaries, preferContext: true)
  }

  public func sendStartConfiguration(_ config: GameStartConfiguration) async throws {
    Log.event(
      .saveStarted,
      level: .debug,
      message: "wc.send.startConfig",
      metadata: ["preferContext": "true", "reachable": String(session.isReachable)]
    )
    try await send(envelopeFor: config, type: .startConfig, preferContext: true)
  }

  public func requestRosterSnapshot() async throws {
    Log.event(
      .loadStarted,
      level: .debug,
      message: "wc.send.rosterRequest",
      metadata: ["reachable": String(session.isReachable)]
    )
    try await send(typeOnly: .rosterRequest)
  }

  public func requestHistorySummaries() async throws {
    Log.event(
      .loadStarted,
      level: .debug,
      message: "wc.send.historyRequest",
      metadata: ["reachable": String(session.isReachable)]
    )
    try await send(typeOnly: .historyRequest)
  }

  public func requestLiveStatus() async throws {
    Log.event(
      .loadStarted,
      level: .debug,
      message: "wc.send.liveStatusRequest",
      metadata: ["reachable": String(session.isReachable)]
    )
    try await send(typeOnly: .liveStatusRequest)
  }

  private func send<T: Codable>(envelopeFor value: T, type: SyncMessageType, preferContext: Bool) async throws {
    let data = try MessageCodec.encode(value, type: type, sessionId: sessionId)
    if !isActivated {
      pendingSends.append((data, preferContext))
      Log.event(
        .saveStarted,
        level: .debug,
        message: "wc.queue",
        metadata: ["type": type.rawValue, "preferContext": String(preferContext)]
      )
      return
    }
    if preferContext {
      do {
        try session.updateApplicationContext(["data": data])
        Log.event(
          .saveSucceeded,
          level: .debug,
          message: "wc.contextUpdated",
          metadata: ["type": type.rawValue]
        )
      } catch {
        // Fallback to message if context update fails
        try await sendData(data)
      }
    } else {
      try await sendData(data)
    }
  }

  private func send(typeOnly: SyncMessageType) async throws {
    let data = try MessageCodec.encode(SyncEnvelope(type: typeOnly, sessionId: sessionId, payload: Data()), type: typeOnly, sessionId: sessionId)
    if !isActivated {
      pendingSends.append((data, false))
      Log.event(
        .saveStarted,
        level: .debug,
        message: "wc.queue",
        metadata: ["type": typeOnly.rawValue, "preferContext": "false"]
      )
      return
    }
    try await sendData(data)
  }

  private func sendData(_ data: Data) async throws {
    if session.isReachable {
      session.sendMessageData(data, replyHandler: nil, errorHandler: nil)
      Log.event(
        .saveSucceeded,
        level: .debug,
        message: "wc.sendMessageData",
        metadata: nil
      )
    } else {
      session.transferUserInfo(["data": data])
      Log.event(
        .saveSucceeded,
        level: .debug,
        message: "wc.transferUserInfo",
        metadata: nil
      )
    }
  }

  // MARK: Inbound
  public nonisolated func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
    Task { @MainActor in
      self.handleInbound(data: messageData)
    }
  }

  public nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
    if let data = applicationContext["data"] as? Data {
      Task { @MainActor in
        self.handleInbound(data: data)
      }
    }
  }

  public nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
    if let data = userInfo["data"] as? Data {
      Task { @MainActor in
        self.handleInbound(data: data)
      }
    }
  }

  private func handleInbound(data: Data) {
    guard let (type, anyValue) = try? MessageCodec.decode(data) else { return }
    Log.event(
      .loadSucceeded,
      level: .debug,
      message: "wc.received",
      metadata: ["type": type.rawValue, "platform": "iOS"]
    )
    switch type {
    case .liveStatusRequest:
      onReceiveLiveStatusRequest?()
    case .startConfig:
      if let v = anyValue as? GameStartConfiguration { onReceiveStartConfiguration?(v) }
    case .liveSnapshot:
      if let v = anyValue as? LiveGameSnapshotDTO { onReceiveLiveSnapshot?(v) }
    case .liveDelta:
      if let v = anyValue as? LiveGameDeltaDTO { onReceiveLiveDelta?(v) }
    case .rosterSnapshot:
      if let v = anyValue as? RosterSnapshotDTO { onReceiveRosterSnapshot?(v) }
    case .historySummaries:
      if let v = anyValue as? HistorySummariesDTO { onReceiveHistorySummaries?(v) }
    case .rosterRequest:
      onReceiveRosterRequest?()
    case .historyRequest:
      onReceiveHistoryRequest?()
    case .ack, .error:
      break
    }
  }

  // MARK: WCSessionDelegate
  public nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    Task { @MainActor in
      self.isActivated = (activationState == .activated)
      // Flush any queued messages after activation
      if self.isActivated, !self.pendingSends.isEmpty {
        let queued = self.pendingSends
        self.pendingSends.removeAll()
        for item in queued {
          if item.preferContext {
            do { try self.session.updateApplicationContext(["data": item.data]) } catch { try? await self.sendData(item.data) }
          } else {
            try? await self.sendData(item.data)
          }
        }
      }
      self.onReachabilityChanged?(self.currentReachability)
      Log.event(
        .loadSucceeded,
        level: .info,
        message: "wc.activated",
        metadata: [
          "state": String(describing: activationState.rawValue),
          "error": error?.localizedDescription ?? "nil",
          "platform": "iOS"
        ]
      )
    }
  }

  public nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
    Task { @MainActor in
      self.onReachabilityChanged?(self.currentReachability)
      Log.event(
        .loadSucceeded,
        level: .debug,
        message: "wc.reachability",
        metadata: ["reachable": String(self.session.isReachable), "platform": "iOS"]
      )
    }
  }

  // iOS-specific required delegate stubs
  public nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
  public nonisolated func sessionDidDeactivate(_ session: WCSession) {
    session.activate()
  }
}

#endif


