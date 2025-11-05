//
//  RosterUpsertDTO.swift
//  GameTrackerCore
//

import Foundation

/// Incremental roster updates: only changed/missing players/teams/presets
public struct RosterUpsertDTO: Codable, Sendable {
  public let players: [BackupPlayerDTO]
  public let teams: [BackupTeamDTO]
  public let presets: [BackupPresetDTO]
  public let generatedAt: Date

  public init(
    players: [BackupPlayerDTO] = [],
    teams: [BackupTeamDTO] = [],
    presets: [BackupPresetDTO] = [],
    generatedAt: Date = Date()
  ) {
    self.players = players
    self.teams = teams
    self.presets = presets
    self.generatedAt = generatedAt
  }
}

