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
    let rec = GameVariation(
      name: "Recreational Doubles",
      gameType: .recreational,
      teamSize: 2,
      winningScore: 11,
      winByTwo: true
    )
    context.insert(rec)

    let tour = GameVariation(
      name: "Tournament Doubles",
      gameType: .tournament,
      teamSize: 2,
      winningScore: 15,
      winByTwo: true
    )
    context.insert(tour)
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
    let p1 = PlayerProfile(
      name: "Ethan",
      iconSymbolName: "tennis.racket",
      accentColor: StoredRGBAColor(Color.blue),
      skillLevel: .advanced,
      preferredHand: .right
    )
    let p2 = PlayerProfile(
      name: "Reed",
      iconSymbolName: "figure.tennis",
      accentColor: StoredRGBAColor(Color.green),
      skillLevel: .intermediate,
      preferredHand: .right
    )
    let p3 = PlayerProfile(
      name: "Ricky",
      iconSymbolName: "figure.walk",
      accentColor: StoredRGBAColor(Color.orange),
      skillLevel: .beginner,
      preferredHand: .left
    )
    let p4 = PlayerProfile(
      name: "Dave",
      iconSymbolName: "medal.fill",
      accentColor: StoredRGBAColor(Color.purple),
      skillLevel: .expert,
      preferredHand: .right
    )

    let archived1 = PlayerProfile(
      name: "Alex",
      iconSymbolName: "person.fill",
      accentColor: StoredRGBAColor(Color.brown),
      skillLevel: .intermediate,
      preferredHand: .right
    )
    archived1.isArchived = true

    let archived2 = PlayerProfile(
      name: "Jordan",
      iconSymbolName: "person.fill",
      accentColor: StoredRGBAColor(Color.indigo),
      skillLevel: .advanced,
      preferredHand: .left
    )
    archived2.isArchived = true

    for p in [p1, p2, p3, p4, archived1, archived2] { context.insert(p) }

    let t1 = TeamProfile(
      name: "Ethan & Reed",
      iconSymbolName: "person.2.fill",
      accentColor: StoredRGBAColor(Color.teal),
      players: [p1, p2]
    )
    let t2 = TeamProfile(
      name: "Ricky & Dave",
      iconSymbolName: "figure.mind.and.body",
      accentColor: StoredRGBAColor(Color.pink),
      players: [p3, p4]
    )
    let archivedTeam1 = TeamProfile(
      name: "Alex & Jordan",
      iconSymbolName: "person.2.fill",
      accentColor: StoredRGBAColor(Color.brown),
      players: [archived1, archived2]
    )
    archivedTeam1.isArchived = true

    let archivedTeam2 = TeamProfile(
      name: "Old Veterans",
      iconSymbolName: "trophy.fill",
      accentColor: StoredRGBAColor(Color.indigo),
      players: [p1, p4]
    )
    archivedTeam2.isArchived = true

    for t in [t1, t2, archivedTeam1, archivedTeam2] { context.insert(t) }
  }
}


