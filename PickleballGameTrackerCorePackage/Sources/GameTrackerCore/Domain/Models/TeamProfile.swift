//
//  TeamProfile.swift
//  SharedGameCore
//
//  Created by Ethan Anderson on 8/14/25.
//

import Foundation
import SwiftData

@Model
public final class TeamProfile: Hashable {
  // MARK: - SwiftData Properties (direct stored properties for @Model)

  @Attribute(.unique) public var id: UUID
  public var name: String
  public var notes: String?
  public var isArchived: Bool
  public var avatarImageData: Data?
  public var iconSymbolName: String?
  public var accentColorStored: StoredRGBAColor?
  public var createdDate: Date
  public var lastModified: Date

  // MARK: - Team-Specific Properties

  @Relationship public var players: [PlayerProfile] = []
  public var suggestedGameTypeRaw: String?

  // MARK: - Initialization

  public init(
    id: UUID = UUID(),
    name: String,
    notes: String? = nil,
    isArchived: Bool = false,
    avatarImageData: Data? = nil,
    iconSymbolName: String? = nil,
    accentColor: StoredRGBAColor? = nil,
    players: [PlayerProfile] = [],
    suggestedGameType: GameType? = nil,
    createdDate: Date = Date(),
    lastModified: Date = Date()
  ) {
    self.id = id
    self.name = name
    self.notes = notes
    self.isArchived = isArchived
    self.avatarImageData = avatarImageData
    self.iconSymbolName = iconSymbolName
    self.accentColorStored = accentColor
    self.createdDate = createdDate
    self.lastModified = lastModified
    self.players = players
    self.suggestedGameTypeRaw = suggestedGameType?.rawValue
  }

  // MARK: - Team-Specific Computed Properties

  public var teamSize: Int { players.count }

  public var suggestedGameType: GameType? {
    get { suggestedGameTypeRaw.flatMap { GameType(rawValue: $0) } }
    set { suggestedGameTypeRaw = newValue?.rawValue }
  }

  // MARK: - Protocol Implementation

  public func archive() {
    isArchived = true
    lastModified = Date()
  }

  public func restore() {
    isArchived = false
    lastModified = Date()
  }

  // MARK: - Hashable

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  public static func == (lhs: TeamProfile, rhs: TeamProfile) -> Bool {
    lhs.id == rhs.id
  }
}


