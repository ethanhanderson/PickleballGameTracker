import Foundation
import GameTrackerCore
import SwiftData
import SwiftUI

//  WatchCatalogView.swift
//  Pickleball Score Tracking Watch App
//
//  Created by Ethan Anderson on 7/9/25.
//

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
    @State private var isLastGameAvailable = false
    @State private var isStartingLastGame = false
    
    // MARK: - Conflict & Error State
    
    @State private var showingLiveGameConflict = false
    @State private var pendingLastGameStart = false
    @State private var showingError = false
    @State private var errorMessage: String = ""
    
    // MARK: - Constants
    
    private let gameTypes = GameType.watchSupportedCases

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
                                    handleStartLastGameTapped()
                                } else {
                                    handlePlayButtonTapped()
                                }
                            } label: {
                                if isStartingLastGame || isCreatingGame {
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
                            .tint(uiGameTypeForTint.color.opacity(0.6))
                            .disabled(
                                isCreatingGame ||
                                isStartingLastGame ||
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
                                Image(systemName: "play.fill")
                                    .foregroundStyle(.white)
                            }
                            .controlSize(.regular)
                            .disabled(isCreatingGame || isStartingLastGame || isPreviewing)
                            .opacity(isLastGameAvailable ? 1 : 0)
                            .allowsHitTesting(isLastGameAvailable && !isPreviewing)
                            .accessibilityIdentifier("catalog.secondaryNewGame")
                        }
                    }
                }
            }
        }
        .task {
            await refreshLastGameAvailability()
        }
        .onChange(of: selectedTab) { _, newValue in
            withAnimation(.easeInOut) { showTopBarActions = true }
            Task {
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
                    
                    if pendingLastGameStart {
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
    }

    // MARK: - Tab Content
    
    @ViewBuilder
    private func tabViewContent() -> some View {
        TabView(selection: $selectedTab) {
            ForEach(gameTypes, id: \.self) { gameType in
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
        
        NotificationCenter.default.post(
            name: Notification.Name("SetupRequested"),
            object: nil,
            userInfo: ["gameType": uiGameTypeForTint]
        )
    }
    
    private func handleStartLastGameTapped() {
        Log.event(
            .actionTapped,
            level: .debug,
            message: "Start last game tapped",
            metadata: ["platform": "watchOS", "gameType": uiGameTypeForTint.rawValue]
        )
        
        if isPreviewing {
            // Start last game is allowed in previews
        }
        
        guard !isStartingLastGame else { return }
        isStartingLastGame = true
        
        Task { @MainActor in
            defer { isStartingLastGame = false }
            
            if liveGameStateManager.hasLiveGame {
                pendingLastGameStart = true
                showingLiveGameConflict = true
                return
            }
            
            await performLastGameStart()
        }
    }
    
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
    
    private func refreshLastGameAvailability() async {
        let hasRecent = (try? await gameManager.mostRecentCompletedGame(of: uiGameTypeForTint)) != nil
        await MainActor.run {
            isLastGameAvailable = hasRecent
        }
    }

    private func startLocalPreviewGame() {
        guard !isCreatingGame else { return }
        isCreatingGame = true
        Task {
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
