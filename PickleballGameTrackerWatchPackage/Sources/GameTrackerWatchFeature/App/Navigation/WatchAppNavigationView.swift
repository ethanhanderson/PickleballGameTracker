import Foundation
import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
public struct WatchAppNavigationView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Environment(LiveGameStateManager.self) private var liveGameStateManager
    @Environment(SwiftDataGameManager.self) private var gameManager
    @Environment(PlayerTeamManager.self) private var rosterManager
  @Environment(LiveSyncCoordinator.self) private var syncCoordinator
    
    // MARK: - State
    
    @State private var lastRequestError: (any Error)? = nil
  @State private var isBootstrapping = false
    
    // MARK: - Computed Properties
    
    private var isPreviewing: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    private var shouldShowLiveGame: Bool {
        liveGameStateManager.currentGame != nil
    }
    
    // Connectivity UI removed
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Body
    
    public var body: some View {
        Group {
            if shouldShowLiveGame, let liveGame = liveGameStateManager.currentGame {
                WatchLiveView(
                    game: liveGame,
                    onCompleted: {
                        liveGameStateManager.clearCurrentGame()
                    }
                )
            } else {
        switch syncCoordinator.reachability {
        case .reachable:
          WatchCatalogView()
        case .connecting:
          WatchMessageView(
            icon: "iphone",
            message: "Connecting to iPhone…",
            showSpinner: true,
            color: .blue
          )
        case .unavailable:
          WatchMessageView(
            icon: "iphone.slash",
            message: "Not connected to iPhone",
            color: .orange
          )
        }
            }
        }
        .task {
            if liveGameStateManager.gameManager == nil {
                liveGameStateManager.configure(gameManager: gameManager)
            }
          await attemptBootstrapIfNeeded()
        }
    }
    
    // MARK: - Setup Handling
    
    private func attemptBootstrapIfNeeded() async {
        guard !isBootstrapping else { return }
        do {
            isBootstrapping = true
            // If no players and no teams, request roster
            let playerCount = try modelContext.fetchCount(FetchDescriptor<PlayerProfile>())
            let teamCount = try modelContext.fetchCount(FetchDescriptor<TeamProfile>())
            if playerCount == 0 && teamCount == 0 {
                syncCoordinator.onReceiveRosterSnapshot = { roster in
                    Task { @MainActor in
                        // Log that a roster snapshot was received on the watch
                        Log.event(
                            .loadStarted,
                            level: .info,
                            message: "roster.sync.snapshot.received",
                            metadata: [
                                "players": "\(roster.players.count)",
                                "teams": "\(roster.teams.count)",
                                "presets": "\(roster.presets.count)"
                            ]
                        )

                        do {
                            // Capture pre-import IDs to compute additions
                            let existingPlayers = try modelContext
                                .fetch(FetchDescriptor<PlayerProfile>())
                            let existingTeams = try modelContext
                                .fetch(FetchDescriptor<TeamProfile>())
                            let existingPresets = try modelContext
                                .fetch(FetchDescriptor<GameTypePreset>())

                            let beforePlayerIds = Set(existingPlayers.map { $0.id })
                            let beforeTeamIds = Set(existingTeams.map { $0.id })
                            let beforePresetIds = Set(existingPresets.map { $0.id })

                            // Perform import (merge behavior)
                            try await SwiftDataStorage.shared.importRosterSnapshot(roster, mode: .merge)

                            // Fetch after-import and compute deltas
                            let afterPlayers = try modelContext
                                .fetch(FetchDescriptor<PlayerProfile>())
                            let afterTeams = try modelContext
                                .fetch(FetchDescriptor<TeamProfile>())
                            let afterPresets = try modelContext
                                .fetch(FetchDescriptor<GameTypePreset>())

                            let addedPlayers = afterPlayers.filter { beforePlayerIds.contains($0.id) == false }
                            let addedTeams = afterTeams.filter { beforeTeamIds.contains($0.id) == false }
                            let addedPresets = afterPresets.filter { beforePresetIds.contains($0.id) == false }

                            // Report what was added to the watch's roster
                            Log.event(
                                .saveSucceeded,
                                level: .info,
                                message: "roster.sync.imported",
                                metadata: [
                                    "addedPlayers.count": "\(addedPlayers.count)",
                                    "addedTeams.count": "\(addedTeams.count)",
                                    "addedPresets.count": "\(addedPresets.count)",
                                    "addedPlayers": addedPlayers.map { $0.name }.joined(separator: "|") ,
                                    "addedTeams": addedTeams.map { $0.name }.joined(separator: "|"),
                                    "addedPresets": addedPresets.map { $0.name }.joined(separator: "|")
                                ]
                            )
                        } catch {
                            // Failure logging (import or queries)
                            Log.error(
                                error,
                                event: .saveFailed,
                                metadata: ["phase": "roster.sync.import"]
                            )
                        }
                    }
                }
                Log.event(
                    .loadStarted,
                    level: .info,
                    message: "roster.sync.requested",
                    metadata: [
                        "existing.players": "\(playerCount)",
                        "existing.teams": "\(teamCount)"
                    ]
                )
                try await syncCoordinator.requestRoster()
            }
        } catch {
            lastRequestError = error
        }
        isBootstrapping = false
    }

    // applyRosterSnapshot no longer needed; importing handled directly in onReceive callback
}

// MARK: - Previews

#Preview("Catalog Only") {
    let setup = PreviewContainers.standardSetup()
    
    WatchAppNavigationView()
        .modelContainer(setup.container)
        .environment(setup.liveGameManager)
        .environment(setup.gameManager)
        .environment(setup.rosterManager)
}

#Preview("Live Game") {
    let setup = PreviewContainers.liveGameSetup()
    
    WatchAppNavigationView()
        .modelContainer(setup.container)
        .environment(setup.liveGameManager)
        .environment(setup.gameManager)
        .environment(setup.rosterManager)
}

