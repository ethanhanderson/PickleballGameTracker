//
//  RosterSnapshotDTO.swift
//  GameTrackerCore
//

import Foundation

// Reuse existing backup DTOs for roster payloads to avoid duplication.
public struct RosterSnapshotDTO: Codable, Sendable {
  public let players: [BackupPlayerDTO]
  public let teams: [BackupTeamDTO]
  public let presets: [BackupPresetDTO]
  public let generatedAt: Date

  public init(
    players: [BackupPlayerDTO],
    teams: [BackupTeamDTO],
    presets: [BackupPresetDTO],
    generatedAt: Date = Date()
  ) {
    self.players = players
    self.teams = teams
    self.presets = presets
    self.generatedAt = generatedAt
  }
}


