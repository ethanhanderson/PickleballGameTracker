//
//  GameVariationFactory.swift
//  GameTrackerCore
//
//  Created on 2025-09-29.
//

import Foundation
import SwiftData

/// Factory for generating game variation instances with validated, flexible configuration.
///
/// ## Overview
/// Provides a fluent builder-style API with comprehensive presets for creating validated game variations.
/// Wraps `GameVariation.createValidated()` to ensure all generated variations meet validation requirements.
/// Enables catalog generation, matchup-specific variations, and realistic rule combinations.
///
/// ## Basic Usage
/// ```swift
/// let variation = GameVariationFactory()
///     .name("Quick Match")
///     .gameType(.recreational)
///     .winningScore(7)
///     .generate()
/// ```
///
/// ## Catalog Generation
/// ```swift
/// let catalog = GameVariationFactory.realisticCatalog(count: 15)
/// let standard = GameVariationFactory.standardCatalog()
/// ```
///
/// ## Convenience Presets
/// ```swift
/// let quick = GameVariationFactory.quickGame()
/// let tournament = GameVariationFactory.tournamentGame()
/// let championship = GameVariationFactory.championshipGame()
/// ```
@MainActor
public struct GameVariationFactory {
    
    // MARK: - Configuration Properties
    
    private var _name: String?
    private var _gameType: GameType?
    private var _teamSize: Int?
    private var _winningScore: Int = 11
    private var _winByTwo: Bool = true
    private var _kitchenRule: Bool = true
    private var _doubleBounceRule: Bool = true
    private var _scoringType: ScoringType = .sideOut
    private var _servingRotation: ServingRotation = .standard
    private var _sideSwitchingRule: SideSwitchingRule = .at6Points
    private var _timeLimit: TimeInterval?
    private var _maxRallies: Int?
    private var _isDefault: Bool = false
    private var _isCustom: Bool = false
    private var _description: String?
    private var _tags: [String] = []
    
    // MARK: - Initialization
    
    /// Creates a new factory instance with default configuration
    public init() {}
    
    // MARK: - Name Configuration
    
    /// Sets the variation name
    public func name(_ name: String) -> Self {
        var copy = self
        copy._name = name
        return copy
    }
    
    // MARK: - Game Type Configuration
    
    /// Sets the game type
    public func gameType(_ type: GameType) -> Self {
        var copy = self
        copy._gameType = type
        return copy
    }
    
    /// Sets the team size (1-6 players per team)
    public func teamSize(_ size: Int) -> Self {
        var copy = self
        copy._teamSize = size
        return copy
    }
    
    // MARK: - Scoring Configuration
    
    /// Sets the winning score (1-50 points)
    public func winningScore(_ score: Int) -> Self {
        var copy = self
        copy._winningScore = score
        return copy
    }
    
    /// Sets whether win-by-two is required
    public func winByTwo(_ required: Bool) -> Self {
        var copy = self
        copy._winByTwo = required
        return copy
    }
    
    /// Sets the scoring type
    public func scoringType(_ type: ScoringType) -> Self {
        var copy = self
        copy._scoringType = type
        return copy
    }
    
    // MARK: - Rule Configuration
    
    /// Sets whether the kitchen (non-volley zone) rule applies
    public func kitchenRule(_ enabled: Bool) -> Self {
        var copy = self
        copy._kitchenRule = enabled
        return copy
    }
    
    /// Sets whether the double-bounce rule applies
    public func doubleBounceRule(_ enabled: Bool) -> Self {
        var copy = self
        copy._doubleBounceRule = enabled
        return copy
    }
    
    /// Sets the serving rotation pattern
    public func servingRotation(_ rotation: ServingRotation) -> Self {
        var copy = self
        copy._servingRotation = rotation
        return copy
    }
    
    /// Sets the side switching rule
    public func sideSwitchingRule(_ rule: SideSwitchingRule) -> Self {
        var copy = self
        copy._sideSwitchingRule = rule
        return copy
    }
    
    // MARK: - Game Format Configuration
    
    /// Sets a time limit in seconds (60-7200 seconds)
    public func timeLimit(seconds: TimeInterval) -> Self {
        var copy = self
        copy._timeLimit = seconds
        return copy
    }
    
    /// Sets a time limit in minutes
    public func timeLimit(minutes: Int) -> Self {
        var copy = self
        copy._timeLimit = TimeInterval(minutes * 60)
        return copy
    }
    
    /// Sets the maximum number of rallies (1-1000)
    public func maxRallies(_ rallies: Int) -> Self {
        var copy = self
        copy._maxRallies = rallies
        return copy
    }
    
    // MARK: - Metadata Configuration
    
    /// Marks the variation as a default variation
    public func asDefault(_ isDefault: Bool = true) -> Self {
        var copy = self
        copy._isDefault = isDefault
        return copy
    }
    
    /// Marks the variation as custom
    public func asCustom(_ isCustom: Bool = true) -> Self {
        var copy = self
        copy._isCustom = isCustom
        return copy
    }
    
    /// Sets the variation description
    public func description(_ text: String) -> Self {
        var copy = self
        copy._description = text
        return copy
    }
    
    /// Sets the variation tags
    public func tags(_ tags: [String]) -> Self {
        var copy = self
        copy._tags = tags
        return copy
    }
    
    // MARK: - Generation
    
    /// Generates a validated game variation
    ///
    /// - Returns: A validated `GameVariation` instance
    /// - Throws: `GameVariationError` if validation fails
    public func generate() throws(GameVariationError) -> GameVariation {
        let variation = try GameVariation.createValidated(
            name: _name ?? "Custom Game",
            gameType: _gameType ?? .recreational,
            teamSize: _teamSize,
            winningScore: _winningScore,
            winByTwo: _winByTwo,
            kitchenRule: _kitchenRule,
            doubleBounceRule: _doubleBounceRule,
            servingRotation: _servingRotation,
            sideSwitchingRule: _sideSwitchingRule,
            scoringType: _scoringType,
            timeLimit: _timeLimit,
            maxRallies: _maxRallies,
            isCustom: _isCustom
        )
        
        variation.gameDescription = _description
        variation.tags = _tags
        
        return variation
    }
}

// MARK: - Catalog Generation

extension GameVariationFactory {
    /// Recreates the standard catalog from GameVariation.createDefaultVariations()
    ///
    /// This provides the full default catalog of variations as defined in the model.
    public static func standardCatalog() -> [GameVariation] {
        GameVariation.createDefaultVariations()
    }
    
    /// Generates a realistic catalog with proper distribution of game types
    ///
    /// Distribution:
    /// - 40% Recreational
    /// - 25% Tournament
    /// - 20% Training
    /// - 15% Social/Custom
    ///
    /// - Parameter count: Number of variations to generate (default: 15)
    /// - Returns: Array of validated game variations
    public static func realisticCatalog(count: Int = 15) -> [GameVariation] {
        var variations: [GameVariation] = []
        
        for i in 0..<count {
            let roll = Int.random(in: 1...100)
            
            let (gameType, winningScore, scoringType): (GameType, Int, ScoringType)
            
            switch roll {
            case 1...40:
                gameType = .recreational
                winningScore = 11
                scoringType = .sideOut
            case 41...65:
                gameType = .tournament
                winningScore = [11, 15].randomElement()!
                scoringType = .sideOut
            case 66...85:
                gameType = .training
                winningScore = 7
                scoringType = .sideOut
            default:
                gameType = [.social, .custom].randomElement()!
                winningScore = [9, 11, 15].randomElement()!
                scoringType = [.sideOut, .rally].randomElement()!
            }
            
            let variation = try! GameVariationFactory()
                .name("\(gameType.displayName) \(i + 1)")
                .gameType(gameType)
                .winningScore(winningScore)
                .scoringType(scoringType)
                .generate()
            
            variations.append(variation)
        }
        
        return variations
    }
    
    /// Generates a large catalog for performance testing
    ///
    /// - Parameter count: Number of variations to generate (default: 50)
    /// - Returns: Array of validated game variations
    public static func performanceCatalog(count: Int = 50) -> [GameVariation] {
        realisticCatalog(count: count)
    }
}

// MARK: - Matchup Variations

extension GameVariationFactory {
    /// Creates a variation configured for a specific player matchup
    ///
    /// Generates appropriate name and team size based on the number of players.
    /// For 2 players: "Player1 vs Player2" (singles)
    /// For 4+ players: "Player1 & Player2 vs Player3 & Player4" (doubles)
    ///
    /// - Parameters:
    ///   - players: Array of players participating in the matchup
    ///   - gameType: Type of game (default: .recreational)
    /// - Returns: A validated game variation configured for the matchup
    public static func forMatchup(players: [PlayerProfile], gameType: GameType = .recreational) -> GameVariation {
        let name = generateMatchupName(from: players)
        let teamSize = players.count / 2
        
        return try! GameVariationFactory()
            .name(name)
            .gameType(gameType)
            .teamSize(teamSize)
            .asCustom(true)
            .generate()
    }
    
    /// Creates a variation configured for a specific team matchup
    ///
    /// Uses team names and sizes to generate appropriate variation.
    ///
    /// - Parameters:
    ///   - teams: Array of teams participating in the matchup
    ///   - gameType: Type of game (default: .recreational)
    /// - Returns: A validated game variation configured for the matchup
    public static func forMatchup(teams: [TeamProfile], gameType: GameType = .recreational) -> GameVariation {
        guard let firstTeam = teams.first else {
            return try! GameVariationFactory().gameType(gameType).generate()
        }
        
        let name = teams.map { $0.name }.joined(separator: " vs ")
        
        return try! GameVariationFactory()
            .name(name)
            .gameType(gameType)
            .teamSize(firstTeam.teamSize)
            .asCustom(true)
            .generate()
    }
    
    /// Generates a matchup name from player profiles
    ///
    /// - Parameter players: Array of player profiles
    /// - Returns: Formatted matchup name
    private static func generateMatchupName(from players: [PlayerProfile]) -> String {
        if players.count == 2 {
            return "\(players[0].name) vs \(players[1].name)"
        } else {
            let half = players.count / 2
            let team1 = players[..<half].map { $0.name }.joined(separator: " & ")
            let team2 = players[half...].map { $0.name }.joined(separator: " & ")
            return "\(team1) vs \(team2)"
        }
    }
}

// MARK: - Convenience Presets

extension GameVariationFactory {
    /// Creates a quick game variation (7 points, no win-by-two)
    public static func quickGame() -> GameVariation {
        try! GameVariationFactory()
            .name("Quick Game")
            .winningScore(7)
            .winByTwo(false)
            .generate()
    }
    
    /// Creates a standard game variation (11 points, traditional rules)
    public static func standardGame() -> GameVariation {
        try! GameVariationFactory()
            .name("Standard Game")
            .winningScore(11)
            .generate()
    }
    
    /// Creates a tournament game variation
    public static func tournamentGame() -> GameVariation {
        try! GameVariationFactory()
            .name("Tournament")
            .gameType(.tournament)
            .winningScore(11)
            .generate()
    }
    
    /// Creates a championship game variation (15 points)
    public static func championshipGame() -> GameVariation {
        try! GameVariationFactory()
            .name("Championship")
            .gameType(.tournament)
            .winningScore(15)
            .generate()
    }
    
    /// Creates a rally scoring variation (15 points)
    public static func rallyScoring() -> GameVariation {
        try! GameVariationFactory()
            .name("Rally Scoring")
            .scoringType(.rally)
            .winningScore(15)
            .generate()
    }
    
    /// Creates a timed game variation
    ///
    /// - Parameter minutes: Duration of the game in minutes
    /// - Returns: A validated game variation with time limit
    public static func timedGame(minutes: Int) -> GameVariation {
        try! GameVariationFactory()
            .name("\(minutes)-Minute Game")
            .timeLimit(minutes: minutes)
            .generate()
    }
}
