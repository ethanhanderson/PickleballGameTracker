//
//  PlayerProfile.swift
//  SharedGameCore
//
//  Created by Ethan Anderson on 8/14/25.
//

import Foundation
import SwiftData

@Model
public final class PlayerProfile: Hashable {
  // MARK: - SwiftData Properties (direct stored properties for @Model)

  @Attribute(.unique) public var id: UUID
  public var name: String
  public var notes: String?
  public var isArchived: Bool
  public var isGuest: Bool
  public var avatarImageData: Data?
  public var iconSymbolName: String?
  public var accentColorStored: StoredRGBAColor?
  public var createdDate: Date
  public var lastModified: Date

  // MARK: - Player-Specific Properties

  public var skillLevel: PlayerSkillLevel
  public var preferredHand: PlayerHandedness

  // MARK: - Initialization

  public init(
    id: UUID = UUID(),
    name: String,
    notes: String? = nil,
    isArchived: Bool = false,
    isGuest: Bool = false,
    avatarImageData: Data? = nil,
    iconSymbolName: String? = nil,
    accentColor: StoredRGBAColor? = nil,
    skillLevel: PlayerSkillLevel = .unknown,
    preferredHand: PlayerHandedness = .unknown,
    createdDate: Date = Date(),
    lastModified: Date = Date()
  ) {
    self.id = id
    self.name = name
    self.notes = notes
    self.isArchived = isArchived
    self.isGuest = isGuest
    self.avatarImageData = avatarImageData
    self.iconSymbolName = iconSymbolName
    self.accentColorStored = accentColor
    self.createdDate = createdDate
    self.lastModified = lastModified
    self.skillLevel = skillLevel
    self.preferredHand = preferredHand
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

  public static func == (lhs: PlayerProfile, rhs: PlayerProfile) -> Bool {
    lhs.id == rhs.id
  }
}

public enum PlayerSkillLevel: Int, Codable, Sendable {
  case beginner = 0
  case intermediate = 1
  case advanced = 2
  case expert = 3
  case unknown = 999
}

public enum PlayerHandedness: Int, Codable, Sendable {
  case right = 0
  case left = 1
  case unknown = 999
}


