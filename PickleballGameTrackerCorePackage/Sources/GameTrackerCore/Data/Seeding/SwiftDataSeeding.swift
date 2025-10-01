import Foundation
import SwiftData
import SwiftUI

@MainActor
public enum SwiftDataSeeding {
  public static func seedDefaultVariations(into context: ModelContext) {
    let variations = GameVariation.createDefaultVariations()
    for v in variations { context.insert(v) }
  }

  public static func seedCommonVariations(into context: ModelContext) {
    let variations = [
      try! GameVariationFactory()
        .name("Recreational Doubles")
        .gameType(.recreational)
        .teamSize(2)
        .winningScore(11)
        .winByTwo(true)
        .generate(),
      
      try! GameVariationFactory()
        .name("Tournament Doubles")
        .gameType(.tournament)
        .teamSize(2)
        .winningScore(15)
        .winByTwo(true)
        .generate()
    ]
    
    for variation in variations {
      context.insert(variation)
    }
  }

  public static func seedGames(from templates: [Game], into context: ModelContext) {
    for template in templates {
      let g = Game(gameType: template.gameType)
      g.score1 = template.score1
      g.score2 = template.score2
      g.currentServer = template.currentServer
      g.serverNumber = template.serverNumber
      g.totalRallies = template.totalRallies
      g.createdDate = template.createdDate
      g.lastModified = template.lastModified
      g.isArchived = template.isArchived
      if template.isCompleted {
        g.completedDate = template.completedDate
        g.duration = template.duration
      }
      context.insert(g)
    }
  }

  public static func seedRoster(players: [PlayerProfile], teams: [TeamProfile], into context: ModelContext) {
    var oldIdToNewPlayer: [UUID: PlayerProfile] = [:]
    for src in players {
      let clone = PlayerProfile(
        id: src.id,
        name: src.name,
        notes: src.notes,
        isArchived: src.isArchived,
        avatarImageData: src.avatarImageData,
        iconSymbolName: src.iconSymbolName,
        accentColor: src.accentColorStored,
        skillLevel: src.skillLevel,
        preferredHand: src.preferredHand,
        createdDate: src.createdDate,
        lastModified: .now
      )
      context.insert(clone)
      oldIdToNewPlayer[src.id] = clone
    }

    for src in teams {
      let remappedPlayers: [PlayerProfile] = src.players.compactMap { oldIdToNewPlayer[$0.id] }
      let clone = TeamProfile(
        id: src.id,
        name: src.name,
        notes: src.notes,
        isArchived: src.isArchived,
        avatarImageData: src.avatarImageData,
        iconSymbolName: src.iconSymbolName,
        accentColor: src.accentColorStored,
        players: remappedPlayers,
        suggestedGameType: src.suggestedGameType,
        createdDate: src.createdDate,
        lastModified: .now
      )
      context.insert(clone)
    }

    do {
      let activeTeams = try context.fetch(
        FetchDescriptor<TeamProfile>(predicate: #Predicate { $0.isArchived == false })
      )
      for (_, player) in oldIdToNewPlayer where player.isArchived == false {
        let hasNamedTeam = activeTeams.contains { team in
          team.players.contains(where: { $0.id == player.id })
            && team.name.localizedCaseInsensitiveContains(player.name)
        }
        if hasNamedTeam == false {
          let solo = TeamProfile(
            name: player.name,
            avatarImageData: nil,
            iconSymbolName: "person.fill",
            accentColor: player.accentColorStored,
            players: [player]
          )
          context.insert(solo)
        }
      }
    } catch {
      // Non-fatal for seeding
    }
  }

  public static func seedSampleRoster(into context: ModelContext) {
    let (players, teams) = TeamProfileFactory.realisticTeams(playerCount: 12, teamSize: 2)

    for player in players {
      context.insert(player)
    }

    for team in teams {
      context.insert(team)
    }
  }
}


