//
//  GameSection.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 7/9/25.
//

import SharedGameCore
import SwiftUI

// MARK: - Game Section

public struct GameSection<Content: View>: View {
  let title: String
  let content: Content
  let destination: GameSectionDestination

  public init(
    title: String,
    destination: GameSectionDestination,
    @ViewBuilder content: () -> Content
  ) {
    self.title = title
    self.destination = destination
    self.content = content()
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
      // Section Header Button - navigates to section detail view
      NavigationLink(value: destination) {
        HStack(spacing: DesignSystem.Spacing.sm) {
          Text(title)
            .font(DesignSystem.Typography.title2)
            .fontWeight(.semibold)
            .foregroundColor(DesignSystem.Colors.textPrimary)

          Image(systemName: "chevron.right")
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
      }
      .buttonStyle(.plain)

      // Section Content - horizontal scrolling game cards
      content
    }
  }
}
