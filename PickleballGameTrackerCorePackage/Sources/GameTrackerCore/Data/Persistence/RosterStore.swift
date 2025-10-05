import Foundation
import SwiftData

@MainActor
public struct RosterStore: Sendable {
  private let playerRepo: SwiftDataRepository<PlayerProfile>
  private let teamRepo: SwiftDataRepository<TeamProfile>
  private let presetRepo: SwiftDataRepository<GameTypePreset>

  public init(context: ModelContext) {
    self.playerRepo = SwiftDataRepository<PlayerProfile>(context: context)
    self.teamRepo = SwiftDataRepository<TeamProfile>(context: context)
    self.presetRepo = SwiftDataRepository<GameTypePreset>(context: context)
  }

  // MARK: - Players
  public func createPlayer(name: String, configure: (PlayerProfile) -> Void = { _ in }) throws -> PlayerProfile {
    let player = PlayerProfile(name: name)
    configure(player)
    try playerRepo.insert(player)
    try playerRepo.save()
    return player
  }

  public func updatePlayer(_ player: PlayerProfile, mutate: (PlayerProfile) -> Void) throws {
    mutate(player)
    player.lastModified = Date()
    try playerRepo.save()
  }

  public func archivePlayer(_ player: PlayerProfile) throws {
    player.archive()
    try playerRepo.save()
  }

  public func deletePlayer(_ player: PlayerProfile) throws {
    try playerRepo.delete(player)
    try playerRepo.save()
  }

  public func players(includeArchived: Bool = false) throws -> [PlayerProfile] {
    let predicate: Predicate<PlayerProfile> = includeArchived ? #Predicate { $0.isGuest == false } : #Predicate { $0.isArchived == false && $0.isGuest == false }
    let fd = FetchDescriptor<PlayerProfile>(predicate: predicate, sortBy: [SortDescriptor(\.lastModified, order: .reverse)])
    return try playerRepo.fetch(fd)
  }

  /// Get a player by ID
  public func player(id: UUID) throws -> PlayerProfile? {
    let fd = FetchDescriptor<PlayerProfile>(
      predicate: #Predicate { $0.id == id }
    )
    return try playerRepo.fetch(fd).first
  }

  /// Get players by skill level
  public func players(skillLevel: PlayerSkillLevel, includeArchived: Bool = false) throws -> [PlayerProfile] {
    let predicate: Predicate<PlayerProfile> = {
      if includeArchived {
        return #Predicate { $0.skillLevel == skillLevel && $0.isGuest == false }
      } else {
        return #Predicate { $0.skillLevel == skillLevel && $0.isArchived == false && $0.isGuest == false }
      }
    }()

    let fd = FetchDescriptor<PlayerProfile>(
      predicate: predicate,
      sortBy: [SortDescriptor(\.name, order: .forward)]
    )
    return try playerRepo.fetch(fd)
  }

  // MARK: - Teams
  public func createTeam(name: String, players: [PlayerProfile]) throws -> TeamProfile {
    let team = TeamProfile(name: name, players: players)
    try teamRepo.insert(team)
    try teamRepo.save()
    return team
  }

  public func updateTeam(_ team: TeamProfile, mutate: (TeamProfile) -> Void) throws {
    mutate(team)
    team.lastModified = Date()
    try teamRepo.save()
  }

  public func archiveTeam(_ team: TeamProfile) throws {
    team.archive()
    try teamRepo.save()
  }

  public func deleteTeam(_ team: TeamProfile) throws {
    try teamRepo.delete(team)
    try teamRepo.save()
  }

  public func teams(includeArchived: Bool = false) throws -> [TeamProfile] {
    let predicate: Predicate<TeamProfile> = includeArchived ? #Predicate { _ in true } : #Predicate { $0.isArchived == false }
    let fd = FetchDescriptor<TeamProfile>(predicate: predicate, sortBy: [SortDescriptor(\.lastModified, order: .reverse)])
    return try teamRepo.fetch(fd)
  }

  /// Get a team by ID
  public func team(id: UUID) throws -> TeamProfile? {
    let fd = FetchDescriptor<TeamProfile>(
      predicate: #Predicate { $0.id == id }
    )
    return try teamRepo.fetch(fd).first
  }

  // MARK: - Presets
  public func createPreset(name: String, gameType: GameType, team1: TeamProfile?, team2: TeamProfile?) throws -> GameTypePreset {
    let preset = GameTypePreset(name: name, gameType: gameType, team1: team1, team2: team2)
    try presetRepo.insert(preset)
    try presetRepo.save()
    return preset
  }

  public func updatePreset(_ preset: GameTypePreset, mutate: (GameTypePreset) -> Void) throws {
    mutate(preset)
    preset.lastModified = Date()
    try presetRepo.save()
  }

  public func archivePreset(_ preset: GameTypePreset) throws {
    preset.archive()
    try presetRepo.save()
  }

  public func deletePreset(_ preset: GameTypePreset) throws {
    try presetRepo.delete(preset)
    try presetRepo.save()
  }

  public func presets(includeArchived: Bool = false) throws -> [GameTypePreset] {
    let predicate: Predicate<GameTypePreset> = includeArchived ? #Predicate { _ in true } : #Predicate { $0.isArchived == false }
    let fd = FetchDescriptor<GameTypePreset>(predicate: predicate, sortBy: [SortDescriptor(\.lastModified, order: .reverse)])
    return try presetRepo.fetch(fd)
  }

  /// Get a preset by ID
  public func preset(id: UUID) throws -> GameTypePreset? {
    let fd = FetchDescriptor<GameTypePreset>(
      predicate: #Predicate { $0.id == id }
    )
    return try presetRepo.fetch(fd).first
  }

  /// Get presets by game type
  public func presets(gameType: GameType, includeArchived: Bool = false) throws -> [GameTypePreset] {
    let predicate: Predicate<GameTypePreset> = {
      if includeArchived {
        return #Predicate { $0.gameType == gameType }
      } else {
        return #Predicate { $0.gameType == gameType && $0.isArchived == false }
      }
    }()

    let fd = FetchDescriptor<GameTypePreset>(
      predicate: predicate,
      sortBy: [SortDescriptor(\.name, order: .forward)]
    )
    return try presetRepo.fetch(fd)
  }
}


