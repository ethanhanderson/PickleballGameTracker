//
//  NoopSyncService.swift
//  GameTrackerCore
//

import Foundation

@MainActor
public final class NoopSyncService: SyncService {
  public init() {}

  public var onReceiveLiveSnapshot: (@Sendable (LiveGameSnapshotDTO) -> Void)?
  public var onReceiveLiveDelta: (@Sendable (LiveGameDeltaDTO) -> Void)?
  public var onReceiveRosterSnapshot: (@Sendable (RosterSnapshotDTO) -> Void)?
  public var onReceiveHistorySummaries: (@Sendable (HistorySummariesDTO) -> Void)?
  public var onReceiveStartConfiguration: (@Sendable (GameStartConfiguration) -> Void)?
  public var onReceiveStartRequest: (@Sendable (StartGameRequestDTO) -> Void)?
  public var onReceiveLiveStatusRequest: (@Sendable () -> Void)?
  public var onReceiveRosterRequest: (@Sendable () -> Void)?
  public var onReceiveHistoryRequest: (@Sendable () -> Void)?
  public var onReceiveRosterInventory: (@Sendable (RosterInventoryDTO) -> Void)?
  public var onReceiveRosterUpsert: (@Sendable (RosterUpsertDTO) -> Void)?
  public var onReceiveRosterPrune: (@Sendable (RosterPruneDTO) -> Void)?
  public var onReachabilityChanged: (@Sendable (SyncReachability) -> Void)?

  public var currentReachability: SyncReachability { .unavailable }

  public func start() async {}
  public func stop() async {}

  public func sendLiveSnapshot(_ snapshot: LiveGameSnapshotDTO) async throws {}
  public func sendLiveDelta(_ delta: LiveGameDeltaDTO) async throws {}
  public func sendRosterSnapshot(_ roster: RosterSnapshotDTO) async throws {}
  public func sendHistorySummaries(_ summaries: HistorySummariesDTO) async throws {}
  public func sendStartConfiguration(_ config: GameStartConfiguration) async throws {}
  public func sendStartRequest(_ request: StartGameRequestDTO) async throws {}
  public func requestLiveStatus() async throws {}
  public func requestRosterSnapshot() async throws {}
  public func requestHistorySummaries() async throws {}
  public func sendRosterInventory(_ inventory: RosterInventoryDTO) async throws {}
  public func sendRosterUpsert(_ upsert: RosterUpsertDTO) async throws {}
  public func sendRosterPrune(_ prune: RosterPruneDTO) async throws {}
}


