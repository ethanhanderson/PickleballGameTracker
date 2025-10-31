//
//  GameLiveActivityWidget.swift
//  PickleballGameTrackerWidgetExtension
//
//  Live Activity widget view showing avatar, name, and score for each side
//  Supports both iOS and watchOS platforms
//

import GameTrackerCore
import WidgetKit
import SwiftUI
#if canImport(ActivityKit)
@preconcurrency import ActivityKit
#endif
#if canImport(UIKit)
import UIKit
#endif

#if canImport(ActivityKit)
@available(iOS 16.1, watchOS 9.1, *)
struct GameLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: GameActivityAttributes.self) { context in
      #if os(watchOS)
      let padding = DesignSystem.Spacing.sm
      #else
      let padding = DesignSystem.Spacing.md
      #endif
      return GameLiveActivityView(attributes: context.attributes, state: context.state)
        .padding(padding)
        #if os(iOS)
        .activityBackgroundTint(Color(.systemBackground))
        #endif
    } dynamicIsland: { context in
      #if os(iOS)
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          SideView(
            name: context.attributes.side1Name,
            score: context.state.side1Score,
            avatarImageData: context.attributes.side1AvatarImageData,
            iconSymbolName: context.attributes.side1IconSymbolName,
            tintColor: context.attributes.side1TintColor.swiftUIColor,
            isTrailing: false
          )
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        
        DynamicIslandExpandedRegion(.trailing) {
          SideView(
            name: context.attributes.side2Name,
            score: context.state.side2Score,
            avatarImageData: context.attributes.side2AvatarImageData,
            iconSymbolName: context.attributes.side2IconSymbolName,
            tintColor: context.attributes.side2TintColor.swiftUIColor,
            isTrailing: true
          )
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        }
        
        DynamicIslandExpandedRegion(.center) {
          CenterContentView(
            formattedElapsedTime: context.state.formattedElapsedTime,
            mostRecentEventDescription: context.state.mostRecentEventDescription,
            mostRecentEventType: context.state.mostRecentEventType,
            mostRecentEventTeamAffected: context.state.mostRecentEventTeamAffected,
            side1TintColor: context.attributes.side1TintColor.swiftUIColor,
            side2TintColor: context.attributes.side2TintColor.swiftUIColor
          )
        }
      } compactLeading: {
        HStack(spacing: DesignSystem.Spacing.xs) {
          AvatarView(
            imageData: context.attributes.side1AvatarImageData,
            iconSymbolName: context.attributes.side1IconSymbolName,
            tintColor: context.attributes.side1TintColor.swiftUIColor,
            size: 16
          )
          Text("\(context.state.side1Score)")
            .font(.system(size: 14, weight: .bold, design: .rounded))
        }
      } compactTrailing: {
        HStack(spacing: DesignSystem.Spacing.xs) {
          Text("\(context.state.side2Score)")
            .font(.system(size: 14, weight: .bold, design: .rounded))
          AvatarView(
            imageData: context.attributes.side2AvatarImageData,
            iconSymbolName: context.attributes.side2IconSymbolName,
            tintColor: context.attributes.side2TintColor.swiftUIColor,
            size: 16
          )
        }
      } minimal: {
        AvatarView(
          imageData: context.attributes.side1AvatarImageData,
          iconSymbolName: context.attributes.side1IconSymbolName,
          tintColor: context.attributes.side1TintColor.swiftUIColor,
          size: 16
        )
      }
      #endif
    }
  }
}

@available(iOS 16.1, watchOS 9.1, *)
private struct GameLiveActivityView: View {
  let attributes: GameActivityAttributes
  let state: GameActivityAttributes.ContentState
  
  var body: some View {
    #if os(watchOS)
    return VStack(spacing: DesignSystem.Spacing.sm) {
      HStack(alignment: .center) {
        HStack(spacing: DesignSystem.Spacing.xs) {
          Image(systemName: attributes.gameTypeIconName)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.primary)
          
          Text(attributes.gameTypeDisplayName)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.primary)
        }
        
        Spacer()
        
        CenterContentView(
          formattedElapsedTime: state.formattedElapsedTime,
          mostRecentEventDescription: state.mostRecentEventDescription,
          mostRecentEventType: state.mostRecentEventType,
          mostRecentEventTeamAffected: state.mostRecentEventTeamAffected,
          side1TintColor: attributes.side1TintColor.swiftUIColor,
          side2TintColor: attributes.side2TintColor.swiftUIColor,
          alignment: .trailing
        )
      }
      
      HStack(spacing: DesignSystem.Spacing.md) {
        SideView(
          name: attributes.side1Name,
          score: state.side1Score,
          avatarImageData: attributes.side1AvatarImageData,
          iconSymbolName: attributes.side1IconSymbolName,
          tintColor: attributes.side1TintColor.swiftUIColor,
          isTrailing: false
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        
        SideView(
          name: attributes.side2Name,
          score: state.side2Score,
          avatarImageData: attributes.side2AvatarImageData,
          iconSymbolName: attributes.side2IconSymbolName,
          tintColor: attributes.side2TintColor.swiftUIColor,
          isTrailing: true
        )
        .frame(maxWidth: .infinity, alignment: .trailing)
      }
    }
    #else
    return VStack(spacing: DesignSystem.Spacing.md) {
      HStack(alignment: .center) {
        HStack(spacing: DesignSystem.Spacing.sm) {
          Image(systemName: attributes.gameTypeIconName)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.primary)
          
          Text(attributes.gameTypeDisplayName)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.primary)
        }
        
        Spacer()
        
        CenterContentView(
          formattedElapsedTime: state.formattedElapsedTime,
          mostRecentEventDescription: state.mostRecentEventDescription,
          mostRecentEventType: state.mostRecentEventType,
          mostRecentEventTeamAffected: state.mostRecentEventTeamAffected,
          side1TintColor: attributes.side1TintColor.swiftUIColor,
          side2TintColor: attributes.side2TintColor.swiftUIColor,
          alignment: .trailing
        )
      }
      
      HStack(spacing: DesignSystem.Spacing.lg) {
        SideView(
          name: attributes.side1Name,
          score: state.side1Score,
          avatarImageData: attributes.side1AvatarImageData,
          iconSymbolName: attributes.side1IconSymbolName,
          tintColor: attributes.side1TintColor.swiftUIColor,
          isTrailing: false
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        
        SideView(
          name: attributes.side2Name,
          score: state.side2Score,
          avatarImageData: attributes.side2AvatarImageData,
          iconSymbolName: attributes.side2IconSymbolName,
          tintColor: attributes.side2TintColor.swiftUIColor,
          isTrailing: true
        )
        .frame(maxWidth: .infinity, alignment: .trailing)
      }
    }
    #endif
  }
}

@available(iOS 16.1, watchOS 9.1, *)
private struct SideView: View {
  let name: String
  let score: Int
  let avatarImageData: Data?
  let iconSymbolName: String?
  let tintColor: Color
  let isTrailing: Bool
  
  var body: some View {
    #if os(watchOS)
    let avatarSize: CGFloat = 28
    let nameFontSize: CGFloat = 10
    let scoreFontSize: CGFloat = 18
    let spacing: CGFloat = DesignSystem.Spacing.sm
    #else
    let avatarSize: CGFloat = 40
    let nameFontSize: CGFloat = 0
    let scoreFontSize: CGFloat = 0
    let spacing: CGFloat = DesignSystem.Spacing.md
    #endif
    
    return HStack(spacing: spacing) {
      if isTrailing {
        VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
          Text(name)
            #if os(watchOS)
            .font(.system(size: nameFontSize, weight: .medium))
            #else
            .font(.subheadline)
            .fontWeight(.medium)
            #endif
            .lineLimit(1)
          
          Text("\(score)")
            #if os(watchOS)
            .font(.system(size: scoreFontSize, weight: .bold, design: .rounded))
            #else
            .font(.system(.title2, design: .rounded))
            .fontWeight(.bold)
            #endif
        }
        
        AvatarView(
          imageData: avatarImageData,
          iconSymbolName: iconSymbolName,
          tintColor: tintColor,
          size: avatarSize
        )
      } else {
        AvatarView(
          imageData: avatarImageData,
          iconSymbolName: iconSymbolName,
          tintColor: tintColor,
          size: avatarSize
        )
        
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
          Text(name)
            #if os(watchOS)
            .font(.system(size: nameFontSize, weight: .medium))
            #else
            .font(.subheadline)
            .fontWeight(.medium)
            #endif
            .lineLimit(1)
          
          Text("\(score)")
            #if os(watchOS)
            .font(.system(size: scoreFontSize, weight: .bold, design: .rounded))
            #else
            .font(.system(.title2, design: .rounded))
            .fontWeight(.bold)
            #endif
        }
      }
    }
  }
}

@available(iOS 16.1, watchOS 9.1, *)
private struct CenterContentView: View {
  let formattedElapsedTime: String?
  let mostRecentEventDescription: String?
  let mostRecentEventType: String?
  let mostRecentEventTeamAffected: Int?
  let side1TintColor: Color
  let side2TintColor: Color
  let alignment: HorizontalAlignment
  
  init(
    formattedElapsedTime: String?,
    mostRecentEventDescription: String?,
    mostRecentEventType: String?,
    mostRecentEventTeamAffected: Int?,
    side1TintColor: Color,
    side2TintColor: Color,
    alignment: HorizontalAlignment = .center
  ) {
    self.formattedElapsedTime = formattedElapsedTime
    self.mostRecentEventDescription = mostRecentEventDescription
    self.mostRecentEventType = mostRecentEventType
    self.mostRecentEventTeamAffected = mostRecentEventTeamAffected
    self.side1TintColor = side1TintColor
    self.side2TintColor = side2TintColor
    self.alignment = alignment
  }
  
  private var eventIconName: String? {
    guard let eventTypeString = mostRecentEventType,
          let eventType = GameEventType(rawValue: eventTypeString) else {
      return nil
    }
    return eventType.iconName
  }
  
  private var eventColor: Color {
    guard let teamAffected = mostRecentEventTeamAffected else {
      return .primary
    }
    return teamAffected == 1 ? side1TintColor : side2TintColor
  }
  
  var body: some View {
    #if os(watchOS)
    let eventIconSize: CGFloat = 10
    let eventTextSize: CGFloat = 9
    let timerSize: CGFloat = 10
    let eventSpacing: CGFloat = DesignSystem.Spacing.xs
    #else
    let eventIconSize: CGFloat = 14
    let timerSize: CGFloat = 14
    let eventSpacing: CGFloat = DesignSystem.Spacing.sm
    #endif
    
    return VStack(alignment: alignment, spacing: DesignSystem.Spacing.xs) {
      if let eventDescription = mostRecentEventDescription, !eventDescription.isEmpty {
        HStack(spacing: eventSpacing) {
          if alignment == .trailing {
            Spacer(minLength: 0)
          }
          if let iconName = eventIconName {
            Image(systemName: iconName)
              .font(.system(size: eventIconSize, weight: .semibold))
              .foregroundColor(eventColor)
          }
          Text(eventDescription)
            #if os(watchOS)
            .font(.system(size: eventTextSize, weight: .medium))
            #else
            .font(.system(size: 14, weight: .medium))
            #endif
            .lineLimit(1)
          if alignment == .leading {
            Spacer(minLength: 0)
          }
        }
      }
      
      Text(formattedElapsedTime ?? "00:00")
        .font(.system(size: timerSize, weight: .semibold, design: .rounded))
        .monospacedDigit()
        .foregroundColor(.secondary)
        .frame(maxWidth: .infinity, alignment: alignment == .center ? .center : (alignment == .trailing ? .trailing : .leading))
    }
  }
}

@available(iOS 16.1, watchOS 9.1, *)
private struct AvatarView: View {
  let imageData: Data?
  let iconSymbolName: String?
  let tintColor: Color
  let size: CGFloat
  
  var body: some View {
    Group {
      #if canImport(UIKit)
      if let imageData, let uiImage = UIImage(data: imageData) {
        Image(uiImage: uiImage)
          .resizable()
          .scaledToFill()
          .frame(width: size, height: size)
          .clipShape(Circle())
      } else {
        iconAvatar
      }
      #else
      iconAvatar
      #endif
    }
  }
  
  private var iconAvatar: some View {
    ZStack {
      Circle()
        .fill(tintColor.opacity(0.15))
      
      Image(systemName: iconSymbolName ?? "person.fill")
        .font(.system(size: size * 0.5, weight: .semibold))
        .foregroundColor(tintColor)
    }
    .frame(width: size, height: size)
  }
}
#endif

