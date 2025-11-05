//
//  RosterPruneDTO.swift
//  GameTrackerCore
//

import Foundation

/// List of roster entity IDs to delete or mark archived on watch
public struct RosterPruneDTO: Codable, Sendable {
  public let players: [UUID]
  public let teams: [UUID]
  public let presets: [UUID]
  public let generatedAt: Date

  public init(
    players: [UUID] = [],
    teams: [UUID] = [],
    presets: [UUID] = [],
    generatedAt: Date = Date()
  ) {
    self.players = players
    self.teams = teams
    self.presets = presets
    self.generatedAt = generatedAt
  }
}

