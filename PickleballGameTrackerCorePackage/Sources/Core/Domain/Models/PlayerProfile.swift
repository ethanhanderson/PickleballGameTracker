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
  @Attribute(.unique) public var id: UUID
  public var name: String
  public var notes: String?
  public var isArchived: Bool

  // Optional identity visuals
  public var avatarImageData: Data?
  public var iconSymbolName: String?
  public var iconTintHex: String?

  // Preferences/attributes
  public var skillLevel: PlayerSkillLevel
  public var preferredHand: PlayerHandedness

  public var createdDate: Date
  public var lastModified: Date

  public init(
    id: UUID = UUID(),
    name: String,
    notes: String? = nil,
    isArchived: Bool = false,
    avatarImageData: Data? = nil,
    iconSymbolName: String? = nil,
    iconTintHex: String? = nil,
    skillLevel: PlayerSkillLevel = .unknown,
    preferredHand: PlayerHandedness = .unknown,
    createdDate: Date = Date(),
    lastModified: Date = Date()
  ) {
    self.id = id
    self.name = name
    self.notes = notes
    self.isArchived = isArchived
    self.avatarImageData = avatarImageData
    self.iconSymbolName = iconSymbolName
    self.iconTintHex = iconTintHex
    self.skillLevel = skillLevel
    self.preferredHand = preferredHand
    self.createdDate = createdDate
    self.lastModified = lastModified
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
  case ambidextrous = 2
  case unknown = 999
}

// Ensure compatibility with SwiftUI collections like ForEach
extension PlayerProfile: Identifiable {}
