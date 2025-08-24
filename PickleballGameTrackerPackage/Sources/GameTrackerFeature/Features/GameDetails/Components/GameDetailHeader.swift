//
//  GameDetailHeader.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 7/9/25.
//

import PickleballGameTrackerCorePackage
import SwiftUI

public struct GameDetailHeader: View {
  let gameType: GameType

  public var body: some View {
    HStack(spacing: DesignSystem.Spacing.md) {
      Image(systemName: gameType.iconName)
        .font(.system(size: 40, weight: .medium))
        .foregroundStyle(DesignSystem.Colors.gameType(gameType).gradient)
        .shadow(color: DesignSystem.Colors.gameType(gameType).opacity(0.3), radius: 6, x: 0, y: 3)

      Text(gameType.displayName)
        .font(.largeTitle)
        .fontWeight(.bold)
        .foregroundColor(DesignSystem.Colors.textPrimary)
    }
  }
}

#Preview("Recreational") {
  GameDetailHeader(gameType: .recreational)
    .padding()
}
