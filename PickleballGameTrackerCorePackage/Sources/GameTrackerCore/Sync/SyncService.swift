//
//  SyncService.swift
//  GameTrackerCore
//
//  Transport-agnostic contracts for phone–watch sync.
//

import Foundation

// MARK: - Message Types

public enum SyncMessageType: String, Codable, Sendable {
  case liveSnapshot
  case liveDelta
  case rosterSnapshot
  case historySummaries
  case rosterRequest
  case historyRequest
  case startConfig
  case startRequest
  case liveStatusRequest
  case rosterInventory
  case rosterUpsert
  case rosterPrune
  case ack
  case error
}

// MARK: - Versioned Envelope

public struct SyncEnvelope: Codable, Sendable, Identifiable {
  public let id: UUID
  public let version: Int
  public let type: SyncMessageType
  public let sentAt: Date
  public let sessionId: UUID?
  public let payload: Data

  public init(
    id: UUID = UUID(),
    version: Int = 1,
    type: SyncMessageType,
    sentAt: Date = Date(),
    sessionId: UUID? = nil,
    payload: Data
  ) {
    self.id = id
    self.version = version
    self.type = type
    self.sentAt = sentAt
    self.sessionId = sessionId
    self.payload = payload
  }
}

public enum SyncCodecError: Error, Sendable {
  case encodingFailed
  case decodingFailed
  case unsupportedType
}

public enum SyncReachability: String, Sendable {
  case unavailable
  case connecting
  case reachable
}

// MARK: - Transport-agnostic Service

/// Platform transport implements this protocol (e.g., WatchConnectivity on iOS/watchOS).
@MainActor
public protocol SyncService: Sendable {
  // MARK: Lifecycle
  func start() async
  func stop() async

  // MARK: Outbound
  func sendLiveSnapshot(_ snapshot: LiveGameSnapshotDTO) async throws
  func sendLiveDelta(_ delta: LiveGameDeltaDTO) async throws
  func sendRosterSnapshot(_ roster: RosterSnapshotDTO) async throws
  func sendHistorySummaries(_ summaries: HistorySummariesDTO) async throws
  func sendStartConfiguration(_ config: GameStartConfiguration) async throws
  func sendStartRequest(_ request: StartGameRequestDTO) async throws
  func requestLiveStatus() async throws

  func requestRosterSnapshot() async throws
  func requestHistorySummaries() async throws
  
  func sendRosterInventory(_ inventory: RosterInventoryDTO) async throws
  func sendRosterUpsert(_ upsert: RosterUpsertDTO) async throws
  func sendRosterPrune(_ prune: RosterPruneDTO) async throws

  // MARK: Inbound Handlers
  var onReceiveLiveSnapshot: (@Sendable (LiveGameSnapshotDTO) -> Void)? { get set }
  var onReceiveLiveDelta: (@Sendable (LiveGameDeltaDTO) -> Void)? { get set }
  var onReceiveRosterSnapshot: (@Sendable (RosterSnapshotDTO) -> Void)? { get set }
  var onReceiveHistorySummaries: (@Sendable (HistorySummariesDTO) -> Void)? { get set }
  var onReceiveStartConfiguration: (@Sendable (GameStartConfiguration) -> Void)? { get set }
  var onReceiveStartRequest: (@Sendable (StartGameRequestDTO) -> Void)? { get set }
  var onReceiveLiveStatusRequest: (@Sendable () -> Void)? { get set }

  // Type-only inbound requests
  var onReceiveRosterRequest: (@Sendable () -> Void)? { get set }
  var onReceiveHistoryRequest: (@Sendable () -> Void)? { get set }
  
  var onReceiveRosterInventory: (@Sendable (RosterInventoryDTO) -> Void)? { get set }
  var onReceiveRosterUpsert: (@Sendable (RosterUpsertDTO) -> Void)? { get set }
  var onReceiveRosterPrune: (@Sendable (RosterPruneDTO) -> Void)? { get set }

  // MARK: Reachability
  var onReachabilityChanged: (@Sendable (SyncReachability) -> Void)? { get set }
  var currentReachability: SyncReachability { get }
}


