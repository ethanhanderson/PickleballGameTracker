//
//  MessageCodec.swift
//  GameTrackerWatchFeature (watchOS)
//

import Foundation
import GameTrackerCore

enum MessageCodec {
  static func encode<T: Codable>(_ value: T, type: SyncMessageType, sessionId: UUID?) throws -> Data {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let payload = try encoder.encode(value)
    let envelope = SyncEnvelope(type: type, sessionId: sessionId, payload: payload)
    return try encoder.encode(envelope)
  }

  static func decode(_ data: Data) throws -> (SyncMessageType, Any) {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let envelope = try decoder.decode(SyncEnvelope.self, from: data)
    switch envelope.type {
    case .liveStatusRequest:
      return (.liveStatusRequest, ())
    case .startConfig:
      let config = try decoder.decode(GameStartConfiguration.self, from: envelope.payload)
      return (.startConfig, config)
    case .liveSnapshot:
      let snapshot = try decoder.decode(LiveGameSnapshotDTO.self, from: envelope.payload)
      return (.liveSnapshot, snapshot)
    case .liveDelta:
      let delta = try decoder.decode(LiveGameDeltaDTO.self, from: envelope.payload)
      return (.liveDelta, delta)
    case .rosterSnapshot:
      let roster = try decoder.decode(RosterSnapshotDTO.self, from: envelope.payload)
      return (.rosterSnapshot, roster)
    case .historySummaries:
      let history = try decoder.decode(HistorySummariesDTO.self, from: envelope.payload)
      return (.historySummaries, history)
    case .rosterRequest:
      return (.rosterRequest, ())
    case .historyRequest:
      return (.historyRequest, ())
    case .ack, .error:
      return (envelope.type, envelope)
    }
  }
}


