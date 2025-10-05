//
//  ActiveGameFactory.swift
//  GameTrackerCore
//
//  Created on 9/30/25.
//

import Foundation
import SwiftData

/// Factory for generating active/in-progress game instances for previews and testing.
///
/// ## Overview
/// Provides a fluent builder-style API with realistic defaults for creating games
/// in various states (playing, paused, serving). Generates realistic correlations
/// between scores, rallies, and elapsed time.
///
/// ## Basic Usage
/// ```swift
/// let game = ActiveGameFactory()
///     .scores(7, 5)
///     .state(.playing)
///     .generate()
/// ```
///
/// ## Presets
/// ```swift
/// let early = ActiveGameFactory.earlyGame()
/// let mid = ActiveGameFactory.midGame()
/// let close = ActiveGameFactory.closeGame()
/// ```
@MainActor
public struct ActiveGameFactory {

    // MARK: - Configuration Properties

    private var _gameType: GameType?
    private var _gameVariation: GameVariation?
    private var _score1: Int?
    private var _score2: Int?
    private var _currentServer: Int?
    private var _serverNumber: Int?
    private var _serverPosition: ServerPosition?
    private var _sideOfCourt: SideOfCourt?
    private var _gameState: GameState?
    private var _isFirstServiceSequence: Bool?
    private var _winningScore: Int?
    private var _winByTwo: Bool?
    private var _rallies: Int?
    private var _elapsedTime: TimeInterval?
    private var _notes: String?
    private var _context: ModelContext?

    // MARK: - Initialization

    /// Creates a new factory instance.
    ///
    /// - Parameter context: Optional ModelContext for accessing variations and roster
    public init(context: ModelContext? = nil) {
        self._context = context
    }

    // MARK: - Game Type Configuration

    public func gameType(_ type: GameType) -> Self {
        var copy = self
        copy._gameType = type
        return copy
    }

    public func variation(_ variation: GameVariation) -> Self {
        var copy = self
        copy._gameVariation = variation
        copy._gameType = variation.gameType
        return copy
    }

    // MARK: - Score Configuration

    public func scores(_ score1: Int, _ score2: Int) -> Self {
        var copy = self
        copy._score1 = score1
        copy._score2 = score2
        return copy
    }

    public func atMatchPoint(leader: Int) -> Self {
        var copy = self
        if leader == 1 {
            copy._score1 = 10
            copy._score2 = Int.random(in: 8...9)
        } else {
            copy._score1 = Int.random(in: 8...9)
            copy._score2 = 10
        }
        return copy
    }

    public func tiedScore(_ score: Int) -> Self {
        var copy = self
        copy._score1 = score
        copy._score2 = score
        return copy
    }

    public func earlyGame() -> Self {
        var copy = self
        copy._score1 = Int.random(in: 0...3)
        copy._score2 = Int.random(in: 0...3)
        return copy
    }

    public func midGame() -> Self {
        var copy = self
        copy._score1 = Int.random(in: 4...7)
        copy._score2 = Int.random(in: 4...7)
        return copy
    }

    public func lateGame() -> Self {
        var copy = self
        copy._score1 = Int.random(in: 8...10)
        copy._score2 = Int.random(in: 8...10)
        return copy
    }

    // MARK: - Game State Configuration

    public func state(_ state: GameState) -> Self {
        var copy = self
        copy._gameState = state
        return copy
    }

    public func server(team: Int, player: Int = 1) -> Self {
        var copy = self
        copy._currentServer = team
        copy._serverNumber = player
        return copy
    }

    public func serverPosition(_ position: ServerPosition) -> Self {
        var copy = self
        copy._serverPosition = position
        return copy
    }

    public func sideOfCourt(_ side: SideOfCourt) -> Self {
        var copy = self
        copy._sideOfCourt = side
        return copy
    }

    public func firstServiceSequence(_ isFirst: Bool) -> Self {
        var copy = self
        copy._isFirstServiceSequence = isFirst
        return copy
    }

    // MARK: - Game Metrics Configuration

    public func rallies(_ count: Int) -> Self {
        var copy = self
        copy._rallies = count
        return copy
    }

    public func elapsedTime(minutes: Int) -> Self {
        var copy = self
        copy._elapsedTime = TimeInterval(minutes * 60)
        return copy
    }

    public func elapsedTime(seconds: TimeInterval) -> Self {
        var copy = self
        copy._elapsedTime = seconds
        return copy
    }

    // MARK: - Additional Configuration

    public func notes(_ text: String) -> Self {
        var copy = self
        copy._notes = text
        return copy
    }

    public func winningScore(_ score: Int) -> Self {
        var copy = self
        copy._winningScore = score
        return copy
    }

    public func winByTwo(_ required: Bool) -> Self {
        var copy = self
        copy._winByTwo = required
        return copy
    }

    // MARK: - Generation

    public func generate() -> Game {
        let gameType = _gameType ?? [.recreational, .tournament, .training].randomElement()!
        let variation = _gameVariation
        let winningScore = _winningScore ?? variation?.winningScore ?? 11

        let score1 = _score1 ?? Int.random(in: 0...10)
        let score2 = _score2 ?? Int.random(in: 0...10)

        let game: Game
        if let variation = variation {
            game = Game(gameVariation: variation)
        } else {
            game = Game(gameType: gameType)
        }

        game.score1 = min(score1, winningScore)
        game.score2 = min(score2, winningScore)
        game.gameState = _gameState ?? .playing
        game.currentServer = _currentServer ?? [1, 2].randomElement()!
        game.serverNumber = _serverNumber ?? (game.gameVariation?.teamSize ?? 2 >= 2 ? [1, 2].randomElement()! : 1)
        game.serverPosition = _serverPosition ?? ((score1 + score2).isMultiple(of: 2) ? .right : .left)
        game.sideOfCourt = _sideOfCourt ?? .side1
        game.isFirstServiceSequence = _isFirstServiceSequence ?? true
        game.totalRallies = _rallies ?? estimateRallies(score1: game.score1, score2: game.score2)
        game.notes = _notes
        game.lastModified = Date()

        return game
    }

    // MARK: - Batch Generation

    public static func batch(count: Int) -> [Game] {
        (0..<count).map { _ in ActiveGameFactory().generate() }
    }

    public static func batch(count: Int, configure: (ActiveGameFactory) -> ActiveGameFactory) -> [Game] {
        (0..<count).map { _ in configure(ActiveGameFactory()).generate() }
    }

    // MARK: - Private Helpers

    private func estimateRallies(score1: Int, score2: Int) -> Int {
        let totalPoints = score1 + score2
        let baseRallies = totalPoints
        let variance = Int.random(in: 0...5)
        return max(totalPoints, baseRallies + variance)
    }

    private func estimateElapsedTime(rallies: Int) -> TimeInterval {
        let avgSecondsPerRally = Double.random(in: 15...45)
        return Double(rallies) * avgSecondsPerRally
    }
}

// MARK: - Convenience Presets

extension ActiveGameFactory {

    /// Early game state (scores 0-3, low rallies)
    public static func earlyGame() -> Game {
        ActiveGameFactory()
            .earlyGame()
            .state(.playing)
            .generate()
    }

    /// Mid-game state (scores 4-7, moderate rallies)
    public static func midGame() -> Game {
        ActiveGameFactory()
            .midGame()
            .state(.playing)
            .generate()
    }

    /// Close game state (scores 8-10, high rallies)
    public static func closeGame() -> Game {
        ActiveGameFactory()
            .lateGame()
            .state(.playing)
            .generate()
    }

    /// Match point scenario (leader at 10, opponent at 8-9)
    public static func matchPoint() -> Game {
        ActiveGameFactory()
            .atMatchPoint(leader: [1, 2].randomElement()!)
            .state(.playing)
            .generate()
    }

    /// Paused game (random scores, paused state)
    public static func pausedGame() -> Game {
        ActiveGameFactory()
            .scores(Int.random(in: 3...7), Int.random(in: 3...7))
            .state(.paused)
            .generate()
    }

    /// Serving state (random scores, serving state)
    public static func servingState() -> Game {
        ActiveGameFactory()
            .scores(Int.random(in: 2...8), Int.random(in: 2...8))
            .state(.serving)
            .generate()
    }
}

