//
//  GameDetailView.swift
//

import GameTrackerCore
import SwiftData
import SwiftUI

// MARK: - Game Detail View

@MainActor
struct GameDetailView: View {
  let gameType: GameType
  let onStartGame: (GameVariation, MatchupSelection) -> Void
  @Environment(LiveGameStateManager.self) private var activeGameStateManager
  
  // Query all completed games for finding recent games of this type
  @Query(filter: #Predicate<Game> { $0.isCompleted })
  private var allCompletedGames: [Game]

  @State private var winningScore: Int = 11
  @State private var winByTwo: Bool = true
  @State private var kitchenRule: Bool = true
  @State private var doubleBounceRule: Bool = true
  @State private var letServes: Bool = false
  @State private var servingRotation: ServingRotation = .standard
  @State private var sideSwitchingRule: SideSwitchingRule = .at6Points
  @State private var hasTimeLimit: Bool = false

  @State private var showingError = false
  @State private var errorMessage = ""
  @State private var isCreatingGame = false
  @State private var showingPresetPicker = false

  @State private var showNavigationTitle = false

  @State private var showingLiveGameConflict = false
  @State private var pendingGameVariation: GameVariation?
  @State private var pendingMatchup: MatchupSelection?
  @State private var showingSetupSheet = false
  @State private var showingLastGamePreview = false
  @State private var lastGame: Game?

  init(
    gameType: GameType,
    onStartGame: @escaping (GameVariation, MatchupSelection) -> Void
  ) {
    self.gameType = gameType
    self.onStartGame = onStartGame

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
        GeometryReader { geometry in
          GameDetailHeader(gameType: gameType)
            .onChange(of: geometry.frame(in: .named("scroll")).maxY) { _, newValue in
              withAnimation(.easeInOut(duration: 0.2)) {
                showNavigationTitle = newValue <= -5
              }
            }
        }
        .frame(height: 60)

        HStack(spacing: DesignSystem.Spacing.md) {
          Button(action: { showingSetupSheet = true }) {
            Label {
              Text("Start Game")
            } icon: {
              Image(systemName: "play.fill")
                .frame(width: 20, height: 20)
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
          }
          .controlSize(.large)
          .buttonStyle(.glassProminent)
          .tint(Color(UIColor.secondarySystemBackground).opacity(0.4))
          .foregroundStyle(gameType.color)
          .disabled(isCreatingGame)

          Button(action: loadLastGame) {
            Label {
              Text("Last Game")
            } icon: {
              Image(systemName: "arrow.trianglehead.2.clockwise")
                .frame(width: 20, height: 20)
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
          }
          .controlSize(.large)
          .buttonStyle(.glassProminent)
          .tint(Color(UIColor.secondarySystemBackground).opacity(0.4))
          .foregroundStyle(gameType.color)
          .disabled(isCreatingGame)
        }
        .padding(.bottom, DesignSystem.Spacing.sm)

        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xl) {
          VStack(
            alignment: .leading,
            spacing: DesignSystem.Spacing.sm
          ) {
            Text(gameType.description)
              .font(.body)
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.leading)
              .padding(.bottom, DesignSystem.Spacing.sm)

            GameTypeDetails(gameType: gameType)
          }

          GameRulesForm(
            gameType: gameType,
            winningScore: $winningScore,
            winByTwo: $winByTwo,
            kitchenRule: $kitchenRule,
            doubleBounceRule: $doubleBounceRule,
            letServes: $letServes,
            servingRotation: $servingRotation,
            sideSwitchingRule: $sideSwitchingRule,
            hasTimeLimit: $hasTimeLimit
          )
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .coordinateSpace(name: "scroll")
    .contentMargins(.horizontal, DesignSystem.Spacing.lg, for: .scrollContent)
    .contentMargins(.top, DesignSystem.Spacing.lg, for: .scrollContent)
    .contentMargins(.bottom, DesignSystem.Spacing.lg, for: .scrollContent)
    .navigationBarTitleDisplayMode(.inline)
    .viewContainerBackground(color: gameType.color)
    .scrollClipDisabled()
    .sheet(isPresented: $showingPresetPicker) {
      NavigationStack {
        GamePresetPickerView(gameType: gameType) { preset in
          Task { @MainActor in
            do {
              let variation = try await createGameVariation(
                usePresetValues: true,
                isCustom: false
              )
              // Preset start without roster selection: start as preset-only using players/teams unspecified
              let matchup = MatchupSelection(teamSize: variation.teamSize, mode: .players(sideA: [], sideB: []))
              if activeGameStateManager.hasActiveGame {
                pendingGameVariation = variation
                pendingMatchup = matchup
                showingLiveGameConflict = true
              } else {
                onStartGame(variation, matchup)
              }
            } catch let error as GameVariationError {
              errorMessage = error.localizedDescription
              if let suggestion = error.recoverySuggestion {
                errorMessage += "\n\n" + suggestion
              }
              showingError = true
            }
          }
        }
      }
    }
    .sheet(isPresented: $showingSetupSheet) {
      SetupView(
        gameType: gameType,
        onStartGame: { variation, matchup in
          showingSetupSheet = false
          handleGameStart(variation, matchup: matchup)
        }
      )
    }
    .sheet(isPresented: $showingLastGamePreview) {
      if let lastGame {
        LastGamePreview(
          game: lastGame,
          gameType: gameType,
          onStartGame: { startRecentGame() }
        )
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
      }
    }
    .confirmationDialog(
      "An active game is in progress",
      isPresented: $showingLiveGameConflict,
      titleVisibility: .visible
    ) {
      Button("End current game and start new", role: .destructive) {
        guard let variation = pendingGameVariation,
              let matchup = pendingMatchup
        else { return }
        
        Task { @MainActor in
          do {
            try await activeGameStateManager.completeCurrentGame()
          } catch {
            Log.error(
              error,
              event: .saveFailed,
              metadata: ["phase": "completeBeforeStart"]
            )
          }
          onStartGame(variation, matchup)
          pendingGameVariation = nil
          pendingMatchup = nil
        }
      }
      
      Button("Keep current game", role: .cancel) {
        pendingGameVariation = nil
        pendingMatchup = nil
      }
    } message: {
      Text("You already have a game running. What would you like to do?")
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        NavigationTitleWithIcon(
          systemImageName: gameType.iconName,
          title: gameType.displayName,
          gradient: gameType.color.gradient,
          show: showNavigationTitle
        )
      }
    }
    .alert("Error Creating Game", isPresented: $showingError) {
      Button("OK", role: .confirm) {
        errorMessage = ""
      }
    } message: {
      Text(errorMessage)
    }
  }

  private func handleGameStart(_ variation: GameVariation, matchup: MatchupSelection) {
    isCreatingGame = true

    Task { @MainActor in
      isCreatingGame = false

      if activeGameStateManager.hasActiveGame {
        pendingGameVariation = variation
        pendingMatchup = matchup
        showingLiveGameConflict = true
      } else {
        onStartGame(variation, matchup)
      }
    }
  }

  private func loadLastGame() {
    let recentGames = allCompletedGames
      .filter { $0.gameType == gameType }
      .sorted {
        ($0.completedDate ?? $0.lastModified)
          > ($1.completedDate ?? $1.lastModified)
      }

    guard let foundGame = recentGames.first else {
      errorMessage = "No recent games found for this game type"
      showingError = true
      return
    }

    lastGame = foundGame
    showingLastGamePreview = true
  }

  private func startRecentGame() {
    guard let lastGame else { return }
    
    isCreatingGame = true

    Task { @MainActor in
      do {
        Log.event(
          .actionTapped,
          level: .info,
          message: "Starting game based on last game",
          context: .current(gameId: lastGame.id),
          metadata: ["lastGameScore": lastGame.formattedScore]
        )

        let variation = try GameVariation.createValidated(
          name: "Recent Game - \(gameType.displayName)",
          gameType: gameType,
          teamSize: lastGame.effectiveTeamSize,
          winningScore: lastGame.winningScore,
          winByTwo: lastGame.winByTwo,
          kitchenRule: lastGame.kitchenRule,
          doubleBounceRule: lastGame.doubleBounceRule,
          servingRotation: lastGame.gameVariation?.servingRotation
            ?? .standard,
          sideSwitchingRule: lastGame.gameVariation?.sideSwitchingRule
            ?? .at6Points,
          isCustom: true
        )

        isCreatingGame = false

        let matchup = MatchupSelection(
          teamSize: lastGame.effectiveTeamSize,
          mode: .players(sideA: [], sideB: [])
        )

        if activeGameStateManager.hasActiveGame {
          pendingGameVariation = variation
          pendingMatchup = matchup
          showingLiveGameConflict = true
        } else {
          onStartGame(variation, matchup)
        }
      } catch let error as GameVariationError {
        isCreatingGame = false
        errorMessage = error.localizedDescription
        if let suggestion = error.recoverySuggestion {
          errorMessage += "\n\n" + suggestion
        }
        showingError = true
      }
    }
  }

  private func createGameVariation(
    usePresetValues: Bool = false,
    team1: TeamProfile? = nil,
    team2: TeamProfile? = nil,
    teamSize: Int? = nil,
    isCustom: Bool = false
  ) async throws(GameVariationError) -> GameVariation {

    if usePresetValues {
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
      var effectiveTeamSize = gameType.defaultTeamSize

      if let providedTeamSize = teamSize {
        effectiveTeamSize = providedTeamSize
      }

      return try GameVariation.createValidated(
        name: generateGameName(team1: team1, team2: team2),
        gameType: gameType,
        teamSize: effectiveTeamSize,
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

  private func generateGameName(team1: TeamProfile?, team2: TeamProfile?)
    -> String
  {
    if let team1 = team1, let team2 = team2 {
      return "\(team1.name) vs \(team2.name)"
    } else {
      return "\(gameType.displayName) Game"
    }
  }
}

#Preview("Recreational Game Setup") {
  let container = PreviewContainers.standard()
  let (gameManager, liveGameManager) = PreviewContainers.managers(for: container)
  liveGameManager.configure(gameManager: gameManager)
  
  return NavigationStack {
    GameDetailView(
      gameType: .recreational,
      onStartGame: { variation, matchup in
        Log.event(
          .actionTapped,
          level: .debug,
          message: "Start from preview",
          metadata: ["variation": variation.name, "teamSize": String(matchup.teamSize)]
        )
      }
    )
  }
  .modelContainer(container)
  .environment(liveGameManager)
  .environment(gameManager)
  .accentColor(.green)
}
