//
//  GameTypePreset.swift
//  SharedGameCore
//
//  Created by Ethan Anderson on 8/14/25.
//

import Foundation
import SwiftData

@Model
public final class GameTypePreset: Hashable {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var notes: String?
    public var isArchived: Bool

    // Binding
    public var gameTypeRaw: String
    @Relationship public var team1: TeamProfile?
    @Relationship public var team2: TeamProfile?
    public var accentColorStored: StoredRGBAColor?

    public var createdDate: Date
    public var lastModified: Date

    public init(
        id: UUID = UUID(),
        name: String,
        notes: String? = nil,
        isArchived: Bool = false,
        gameType: GameType,
        team1: TeamProfile? = nil,
        team2: TeamProfile? = nil,
        accentColor: StoredRGBAColor? = nil,
        createdDate: Date = Date(),
        lastModified: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.isArchived = isArchived
        self.gameTypeRaw = gameType.rawValue
        self.team1 = team1
        self.team2 = team2
        self.accentColorStored = accentColor
        self.createdDate = createdDate
        self.lastModified = lastModified
    }

    public var gameType: GameType {
        get { GameType(rawValue: gameTypeRaw) ?? .recreational }
        set { gameTypeRaw = newValue.rawValue }
    }

    public func archive() {
        isArchived = true
        lastModified = Date()
    }

    public func restore() {
        isArchived = false
        lastModified = Date()
    }

    // MARK: - Hashable
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
    public static func == (lhs: GameTypePreset, rhs: GameTypePreset) -> Bool {
        lhs.id == rhs.id
    }
}

