//
//  GameHomeView.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 7/9/25.
//

import CorePackage
import SwiftData
import SwiftUI

@MainActor
struct GameHomeView: View {
  @Environment(\.modelContext) private var modelContext
  @State private var navigationState = AppNavigationState()

  var body: some View {
    NavigationStack(path: $navigationState.navigationPath) {
      ScrollView {
        LazyVStack(spacing: DesignSystem.Spacing.xl) {
          ForEach(GameCatalog.sections, id: \.title) { section in
            GameSection(
              title: section.title,
              destination: section.destination
            ) {
              ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: DesignSystem.Spacing.md) {
                  ForEach(section.gameTypes, id: \.self) {
                    gameType in
                    NavigationLink(
                      value:
                        GameSectionDestination
                        .gameDetail(gameType)
                    ) {
                      GameOptionCard(
                        gameType: gameType,
                        isEnabled: true
                      )
                    }
                    .accessibilityIdentifier("NavLink.Games.gameType.\(gameType.rawValue)")
                    .simultaneousGesture(
                      TapGesture().onEnded {
                        navigationState
                          .trackGameDetailNavigation(
                            gameType
                          )
                      }
                    )
                  }
                }
                .scrollTargetLayout()
                .padding(.horizontal, DesignSystem.Spacing.md)
              }
              .scrollClipDisabled()
              .scrollTargetBehavior(.viewAligned)
            }
          }
        }
        .padding(.top, DesignSystem.Spacing.md)
      }
      .scrollClipDisabled()
      .navigationTitle("Games")
      .containerBackground(DesignSystem.Colors.navigationBrandGradient, for: .navigation)
      .navigationDestination(for: GameSectionDestination.self) {
        destination in
        NavigationDestinationFactory.createDestination(
          for: destination,
          modelContext: modelContext,
          navigationState: navigationState
        )
      }
    }
    .navigationTint()
  }
}

#Preview("Default") {
  GameHomeView()
    .modelContainer(
      try! PreviewGameData.createPreviewContainer(with: [
        PreviewGameData.midGame
      ]))
}
