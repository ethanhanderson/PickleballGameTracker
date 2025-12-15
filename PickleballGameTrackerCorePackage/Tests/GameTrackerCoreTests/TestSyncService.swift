//
//  TestSyncService.swift
//  GameTrackerCoreTests
//
//

import Foundation
@testable import GameTrackerCore

@MainActor
final class TestSyncService: SyncService {
  enum Role {
    case phone
    case watch
  }

  let role: Role

  // Peer endpoint to forward messages to.
  weak var peer: TestSyncService?

  // Inbound handlers
  var onReceiveLiveSnapshot: (@Sendable (LiveGameSnapshotDTO) -> Void)?
  var onReceiveLiveDelta: (@Sendable (LiveGameDeltaDTO) -> Void)?
  var onReceiveRosterSnapshot: (@Sendable (RosterSnapshotDTO) -> Void)?
  var onReceiveHistorySummaries: (@Sendable (HistorySummariesDTO) -> Void)?
  var onReceiveStartConfiguration: (@Sendable (GameStartConfiguration) -> Void)?
  var onReceiveStartRequest: (@Sendable (StartGameRequestDTO) -> Void)?
  var onReceiveLiveStatusRequest: (@Sendable () -> Void)?
  var onReachabilityChanged: (@Sendable (SyncReachability) -> Void)?
  var onReceiveRosterRequest: (@Sendable () -> Void)?
  var onReceiveHistoryRequest: (@Sendable () -> Void)?
  var onReceiveRosterInventory: (@Sendable (RosterInventoryDTO) -> Void)?
  var onReceiveRosterUpsert: (@Sendable (RosterUpsertDTO) -> Void)?
  var onReceiveRosterPrune: (@Sendable (RosterPruneDTO) -> Void)?

  var currentReachability: SyncReachability = .reachable {
    didSet {
      onReachabilityChanged?(currentReachability)
    }
  }

  init(role: Role) {
    self.role = role
  }

  // MARK: - Lifecycle

  func start() async {
    // For tests, treat start as an immediate reachability notification.
    onReachabilityChanged?(currentReachability)
  }

  func stop() async {
    // No-op for tests
  }

  // MARK: - Outbound helpers

  private func forward(_ action: (TestSyncService) -> Void) {
    guard let peer else { return }
    action(peer)
  }

  func sendLiveSnapshot(_ snapshot: LiveGameSnapshotDTO) async throws {
    forward { service in
      service.onReceiveLiveSnapshot?(snapshot)
    }
  }

  func sendLiveDelta(_ delta: LiveGameDeltaDTO) async throws {
    forward { service in
      service.onReceiveLiveDelta?(delta)
    }
  }

  func sendRosterSnapshot(_ roster: RosterSnapshotDTO) async throws {
    forward { service in
      service.onReceiveRosterSnapshot?(roster)
    }
  }

  func sendHistorySummaries(_ summaries: HistorySummariesDTO) async throws {
    forward { service in
      service.onReceiveHistorySummaries?(summaries)
    }
  }

  func sendStartConfiguration(_ config: GameStartConfiguration) async throws {
    forward { service in
      service.onReceiveStartConfiguration?(config)
    }
  }

  func sendStartRequest(_ request: StartGameRequestDTO) async throws {
    forward { service in
      service.onReceiveStartRequest?(request)
    }
  }

  func requestLiveStatus() async throws {
    forward { service in
      service.onReceiveLiveStatusRequest?()
    }
  }

  func requestRosterSnapshot() async throws {
    forward { service in
      service.onReceiveRosterRequest?()
    }
  }

  func requestHistorySummaries() async throws {
    forward { service in
      service.onReceiveHistoryRequest?()
    }
  }

  func sendRosterInventory(_ inventory: RosterInventoryDTO) async throws {
    forward { service in
      service.onReceiveRosterInventory?(inventory)
    }
  }

  func sendRosterUpsert(_ upsert: RosterUpsertDTO) async throws {
    forward { service in
      service.onReceiveRosterUpsert?(upsert)
    }
  }

  func sendRosterPrune(_ prune: RosterPruneDTO) async throws {
    forward { service in
      service.onReceiveRosterPrune?(prune)
    }
  }
}


