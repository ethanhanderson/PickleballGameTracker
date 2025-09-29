//
//  NavigationTypes.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 7/9/25.
//

import GameTrackerCore
import SwiftUI

// MARK: - App Tab Navigation

enum AppTab: String, CaseIterable {
  case games
  case history
  case search
  case statistics
  case roster
  case settings

  var displayName: String {
    switch self {
    case .games: return "Games"
    case .history: return "History"
    case .search: return "Search"
    case .statistics: return "Statistics"
    case .roster: return "Roster"
    case .settings: return "Settings"
    }
  }

  var systemImage: String {
    switch self {
    case .games: return "gamecontroller"
    case .history: return "clock"
    case .search: return "magnifyingglass"
    case .statistics: return "chart.bar"
    case .roster: return "person.2"
    case .settings: return "gear"
    }
  }
}

// MARK: - Navigation Destinations

enum GameHistoryDestination: Hashable {
  case gameDetail(UUID)
  case archiveList
}
