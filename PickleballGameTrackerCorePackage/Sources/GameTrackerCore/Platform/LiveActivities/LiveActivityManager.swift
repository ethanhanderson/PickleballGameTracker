//
//  LiveActivityManager.swift
//  GameTrackerCore
//
//  Manages Live Activity lifecycle for active games
//

import Foundation
#if canImport(ActivityKit)
@preconcurrency import ActivityKit
#endif
import SwiftData
import SwiftUI

#if canImport(ActivityKit)
@available(iOS 16.1, watchOS 9.1, *)
@MainActor
public final class LiveActivityManager {
  public static let shared = LiveActivityManager()
  
  private var currentActivity: Activity<GameActivityAttributes>?
  private var modelContext: ModelContext?
  
  private init() {}
  
  public func configure(context: ModelContext) {
    self.modelContext = context
  }
  
  public func startActivity(
    for game: Game,
    context: ModelContext,
    formattedElapsedTime: String? = nil,
    mostRecentEventDescription: String? = nil,
    mostRecentEventType: String? = nil,
    mostRecentEventTeamAffected: Int? = nil
  ) async throws {
    let authInfo = ActivityAuthorizationInfo()
    guard authInfo.areActivitiesEnabled else {
      Log.event(.appLaunch, level: .warn, message: "Live Activities not enabled")
      throw LiveActivityError.notAvailable
    }
    
    // End any existing activity first
    if currentActivity != nil {
      await endActivity()
    }
    
    let attributes = try buildAttributes(from: game, context: context)
    let contentState = GameActivityAttributes.ContentState(
      side1Score: game.score1,
      side2Score: game.score2,
      formattedElapsedTime: formattedElapsedTime,
      mostRecentEventDescription: mostRecentEventDescription,
      mostRecentEventType: mostRecentEventType,
      mostRecentEventTeamAffected: mostRecentEventTeamAffected
    )
    
    let activityContent = ActivityContent(state: contentState, staleDate: nil)
    
    do {
      let activity = try Activity<GameActivityAttributes>.request(
        attributes: attributes,
        content: activityContent,
        pushType: nil
      )
      currentActivity = activity
      Log.event(.appLaunch, level: .info, message: "Live Activity started", metadata: ["gameId": "\(game.id)"])
    } catch {
      Log.error(error, event: .appLaunch, metadata: ["gameId": "\(game.id)", "action": "startLiveActivity"])
      throw LiveActivityError.failedToStart(error)
    }
  }
  
  public func updateActivity(
    for game: Game,
    formattedElapsedTime: String? = nil,
    mostRecentEventDescription: String? = nil,
    mostRecentEventType: String? = nil,
    mostRecentEventTeamAffected: Int? = nil
  ) async {
    guard let activity = currentActivity else { return }
    
    let contentState = GameActivityAttributes.ContentState(
      side1Score: game.score1,
      side2Score: game.score2,
      formattedElapsedTime: formattedElapsedTime,
      mostRecentEventDescription: mostRecentEventDescription,
      mostRecentEventType: mostRecentEventType,
      mostRecentEventTeamAffected: mostRecentEventTeamAffected
    )
    
    let activityContent = ActivityContent(state: contentState, staleDate: nil)
    await activity.update(activityContent)
  }
  
  public func endActivity() async {
    guard let activity = currentActivity else { return }
    
    let contentState = GameActivityAttributes.ContentState(
      side1Score: activity.content.state.side1Score,
      side2Score: activity.content.state.side2Score
    )
    
    let activityContent = ActivityContent(state: contentState, staleDate: Date())
    
    await activity.end(activityContent, dismissalPolicy: .immediate)
    currentActivity = nil
  }
  
  private func buildAttributes(from game: Game, context: ModelContext) throws -> GameActivityAttributes {
    let (side1Name, side1AvatarData, side1Icon, side1Color) = try resolveSideInfo(
      for: 1,
      game: game,
      context: context
    )
    
    let (side2Name, side2AvatarData, side2Icon, side2Color) = try resolveSideInfo(
      for: 2,
      game: game,
      context: context
    )
    
    return GameActivityAttributes(
      gameId: game.id,
      gameTypeIconName: game.gameType.iconName,
      gameTypeDisplayName: game.gameType.displayName,
      gameTypeTintColor: StoredRGBAColor(game.gameType.color),
      side1Name: side1Name,
      side2Name: side2Name,
      side1AvatarImageData: side1AvatarData,
      side1IconSymbolName: side1Icon,
      side1TintColor: side1Color,
      side2AvatarImageData: side2AvatarData,
      side2IconSymbolName: side2Icon,
      side2TintColor: side2Color
    )
  }
  
  private func resolveSideInfo(
    for teamNumber: Int,
    game: Game,
    context: ModelContext
  ) throws -> (String, Data?, String?, StoredRGBAColor) {
    switch game.participantMode {
    case .players:
      let players = teamNumber == 1
        ? game.resolveSide1Players(context: context)
        : game.resolveSide2Players(context: context)
      
      guard let players, let firstPlayer = players.first else {
        throw LiveActivityError.failedToStart(NSError(
          domain: "LiveActivity",
          code: 1001,
          userInfo: [NSLocalizedDescriptionKey: "Participants not resolvable for team \(teamNumber)"]
        ))
      }
      
      let name = players.map { $0.name }.joined(separator: " & ")
      return (
        name,
        firstPlayer.avatarImageData,
        firstPlayer.iconSymbolName,
        firstPlayer.accentColorStored
      )
      
    case .teams:
      let team = teamNumber == 1
        ? game.resolveSide1Team(context: context)
        : game.resolveSide2Team(context: context)
      
      guard let team else {
        throw LiveActivityError.failedToStart(NSError(
          domain: "LiveActivity",
          code: 1002,
          userInfo: [NSLocalizedDescriptionKey: "Team not resolvable for team \(teamNumber)"]
        ))
      }
      
      return (
        team.name,
        team.avatarImageData,
        team.iconSymbolName,
        team.accentColorStored
      )
      
    
    }
  }
}

@available(iOS 16.1, watchOS 9.1, *)
public enum LiveActivityError: Error {
  case failedToStart(Error)
  case notAvailable
}
#endif

