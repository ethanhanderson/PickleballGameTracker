//
//  GameSectionDetailView.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 7/9/25.
//

import PickleballGameTrackerCorePackage
import SwiftData
import SwiftUI

@MainActor
struct GameSectionDetailView: View {
  let modelContext: ModelContext
  @Bindable var navigationState: AppNavigationState

  private let destination: GameSectionDestination?
  private let section: GameCatalog.GameSection?

  // Convenience initializer for destination-based creation
  init(
    destination: GameSectionDestination, modelContext: ModelContext,
    navigationState: AppNavigationState
  ) {
    self.destination = destination
    self.section = nil
    self.modelContext = modelContext
    self.navigationState = navigationState
  }

  // Convenience initializer for section-based creation
  init(
    section: GameCatalog.GameSection, modelContext: ModelContext,
    navigationState: AppNavigationState
  ) {
    self.destination = nil
    self.section = section
    self.modelContext = modelContext
    self.navigationState = navigationState
  }

  // Convenience initializer for custom section creation
  init(
    sectionTitle: String, gameTypes: [GameType], modelContext: ModelContext,
    navigationState: AppNavigationState
  ) {
    self.destination = nil
    self.section = GameCatalog.GameSection(
      title: sectionTitle, gameTypes: gameTypes, destination: .allGames)  // destination unused in this context
    self.modelContext = modelContext
    self.navigationState = navigationState
  }

  var body: some View {
    ScrollView {
      LazyVStack(spacing: DesignSystem.Spacing.md) {
        ForEach(gameTypesForSection, id: \.self) { gameType in
          NavigationLink(value: GameSectionDestination.gameDetail(gameType)) {
            GameOptionCard(
              gameType: gameType,
              isEnabled: isGameTypeEnabled(gameType),
              fillsWidth: true
            )
          }
          .buttonStyle(.plain)
          .disabled(!isGameTypeEnabled(gameType))
          .simultaneousGesture(
            TapGesture().onEnded {
              navigationState.trackGameDetailNavigation(gameType)
            }
          )
        }
      }
      .padding(.horizontal, DesignSystem.Spacing.md)
      .padding(.top, DesignSystem.Spacing.md)
    }
    .navigationTitle(sectionTitle)
    .navigationBarTitleDisplayMode(.large)
    .onAppear {
      navigationState.trackSectionNavigation(sectionTitle)
    }
  }

  private var sectionTitle: String {
    if let section = section {
      return section.title
    }

    guard let destination = destination else {
      return "Games"
    }

    switch destination {
    case .quickStart:
      return "Quick Start"
    case .allGames:
      return "All Game Types"
    case .recommended:
      return "Recommended Games"
    case .beginnerFriendly:
      return "Beginner Friendly"
    case .advancedPlay:
      return "Advanced Play"
    case .testing:
      return "Testing Suite"
    case .customizable:
      return "Customizable Games"
    case .gameDetail:
      return "Game Detail"  // This should never be reached
    case .sectionDetail(let title, _):
      return title
    }
  }

  private var gameTypesForSection: [GameType] {
    if let section = section {
      return section.gameTypes
    }

    guard let destination = destination else {
      return []
    }

    switch destination {
    case .quickStart:
      return GameType.quickStartTypes
    case .allGames:
      return GameType.allTypes
    case .recommended:
      return GameType.recommendedTypes
    case .beginnerFriendly:
      return GameType.beginnerTypes
    case .advancedPlay:
      return GameType.competitiveTypes
    case .testing:
      return GameType.testingTypes
    case .customizable:
      return GameType.customizableTypes
    case .gameDetail:
      return []  // This should never be reached
    case .sectionDetail(_, let gameTypes):
      return gameTypes
    }
  }

  private func isGameTypeEnabled(_ gameType: GameType) -> Bool {
    // All game types are enabled for navigation to GameDetailView
    return true
  }

}

#Preview("All Game Types") {
  NavigationStack {
    GameSectionDetailView(
      destination: .allGames,
      modelContext: try! PreviewGameData.createPreviewContainer(with: []).mainContext,
      navigationState: AppNavigationState()
    )
  }
}
