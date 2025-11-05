import Foundation
import GameTrackerCore

#if canImport(WatchConnectivity)
import WatchConnectivity
import UserNotifications

@MainActor
public final class WatchConnectivityTransport: NSObject, SyncService, WCSessionDelegate {
  private let session: WCSession = .default
  private var sessionId: UUID = UUID()
  private var isActivated: Bool = false
  private var pendingSends: [(data: Data, preferContext: Bool)] = []
  private var retryTask: Task<Void, Never>? = nil
  private var lastReachable: Bool? = nil
  private let defaults: UserDefaults = .standard
  private let activationFailuresKey = "wc.activationFailures.ios"
  private let lostConnectionsKey = "wc.lostConnections.ios"
  private let rejectionsKey = "wc.rejections.ios"
  private let maxActivationFailures = 10
  private let maxLostConnections = 10
  private let maxRejections = 10

  public var onReceiveLiveSnapshot: (@Sendable (LiveGameSnapshotDTO) -> Void)?
  public var onReceiveLiveDelta: (@Sendable (LiveGameDeltaDTO) -> Void)?
  public var onReceiveRosterSnapshot: (@Sendable (RosterSnapshotDTO) -> Void)?
  public var onReceiveHistorySummaries: (@Sendable (HistorySummariesDTO) -> Void)?
  public var onReceiveStartConfiguration: (@Sendable (GameStartConfiguration) -> Void)?
  public var onReceiveStartRequest: (@Sendable (StartGameRequestDTO) -> Void)?
  public var onReceiveLiveStatusRequest: (@Sendable () -> Void)?
  public var onReachabilityChanged: (@Sendable (SyncReachability) -> Void)?
  public var onReceiveRosterRequest: (@Sendable () -> Void)?
  public var onReceiveHistoryRequest: (@Sendable () -> Void)?
  public var onReceiveRosterInventory: (@Sendable (RosterInventoryDTO) -> Void)?
  public var onReceiveRosterUpsert: (@Sendable (RosterUpsertDTO) -> Void)?
  public var onReceiveRosterPrune: (@Sendable (RosterPruneDTO) -> Void)?

  public var currentReachability: SyncReachability {
    guard WCSession.isSupported() else { return .unavailable }
    // On iOS, also factor in pairing and watch app install state
    if !session.isPaired || !session.isWatchAppInstalled { return .unavailable }
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
    // On iOS, the activation delegate may not fire; ensure we eventually mark as activated
    await ensureActivationReady()
    startAutoConnectRetriesIfNeeded()
  }

  public func stop() async {
    // WCSession has no explicit stop; rotate sessionId to partition streams
    sessionId = UUID()
    retryTask?.cancel()
    retryTask = nil
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

  public func sendStartRequest(_ request: StartGameRequestDTO) async throws {
    Log.event(
      .saveStarted,
      level: .debug,
      message: "wc.send.startRequest",
      metadata: ["preferContext": "true", "reachable": String(session.isReachable)]
    )
    try await send(envelopeFor: request, type: .startRequest, preferContext: true)
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

  public func sendRosterInventory(_ inventory: RosterInventoryDTO) async throws {
    Log.event(
      .saveStarted,
      level: .debug,
      message: "wc.send.rosterInventory",
      metadata: ["preferContext": "true", "reachable": String(session.isReachable)]
    )
    try await send(envelopeFor: inventory, type: .rosterInventory, preferContext: true)
  }

  public func sendRosterUpsert(_ upsert: RosterUpsertDTO) async throws {
    Log.event(
      .saveStarted,
      level: .debug,
      message: "wc.send.rosterUpsert",
      metadata: ["preferContext": "true", "reachable": String(session.isReachable)]
    )
    try await send(envelopeFor: upsert, type: .rosterUpsert, preferContext: true)
  }

  public func sendRosterPrune(_ prune: RosterPruneDTO) async throws {
    Log.event(
      .saveStarted,
      level: .debug,
      message: "wc.send.rosterPrune",
      metadata: ["preferContext": "true", "reachable": String(session.isReachable)]
    )
    try await send(envelopeFor: prune, type: .rosterPrune, preferContext: true)
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
    // Encode a single envelope directly for type-only messages (no nested envelope)
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let envelope = SyncEnvelope(type: typeOnly, sessionId: sessionId, payload: Data())
    let data = try encoder.encode(envelope)
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
    // Prefer interactive messaging for small payloads when reachable; otherwise use background transfer
    let interactiveLimit = 60 * 1024
    if data.count > interactiveLimit {
      session.transferUserInfo(["data": data])
      Log.event(
        .saveSucceeded,
        level: .debug,
        message: "wc.transferUserInfo.large",
        metadata: ["bytes": String(data.count)]
      )
      return
    }
    if session.isReachable {
      session.sendMessageData(
        data,
        replyHandler: nil,
        errorHandler: makeSendErrorHandler(for: data)
      )
      Log.event(
        .saveSucceeded,
        level: .debug,
        message: "wc.sendMessageData",
        metadata: nil
      )
    } else {
      // When not reachable, push latest state via application context for faster delivery, and also queue background transfer
      _ = try? session.updateApplicationContext(["data": data])
      session.transferUserInfo(["data": data])
      Log.event(
        .saveSucceeded,
        level: .debug,
        message: "wc.contextAndTransfer",
        metadata: nil
      )
    }
  }

  // Create a nonisolated error handler so WCSession can invoke it on its own queue
  nonisolated private func makeSendErrorHandler(for data: Data) -> @Sendable (Error) -> Void {
    { _ in
      Task { @MainActor in
        let sess = WCSession.default
        _ = try? sess.updateApplicationContext(["data": data])
        sess.transferUserInfo(["data": data])
      }
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
    case .startRequest:
      if let v = anyValue as? StartGameRequestDTO {
        // Always schedule a notification in case app is in background or terminated
        // AppNavigationView will cancel it if it can open immediately
        Task {
          await scheduleSetupNotificationIfNeeded(for: v.gameType)
        }
        onReceiveStartRequest?(v)
      }
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
    case .rosterInventory:
      if let v = anyValue as? RosterInventoryDTO { onReceiveRosterInventory?(v) }
    case .rosterUpsert:
      if let v = anyValue as? RosterUpsertDTO { onReceiveRosterUpsert?(v) }
    case .rosterPrune:
      if let v = anyValue as? RosterPruneDTO { onReceiveRosterPrune?(v) }
    case .ack, .error:
      break
    }
  }

  // MARK: WCSessionDelegate
  public nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    Task { @MainActor in
      self.isActivated = (activationState == .activated)
      self.handleActivationResult(error: error)
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
      let wasReachable = self.lastReachable
      self.lastReachable = self.session.isReachable
      if let wasReachable, wasReachable && !self.session.isReachable {
        self.incrementCounter(self.lostConnectionsKey)
        self.startAutoConnectRetriesIfNeeded()
      }
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
    Task { @MainActor in
      self.isActivated = false
    }
    session.activate()
    Task { @MainActor in
      self.startAutoConnectRetriesIfNeeded()
    }
  }

  // MARK: - Watch/app install and activation helpers (iOS)
  public nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
    Task { @MainActor in
      // Update activation snapshot and notify reachability changes
      self.isActivated = (self.session.activationState == .activated)
      if self.isActivated { await self.flushPendingSends() }
      if !self.session.isPaired || !self.session.isWatchAppInstalled {
        self.incrementCounter(self.rejectionsKey)
        self.startAutoConnectRetriesIfNeeded()
      }
      self.onReachabilityChanged?(self.currentReachability)
      Log.event(
        .loadSucceeded,
        level: .debug,
        message: "wc.watchStateChanged",
        metadata: [
          "paired": String(self.session.isPaired),
          "installed": String(self.session.isWatchAppInstalled),
          "activation": String(self.session.activationState.rawValue)
        ]
      )
    }
  }

  private func updateActivationFromSession() {
    isActivated = (session.activationState == .activated)
  }

  private func flushPendingSends() async {
    guard !pendingSends.isEmpty else { return }
    let queued = pendingSends
    pendingSends.removeAll()
    for item in queued {
      if item.preferContext {
        do { try session.updateApplicationContext(["data": item.data]) } catch { try? await sendData(item.data) }
      } else {
        try? await sendData(item.data)
      }
    }
  }

  private func ensureActivationReady() async {
    // If already activated, set and flush immediately
    updateActivationFromSession()
    if isActivated {
      await flushPendingSends()
      return
    }
    // Poll briefly to allow activation to complete on iOS
    let deadline = Date().addingTimeInterval(3.0)
    while Date() < deadline {
      try? await Task.sleep(nanoseconds: 50_000_000)
      updateActivationFromSession()
      if isActivated {
        await flushPendingSends()
        break
      }
    }
  }

  // MARK: - Persistent retry/backoff
  private func startAutoConnectRetriesIfNeeded() {
    guard !hasExceededRetryLimits(), !isConnected() else { return }
    if retryTask?.isCancelled == false { return }
    retryTask = Task { [weak self] in
      guard let self else { return }
      var attempt: Int = 0
      while !Task.isCancelled {
        let connected = await MainActor.run { self.isConnected() }
        let exceeded = await MainActor.run { self.hasExceededRetryLimits() }
        if connected || exceeded { break }
        let delay = self.backoff(for: attempt)
        do { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) } catch { break }
        await MainActor.run {
          self.session.activate()
        }
        attempt += 1
      }
    }
  }

  private func isConnected() -> Bool {
    if !WCSession.isSupported() { return false }
    if !session.isPaired || !session.isWatchAppInstalled { return false }
    return isActivated && session.isReachable
  }

  private func backoff(for attempt: Int) -> Double {
    let base: Double = 0.5
    let maxDelay: Double = 30.0
    let delay = base * pow(2.0, Double(min(attempt, 10)))
    return min(delay, maxDelay)
  }

  private func handleActivationResult(error: Error?) {
    if isConnected() {
      resetRetryCounters()
      retryTask?.cancel()
      retryTask = nil
    } else {
      if error != nil || session.activationState != .activated {
        incrementCounter(activationFailuresKey)
      }
      startAutoConnectRetriesIfNeeded()
    }
  }

  private func hasExceededRetryLimits() -> Bool {
    let failures = defaults.integer(forKey: activationFailuresKey)
    let lost = defaults.integer(forKey: lostConnectionsKey)
    let rejections = defaults.integer(forKey: rejectionsKey)
    return failures >= maxActivationFailures || lost >= maxLostConnections || rejections >= maxRejections
  }

  private func resetRetryCounters() {
    defaults.set(0, forKey: activationFailuresKey)
    defaults.set(0, forKey: lostConnectionsKey)
    defaults.set(0, forKey: rejectionsKey)
  }

  private func incrementCounter(_ key: String) {
    let v = defaults.integer(forKey: key)
    defaults.set(v + 1, forKey: key)
  }
  
  private func scheduleSetupNotificationIfNeeded(for gameType: GameType) async {
    // Brief delay to let UI register observers and update sheet state
    try? await Task.sleep(nanoseconds: 200_000_000)
    let (isActive, hasSheet, isSetupOpen) = await MainActor.run { () -> (Bool, Bool, Bool) in
      let global = GlobalNavigationState.shared
      return (global.isAppActive, global.hasOpenSheet, global.isSheetOpen("setup"))
    }
    // If app is active and no sheets are open, request opening immediately (no notification)
    if isActive && !hasSheet {
      Log.event(
        .actionTapped,
        level: .info,
        message: "Skip scheduling setup notification (app active, can present)",
        metadata: [
          "gameType": gameType.rawValue,
          "hasSheet": String(hasSheet),
          "isSetupOpen": String(isSetupOpen)
        ]
      )
      NotificationCenter.default.post(
        name: Notification.Name("OpenSetupRequested"),
        object: nil,
        userInfo: ["gameTypeId": gameType.rawValue]
      )
      return
    }

    // Otherwise, schedule a notification to prompt the user
    await SetupNotificationService.shared.scheduleSetupNotification(for: gameType)
  }
}

#endif


