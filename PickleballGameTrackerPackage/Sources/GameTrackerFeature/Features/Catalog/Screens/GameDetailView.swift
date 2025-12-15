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
  @Environment(PersonalizationEngine.self) private var personalizationEngine
  @Environment(\.modelContext) private var modelContext

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
  @State private var pendingSelectedGame: Game?
  @State private var showingSetupSheet = false
  @State private var showingRecentGamesSheet = false
  @State private var showingGroupSetupSheet = false
  @State private var showingGroupSessionSheet = false
  @State private var createdGroupSession: GroupPlaySession?

  private static let completedSort: [SortDescriptor<GameSummary>] = [
    SortDescriptor(\.completedDate, order: .reverse)
  ]
  @Query private var completedSummaries: [GameSummary]
  
  @State private var similarGames: [GameType] = []

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

    let predicate: Predicate<GameSummary> = #Predicate { summary in
      summary.gameTypeId == gameType.rawValue
    }
    self._completedSummaries = Query(filter: predicate, sort: Self.completedSort)
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

        if completedSummaries.isEmpty == false {
          HStack(spacing: DesignSystem.Spacing.md) {
            Button(action: { 
              if gameType == .groupPlay {
                showingGroupSetupSheet = true
              } else {
                showingSetupSheet = true
              }
            }) {
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

            Button(action: { showingRecentGamesSheet = true }) {
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
                  
                  if let selected = pendingSelectedGame {
                    pendingSelectedGame = nil
                    await startFromCompleted(selected)
                  } else if pendingLastGameStart {
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
        } else {
          Button(action: { 
            if gameType == .groupPlay {
              showingGroupSetupSheet = true
            } else {
              showingSetupSheet = true
            }
          }) {
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
          .padding(.bottom, DesignSystem.Spacing.sm)
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
                
                if let selected = pendingSelectedGame {
                  pendingSelectedGame = nil
                  await startFromCompleted(selected)
                } else if pendingLastGameStart {
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
          
          if similarGames.isEmpty == false {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
              Text("Similar games")
                .font(.headline)
                .padding(.bottom, DesignSystem.Spacing.xs)
              ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: DesignSystem.Spacing.md) {
                  ForEach(similarGames, id: \.self) { gt in
                    NavigationLink(
                      value: GameSectionDestination.gameDetail(gt)
                    ) {
                      GameTypeCard(gameType: gt)
                    }
                    .accessibilityIdentifier("NavLink.Games.similar.\(gt.rawValue)")
                  }
                }
                .scrollTargetLayout()
              }
              .contentMargins(.horizontal, DesignSystem.Spacing.md, for: .scrollContent)
              .scrollTargetBehavior(.viewAligned)
              .scrollClipDisabled()
            }
          }
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
      .environment(personalizationEngine)
    }
    .sheet(isPresented: $showingRecentGamesSheet) {
      RecentGamesSheet(
        gameType: gameType,
        onSelect: { game in
          Task { @MainActor in
            showingRecentGamesSheet = false
            if activeGameStateManager.hasLiveGame {
              pendingSelectedGame = game
              showingLiveGameConflict = true
            } else {
              await startFromCompleted(game)
            }
          }
        },
        onStartNewGame: { showingSetupSheet = true }
      )
    }
    .sheet(isPresented: $showingGroupSetupSheet) {
      GroupPlaySetupView { session in
        createdGroupSession = session
        showingGroupSessionSheet = true
      }
      .environment(personalizationEngine)
    }
    .sheet(isPresented: $showingGroupSessionSheet) {
      if let session = createdGroupSession {
        NavigationStack {
          GroupPlaySessionView(session: session)
        }
        .environment(personalizationEngine)
      }
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
    .task(id: gameType.rawValue) {
      // Load similar games for this detail view
      similarGames = personalizationEngine.recommendations(for: gameType, context: modelContext, max: 8)
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

      // Personalization start is now deferred to first meaningful activity or 5-minute threshold

      await LiveGameStartSync.syncGameStart(
        source: "startLastGame",
        game: game,
        liveManager: activeGameStateManager,
        syncCoordinator: syncCoordinator
      )
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

  private func startFromCompleted(_ lastGame: Game) async {
    do {
      let game = try await activeGameStateManager.startGameFromCompleted(lastGame)

      Log.event(
        .viewAppear,
        level: .info,
        message: "Selected recent game started",
        context: .current(gameId: game.id),
        metadata: ["gameType": gameType.rawValue]
      )

      NotificationCenter.default.post(
        name: Notification.Name("OpenLiveGameRequested"),
        object: nil
      )

      // Personalization start is now deferred to first meaningful activity or 5-minute threshold

      await LiveGameStartSync.syncGameStart(
        source: "startFromCompleted",
        game: game,
        liveManager: activeGameStateManager,
        syncCoordinator: syncCoordinator
      )
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
        metadata: ["phase": "startFromCompleted"]
      )
      errorMessage = "Failed to start selected game: \(error.localizedDescription)"
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
  let p = PersonalizationPreviewFactory.build(profile: .mixedRecent)
  let container = p.container
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
  .environment(p.engine)
  .accentColor(.green)
}
