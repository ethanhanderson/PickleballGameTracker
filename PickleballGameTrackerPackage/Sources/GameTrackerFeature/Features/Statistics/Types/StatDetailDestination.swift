import Foundation

public enum StatDetailDestination: Hashable {
  case winRate(filters: StatisticsFilters)
  case serveWin(filters: StatisticsFilters)
  case trends(filters: StatisticsFilters)
  case streaks(filters: StatisticsFilters)
}


