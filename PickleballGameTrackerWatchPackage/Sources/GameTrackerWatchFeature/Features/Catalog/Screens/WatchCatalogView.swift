import Foundation
import GameTrackerCore
import SwiftData
import SwiftUI

//  WatchCatalogView.swift
//  Pickleball Score Tracking Watch App
//
//  Created by Ethan Anderson on 7/9/25.
//

@MainActor
public struct WatchCatalogView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Environment(LiveGameStateManager.self) private var liveGameStateManager
    @Environment(SwiftDataGameManager.self) private var gameManager
    @Environment(PlayerTeamManager.self) private var rosterManager
    @Environment(LiveSyncCoordinator.self) private var syncCoordinator
    
    // MARK: - Tab State
    
    private enum TabSelection: Hashable {
        case gameType(GameType)
    }
    
    @State private var selectedTab: TabSelection
    @State private var showTopBarActions = true
    
    // MARK: - UI State
    
    @State private var isCreatingGame = false
    @State private var isStartingNewGame = false
    @State private var isLastGameAvailable = false
    @State private var isStartingLastGame = false
    @State private var showingRecentGamesSheet = false
    @State private var pendingSelectedGame: Game?
    
    // MARK: - Conflict & Error State
    
    @State private var showingLiveGameConflict = false
    @State private var pendingLastGameStart = false
    @State private var showingError = false
    @State private var errorMessage: String = ""
    
    // MARK: - Constants
    
    @Query(
        sort: [SortDescriptor<GameSummary>(\.completedDate, order: .reverse)]
    ) private var recentSummaries: [GameSummary]

    // MARK: - Initialization
    
    public init() {
        let initial = GameType.allCases.first!
        self._selectedTab = State(initialValue: .gameType(initial))
    }
    
    // MARK: - Body
    
    public var body: some View {
        NavigationStack {
            tabViewContent()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Log.event(
                            .actionTapped,
                            level: .debug,
                            message: "Statistics tapped",
                            metadata: ["platform": "watchOS"]
                        )
                    } label: {
                        Image(systemName: "chart.bar.fill")
                            .foregroundStyle(.white)
                    }
                    .opacity(showTopBarActions ? 1 : 0)
                    .allowsHitTesting(showTopBarActions)
                    .animation(.easeInOut, value: showTopBarActions)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Log.event(
                            .actionTapped,
                            level: .debug,
                            message: "History tapped",
                            metadata: ["platform": "watchOS"]
                        )
                    } label: {
                        Image(systemName: "clock")
                            .foregroundStyle(.white)
                    }
                    .opacity(showTopBarActions ? 1 : 0)
                    .allowsHitTesting(showTopBarActions)
                    .animation(.easeInOut, value: showTopBarActions)
                }
                
                ToolbarItemGroup(placement: .bottomBar) {
                    ZStack {
                        HStack {
                            Spacer()
                            
                            Button {
                                if isLastGameAvailable {
                                    showingRecentGamesSheet = true
                                } else {
                                    handlePlayButtonTapped()
                                }
                            } label: {
                                if isStartingLastGame || isCreatingGame || isStartingNewGame {
                                    ProgressView()
                                        .progressViewStyle(
                                            CircularProgressViewStyle(tint: .white)
                                        )
                                        .scaleEffect(0.8)
                                } else if isLastGameAvailable {
                                    Image(systemName: "arrow.trianglehead.2.clockwise")
                                        .foregroundStyle(.white)
                                        .contentTransition(.symbolEffect(.replace))
                                } else {
                                    Image(systemName: "play.fill")
                                        .foregroundStyle(.white)
                                        .contentTransition(.symbolEffect(.replace))
                                }
                            }
                            .controlSize(.large)
                            .frame(width: 44, height: 44)
                            .tint(uiGameTypeForTint.color.opacity(0.6))
                            .disabled(
                                isCreatingGame ||
                                isStartingLastGame ||
                                isStartingNewGame ||
                                (isPreviewing && !isLastGameAvailable)
                            )
                            .accessibilityIdentifier("catalog.primaryAction")
                            
                            Spacer()
                        }
                        
                        HStack {
                            Spacer()
                            
                            Button {
                                handlePlayButtonTapped()
                            } label: {
                                if isStartingNewGame {
                                    ProgressView()
                                        .progressViewStyle(
                                            CircularProgressViewStyle(tint: .white)
                                        )
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "play.fill")
                                        .foregroundStyle(.white)
                                }
                            }
                            .controlSize(.regular)
                            .frame(width: 36, height: 36)
                            .disabled(isCreatingGame || isStartingLastGame || isStartingNewGame || isPreviewing)
                            .opacity(isLastGameAvailable ? 1 : 0)
                            .allowsHitTesting(isLastGameAvailable && !isPreviewing && !isStartingNewGame)
                            .accessibilityIdentifier("catalog.secondaryNewGame")
                        }
                    }
                }
            }
        }
        .task {
            await refreshLastGameAvailability()
        }
        .onChange(of: liveGameStateManager.hasLiveGame) { _, hasLive in
            if hasLive {
                isStartingNewGame = false
            }
        }
        .onChange(of: selectedTab) { _, newValue in
            withAnimation(.easeInOut) { showTopBarActions = true }
            Task { @MainActor in
                await refreshLastGameAvailability()
            }
        }
        .confirmationDialog(
            "An active game is in progress",
            isPresented: $showingLiveGameConflict,
            titleVisibility: .visible
        ) {
            Button("Complete current game") {
                Task { @MainActor in
                    do {
                        try await liveGameStateManager.completeCurrentGame()
                    } catch {
                        Log.error(
                            error,
                            event: .saveFailed,
                            metadata: ["phase": "completeBeforeStart", "platform": "watchOS"]
                        )
                    }
                    
                    if let selected = pendingSelectedGame {
                        pendingSelectedGame = nil
                        await startFromCompleted(selected)
                    } else if pendingLastGameStart {
                        await performLastGameStart()
                        pendingLastGameStart = false
                    }
                }
            }
            
            Button("Keep current game", role: .cancel) {
                pendingLastGameStart = false
            }
        } message: {
            Text("You already have a game running. What would you like to do?")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingRecentGamesSheet) {
            WatchRecentGamesSheet(gameType: uiGameTypeForTint) { game in
                Task { @MainActor in
                    showingRecentGamesSheet = false
                    guard game.modelContext != nil else {
                        errorMessage = "Selected game is no longer available."
                        showingError = true
                        return
                    }
                    if liveGameStateManager.hasLiveGame {
                        pendingSelectedGame = game
                        showingLiveGameConflict = true
                    } else {
                        await startFromCompleted(game)
                    }
                }
            }
        }
    }

    // MARK: - Tab Content
    
    @ViewBuilder
    private func tabViewContent() -> some View {
        TabView(selection: $selectedTab) {
            ForEach(rankedGameTypes, id: \.self) { gameType in
                GameTypeCard(gameType: gameType)
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .top
                    )
                    .padding(DesignSystem.Spacing.sm)
                    .containerBackground(
                        gameType.color.gradient,
                        for: .tabView
                    )
                    .tag(TabSelection.gameType(gameType))
            }
        }
        .tabViewStyle(.verticalPage)
    }
    
    // MARK: - Actions

    private func handlePlayButtonTapped() {
        Log.event(
            .actionTapped,
            level: .debug,
            message: "New game tapped",
            metadata: ["platform": "watchOS", "gameType": uiGameTypeForTint.rawValue]
        )
        
        if isPreviewing {
            Log.event(
                .actionTapped,
                level: .debug,
                message: "New game disabled in preview",
                metadata: ["platform": "watchOS"]
            )
            return
        }
        
        Task { @MainActor in
            do {
                isStartingNewGame = true
                try await syncCoordinator.requestStart(gameType: uiGameTypeForTint)
                Log.event(
                    .actionTapped,
                    level: .info,
                    message: "Start game request sent to iPhone",
                    metadata: ["platform": "watchOS", "gameType": uiGameTypeForTint.rawValue]
                )
            } catch {
                isStartingNewGame = false
                Log.error(
                    error,
                    event: .saveFailed,
                    metadata: ["phase": "sendStartRequest", "platform": "watchOS"]
                )
            }
        }
    }
    
    private func handleStartLastGameTapped() { /* replaced by sheet */ }
    
    private func performLastGameStart() async {
        do {
            let game = try await liveGameStateManager.startLastGame(of: uiGameTypeForTint)
            
            Log.event(
                .viewAppear,
                level: .info,
                message: "Last game started",
                context: .current(gameId: game.id),
                metadata: ["gameType": uiGameTypeForTint.rawValue, "platform": "watchOS"]
            )
            
            NotificationCenter.default.post(
                name: Notification.Name("OpenLiveGameRequested"),
                object: nil
            )

            // Mirror game start on companion
            let snapshot = GameSnapshotBuilder.make(
                from: game,
                elapsedTime: liveGameStateManager.elapsedTime,
                isTimerRunning: liveGameStateManager.isTimerRunning
            )
            try? await syncCoordinator.publish(snapshot: snapshot)
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
                metadata: ["phase": "startLastGame", "platform": "watchOS"]
            )
            errorMessage = "Failed to start last game: \(error.localizedDescription)"
            showingError = true
        }
    }

    private func startFromCompleted(_ lastGame: Game) async {
        guard lastGame.modelContext != nil else {
            errorMessage = "Selected game is no longer available."
            showingError = true
            return
        }
        do {
            let game = try await liveGameStateManager.startGameFromCompleted(lastGame)

            Log.event(
                .viewAppear,
                level: .info,
                message: "Selected recent game started",
                context: .current(gameId: game.id),
                metadata: ["gameType": uiGameTypeForTint.rawValue, "platform": "watchOS"]
            )

            NotificationCenter.default.post(
                name: Notification.Name("OpenLiveGameRequested"),
                object: nil
            )

            let snapshot = GameSnapshotBuilder.make(
                from: game,
                elapsedTime: liveGameStateManager.elapsedTime,
                isTimerRunning: liveGameStateManager.isTimerRunning
            )
            try? await syncCoordinator.publish(snapshot: snapshot)
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
                metadata: ["phase": "startFromCompleted", "platform": "watchOS"]
            )
            errorMessage = "Failed to start selected game: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func refreshLastGameAvailability() async {
        let hasRecent: Bool = {
            var fd = FetchDescriptor<GameSummary>(
                predicate: #Predicate { $0.gameTypeId == uiGameTypeForTint.rawValue }
            )
            fd.fetchLimit = 1
            return (try? modelContext.fetch(fd))?.isEmpty == false
        }()
        await MainActor.run { isLastGameAvailable = hasRecent }
    }

    private func startLocalPreviewGame() {
        guard !isCreatingGame else { return }
        isCreatingGame = true
        Task { @MainActor in
            do {
                let newGame = try await gameManager.createGame(
                    type: uiGameTypeForTint
                )
                await liveGameStateManager.setCurrentGame(newGame)
                await MainActor.run {
                    isCreatingGame = false
                }
            } catch {
                await MainActor.run {
                    isCreatingGame = false
                }
                Log.error(
                    error,
                    event: .saveFailed,
                    metadata: [
                        "platform": "watchOS",
                        "action": "startLocalPreviewGame",
                    ]
                )
            }
        }
    }

    // MARK: - Computed Properties
    
    private var uiGameTypeForTint: GameType {
        switch selectedTab {
        case .gameType(let gameType):
            return gameType
        }
    }
    
    private var isPreviewing: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    // Rank all game types by recent play (21 days), then by last played date
    private var rankedGameTypes: [GameType] {
        let all = GameType.allTypes
        let now = Date()
        let cutoff = Calendar.current.date(byAdding: .day, value: -21, to: now) ?? .distantPast
        var countsById: [String: Int] = [:]
        var lastPlayedById: [String: Date] = [:]
        for s in recentSummaries {
            lastPlayedById[s.gameTypeId] = max(lastPlayedById[s.gameTypeId] ?? .distantPast, s.completedDate)
            if s.completedDate >= cutoff {
                countsById[s.gameTypeId, default: 0] += 1
            }
        }
        return all.sorted { lhs, rhs in
            let lc = countsById[lhs.rawValue] ?? 0
            let rc = countsById[rhs.rawValue] ?? 0
            if lc != rc { return lc > rc }
            let ld = lastPlayedById[lhs.rawValue] ?? .distantPast
            let rd = lastPlayedById[rhs.rawValue] ?? .distantPast
            return ld > rd
        }
    }
}


// MARK: - Previews

#Preview {
    let container = PreviewContainers.standard()
    let (gameManager, liveGameManager) = PreviewContainers.managers(for: container)
    let rosterManager = PreviewContainers.rosterManager(for: container)

    WatchCatalogView()
        .modelContainer(container)
        .environment(liveGameManager)
        .environment(gameManager)
        .environment(rosterManager)
}
