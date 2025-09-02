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
  @Attribute(.unique) public var id: UUID
  public var name: String
  public var notes: String?
  public var isArchived: Bool

  // Identity visuals
  public var avatarImageData: Data?
  public var iconSymbolName: String?
  public var iconTintColor: DesignSystem.AppleSystemColor?

  // MARK: - Migration Support
  @Transient
  public var iconTintHex: String? {
    get {
      iconTintColor?.legacyHex
    }
    set {
      if let hex = newValue {
        iconTintColor = DesignSystem.AppleSystemColor(fromHex: hex)
      } else {
        iconTintColor = nil
      }
    }
  }

  // Relationship to players
  @Relationship public var players: [PlayerProfile]

  // Suggestions for game type compatibility
  public var suggestedGameTypeRaw: String?

  public var createdDate: Date
  public var lastModified: Date

  public init(
    id: UUID = UUID(),
    name: String,
    notes: String? = nil,
    isArchived: Bool = false,
    avatarImageData: Data? = nil,
    iconSymbolName: String? = nil,
    iconTintColor: DesignSystem.AppleSystemColor? = nil,
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
    self.iconTintColor = iconTintColor
    self.players = players
    self.suggestedGameTypeRaw = suggestedGameType?.rawValue
    self.createdDate = createdDate
    self.lastModified = lastModified
  }

  // MARK: - Legacy Constructor for Migration
  public init(
    id: UUID = UUID(),
    name: String,
    notes: String? = nil,
    isArchived: Bool = false,
    avatarImageData: Data? = nil,
    iconSymbolName: String? = nil,
    legacyIconTintHex iconTintHex: String?,
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
    self.iconTintColor = iconTintHex.flatMap { DesignSystem.AppleSystemColor(fromHex: $0) }
    self.players = players
    self.suggestedGameTypeRaw = suggestedGameType?.rawValue
    self.createdDate = createdDate
    self.lastModified = lastModified
  }

  public var teamSize: Int { players.count }

  public var suggestedGameType: GameType? {
    get { suggestedGameTypeRaw.flatMap { GameType(rawValue: $0) } }
    set { suggestedGameTypeRaw = newValue?.rawValue }
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

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  public static func == (lhs: TeamProfile, rhs: TeamProfile) -> Bool {
    lhs.id == rhs.id
  }
}

// Ensure compatibility with SwiftUI collections like ForEach
extension TeamProfile: Identifiable {}
