//
//  GameEvent.swift
//  SharedGameCore
//
//  Created by Ethan Anderson on 7/9/25.
//

import Foundation
import SwiftData

/// Represents different types of game events that can occur during a pickleball game
public enum GameEventType: String, Codable, CaseIterable {
    // Scoring events
    case playerScored = "Player Scored"
    case scoreUndone = "Score Undone"

    // Serving events
    case ballOutOfBounds = "Out of Bounds"
    case ballInKitchenOnServe = "Kitchen Serve"
    case serviceFault = "Service Fault"

    // Court events
    case ballHitNet = "Hit Net"
    case doubleBounce = "Double Bounce"
    case kitchenViolation = "Kitchen"

    // Player/team events
    case injuryTimeout = "Injury Timeout"
    case substitution = "Substitution"
    case delayPenalty = "Delay Penalty"

    // Administrative events
    case sideChange = "Side Change"
    case serveChange = "Serve Change"
    case gamePaused = "Game Paused"
    case gameResumed = "Game Resumed"
    case gameCompleted = "Game Completed"

    /// Human-readable display name
    public var displayName: String {
        rawValue
    }

    /// Icon name for the event type
    public var iconName: String {
        switch self {
        case .playerScored:
            return "1.circle.fill"
        case .scoreUndone:
            return "arrow.uturn.backward.circle.fill"
        case .ballOutOfBounds:
            return "arrow.up.right.circle.fill"
        case .ballInKitchenOnServe:
            return "rectangle.slash.fill"
        case .serviceFault:
            return "xmark.circle.fill"
        case .ballHitNet:
            return "slash.circle.fill"
        case .doubleBounce:
            return "repeat.circle.fill"
        case .kitchenViolation:
            return "exclamationmark.triangle.fill"
        case .injuryTimeout:
            return "cross.circle.fill"
        case .substitution:
            return "person.2.fill"
        case .delayPenalty:
            return "clock.badge.exclamationmark.fill"
        case .sideChange:
            return "arrow.left.arrow.right.circle.fill"
        case .serveChange:
            return "arrow.clockwise.circle.fill"
        case .gamePaused:
            return "pause.circle.fill"
        case .gameResumed:
            return "play.circle.fill"
        case .gameCompleted:
            return "trophy.fill"
        }
    }

    /// Whether this event typically results in a serve change
    public var typicallyChangesServe: Bool {
        switch self {
        case .playerScored:
            return false
        case .ballOutOfBounds, .ballInKitchenOnServe, .serviceFault, .ballHitNet, .doubleBounce, .kitchenViolation:
            return true
        case .injuryTimeout, .substitution, .delayPenalty, .sideChange, .serveChange, .gamePaused, .gameResumed, .gameCompleted:
            return false
        case .scoreUndone:
            return false
        }
    }
}

/// Represents a logged event that occurred during a game
@Model
public final class GameEvent: Hashable {
    @Attribute(.unique) public var id: UUID
    public var eventType: GameEventType
    public var timestamp: TimeInterval  // Elapsed time when the event occurred
    public var createdAt: Date  // When the event was logged
    public var customDescription: String?  // Optional custom description
    public var teamAffected: Int?  // 1 or 2, nil if not team-specific

    // Relationship to the game
    @Relationship(inverse: \Game.events) public var game: Game?

    public init(
        id: UUID = UUID(),
        eventType: GameEventType,
        timestamp: TimeInterval,
        createdAt: Date = Date(),
        customDescription: String? = nil,
        teamAffected: Int? = nil
    ) {
        self.id = id
        self.eventType = eventType
        self.timestamp = timestamp
        self.createdAt = createdAt
        self.customDescription = customDescription
        self.teamAffected = teamAffected
        self.game = nil  // Set via relationship after creation
    }

    /// Formatted timestamp string (MM:SS.cc format)
    public var formattedTimestamp: String {
        let totalSeconds = Int(timestamp)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        let centiseconds = Int((timestamp.truncatingRemainder(dividingBy: 1)) * 100)

        return String(format: "%02d:%02d.%02d", minutes, seconds, centiseconds)
    }

    /// Short description of the event
    public var shortDescription: String {
        if let customDescription = customDescription, !customDescription.isEmpty {
            return customDescription
        }
        return eventType.displayName
    }

    /// Whether this event affects serving
    public var affectsServing: Bool {
        eventType.typicallyChangesServe
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: GameEvent, rhs: GameEvent) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Convenience Initializers

extension GameEvent {
    /// Create a serving fault event
    public static func servingFault(
        timestamp: TimeInterval,
        teamAffected: Int,
        game: Game? = nil
    ) -> GameEvent {
        let event = GameEvent(
            eventType: .serviceFault,
            timestamp: timestamp,
            teamAffected: teamAffected
        )
        event.game = game
        return event
    }

    /// Create a ball out of bounds event
    public static func ballOutOfBounds(
        timestamp: TimeInterval,
        teamAffected: Int,
        game: Game? = nil
    ) -> GameEvent {
        let event = GameEvent(
            eventType: .ballOutOfBounds,
            timestamp: timestamp,
            teamAffected: teamAffected
        )
        event.game = game
        return event
    }

    /// Create a kitchen violation on serve event
    public static func kitchenOnServe(
        timestamp: TimeInterval,
        teamAffected: Int,
        game: Game? = nil
    ) -> GameEvent {
        let event = GameEvent(
            eventType: .ballInKitchenOnServe,
            timestamp: timestamp,
            teamAffected: teamAffected
        )
        event.game = game
        return event
    }

    /// Create a game pause/resume event
    public static func gameStateChange(
        eventType: GameEventType,
        timestamp: TimeInterval,
        game: Game? = nil
    ) -> GameEvent {
        let event = GameEvent(
            eventType: eventType,
            timestamp: timestamp
        )
        event.game = game
        return event
    }
}
