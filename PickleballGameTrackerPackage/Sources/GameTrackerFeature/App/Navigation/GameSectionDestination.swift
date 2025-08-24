//
//  GameSectionDestination.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 7/9/25.
//

import Foundation
import PickleballGameTrackerCorePackage

// MARK: - Game Section Destination

public indirect enum GameSectionDestination: Hashable, Sendable {
  case quickStart
  case allGames
  case recommended
  case beginnerFriendly
  case advancedPlay
  case testing
  case customizable
  case gameDetail(GameType)
  case sectionDetail(String, [GameType])  // title and gameTypes to avoid circular reference
}

// MARK: - GameSectionDestination Extensions

extension GameSectionDestination {
  var title: String {
    switch self {
    case .quickStart:
      return "Quick Start"
    case .allGames:
      return "All Game Types"
    case .recommended:
      return "Recommended"
    case .beginnerFriendly:
      return "Beginner Friendly"
    case .advancedPlay:
      return "Advanced Play"
    case .testing:
      return "Testing Suite"
    case .customizable:
      return "Customizable Games"
    case .gameDetail(let gameType):
      return gameType.displayName
    case .sectionDetail(let title, _):
      return title
    }
  }

  var gameTypes: [GameType] {
    switch self {
    case .quickStart:
      return GameType.quickStartTypes
    case .allGames:
      return GameType.allTypes
    case .recommended:
      return GameType.recommendedTypes
    case .beginnerFriendly:
      return GameType.beginnerTypes
    case .advancedPlay:
      return GameType.competitiveTypes
    case .testing:
      return GameType.testingTypes
    case .customizable:
      return GameType.customizableTypes
    case .gameDetail(_):
      return []
    case .sectionDetail(_, let gameTypes):
      return gameTypes
    }
  }
}
