//
//  RosterInventoryDTO.swift
//  GameTrackerCore
//

import Foundation

/// Compact summary of roster entities on watch: maps of id → lastModified
public struct RosterInventoryDTO: Codable, Sendable {
  public let players: [UUID: Date]
  public let teams: [UUID: Date]
  public let presets: [UUID: Date]
  public let generatedAt: Date

  public init(
    players: [UUID: Date] = [:],
    teams: [UUID: Date] = [:],
    presets: [UUID: Date] = [:],
    generatedAt: Date = Date()
  ) {
    self.players = players
    self.teams = teams
    self.presets = presets
    self.generatedAt = generatedAt
  }
}

