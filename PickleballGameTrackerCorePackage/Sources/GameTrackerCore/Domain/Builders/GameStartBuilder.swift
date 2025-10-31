//
//  GameStartBuilder.swift
//  GameTrackerCore
//
//  Fluent builder for assembling game start configurations.
//

import Foundation

/// Fluent builder for creating game start configurations.
///
/// Guides the user through the natural flow of starting a game:
/// 1. Pick game type
/// 2. Choose team size (singles/doubles)
/// 3. Select participants (players or teams)
/// 4. Optionally add notes and variation
/// 5. Start the game via LiveGameStateManager
///
/// Example:
/// ```swift
/// let game = try await GameStartBuilder
///     .forType(.recreational)
///     .teamSize(.doubles)
///     .players(side1: [player1, player2], side2: [player3, player4])
///     .notes("Weekend match")
///     .start(using: liveGameManager)
/// ```
public struct GameStartBuilder {
    private let gameType: GameType
    private var teamSize: TeamSize?
    private var participants: Participants?
    private var notes: String?
    private var rules: GameRules?
    
    private init(gameType: GameType) {
        self.gameType = gameType
    }
    
    // MARK: - Factory
    
    /// Start building a game configuration for the specified type.
    public static func forType(_ type: GameType) -> GameStartBuilder {
        GameStartBuilder(gameType: type)
    }
    
    // MARK: - Configuration
    
    /// Set the team size (singles or doubles).
    public func teamSize(_ size: TeamSize) -> Self {
        var copy = self
        copy.teamSize = size
        return copy
    }
    
    /// Set participants as individual players for both sides.
    ///
    /// - Parameters:
    ///   - side1: Player IDs for side 1 (1 for singles, 2 for doubles)
    ///   - side2: Player IDs for side 2 (1 for singles, 2 for doubles)
    public func players(side1: [UUID], side2: [UUID]) -> Self {
        var copy = self
        copy.participants = Participants(
            side1: .players(side1),
            side2: .players(side2)
        )
        return copy
    }
    
    /// Set participants as teams.
    ///
    /// - Parameters:
    ///   - team1: Team ID for side 1
    ///   - team2: Team ID for side 2
    public func teams(team1: UUID, team2: UUID) -> Self {
        var copy = self
        copy.participants = Participants(
            side1: .team(team1),
            side2: .team(team2)
        )
        return copy
    }
    
    /// Add optional notes for the game.
    public func notes(_ text: String?) -> Self {
        var copy = self
        copy.notes = text
        return copy
    }
    
    /// Provide specific game rules.
    ///
    /// If not provided, defaults will be derived from the game type.
    public func rules(_ r: GameRules) -> Self {
        var copy = self
        copy.rules = r
        return copy
    }
    
    // MARK: - Build & Start
    
    /// Build the configuration without starting the game.
    ///
    /// Validates that team size and participants are set and compatible.
    ///
    /// - Throws: `GameRulesError` if configuration is invalid
    public func build() throws -> GameStartConfiguration {
        guard let teamSize = teamSize else {
            throw GameRulesError.invalidConfiguration("Team size must be set before building")
        }
        
        guard let participants = participants else {
            throw GameRulesError.invalidConfiguration("Participants must be set before building")
        }
        
        // Validate participant counts match team size
        try validateParticipants(participants, teamSize: teamSize)
        
        return GameStartConfiguration(
            gameType: gameType,
            teamSize: teamSize,
            participants: participants,
            notes: notes,
            rules: rules
        )
    }
    
    /// Build and start the game using the provided manager.
    ///
    /// This is the primary entry point for starting games. The manager will
    /// validate the configuration, persist the game, and set it as current.
    ///
    /// - Parameter manager: The live game state manager to use
    /// - Returns: The newly created and started game
    /// - Throws: `GameRulesError` if configuration is invalid, or persistence errors
    @MainActor
    public func start(using manager: LiveGameStateManager) async throws -> Game {
        let config = try build()
        return try await manager.startNewGame(with: config)
    }
    
    // MARK: - Validation
    
    private func validateParticipants(_ participants: Participants, teamSize: TeamSize) throws {
        switch (participants.side1, participants.side2, teamSize) {
        case (.players(let a), .players(let b), .singles):
            guard a.count == 1 && b.count == 1 else {
                throw GameRulesError.invalidConfiguration(
                    "Singles requires exactly 1 player per side (got \(a.count) vs \(b.count))"
                )
            }
            
        case (.players(let a), .players(let b), .doubles):
            guard a.count == 2 && b.count == 2 else {
                throw GameRulesError.invalidConfiguration(
                    "Doubles requires exactly 2 players per side (got \(a.count) vs \(b.count))"
                )
            }
            
        case (.team, .team, .doubles):
            // Teams are valid for doubles
            break
            
        case (.team, .team, .singles):
            throw GameRulesError.invalidConfiguration(
                "Singles cannot use team participants"
            )
            
        default:
            throw GameRulesError.invalidConfiguration(
                "Both sides must use the same participant type (players or teams)"
            )
        }
    }
}

