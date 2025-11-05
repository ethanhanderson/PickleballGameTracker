//
//  StartGameRequestDTO.swift
//  GameTrackerCore
//

import Foundation

public struct StartGameRequestDTO: Codable, Sendable {
  public let gameType: GameType
  
  public init(gameType: GameType) {
    self.gameType = gameType
  }
}

