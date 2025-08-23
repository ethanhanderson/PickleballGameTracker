//
//  GameDetailView.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 7/9/25.
//

import SharedGameCore
import SwiftData
import SwiftUI

// MARK: - Game Detail View

@MainActor
struct GameDetailView: View {
  let gameType: GameType
  let onStartGame: (GameVariation) -> Void
  @Environment(ActiveGameStateManager.self) private var activeGameStateManager

  @State private var selectedTeamSize: Int
  @State private var winningScore: Int = 11
  @State private var winByTwo: Bool = true
  @State private var kitchenRule: Bool = true
  @State private var doubleBounceRule: Bool = true
  @State private var letServes: Bool = false
  @State private var servingRotation: ServingRotation = .standard
  @State private var sideSwitchingRule: SideSwitchingRule = .at6Points
  @State private var hasTimeLimit: Bool = false

  // Error handling state
  @State private var showingError = false
  @State private var errorMessage = ""
  @State private var isCreatingGame = false
  @State private var showingPresetPicker = false

  // Navigation title state
  @State private var showNavigationTitle = false

  // Active game conflict state
  @State private var showingActiveGameConflict = false
  @State private var pendingGameVariation: GameVariation?
  @State private var conflictingActiveGame: Game?

  init(
    gameType: GameType,
    onStartGame: @escaping (GameVariation) -> Void
  ) {
    self.gameType = gameType
    self.onStartGame = onStartGame
    self._selectedTeamSize = State(initialValue: gameType.defaultTeamSize)

    // Initialize rules based on game type defaults
    self._winningScore = State(initialValue: gameType.defaultWinningScore)
    self._winByTwo = State(initialValue: gameType.defaultWinByTwo)
    self._kitchenRule = State(initialValue: gameType.defaultKitchenRule)
    self._doubleBounceRule = State(
      initialValue: gameType.defaultDoubleBounceRule
    )
    self._servingRotation = State(initialValue: .standard)
    self._sideSwitchingRule = State(
      initialValue: gameType.defaultSideSwitchingRule
    )
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
        // Header with scroll tracking
        GeometryReader { geometry in
          GameDetailHeader(gameType: gameType)
            .onChange(of: geometry.frame(in: .named("scroll")).maxY) { _, newValue in
              withAnimation(.easeInOut(duration: 0.2)) {
                showNavigationTitle = newValue <= -35
              }
            }
        }
        .frame(height: 60)
        .padding(.horizontal, DesignSystem.Spacing.lg)

        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
          Text(gameType.description)
            .font(DesignSystem.Typography.body)
            .foregroundColor(DesignSystem.Colors.textSecondary)
            .multilineTextAlignment(.leading)
            .padding(.bottom, DesignSystem.Spacing.sm)

          GameTypeDetails(gameType: gameType)

          GameRulesSection(
            winningScore: $winningScore,
            winByTwo: $winByTwo,
            kitchenRule: $kitchenRule,
            doubleBounceRule: $doubleBounceRule,
            letServes: $letServes,
            servingRotation: $servingRotation,
            sideSwitchingRule: $sideSwitchingRule,
            hasTimeLimit: $hasTimeLimit
          )

          GameDetailActions(
            gameType: gameType,
            isCreatingGame: isCreatingGame,
            onStartGame: startGame,
            onStartFromPreset: { showingPresetPicker = true },
            onShowGameSettings: showGameSettings,
            showingActiveGameConflict: $showingActiveGameConflict,
            conflictingActiveGame: $conflictingActiveGame,
            onContinueActiveGame: continueActiveGame,
            onEndActiveGameAndStartNew: endActiveGameAndStartNew,
            onCancelNewGame: cancelNewGame
          )
          .padding(.top, DesignSystem.Spacing.lg)
          .accessibilityIdentifier("GameDetail.actions")
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.bottom, DesignSystem.Spacing.lg)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.top, DesignSystem.Spacing.lg)
    }
    .coordinateSpace(name: "scroll")
    .navigationBarTitleDisplayMode(.inline)
    .sheet(isPresented: $showingPresetPicker) {
      NavigationStack {
        PresetPickerView(gameType: gameType) { preset in
          Task { @MainActor in
            do {
              let variation = try await createGameVariation(
                usePresetValues: true,
                isCustom: false
              )
              // Active game check remains identical to startGame
              if activeGameStateManager.hasActiveGame {
                pendingGameVariation = variation
                conflictingActiveGame = activeGameStateManager.currentGame
                showingActiveGameConflict = true
              } else {
                onStartGame(variation)
              }
            } catch let error as GameVariationError {
              errorMessage = error.localizedDescription
              if let suggestion = error.recoverySuggestion {
                errorMessage += "\n\n" + suggestion
              }
              showingError = true
            } catch {
              errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
              showingError = true
            }
          }
        }
      }
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        HStack(spacing: DesignSystem.Spacing.sm) {
          Image(systemName: gameType.iconName)
            .font(.system(size: 24, weight: .medium))
            .foregroundStyle(DesignSystem.Colors.gameType(gameType).gradient)

          Text(gameType.displayName)
            .font(DesignSystem.Typography.headline)
            .fontWeight(.semibold)
            .foregroundColor(DesignSystem.Colors.textPrimary)
        }
        .opacity(showNavigationTitle ? 1.0 : 0.0)
        .offset(y: showNavigationTitle ? 0 : 4)
        .animation(
          .easeInOut(duration: 0.2),
          value: showNavigationTitle
        )
      }
    }
    .alert("Error Creating Game", isPresented: $showingError) {
      Button("OK") {
        errorMessage = ""
      }
    } message: {
      Text(errorMessage)
    }
  }

  private func startGame() {
    isCreatingGame = true

    Task { @MainActor in
      do {
        let variation = try await createGameVariation(
          isCustom: gameType.supportsTeamCustomization
        )

        isCreatingGame = false

        // Check for active game before proceeding
        if activeGameStateManager.hasActiveGame {
          // Store pending variation and show conflict dialog
          pendingGameVariation = variation
          conflictingActiveGame = activeGameStateManager.currentGame
          showingActiveGameConflict = true
        } else {
          // No active game, proceed directly
          onStartGame(variation)
        }
      } catch let error as GameVariationError {
        isCreatingGame = false
        errorMessage = error.localizedDescription
        if let suggestion = error.recoverySuggestion {
          errorMessage += "\n\n" + suggestion
        }
        showingError = true
      } catch {
        isCreatingGame = false
        errorMessage =
          "An unexpected error occurred: \(error.localizedDescription)"
        showingError = true
      }
    }
  }

  private func startFromPreset() {
    isCreatingGame = true

    Task { @MainActor in
      do {
        let variation = try await createGameVariation(
          usePresetValues: true,
          isCustom: false
        )

        isCreatingGame = false

        // Check for active game before proceeding
        if activeGameStateManager.hasActiveGame {
          // Store pending variation and show conflict dialog
          pendingGameVariation = variation
          conflictingActiveGame = activeGameStateManager.currentGame
          showingActiveGameConflict = true
        } else {
          // No active game, proceed directly
          onStartGame(variation)
        }
      } catch let error as GameVariationError {
        isCreatingGame = false
        errorMessage = error.localizedDescription
        if let suggestion = error.recoverySuggestion {
          errorMessage += "\n\n" + suggestion
        }
        showingError = true
      } catch {
        isCreatingGame = false
        errorMessage =
          "An unexpected error occurred: \(error.localizedDescription)"
        showingError = true
      }
    }
  }

  private func createGameVariation(
    usePresetValues: Bool = false,
    isCustom: Bool = false
  ) async throws(GameVariationError) -> GameVariation {

    if usePresetValues {
      // Use default preset values
      return try GameVariation.createValidated(
        name: "\(gameType.displayName) Game",
        gameType: gameType,
        teamSize: gameType.defaultTeamSize,
        winningScore: gameType.defaultWinningScore,
        winByTwo: gameType.defaultWinByTwo,
        kitchenRule: gameType.defaultKitchenRule,
        doubleBounceRule: gameType.defaultDoubleBounceRule,
        servingRotation: .standard,
        sideSwitchingRule: gameType.defaultSideSwitchingRule,
        isCustom: false
      )
    } else {
      // Use current form values with validation
      return try GameVariation.createValidated(
        name: "\(gameType.displayName) Game",
        gameType: gameType,
        teamSize: selectedTeamSize,
        winningScore: winningScore,
        winByTwo: winByTwo,
        kitchenRule: kitchenRule,
        doubleBounceRule: doubleBounceRule,
        servingRotation: servingRotation,
        sideSwitchingRule: sideSwitchingRule,
        isCustom: isCustom
      )
    }
  }

  private func showGameSettings() {
    Log.event(.actionTapped, level: .debug, message: "Game settings tapped")
  }

  // MARK: - Active Game Conflict Handling

  private func continueActiveGame() {
    guard let activeGame = conflictingActiveGame else { return }

    // Clear conflict state
    clearActiveGameConflict()

    // Note: The active game is already accessible through the app's main navigation
    // (tab bar preview or main menu). This dialog just informs the user and
    // dismisses to let them navigate to it through existing UI.

    Log.event(
      .actionTapped,
      level: .info,
      message: "Continue active game",
      context: .current(gameId: activeGame.id)
    )
  }

  private func endActiveGameAndStartNew() {
    guard let pendingVariation = pendingGameVariation else { return }

    Task {
      do {
        // Complete the current active game
        try await activeGameStateManager.completeCurrentGame()

        await MainActor.run {
          // Clear conflict state
          clearActiveGameConflict()

          // Start the new game
          onStartGame(pendingVariation)
          Log.event(
            .gameResumed,
            level: .info,
            message: "Ended active and started new game"
          )
        }
      } catch {
        await MainActor.run {
          clearActiveGameConflict()
          errorMessage =
            "Failed to end active game: \(error.localizedDescription)"
          showingError = true
          Log.error(
            error,
            event: .saveFailed,
            metadata: ["action": "endActiveAndStartNew"]
          )
        }
      }
    }
  }

  private func cancelNewGame() {
    clearActiveGameConflict()
    Log.event(
      .actionTapped,
      level: .info,
      message: "Cancel new game creation"
    )
  }

  private func clearActiveGameConflict() {
    showingActiveGameConflict = false
    pendingGameVariation = nil
    conflictingActiveGame = nil
  }
}

#Preview("Recreational Game Setup") {
  NavigationStack {
    GameDetailView(
      gameType: .recreational,
      onStartGame: { variation in
        Log.event(
          .actionTapped,
          level: .debug,
          message: "Start from preview",
          metadata: ["variation": variation.name]
        )
      }
    )
  }
  .modelContainer(try! PreviewGameData.createFullPreviewContainer())
}
