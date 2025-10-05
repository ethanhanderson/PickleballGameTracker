//
//  PlayerTeamManager.swift
//  SharedGameCore
//
//  Created by Ethan Anderson on 8/14/25.
//

import Foundation
import SwiftData

/// Business logic service for player and team roster management
/// Handles all CRUD operations, validation, and duplicate detection
///
/// Views should use @Query for data access, and this manager for operations only.
@MainActor
@Observable
public final class PlayerTeamManager {
  public let storage: any SwiftDataStorageProtocol
  private let rosterStore: RosterStore

  public init(storage: any SwiftDataStorageProtocol = SwiftDataStorage.shared) {
    self.storage = storage
    self.rosterStore = RosterStore(context: storage.modelContainer.mainContext)
  }

  // MARK: - Player CRUD
  public func createPlayer(
    name: String,
    configure: ((PlayerProfile) -> Void)? = nil
  ) throws -> PlayerProfile {
    let player = try rosterStore.createPlayer(name: name) { pl in
      configure?(pl)
    }
    return player
  }

  public func createGuestPlayer(name: String) throws -> PlayerProfile {
    let player = try rosterStore.createPlayer(name: name) { pl in
      pl.isGuest = true
      pl.skillLevel = .unknown
      pl.preferredHand = .unknown
    }
    return player
  }

  public func convertGuestToPlayer(_ guest: PlayerProfile) throws {
    guard guest.isGuest else { return }
    try updatePlayer(guest) { player in
      player.isGuest = false
    }
  }

  public func updatePlayer(
    _ player: PlayerProfile,
    mutate: (PlayerProfile) -> Void
  ) throws {
    try rosterStore.updatePlayer(player, mutate: mutate)
  }

  public func archivePlayer(_ player: PlayerProfile) throws {
    try rosterStore.archivePlayer(player)
  }

  public func restorePlayer(_ player: PlayerProfile) throws {
    player.isArchived = false
    player.lastModified = Date()
    try rosterStore.updatePlayer(player) { _ in }
  }

  // MARK: - Team CRUD
  public func createTeam(name: String, players: [PlayerProfile]) throws -> TeamProfile {
    let team = try rosterStore.createTeam(name: name, players: players)
    return team
  }

  public func updateTeam(_ team: TeamProfile, mutate: (TeamProfile) -> Void) throws {
    try rosterStore.updateTeam(team, mutate: mutate)
  }

  public func archiveTeam(_ team: TeamProfile) throws {
    try rosterStore.archiveTeam(team)
  }

  public func restoreTeam(_ team: TeamProfile) throws {
    team.isArchived = false
    team.lastModified = Date()
    try rosterStore.updateTeam(team) { _ in }
  }

  // MARK: - Preset CRUD
  public func createPreset(
    name: String,
    gameType: GameType,
    team1: TeamProfile?,
    team2: TeamProfile?
  ) throws -> GameTypePreset {
    let preset = try rosterStore.createPreset(name: name, gameType: gameType, team1: team1, team2: team2)
    return preset
  }

  public func updatePreset(
    _ preset: GameTypePreset,
    mutate: (GameTypePreset) -> Void
  ) throws {
    try rosterStore.updatePreset(preset, mutate: mutate)
  }

  public func archivePreset(_ preset: GameTypePreset) throws {
    try rosterStore.archivePreset(preset)
  }

  // MARK: - Duplicate detection

  private func normalizedName(_ name: String) -> String {
    return name.folding(
      options: [.caseInsensitive, .diacriticInsensitive],
      locale: .current
    )
    .trimmingCharacters(in: .whitespacesAndNewlines)
  }

  public func findDuplicatePlayers(for name: String) -> [PlayerProfile] {
    let key = normalizedName(name)
    let predicate = #Predicate<PlayerProfile> { !$0.isArchived && !$0.isGuest }
    let descriptor = FetchDescriptor(predicate: predicate)
    
    guard let allPlayers = try? storage.modelContainer.mainContext.fetch(descriptor) else {
      return []
    }
    
    return allPlayers.filter { normalizedName($0.name) == key }
  }

  public func findDuplicateTeams(
    candidates: [PlayerProfile],
    name: String? = nil
  ) -> [TeamProfile] {
    let candidateIds = Set(candidates.map { $0.id })
    let normalized: String? = name.map { normalizedName($0) }
    
    let predicate = #Predicate<TeamProfile> { !$0.isArchived }
    let descriptor = FetchDescriptor(predicate: predicate)
    
    guard let allTeams = try? storage.modelContainer.mainContext.fetch(descriptor) else {
      return []
    }
    
    return allTeams.filter { team in
      let ids = Set(team.players.map { $0.id })
      let sameRoster = ids == candidateIds
      if let normalized {
        return sameRoster && normalizedName(team.name) == normalized
      }
      return sameRoster
    }
  }

  // MARK: - Merge operations (archive source, preserve history)

  public enum RosterError: Error, LocalizedError, Sendable {
    case sameEntity
    case notFound
  }

  /// Merge `source` player into `target`. Updates all teams to reference `target`, archives `source`.
  public func mergePlayer(source: PlayerProfile, into target: PlayerProfile) throws {
    guard source.id != target.id else { throw RosterError.sameEntity }
    // Update team memberships using storage context
    let context = storage.modelContainer.mainContext
    let teamFetch = FetchDescriptor<TeamProfile>(
      predicate: #Predicate { $0.isArchived == false }
    )
    let affectedTeams = (try? context.fetch(teamFetch)) ?? []
    for team in affectedTeams {
      if let idx = team.players.firstIndex(where: { $0.id == source.id }) {
        if !team.players.contains(where: { $0.id == target.id }) {
          team.players[idx] = target
        } else {
          team.players.remove(at: idx)
        }
        team.lastModified = Date()
      }
    }
    try storage.archivePlayer(source)
    try context.save()
  }

  /// Merge `source` team into `target`. Updates presets to reference `target`, archives `source`.
  public func mergeTeam(source: TeamProfile, into target: TeamProfile) throws {
    guard source.id != target.id else { throw RosterError.sameEntity }
    let context = storage.modelContainer.mainContext
    let presetFetch = FetchDescriptor<GameTypePreset>(
      predicate: #Predicate { $0.isArchived == false }
    )
    let affectedPresets = (try? context.fetch(presetFetch)) ?? []
    for preset in affectedPresets {
      var changed = false
      if let t1 = preset.team1, t1.id == source.id {
        preset.team1 = target
        changed = true
      }
      if let t2 = preset.team2, t2.id == source.id {
        preset.team2 = target
        changed = true
      }
      if changed { preset.lastModified = Date() }
    }
    try storage.archiveTeam(source)
    try context.save()
  }

}
