//
//  GameHistoryGroupedList.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 7/9/25.
//

import PickleballGameTrackerCorePackage
import SwiftUI

struct GameHistoryGroupedList: View {
  let groupedGames: [GroupedGames]
  let selectedGrouping: GroupingOption
  let onGameTapped: (Game) -> Void

  var body: some View {
    VStack(spacing: DesignSystem.Spacing.md) {
      ForEach(groupedGames.indices, id: \.self) { groupIndex in
        let group = groupedGames[groupIndex]

        Section {
          ForEach(group.games.indices, id: \.self) { gameIndex in
            GameHistoryCard(
              game: group.games[gameIndex],
              onTapped: { onGameTapped(group.games[gameIndex]) }
            )
          }
        } header: {
          if shouldShowHeader(for: group) {
            HStack {
              Text(group.title)
                .font(DesignSystem.Typography.title3)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
              Spacer()
            }
          }
        }
      }
    }
    .padding(.top, DesignSystem.Spacing.lg)
  }

  // MARK: - Helper Methods

  private func shouldShowHeader(for group: GroupedGames) -> Bool {
    selectedGrouping != .none && !group.title.isEmpty
  }
}

// MARK: - Preview Support

extension GameHistoryGroupedList {
  fileprivate static func createSampleGroupedGames() -> [GroupedGames] {
    [
      GroupedGames(
        title: "Quick Play",
        games: [
          Game(gameType: .training),
          Game(gameType: .training),
        ]
      ),
      GroupedGames(
        title: "Standard",
        games: [Game(gameType: .recreational)]
      ),
    ]
  }

  fileprivate static func createSampleUngroupedGames() -> [GroupedGames] {
    [
      GroupedGames(
        title: "",
        games: [
          Game(gameType: .training),
          Game(gameType: .recreational),
          Game(gameType: .tournament),
        ]
      )
    ]
  }
}

// MARK: - Previews

#Preview("Grouped List - Game Type") {
  GameHistoryGroupedList(
    groupedGames: [
      GroupedGames(
        title: "Quick Play", games: [PreviewGameData.trainingGame, PreviewGameData.trainingGame]),
      GroupedGames(title: "Standard", games: [PreviewGameData.midGame]),
    ],
    selectedGrouping: .gameType,
    onGameTapped: { _ in }
  )
  .padding()
}

#Preview("Grouped List - None (Ungrouped)") {
  GameHistoryGroupedList(
    groupedGames: [
      GroupedGames(
        title: "",
        games: [
          PreviewGameData.trainingGame,
          PreviewGameData.midGame,
          PreviewGameData.highScoreGame,
        ])
    ],
    selectedGrouping: .none,
    onGameTapped: { _ in }
  )
  .padding()
}
