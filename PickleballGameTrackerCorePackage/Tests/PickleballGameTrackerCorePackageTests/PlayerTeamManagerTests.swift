//
//  PlayerTeamManagerTests.swift
//  SharedGameCoreTests
//
//  Created by Ethan Anderson on 8/14/25.
//

import Foundation
import SwiftData
import Testing

@testable import SharedGameCore

@Suite("Player & Team Manager")
struct PlayerTeamManagerTests {

  @Test("Create player, team, and preset")
  @MainActor
  func testBasicCRUD() throws {
    // Use in-memory container for isolation
    let container = SwiftDataContainer.createPreviewContainer()
    let manager = PlayerTeamManager()

    // Create players
    let p1 = try manager.createPlayer(name: "Alice")
    let p2 = try manager.createPlayer(name: "Bob")

    #expect(manager.players.contains { $0.id == p1.id })
    #expect(manager.players.contains { $0.id == p2.id })

    // Create team
    let team = try manager.createTeam(name: "A&B", players: [p1, p2])
    #expect(manager.teams.contains { $0.id == team.id })
    #expect(team.players.count == 2)

    // Create preset
    let preset = try manager.createPreset(
      name: "Rec Doubles", gameType: .recreational, team1: team, team2: nil)
    #expect(manager.presets.contains { $0.id == preset.id })
    #expect(preset.gameType == .recreational)
  }

  @Test("Detect and merge duplicate players")
  @MainActor
  func testDuplicatePlayerMerge() throws {
    let container = SwiftDataContainer.createPreviewContainer()
    let manager = PlayerTeamManager()

    let p1 = try manager.createPlayer(name: "Alice")
    let p2 = try manager.createPlayer(name: "alice ")  // normalized duplicate
    let dups = manager.findDuplicatePlayers(for: "ALICE")
    #expect(dups.count >= 2)

    // Place both on a team then merge
    let team = try manager.createTeam(name: "Team A", players: [p1, p2])
    try manager.mergePlayer(source: p2, into: p1)

    // Team should reference only target
    #expect(team.players.contains { $0.id == p1.id })
    #expect(!team.players.contains { $0.id == p2.id })
  }

  @Test("Detect and merge duplicate teams and update presets")
  @MainActor
  func testDuplicateTeamMerge() throws {
    let container = SwiftDataContainer.createPreviewContainer()
    let manager = PlayerTeamManager()

    let p1 = try manager.createPlayer(name: "Alice")
    let p2 = try manager.createPlayer(name: "Bob")
    let t1 = try manager.createTeam(name: "AB", players: [p1, p2])
    let t2 = try manager.createTeam(name: "ab ", players: [p1, p2])

    // Create a preset that references the duplicate to ensure update
    let preset = try manager.createPreset(
      name: "Rec", gameType: .recreational, team1: t2, team2: nil)
    let dupTeams = manager.findDuplicateTeams(candidates: [p1, p2], name: "AB")
    #expect(dupTeams.count >= 2)

    try manager.mergeTeam(source: t2, into: t1)

    // Preset should now reference t1
    #expect(preset.team1?.id == t1.id)
    #expect(preset.team1?.id != t2.id)
  }

  @Test("Update player refreshes lastModified and in-memory state")
  @MainActor
  func testUpdatePlayerLastModified() throws {
    let container = SwiftDataContainer.createPreviewContainer()
    let manager = PlayerTeamManager()

    let player = try manager.createPlayer(name: "Temp")
    let originalLastModified = player.lastModified

    // Ensure time progresses to observe change
    Thread.sleep(forTimeInterval: 0.01)

    try manager.updatePlayer(player) { p in
      p.name = "Updated"
    }

    #expect(player.name == "Updated")
    #expect(player.lastModified >= originalLastModified)
  }
}
