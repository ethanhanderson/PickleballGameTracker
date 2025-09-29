import GameTrackerCore
import Foundation

enum GroupingOption: String, CaseIterable, Identifiable {
  case none = "none"
  case gameType = "gameType"
  case date = "date"
  case winnerLose = "winnerLose"

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .none: return "No Grouping"
    case .gameType: return "Game Type"
    case .date: return "Date"
    case .winnerLose: return "Win/Loss"
    }
  }

  var description: String {
    switch self {
    case .none: return "Show all games in chronological order"
    case .gameType: return "Group games by type (Singles, Doubles, Traditional)"
    case .date: return "Group games by date played"
    case .winnerLose: return "Group games by whether you won or lost"
    }
  }

  var systemImage: String {
    switch self {
    case .none: return "list.bullet"
    case .gameType: return "gamecontroller.fill"
    case .date: return "calendar"
    case .winnerLose: return "trophy.fill"
    }
  }
}

enum GameFilter: Identifiable, Hashable {
  case all
  case gameType(GameType)
  case wins
  case losses

  var id: String {
    switch self {
    case .all: return "all"
    case .gameType(let type): return "gameType_\(type.rawValue)"
    case .wins: return "wins"
    case .losses: return "losses"
    }
  }

  var displayName: String {
    switch self {
    case .all: return "All Games"
    case .gameType(let type): return type.displayName
    case .wins: return "Wins"
    case .losses: return "Losses"
    }
  }

  static var allFilters: [GameFilter] {
    var filters: [GameFilter] = [.all]
    filters.append(contentsOf: GameCatalog.allGameTypes.map { .gameType($0) })
    filters.append(contentsOf: [.wins, .losses])
    return filters
  }
}

struct GroupedGames: Identifiable {
  var id: String { title }
  let title: String
  let games: [Game]
}


