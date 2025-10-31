import GameTrackerCore
import GameTrackerFeature
import SwiftData
import SwiftUI
import UIKit
import UserNotifications
import WidgetKit

@main
struct PickleballGameTrackerApp: App {
  @State private var liveGameStateManager: LiveGameStateManager = LiveGameStateManager.production()
  @State private var rosterManager: PlayerTeamManager = PlayerTeamManager()
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
    Log.event(.appLaunch, level: .warn, message: "iOS app launch")
    
    // Best-effort: request notification permission for background setup prompts
    Task {
      let center = UNUserNotificationCenter.current()
      let settings = await center.notificationSettings()
      if settings.authorizationStatus == .notDetermined {
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
      }
    }
  }

  var body: some Scene {
    WindowGroup {
      AppNavigationView()
        .background {
          AppLifecycleHandler(liveGameStateManager: liveGameStateManager)
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
          if #available(iOS 16.1, *) {
            LiveActivityManager.shared.configure(context: SwiftDataContainer.shared.modelContainer.mainContext)
          }
          #endif
          
          // Phone acts as roster source of truth
          syncCoordinator.bind(storage: SwiftDataStorage.shared)
          // Ensure high-precision timer on iOS (centiseconds)
          liveGameStateManager.setTimerUpdateInterval(0.01)
          Log.event(
            .loadStarted,
            level: .info,
            message: "sync.bound",
            metadata: [
              "role": "phone",
              "storageBound": "true"
            ]
          )
          await syncCoordinator.start()
          // Fast resume from local session if present
          await liveGameStateManager.attemptResumeFromSession()
          Log.event(
            .loadSucceeded,
            level: .info,
            message: "sync.started",
            metadata: ["role": "phone"]
          )

          // Optional diagnostic: log current roster counts on phone
          do {
            let snapshot = try RosterSnapshotBuilder(storage: SwiftDataStorage.shared).build(includeArchived: false)
            Log.event(
              .loadSucceeded,
              level: .info,
              message: "roster.sync.phone.snapshot.preview",
              metadata: [
                "players": "\(snapshot.players.count)",
                "teams": "\(snapshot.teams.count)",
                "presets": "\(snapshot.presets.count)"
              ]
            )
          } catch {
            Log.error(error, event: .loadFailed, metadata: ["phase": "phone.roster.preview"])
          }
        }
    }
  }
}

@MainActor
private struct AppLifecycleHandler: View {
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
      .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
        // Only pause when app is actually terminating
        Task { @MainActor in
          await liveGameStateManager.handleAppWillTerminate()
        }
      }
  }
}
