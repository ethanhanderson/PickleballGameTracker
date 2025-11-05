//
//  GameActivityAttributes.swift
//  GameTrackerCore
//
//  Attributes for Live Activity displaying active game state
//

import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

#if canImport(ActivityKit)
@available(iOS 16.1, watchOS 9.1, *)
public struct GameActivityAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    public let side1Score: Int
    public let side2Score: Int
    public let formattedElapsedTime: String?
    public let mostRecentEventDescription: String?
    public let mostRecentEventType: String?
    public let mostRecentEventTeamAffected: Int?
    
    public init(
      side1Score: Int,
      side2Score: Int,
      formattedElapsedTime: String? = nil,
      mostRecentEventDescription: String? = nil,
      mostRecentEventType: String? = nil,
      mostRecentEventTeamAffected: Int? = nil
    ) {
      self.side1Score = side1Score
      self.side2Score = side2Score
      self.formattedElapsedTime = formattedElapsedTime
      self.mostRecentEventDescription = mostRecentEventDescription
      self.mostRecentEventType = mostRecentEventType
      self.mostRecentEventTeamAffected = mostRecentEventTeamAffected
    }
  }
  
  public let gameId: UUID
  public let gameTypeIconName: String
  public let gameTypeDisplayName: String
  public let gameTypeTintColor: StoredRGBAColor
  public let side1Name: String
  public let side2Name: String
  public let side1AvatarImageData: Data?
  public let side1IconSymbolName: String?
  public let side1TintColor: StoredRGBAColor
  public let side2AvatarImageData: Data?
  public let side2IconSymbolName: String?
  public let side2TintColor: StoredRGBAColor
  
  public init(
    gameId: UUID,
    gameTypeIconName: String,
    gameTypeDisplayName: String,
    gameTypeTintColor: StoredRGBAColor,
    side1Name: String,
    side2Name: String,
    side1AvatarImageData: Data?,
    side1IconSymbolName: String?,
    side1TintColor: StoredRGBAColor,
    side2AvatarImageData: Data?,
    side2IconSymbolName: String?,
    side2TintColor: StoredRGBAColor
  ) {
    self.gameId = gameId
    self.gameTypeIconName = gameTypeIconName
    self.gameTypeDisplayName = gameTypeDisplayName
    self.gameTypeTintColor = gameTypeTintColor
    self.side1Name = side1Name
    self.side2Name = side2Name
    self.side1AvatarImageData = side1AvatarImageData
    self.side1IconSymbolName = side1IconSymbolName
    self.side1TintColor = side1TintColor
    self.side2AvatarImageData = side2AvatarImageData
    self.side2IconSymbolName = side2IconSymbolName
    self.side2TintColor = side2TintColor
  }
}
#endif

