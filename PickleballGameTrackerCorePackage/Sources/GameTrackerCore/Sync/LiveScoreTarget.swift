import Foundation

public struct LiveScoreTarget: Sendable {
  public let team: Int
  public let playerId: UUID?
  public let playerName: String?

  public init(team: Int, playerId: UUID? = nil, playerName: String? = nil) {
    self.team = team
    self.playerId = playerId
    self.playerName = playerName
  }

  public static func side(_ team: Int) -> LiveScoreTarget {
    LiveScoreTarget(team: team)
  }

  public static func player(team: Int, id: UUID, name: String) -> LiveScoreTarget {
    LiveScoreTarget(team: team, playerId: id, playerName: name)
  }

  public static func player(team: Int, player: PlayerProfile) -> LiveScoreTarget {
    LiveScoreTarget(team: team, playerId: player.id, playerName: player.name)
  }

  public static func resolved(team: Int, playerId: UUID?, playerName: String?) -> LiveScoreTarget {
    LiveScoreTarget(team: team, playerId: playerId, playerName: playerName)
  }
}


