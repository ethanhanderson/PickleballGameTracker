//
//  GameEventFactory.swift
//  GameTrackerCore
//
//  Created by Ethan Anderson on 1/27/25.
//

import Foundation

/// Factory for generating realistic game events for previews and testing.
///
/// Provides fluent API for creating individual events and batch generation
/// for rally sequences and complete game narratives.
///
/// ## Usage
///
/// Individual event:
/// ```swift
/// let event = GameEventFactory(forGame: game)
///     .eventType(.playerScored)
///     .timestamp(45.0)
///     .teamAffected(1)
///     .description("Point scored")
///     .generate()
/// ```
///
/// Rally sequence:
/// ```swift
/// let rallyEvents = GameEventFactory.createRally(
///     startTime: 0,
///     duration: 30,
///     winner: 1
/// )
/// ```
///
/// Complete game narrative:
/// ```swift
/// let events = GameEventFactory.createRealisticGameNarrative(
///     for: game,
///     targetDuration: 1200
/// )
/// game.events = events
/// ```
@MainActor
public struct GameEventFactory {
    private var _game: Game
    private var _eventType: GameEventType?
    private var _timestamp: TimeInterval?
    private var _teamAffected: Int?
    private var _description: String?

    public init(forGame game: Game) {
        self._game = game
    }

    public func eventType(_ type: GameEventType) -> Self {
        var copy = self
        copy._eventType = type
        return copy
    }

    public func timestamp(_ time: TimeInterval) -> Self {
        var copy = self
        copy._timestamp = time
        return copy
    }

    public func teamAffected(_ team: Int?) -> Self {
        var copy = self
        copy._teamAffected = team
        return copy
    }

    public func description(_ text: String) -> Self {
        var copy = self
        copy._description = text
        return copy
    }

    public func generate() -> GameEvent {
        GameEvent(
            eventType: _eventType ?? .playerScored,
            timestamp: _timestamp ?? 0,
            customDescription: _description,
            teamAffected: _teamAffected
        )
    }
}

// MARK: - Rally Generation

extension GameEventFactory {
    /// Creates a single rally sequence with realistic event flow.
    ///
    /// A rally consists of:
    /// 1. Service initiation
    /// 2. Optional exchanges (hits, errors)
    /// 3. Rally conclusion (point scored)
    ///
    /// - Parameters:
    ///   - startTime: Starting timestamp for the rally
    ///   - duration: Total duration of the rally in seconds
    ///   - winner: Team that wins the rally (1 or 2)
    /// - Returns: Array of events representing the rally
    public static func createRally(
        startTime: TimeInterval,
        duration: TimeInterval,
        winner: Int
    ) -> [GameEvent] {
        var events: [GameEvent] = []
        var currentTime = startTime

        // 1. Service
        events.append(GameEvent(
            eventType: .serveChange,
            timestamp: currentTime,
            customDescription: "Service change",
            teamAffected: nil
        ))
        currentTime += Double.random(in: 3...8)

        // 2. Exchanges (0-3 hits/errors)
        let exchangeCount = Int.random(in: 0...3)
        for _ in 0..<exchangeCount {
            guard currentTime < startTime + duration else { break }
            
            let eventType: GameEventType = [
                .ballHitNet,
                .ballOutOfBounds,
                .kitchenViolation
            ].randomElement()!

            events.append(GameEvent(
                eventType: eventType,
                timestamp: currentTime,
                customDescription: nil,
                teamAffected: [1, 2].randomElement()
            ))
            currentTime += Double.random(in: 5...15)
        }

        // 3. Rally end (score)
        events.append(GameEvent(
            eventType: .playerScored,
            timestamp: min(currentTime, startTime + duration),
            customDescription: "Point scored",
            teamAffected: winner
        ))

        return events
    }

    /// Creates a service sequence with optional fault.
    ///
    /// - Parameter startTime: Starting timestamp for the service
    /// - Returns: Array of service-related events
    public static func createServiceSequence(startTime: TimeInterval) -> [GameEvent] {
        var events: [GameEvent] = []
        var currentTime = startTime

        // Service attempt
        events.append(GameEvent(
            eventType: .serveChange,
            timestamp: currentTime,
            customDescription: nil,
            teamAffected: nil
        ))
        currentTime += Double.random(in: 2...5)

        // Possible fault
        if Bool.random() {
            events.append(GameEvent(
                eventType: .serviceFault,
                timestamp: currentTime,
                customDescription: "Service fault",
                teamAffected: nil
            ))
        }

        return events
    }
}

// MARK: - Game Narrative Generation

extension GameEventFactory {
    /// Creates complete game narrative with realistic event flow.
    ///
    /// Generates a coherent sequence of events that tells the story of a complete game,
    /// including rallies, administrative events, and proper score tracking.
    ///
    /// - Parameters:
    ///   - game: The game to generate events for
    ///   - targetDuration: Target duration for the game in seconds
    /// - Returns: Array of events representing the complete game
    public static func createRealisticGameNarrative(
        for game: Game,
        targetDuration: TimeInterval
    ) -> [GameEvent] {
        var events: [GameEvent] = []
        var currentTime: TimeInterval = 0

        let totalPoints = game.score1 + game.score2
        let avgRallyDuration: TimeInterval = targetDuration / Double(max(totalPoints, 1))

        var currentScore1 = 0
        var currentScore2 = 0

        // Generate rallies for each point
        while currentScore1 < game.score1 || currentScore2 < game.score2 {
            let rallyDuration = avgRallyDuration * Double.random(in: 0.7...1.3)

            // Determine winner based on remaining points
            let winner: Int
            if currentScore1 < game.score1 && currentScore2 < game.score2 {
                winner = [1, 2].randomElement()!
            } else if currentScore1 < game.score1 {
                winner = 1
            } else {
                winner = 2
            }

            // Create rally
            let rallyEvents = createRally(
                startTime: currentTime,
                duration: rallyDuration,
                winner: winner
            )
            events.append(contentsOf: rallyEvents)

            // Update score
            if winner == 1 {
                currentScore1 += 1
            } else {
                currentScore2 += 1
            }

            currentTime += rallyDuration

            // Add administrative events at milestones
            if currentScore1 + currentScore2 == 6 {
                events.append(GameEvent(
                    eventType: .sideChange,
                    timestamp: currentTime,
                    customDescription: "Side change at 6 points",
                    teamAffected: nil
                ))
                currentTime += 15
            }
        }

        // Game completion
        events.append(GameEvent(
            eventType: .gameCompleted,
            timestamp: currentTime,
            customDescription: "Game completed",
            teamAffected: nil
        ))

        return events
    }

    /// Populates game with realistic event sequence.
    ///
    /// Convenience method that generates events and attaches them to the game.
    ///
    /// - Parameters:
    ///   - game: The game to populate with events
    ///   - eventCount: Maximum number of events to generate
    /// - Returns: The game with events populated
    @discardableResult
    public static func populateGameWithEvents(_ game: Game, eventCount: Int) -> Game {
        let estimatedDuration: TimeInterval = Double(game.totalRallies) * Double.random(in: 20...40)
        let events = createRealisticGameNarrative(for: game, targetDuration: estimatedDuration)

        game.events = Array(events.prefix(eventCount))
        return game
    }
}

// MARK: - Batch Event Generation

extension GameEventFactory {
    /// Generate sequence of events with time spacing.
    ///
    /// Creates multiple events of the same type with realistic time intervals.
    ///
    /// - Parameters:
    ///   - count: Number of events to generate
    ///   - startTime: Starting timestamp
    ///   - spacing: Range of time between events
    /// - Returns: Array of generated events
    public func generateSequence(
        count: Int,
        startTime: TimeInterval = 0,
        spacing: ClosedRange<TimeInterval> = 5...45
    ) -> [GameEvent] {
        var events: [GameEvent] = []
        var currentTime = startTime

        for _ in 0..<count {
            let event = GameEvent(
                eventType: _eventType ?? .playerScored,
                timestamp: currentTime,
                customDescription: _description,
                teamAffected: _teamAffected
            )
            events.append(event)
            currentTime += TimeInterval.random(in: spacing)
        }

        return events
    }
}
