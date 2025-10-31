//
//  Pickleball_Score_TrackingApp.swift
//  Pickleball Score Tracking Watch App
//
//  Created by Ethan Anderson on 7/9/25.
//

import SwiftData
import SwiftUI
import GameTrackerWatchFeature
import GameTrackerCore
import WidgetKit

@main
struct PickleballGameTrackingWatchApp: App {
  @State private var liveGameStateManager: LiveGameStateManager = LiveGameStateManager.production()
  @State private var rosterManager: PlayerTeamManager = PlayerTeamManager(storage: SwiftDataStorage.shared)
  @State private var syncCoordinator: LiveSyncCoordinator = {
    #if canImport(WatchConnectivity)
    let transport = WatchConnectivityTransport()
    let coordinator = LiveSyncCoordinator(service: transport)
    return coordinator
    #else
    return LiveSyncCoordinator(service: NoopSyncService())
    #endif
  }()
  
  init() {
    Task { await LoggingService.shared.configure(sinks: [OSLogSink(), ConsoleSink()], minimumLevel: .warn) }
    Log.event(.appLaunch, level: .warn, message: "Watch app launch")
  }
  
  var body: some Scene {
    WindowGroup {
      WatchAppNavigationView()
        .background {
          WatchAppLifecycleHandler(liveGameStateManager: liveGameStateManager)
        }
        .modelContainer(SwiftDataContainer.shared.modelContainer)
        .environment(liveGameStateManager)
        .environment(liveGameStateManager.gameManager!)
        .environment(rosterManager)
        .environment(syncCoordinator)
        .task {
          if let gm = liveGameStateManager.gameManager {
            syncCoordinator.bind(liveManager: liveGameStateManager, gameManager: gm)
          }
          
          // Configure sync coordinator for app lifecycle management
          liveGameStateManager.configure(syncCoordinator: syncCoordinator)
          
          #if canImport(ActivityKit)
          if #available(watchOS 9.1, *) {
            LiveActivityManager.shared.configure(context: SwiftDataContainer.shared.modelContainer.mainContext)
          }
          #endif
          
          await syncCoordinator.start()
          // Fast resume from local session if present
          await liveGameStateManager.attemptResumeFromSession()
        }
    }
  }
}

@MainActor
private struct WatchAppLifecycleHandler: View {
  @Environment(\.scenePhase) private var scenePhase
  let liveGameStateManager: LiveGameStateManager
  
  var body: some View {
    Color.clear
      .onChange(of: scenePhase) { oldPhase, newPhase in
        // Persist state when going to background, but don't pause
        // The game continues running in the background
        if newPhase == .background {
          Task { @MainActor in
            await liveGameStateManager.persistSessionOnly()
          }
        }
      }
      .onDisappear {
        // When view disappears (app terminating), pause if needed
        Task { @MainActor in
          await liveGameStateManager.handleAppWillTerminate()
        }
      }
  }
}
