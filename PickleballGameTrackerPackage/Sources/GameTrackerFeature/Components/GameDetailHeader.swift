//
//  GameDetailHeader.swift
//

import GameTrackerCore
import SwiftUI

public struct GameDetailHeader: View {
  let gameType: GameType

  public var body: some View {
    HStack(spacing: DesignSystem.Spacing.md) {
      Image(systemName: gameType.iconName)
        .font(.system(size: 40, weight: .medium))
        .foregroundStyle(gameType.color.gradient)
        .shadow(color: gameType.color.opacity(0.3), radius: 6, x: 0, y: 3)

      Text(gameType.displayName)
        .font(.largeTitle)
        .fontWeight(.bold)
        .foregroundStyle(.primary)
    }
  }
}

#Preview("Recreational") {
  GameDetailHeader(gameType: PreviewGameData.midGame.gameType)
    .padding()
    .accentColor(.green)
}


