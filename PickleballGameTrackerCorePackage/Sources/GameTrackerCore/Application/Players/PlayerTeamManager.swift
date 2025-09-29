//
//  PlayerTeamManager.swift
//  SharedGameCore
//
//  Created by Ethan Anderson on 8/14/25.
//

import Foundation
import SwiftData

@MainActor
@Observable
public final class PlayerTeamManager {
  public let storage: any SwiftDataStorageProtocol
  private let rosterStore: RosterStore
  public var players: [PlayerProfile] = []
  public var teams: [TeamProfile] = []
  public var presets: [GameTypePreset] = []

  public init(
    storage: any SwiftDataStorageProtocol = SwiftDataStorage.shared, autoRefresh: Bool = true
  ) {
    self.storage = storage
    self.rosterStore = RosterStore(context: storage.modelContainer.mainContext)
    if autoRefresh {
      Task { refreshAll() }
    }
  }

  // MARK: - Loaders
  public func refreshAll() {
    refreshPlayers()
    refreshTeams()
    refreshPresets()
  }

  public func refreshPlayers() {
    players = (try? rosterStore.players()) ?? []
  }

  public func refreshTeams() {
    teams = (try? rosterStore.teams()) ?? []
  }

  public func refreshPresets() {
    presets = (try? rosterStore.presets()) ?? []
  }

  // MARK: - Archive Loaders
  public func loadArchivedPlayers() -> [PlayerProfile] {
    (try? rosterStore.players(includeArchived: true).filter { $0.isArchived }) ?? []
  }

  public func loadArchivedTeams() -> [TeamProfile] {
    (try? rosterStore.teams(includeArchived: true).filter { $0.isArchived }) ?? []
  }

  // MARK: - Player CRUD
  public func createPlayer(
    name: String,
    configure: ((PlayerProfile) -> Void)? = nil
  ) throws
    -> PlayerProfile
  {
    let player = try rosterStore.createPlayer(name: name) { pl in
      configure?(pl)
    }
    players.insert(player, at: 0)
    return player
  }

  public func updatePlayer(
    _ player: PlayerProfile,
    mutate: (PlayerProfile) -> Void
  ) throws {
    try rosterStore.updatePlayer(player, mutate: mutate)
    try awaitRefreshAfterMutation()
  }

  public func archivePlayer(_ player: PlayerProfile) throws {
    try rosterStore.archivePlayer(player)
    players.removeAll { $0.id == player.id }
  }

  public func restorePlayer(_ player: PlayerProfile) throws {
    player.isArchived = false
    player.lastModified = Date()
    try rosterStore.updatePlayer(player) { _ in }
    refreshPlayers()
  }

  // MARK: - Team CRUD
  public func createTeam(name: String, players: [PlayerProfile]) throws
    -> TeamProfile
  {
    let team = try rosterStore.createTeam(name: name, players: players)
    teams.insert(team, at: 0)
    return team
  }

  public func updateTeam(_ team: TeamProfile, mutate: (TeamProfile) -> Void)
    throws
  {
    try rosterStore.updateTeam(team, mutate: mutate)
    try awaitRefreshAfterMutation()
  }

  public func archiveTeam(_ team: TeamProfile) throws {
    try rosterStore.archiveTeam(team)
    teams.removeAll { $0.id == team.id }
  }

  public func restoreTeam(_ team: TeamProfile) throws {
    team.isArchived = false
    team.lastModified = Date()
    try rosterStore.updateTeam(team) { _ in }
    refreshTeams()
  }

  // MARK: - Preset CRUD
  public func createPreset(
    name: String,
    gameType: GameType,
    team1: TeamProfile?,
    team2: TeamProfile?
  ) throws -> GameTypePreset {
    let preset = try rosterStore.createPreset(name: name, gameType: gameType, team1: team1, team2: team2)
    presets.insert(preset, at: 0)
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
    presets.removeAll { $0.id == preset.id }
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
    return players.filter { normalizedName($0.name) == key }
  }

  public func findDuplicateTeams(
    candidates: [PlayerProfile],
    name: String? = nil
  ) -> [TeamProfile] {
    let candidateIds = Set(candidates.map { $0.id })
    let normalized: String? = name.map { normalizedName($0) }
    return teams.filter { team in
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
  public func mergePlayer(source: PlayerProfile, into target: PlayerProfile)
    throws
  {
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
    try awaitRefreshAfterMutation()
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
    try awaitRefreshAfterMutation()
  }

  // Ensures lists reflect latest persisted state after a merge/archive
  private func awaitRefreshAfterMutation() throws {
    Task { @MainActor in
      refreshAll()
    }
  }

}
