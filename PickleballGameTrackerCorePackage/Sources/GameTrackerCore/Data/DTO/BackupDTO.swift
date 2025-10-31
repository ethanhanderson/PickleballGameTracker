//
//  BackupDTO.swift
//  SharedGameCore
//
//  Created by Agent on 9/8/25.
//

import Foundation

public enum BackupImportMode: String, Codable, Sendable {
  case merge
  case replace
}

public struct BackupFileDTO: Codable, Sendable {
  public let version: Int
  public let createdAt: Date

  public var games: [BackupGameDTO]
  public var players: [BackupPlayerDTO]
  public var teams: [BackupTeamDTO]
  public var presets: [BackupPresetDTO]

  public init(
    version: Int = 1,
    createdAt: Date = Date(),
    games: [BackupGameDTO] = [],
    players: [BackupPlayerDTO] = [],
    teams: [BackupTeamDTO] = [],
    presets: [BackupPresetDTO] = []
  ) {
    self.version = version
    self.createdAt = createdAt
    self.games = games
    self.players = players
    self.teams = teams
    self.presets = presets
  }
}

public struct BackupGameDTO: Codable, Sendable, Identifiable {
  public let id: UUID
  public let gameType: GameType
  public let score1: Int
  public let score2: Int
  public let isCompleted: Bool
  public let isArchived: Bool
  public let createdDate: Date
  public let completedDate: Date?
  public let lastModified: Date
  public let duration: TimeInterval?
  public let currentServer: Int
  public let serverNumber: Int
  public let serverPosition: ServerPosition
  public let sideOfCourt: SideOfCourt
  public let gameState: GameState
  public let isFirstServiceSequence: Bool
  public let winningScore: Int
  public let winByTwo: Bool
  public let kitchenRule: Bool
  public let doubleBounceRule: Bool
  public let sideSwitchingRule: SideSwitchingRule
  public let servingRotation: ServingRotation
  public let scoringType: ScoringType
  public let timeLimit: TimeInterval?
  public let maxRallies: Int?
  public let notes: String?
  public let totalRallies: Int
  public let team1Id: UUID?
  public let team2Id: UUID?
  public let team1PlayerIds: [UUID]
  public let team2PlayerIds: [UUID]

  public init(from game: Game) {
    self.id = game.id
    self.gameType = game.gameType
    self.score1 = game.score1
    self.score2 = game.score2
    self.isCompleted = game.isCompleted
    self.isArchived = game.isArchived
    self.createdDate = game.createdDate
    self.completedDate = game.completedDate
    self.lastModified = game.lastModified
    self.duration = game.duration
    self.currentServer = game.currentServer
    self.serverNumber = game.serverNumber
    self.serverPosition = game.serverPosition
    self.sideOfCourt = game.sideOfCourt
    self.gameState = game.gameState
    self.isFirstServiceSequence = game.isFirstServiceSequence
    self.winningScore = game.winningScore
    self.winByTwo = game.winByTwo
    self.kitchenRule = game.kitchenRule
    self.doubleBounceRule = game.doubleBounceRule
    self.sideSwitchingRule = game.sideSwitchingRule
    self.servingRotation = game.servingRotation
    self.scoringType = game.scoringType
    self.timeLimit = game.timeLimit
    self.maxRallies = game.maxRallies
    self.notes = game.notes
    self.totalRallies = game.totalRallies
    self.team1Id = nil
    self.team2Id = nil
    self.team1PlayerIds = []
    self.team2PlayerIds = []
  }
}

public struct BackupPlayerDTO: Codable, Sendable, Identifiable {
  public let id: UUID
  public let name: String
  public let notes: String?
  public let isArchived: Bool
  public let isGuest: Bool
  public let iconSymbolName: String?
  public let accentColor: StoredRGBAColor?
  public let skillLevel: PlayerSkillLevel
  public let preferredHand: PlayerHandedness
  public let createdDate: Date
  public let lastModified: Date

  public init(from player: PlayerProfile) {
    self.id = player.id
    self.name = player.name
    self.notes = player.notes
    self.isArchived = player.isArchived
    self.isGuest = player.isGuest
    self.iconSymbolName = player.iconSymbolName
    self.accentColor = player.accentColorStored
    self.skillLevel = player.skillLevel
    self.preferredHand = player.preferredHand
    self.createdDate = player.createdDate
    self.lastModified = player.lastModified
  }
}

public struct BackupTeamDTO: Codable, Sendable, Identifiable {
  public let id: UUID
  public let name: String
  public let notes: String?
  public let isArchived: Bool
  public let iconSymbolName: String?
  public let accentColor: StoredRGBAColor?
  public let playerIds: [UUID]
  public let suggestedGameType: GameType?
  public let createdDate: Date
  public let lastModified: Date

  public init(from team: TeamProfile) {
    self.id = team.id
    self.name = team.name
    self.notes = team.notes
    self.isArchived = team.isArchived
    self.iconSymbolName = team.iconSymbolName
    self.accentColor = team.accentColorStored
    self.playerIds = team.players.map { $0.id }
    self.suggestedGameType = team.suggestedGameType
    self.createdDate = team.createdDate
    self.lastModified = team.lastModified
  }
}

public struct BackupPresetDTO: Codable, Sendable, Identifiable {
  public let id: UUID
  public let name: String
  public let notes: String?
  public let isArchived: Bool
  public let gameType: GameType
  public let team1Id: UUID?
  public let team2Id: UUID?
  public let accentColor: StoredRGBAColor?
  public let createdDate: Date
  public let lastModified: Date

  public init(from preset: GameTypePreset) {
    self.id = preset.id
    self.name = preset.name
    self.notes = preset.notes
    self.isArchived = preset.isArchived
    self.gameType = preset.gameType
    self.team1Id = preset.team1?.id
    self.team2Id = preset.team2?.id
    self.accentColor = preset.accentColorStored
    self.createdDate = preset.createdDate
    self.lastModified = preset.lastModified
  }
}

