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
  let onStartGame: (GameType, GameRules?, MatchupSelection) -> Void
  @Environment(LiveGameStateManager.self) private var activeGameStateManager
  @Environment(LiveSyncCoordinator.self) private var syncCoordinator

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
  @State private var pendingGameRules: GameRules?
  @State private var pendingMatchup: MatchupSelection?
  @State private var pendingLastGameStart = false
  @State private var showingSetupSheet = false

  init(
    gameType: GameType,
    onStartGame: @escaping (GameType, GameRules?, MatchupSelection) -> Void
  ) {
    self.gameType = gameType
    self.onStartGame = onStartGame

    let defaultRules = gameType.defaultRules
    self._winningScore = State(initialValue: defaultRules.winningScore)
    self._winByTwo = State(initialValue: defaultRules.winByTwo)
    self._kitchenRule = State(initialValue: defaultRules.kitchenRule)
    self._doubleBounceRule = State(initialValue: defaultRules.doubleBounceRule)
    self._servingRotation = State(initialValue: defaultRules.servingRotation)
    self._sideSwitchingRule = State(initialValue: defaultRules.sideSwitchingRule)
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

          Button(action: handleLastGameStart) {
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
          .confirmationDialog(
            "An active game is in progress",
            isPresented: $showingLiveGameConflict,
            titleVisibility: .visible
          ) {
            Button("End current game and start new", role: .destructive) {
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
                
                if pendingLastGameStart {
                  await performLastGameStart()
                  pendingLastGameStart = false
                } else if let rules = pendingGameRules, let matchup = pendingMatchup {
                  onStartGame(gameType, rules, matchup)
                  pendingGameRules = nil
                  pendingMatchup = nil
                }
              }
            }
            
            Button("Keep current game", role: .cancel) {
              pendingGameRules = nil
              pendingMatchup = nil
              pendingLastGameStart = false
            }
          } message: {
            Text("You already have a game running. What would you like to do?")
          }
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
              let rules = try createGameRules(usePresetValues: true)
              let teamSize = gameType.defaultTeamSize
              let matchup = MatchupSelection(teamSize: teamSize, mode: .players(sideA: [], sideB: []))
              if activeGameStateManager.hasLiveGame {
                pendingGameRules = rules
                pendingMatchup = matchup
                showingLiveGameConflict = true
              } else {
                onStartGame(gameType, rules, matchup)
              }
            } catch let error as GameRulesError {
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
        onStartGame: { gameType, rules, matchup in
          showingSetupSheet = false
          handleGameStart(gameType, rules: rules, matchup: matchup)
        }
      )
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

  private func handleGameStart(_ gameType: GameType, rules: GameRules?, matchup: MatchupSelection) {
    isCreatingGame = true

    Task { @MainActor in
      isCreatingGame = false

      if activeGameStateManager.hasLiveGame {
        pendingGameRules = rules
        pendingMatchup = matchup
        showingLiveGameConflict = true
      } else {
        onStartGame(gameType, rules, matchup)
      }
    }
  }

  private func handleLastGameStart() {
    isCreatingGame = true

    Task { @MainActor in
      defer { isCreatingGame = false }

      if activeGameStateManager.hasLiveGame {
        pendingLastGameStart = true
        showingLiveGameConflict = true
        return
      }

      await performLastGameStart()
    }
  }
  
  private func performLastGameStart() async {
    do {
      let game = try await activeGameStateManager.startLastGame(of: gameType)

      Log.event(
        .viewAppear,
        level: .info,
        message: "Last game started",
        context: .current(gameId: game.id),
        metadata: ["gameType": gameType.rawValue]
      )

      NotificationCenter.default.post(
        name: Notification.Name("OpenLiveGameRequested"),
        object: nil
      )

      // Mirror game start on companion
      // 1) Publish roster snapshot first to ensure identities exist
      let rosterBuilder = RosterSnapshotBuilder(storage: SwiftDataStorage.shared)
      if let roster = try? rosterBuilder.build(includeArchived: false) {
        try? await syncCoordinator.publishRoster(roster)
      }
      // 2) Publish start configuration with gameId for id alignment
      let config = GameStartConfiguration(
        gameId: game.id,
        gameType: game.gameType,
        teamSize: TeamSize(playersPerSide: game.effectiveTeamSize) ?? .doubles,
        participants: {
          switch game.participantMode {
          case .players:
            return Participants(side1: .players(game.side1PlayerIds), side2: .players(game.side2PlayerIds))
          case .teams:
            return Participants(side1: .team(game.side1TeamId!), side2: .team(game.side2TeamId!))
          case .anonymous:
            return Participants(side1: .players([]), side2: .players([]))
          }
        }(),
        rules: try? GameRules.createValidated(
          winningScore: game.winningScore,
          winByTwo: game.winByTwo,
          kitchenRule: game.kitchenRule,
          doubleBounceRule: game.doubleBounceRule,
          servingRotation: game.servingRotation,
          sideSwitchingRule: game.sideSwitchingRule,
          scoringType: game.scoringType,
          timeLimit: game.timeLimit,
          maxRallies: game.maxRallies
        )
      )
      try? await syncCoordinator.publishStart(config)
    } catch let error as GameRulesError {
      errorMessage = error.localizedDescription
      if let suggestion = error.recoverySuggestion {
        errorMessage += "\n\n" + suggestion
      }
      showingError = true
    } catch {
      Log.error(
        error,
        event: .saveFailed,
        metadata: ["phase": "startLastGame"]
      )
      errorMessage = "Failed to start last game: \(error.localizedDescription)"
      showingError = true
    }
  }

  private func createGameRules(
    usePresetValues: Bool = false,
    teamSize: Int? = nil
  ) throws(GameRulesError) -> GameRules {

    if usePresetValues {
      return gameType.defaultRules
    } else {
      // GameRules doesn't include teamSize - that's determined by matchup
      // Just return the rules based on the form values
      let rules = GameRules(
        winningScore: winningScore,
        winByTwo: winByTwo,
        kitchenRule: kitchenRule,
        doubleBounceRule: doubleBounceRule,
        servingRotation: servingRotation,
        sideSwitchingRule: sideSwitchingRule,
        scoringType: .sideOut
      )
      return rules
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
      onStartGame: { gameType, rules, matchup in
        Log.event(
          .actionTapped,
          level: .debug,
          message: "Start from preview",
          metadata: ["gameType": gameType.rawValue, "teamSize": String(matchup.teamSize)]
        )
      }
    )
  }
  .modelContainer(container)
  .environment(liveGameManager)
  .environment(gameManager)
  .accentColor(.green)
}
