//
//  GameDetailActions.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 7/9/25.
//

import PickleballGameTrackerCorePackage
import SwiftUI

public struct GameDetailActions: View {
  let gameType: GameType
  let isCreatingGame: Bool
  let onStartGame: () -> Void
  let onStartFromPreset: () -> Void
  let onShowGameSettings: () -> Void

  // Active game conflict handling
  @Binding var showingActiveGameConflict: Bool
  @Binding var conflictingActiveGame: Game?
  let onContinueActiveGame: () -> Void
  let onEndActiveGameAndStartNew: () -> Void
  let onCancelNewGame: () -> Void

  public init(
    gameType: GameType,
    isCreatingGame: Bool,
    onStartGame: @escaping () -> Void,
    onStartFromPreset: @escaping () -> Void,
    onShowGameSettings: @escaping () -> Void,
    showingActiveGameConflict: Binding<Bool>,
    conflictingActiveGame: Binding<Game?>,
    onContinueActiveGame: @escaping () -> Void,
    onEndActiveGameAndStartNew: @escaping () -> Void,
    onCancelNewGame: @escaping () -> Void
  ) {
    self.gameType = gameType
    self.isCreatingGame = isCreatingGame
    self.onStartGame = onStartGame
    self.onStartFromPreset = onStartFromPreset
    self.onShowGameSettings = onShowGameSettings
    self._showingActiveGameConflict = showingActiveGameConflict
    self._conflictingActiveGame = conflictingActiveGame
    self.onContinueActiveGame = onContinueActiveGame
    self.onEndActiveGameAndStartNew = onEndActiveGameAndStartNew
    self.onCancelNewGame = onCancelNewGame
  }

  public var body: some View {
    VStack(spacing: DesignSystem.Spacing.md) {
      // Start from preset button
      Button(action: onStartFromPreset) {
        HStack(spacing: DesignSystem.Spacing.sm) {
          Image(systemName: "text.pad.header.badge.plus")
            .font(.system(size: 16, weight: .semibold))

          Text("Start from a preset")
            .font(.system(size: 17, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 52)
      }
      .buttonStyle(.glassProminent)
      .tint(DesignSystem.Colors.tertiary)
      .disabled(isCreatingGame)

      HStack(spacing: DesignSystem.Spacing.md) {
        Button(action: onStartGame) {
          HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "play.fill")
              .font(.system(size: 16, weight: .semibold))

            Text("Start Game")
              .font(.system(size: 17, weight: .semibold))
          }
          .frame(maxWidth: .infinity)
          .frame(height: 52)
        }
        .buttonStyle(.glassProminent)
        .tint(DesignSystem.Colors.gameType(gameType))
        .disabled(isCreatingGame)
        .confirmationDialog(
          "Active Game in Progress",
          isPresented: $showingActiveGameConflict,
          titleVisibility: .visible
        ) {
          Button("Continue Active Game") {
            onContinueActiveGame()
          }

          Button("End Current & Start New", role: .destructive) {
            onEndActiveGameAndStartNew()
          }

          Button("Cancel", role: .cancel) {
            onCancelNewGame()
          }
        } message: {
          if let activeGame = conflictingActiveGame {
            Text(
              "You have an active \(activeGame.gameType.displayName) game with a score of \(activeGame.formattedScore). What would you like to do?"
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
          }
        }

        Button(action: onShowGameSettings) {
          Image(systemName: "gearshape.fill")
            .font(.system(size: 20, weight: .medium))
            .frame(width: 52, height: 52)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.circle)
        .tint(DesignSystem.Colors.textSecondary)
        .disabled(isCreatingGame)
      }
    }
  }
}

#Preview("Actions") {
  @Previewable @State var showingConflict = false
  @Previewable @State var conflictingGame: Game? = nil

  GameDetailActions(
    gameType: .recreational,
    isCreatingGame: false,
    onStartGame: { Log.event(.actionTapped, level: .debug, message: "Start Game (preview)") },
    onStartFromPreset: {
      Log.event(.actionTapped, level: .debug, message: "Start from Preset (preview)")
    },
    onShowGameSettings: {
      Log.event(.actionTapped, level: .debug, message: "Show Settings (preview)")
    },
    showingActiveGameConflict: $showingConflict,
    conflictingActiveGame: $conflictingGame,
    onContinueActiveGame: {
      Log.event(.actionTapped, level: .debug, message: "Continue Active Game (preview)")
    },
    onEndActiveGameAndStartNew: {
      Log.event(.actionTapped, level: .debug, message: "End Active & Start New (preview)")
    },
    onCancelNewGame: {
      Log.event(.actionTapped, level: .debug, message: "Cancel New Game (preview)")
    }
  )
  .padding()
}
