//
//  AppNavigationView.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 7/9/25.
//

import CorePackage
import SwiftData
import SwiftUI

@MainActor
public struct AppNavigationView: View {
  @Namespace var animation
  @Environment(\.modelContext) private var modelContext
  @State private var rosterManager: PlayerTeamManager

  public init(rosterManager: PlayerTeamManager = PlayerTeamManager()) {
    _rosterManager = State(initialValue: rosterManager)
  }
  @State private var selectedTab: AppTab = .games
  @State private var showingActiveGameSheet = false

  @State private var gameManager = SwiftDataGameManager()
  @Environment(ActiveGameStateManager.self) private var activeGameStateManager

  @State private var deepLinkDestination: DeepLinkDestination?
  @State private var showDeepLink: Bool = false
  @State private var statisticsFilter: (gameId: String?, gameTypeId: String?)? = nil
  @State private var deepLinkObserver: (any NSObjectProtocol)? = nil

  // MARK: - Body

  public var body: some View {
    TabView(selection: $selectedTab) {
      Tab("Games", systemImage: "gamecontroller", value: AppTab.games) {
        GameHomeView()
          .accessibilityIdentifier("Tab.Games")
      }

      Tab("History", systemImage: "clock", value: AppTab.history) {
        GameHistoryView()
          .accessibilityIdentifier("Tab.History")
      }

      Tab(
        "Roster",
        systemImage: "person.2",
        value: AppTab.roster
      ) {
        RosterHomeView(manager: rosterManager)
          .accessibilityIdentifier("Tab.Roster")
      }

      Tab(
        "Statistics",
        systemImage: "chart.bar",
        value: AppTab.statistics
      ) {
        StatisticsHomeView(
          gameId: statisticsFilter?.gameId,
          gameTypeId: statisticsFilter?.gameTypeId
        )
        .accessibilityIdentifier("Tab.Statistics")
      }

      Tab(
        "Search",
        systemImage: "magnifyingglass",
        value: AppTab.search,
        role: .search
      ) {
        GameSearchView(
          modelContext: modelContext,
          navigationState: AppNavigationState()
        )
        .accessibilityIdentifier("Tab.Search")
      }
    }
    .accentColor(DesignSystem.Colors.primary)
    .environment(gameManager)
    .tabViewBottomAccessory {
      if activeGameStateManager.hasActiveGame {
        GamePreviewControls(
          onTap: {
            showingActiveGameSheet = true
          },
          animation: animation
        )
      }
    }
    .tabBarMinimizeBehavior(.onScrollDown)
    .task {
      // Configure both managers with proper relationships
      activeGameStateManager.configure(
        with: modelContext,
        gameManager: gameManager
      )
      // Ensure device sync is enabled so watch sees phone-created games
      activeGameStateManager.setSyncEnabled(true)

      // Observe in-app deep link requests via DeepLinkBus
      deepLinkObserver = DeepLinkBus.observe { dest in
        Task { @MainActor in
          switch dest {
          case .statistics(let gameId, let gameTypeId):
            statisticsFilter = (gameId, gameTypeId)
            selectedTab = .statistics
            showDeepLink = false
            deepLinkDestination = nil
          default:
            deepLinkDestination = dest
            showDeepLink = true
          }
        }
      }
    }
    .onDisappear {
      if let deepLinkObserver { NotificationCenter.default.removeObserver(deepLinkObserver) }
      deepLinkObserver = nil
    }
    .onOpenURL { url in
      do {
        let dest = try DeepLinkResolver().resolve(url)
        Log.event(
          .viewAppear,
          level: .info,
          message: "Deep link resolved",
          metadata: ["url": url.absoluteString]
        )
        switch dest {
        case .statistics(let gameId, let gameTypeId):
          statisticsFilter = (gameId, gameTypeId)
          selectedTab = .statistics
          showDeepLink = false
          deepLinkDestination = nil
        default:
          deepLinkDestination = dest
          showDeepLink = true
        }
      } catch {
        Log.error(
          error,
          event: .loadFailed,
          metadata: ["phase": "deepLinkResolve"]
        )
      }
    }
    .sheet(isPresented: $showingActiveGameSheet) {
      if let currentGame = activeGameStateManager.currentGame {
        NavigationStack {
          ActiveGameView(
            game: currentGame,
            gameManager: gameManager,
            onDismiss: {
              showingActiveGameSheet = false
            }
          )
        }
        .navigationTint()
        .navigationTransition(.zoom(sourceID: "sheet", in: animation))
      }
    }
    // Deep link presentation as a top-level sheet for non-Statistics destinations in v0.3
    .sheet(isPresented: $showDeepLink) {
      NavigationStack {
        DeepLinkDestinationView(
          destination: deepLinkDestination,
          gameManager: gameManager,
          activeGameStateManager: activeGameStateManager
        )
      }
      .navigationTint()
    }

  }
}

// MARK: - Preview Support

extension AppNavigationView {
  fileprivate static func createPreviewContainer() -> ModelContainer {
    return SwiftDataContainer.createPreviewContainer()
  }

  fileprivate static var blankPreview: some View {
    let container = try! CorePackage.PreviewGameData.createPreviewContainer(with: [])
    let context = container.mainContext

    UserDefaults.standard.removeObject(forKey: "GameSearchHistory")

    let rosterManager = PlayerTeamManager(storage: SwiftDataStorage(modelContainer: container))

    return AppNavigationView(rosterManager: rosterManager)
      .modelContainer(container)
      .environment(ActiveGameStateManager.shared)
      .task {
        let stateManager = ActiveGameStateManager.shared
        stateManager.configure(with: context)
        stateManager.clearCurrentGame()
        try? context.delete(model: PlayerProfile.self)
        try? context.delete(model: TeamProfile.self)
        try? context.delete(model: GameTypePreset.self)
        try? context.delete(model: Game.self)
        try? context.delete(model: GameSummary.self)
        try? context.save()
      }
  }

  fileprivate static var populatedPreview: some View {
    let container = try! CorePackage.PreviewGameData.createFullPreviewContainer()
    let context = container.mainContext

    UserDefaults.standard.set(
      [GameType.training.rawValue, GameType.recreational.rawValue, GameType.tournament.rawValue],
      forKey: "GameSearchHistory")

    // Use core package preview roster data, but CLONE into fresh @Model instances
    // to avoid stale SwiftData references across previews/containers.
    var oldIdToNewPlayer: [UUID: PlayerProfile] = [:]
    for src in CorePackage.PreviewGameData.samplePlayers {
      let clone = PlayerProfile(
        id: src.id,
        name: src.name,
        notes: src.notes,
        isArchived: src.isArchived,
        avatarImageData: src.avatarImageData,
        iconSymbolName: src.iconSymbolName,
        iconTintColor: src.iconTintColor,
        skillLevel: src.skillLevel,
        preferredHand: src.preferredHand,
        createdDate: src.createdDate,
        lastModified: Date()
      )
      context.insert(clone)
      oldIdToNewPlayer[src.id] = clone
    }
    for src in CorePackage.PreviewGameData.sampleTeams {
      let remappedPlayers: [PlayerProfile] = src.players.compactMap { oldIdToNewPlayer[$0.id] }
      let clone = TeamProfile(
        id: src.id,
        name: src.name,
        notes: src.notes,
        isArchived: src.isArchived,
        avatarImageData: src.avatarImageData,
        iconSymbolName: src.iconSymbolName,
        iconTintColor: src.iconTintColor,
        players: remappedPlayers,
        suggestedGameType: src.suggestedGameType,
        createdDate: src.createdDate,
        lastModified: Date()
      )
      context.insert(clone)
    }
    // Ensure every active player has an active team with their name
    do {
      let activeTeams = try context.fetch(
        FetchDescriptor<TeamProfile>(predicate: #Predicate { $0.isArchived == false })
      )
      for (_, player) in oldIdToNewPlayer {
        guard player.isArchived == false else { continue }
        let hasNamedTeam = activeTeams.contains { team in
          team.players.contains(where: { $0.id == player.id })
            && team.name.localizedCaseInsensitiveContains(player.name)
        }
        if hasNamedTeam == false {
          let solo = TeamProfile(
            name: player.name,
            avatarImageData: nil,
            iconSymbolName: "person.fill",
            iconTintColor: player.iconTintColor,
            players: [player]
          )
          context.insert(solo)
        }
      }
    } catch {
      // preview-only safeguard
    }
    try? context.save()

    let rosterManager = PlayerTeamManager(storage: SwiftDataStorage(modelContainer: container))

    return AppNavigationView(rosterManager: rosterManager)
      .modelContainer(container)
      .environment(ActiveGameStateManager.shared)
      .task {
        let stateManager = ActiveGameStateManager.shared
        stateManager.configure(with: context)
        stateManager.setCurrentGame(CorePackage.PreviewGameData.midGame)
        rosterManager.refreshAll()
      }
  }
}

// MARK: - Previews

#Preview("Blank") { AppNavigationView.blankPreview }

#Preview("Fully Populated") { AppNavigationView.populatedPreview }
