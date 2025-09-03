//
//  GameHistoryContent.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 7/9/25.
//

import CorePackage
import SwiftData
import SwiftUI

struct GameHistoryContent: View {
  let completedGames: [Game]
  let filteredGames: [Game]
  let groupedGames: [GroupedGames]
  let selectedGrouping: GroupingOption
  let onGameTapped: (Game) -> Void

  var body: some View {
    VStack(spacing: DesignSystem.Spacing.lg) {
      summarySection
      gamesListSection
    }
    .padding(.top, DesignSystem.Spacing.sm)
  }

  // MARK: - View Components

  private var summarySection: some View {
    SectionContainer(title: "Summary") {
      VStack(spacing: DesignSystem.Spacing.md) {
        GameHistorySummary(games: completedGames)
        GameInsightsCard(games: completedGames)
      }
    }
  }

  private var gamesListSection: some View {
    VStack(spacing: 0) {
      if selectedGrouping == .none {
        SectionContainer(title: "Games") {
          ungroupedGamesListInner
        }
      } else {
        groupedGamesList
      }
    }
  }

  private var ungroupedGamesListInner: some View {
    VStack(spacing: DesignSystem.Spacing.md) {
      ForEach(filteredGames.indices, id: \.self) { index in
        GameHistoryCard(
          game: filteredGames[index],
          onTapped: { onGameTapped(filteredGames[index]) }
        )
      }
    }
  }

  private var groupedGamesList: some View {
    GameHistoryGroupedList(
      groupedGames: groupedGames,
      selectedGrouping: selectedGrouping,
      onGameTapped: onGameTapped
    )
  }
}

// MARK: - Preview Support

extension GameHistoryContent {
  /// Creates sample games for preview
  fileprivate static func createSampleGames() -> [Game] {
    let gameConfigs: [(GameType, Int, Int)] = [
      (.training, 11, 7),
      (.recreational, 9, 11),
      (.tournament, 15, 13),
    ]

    return gameConfigs.map { gameType, score1, score2 in
      let game = Game(gameType: gameType)
      game.score1 = score1
      game.score2 = score2
      game.isCompleted = true
      return game
    }
  }

  /// Creates sample grouped games for preview
  fileprivate static func createSampleGroupedGames() -> [GroupedGames] {
    let games = createSampleGames()
    return [
      GroupedGames(title: "Quick Play", games: [games[0]]),
      GroupedGames(title: "Standard", games: [games[1]]),
      GroupedGames(title: "Extended", games: [games[2]]),
    ]
  }
}

// MARK: - Previews

#Preview("Game History Content") {
  let sampleGames = PreviewGameData.competitivePlayerGames
  let sampleGroupedGames: [GroupedGames] = [
    GroupedGames(title: "Quick Play", games: [PreviewGameData.trainingGame]),
    GroupedGames(title: "Standard", games: [PreviewGameData.midGame]),
    GroupedGames(title: "Extended", games: [PreviewGameData.highScoreGame]),
  ]

  GameHistoryContent(
    completedGames: sampleGames,
    filteredGames: sampleGames,
    groupedGames: sampleGroupedGames,
    selectedGrouping: .none,
    onGameTapped: { _ in }
  )
  .padding(.horizontal)
}
