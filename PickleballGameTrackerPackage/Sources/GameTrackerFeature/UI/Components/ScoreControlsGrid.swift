//
//  ScoreControlsGrid.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 7/9/25.
//

import PickleballGameTrackerCorePackage
import SwiftUI

public struct ScoreControlsGrid<Content: View>: View {
  let spacing: CGFloat
  let content: Content

  public init(spacing: CGFloat = DesignSystem.Spacing.md, @ViewBuilder content: () -> Content) {
    self.spacing = spacing
    self.content = content()
  }

  public var body: some View {
    HStack(spacing: spacing) {
      content
    }
  }
}

#Preview("Demo") {
  ScoreControlsGrid {
    Text("Player 1")
      .frame(maxWidth: .infinity)
      .padding()
      .background(DesignSystem.Colors.scorePlayer1.opacity(0.2))

    Text("VS")
      .frame(width: 50)
      .padding()
      .background(DesignSystem.Colors.neutralBorder.opacity(0.2))

    Text("Player 2")
      .frame(maxWidth: .infinity)
      .padding()
      .background(DesignSystem.Colors.scorePlayer2.opacity(0.2))
  }
  .padding()
}
