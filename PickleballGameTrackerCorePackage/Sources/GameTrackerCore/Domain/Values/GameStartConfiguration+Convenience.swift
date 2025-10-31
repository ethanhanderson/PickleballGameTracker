//
//  GameStartConfiguration+Convenience.swift
//  GameTrackerCore
//
//  Convenience extensions for creating GameStartConfiguration from UI types.
//

import Foundation

extension GameStartConfiguration {
  /// Create a configuration from a MatchupSelection (UI type).
  ///
  /// This is a convenience for UI code that receives `MatchupSelection` from setup flows
  /// and needs to convert it to the core `GameStartConfiguration` type.
  ///
  /// - Parameters:
  ///   - gameType: The game type being played
  ///   - matchup: The matchup selection from the UI
  ///   - rules: Optional custom rules; defaults will be derived if nil
  ///   - notes: Optional game notes
  public init(
    gameType: GameType,
    matchup: MatchupSelection,
    rules: GameRules? = nil,
    notes: String? = nil
  ) {
    let teamSize = TeamSize(playersPerSide: matchup.teamSize) ?? .doubles
    
    let participants: Participants
    switch matchup.mode {
    case .players(let sideA, let sideB):
      participants = Participants(side1: .players(sideA), side2: .players(sideB))
    case .teams(let team1Id, let team2Id):
      participants = Participants(side1: .team(team1Id), side2: .team(team2Id))
    }
    
    self.init(
      gameType: gameType,
      teamSize: teamSize,
      participants: participants,
      notes: notes,
      rules: rules
    )
  }
}

