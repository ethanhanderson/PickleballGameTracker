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
  
  @UIApplicationDelegateAdaptor(NotificationDelegate.self) private var notificationDelegate
  
  init() {
    Task { await LoggingService.shared.configure(sinks: [OSLogSink(), ConsoleSink()], minimumLevel: .warn) }
    Log.event(.appLaunch, level: .warn, message: "iOS app launch")
  }

  var body: some Scene {
    WindowGroup {
      AppRootView()
        .tint(.accentColor)
        .modelContainer(SwiftDataContainer.shared.modelContainer)
        .environment(liveGameStateManager)
        .environment(liveGameStateManager.gameManager!)
        .environment(rosterManager)
        .environment(syncCoordinator)
        .modifier(AppLifecycleModifier(liveGameStateManager: liveGameStateManager))
        .task {
          UNUserNotificationCenter.current().delegate = notificationDelegate
          
          let center = UNUserNotificationCenter.current()
          let settings = await center.notificationSettings()
          if settings.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
          }
          
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

          // After initial setup, forward any pending launch intent to the feature layer
          if let pending = LaunchIntentStore.shared.consumePendingSetup() {
            // Give AppNavigationView a brief moment to register observers
            try? await Task.sleep(nanoseconds: 200_000_000)
            NotificationCenter.default.post(
              name: Notification.Name("OpenSetupRequested"),
              object: nil,
              userInfo: ["gameType": pending]
            )
          }
        }
    }
  }
}

final class NotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    // Ensure notification delegate is set as early as possible for cold-start from tap
    UNUserNotificationCenter.current().delegate = self

    // Register categories used by local notifications
    let category = UNNotificationCategory(
      identifier: "SETUP_REQUEST",
      actions: [],
      intentIdentifiers: [],
      options: [.customDismissAction]
    )
    UNUserNotificationCenter.current().setNotificationCategories([category])
    return true
  }
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if response.notification.request.content.categoryIdentifier == "SETUP_REQUEST",
       let gameTypeRawValue = response.notification.request.content.userInfo["gameType"] as? String,
       let gameType = GameType(rawValue: gameTypeRawValue) {
      // Persist the intent so SwiftUI can consume even if observer isn't attached yet
      LaunchIntentStore.shared.setPendingSetup(gameType: gameType)
      Task { @MainActor in
        NotificationCenter.default.post(
          name: .setupNotificationTapped,
          object: nil,
          userInfo: ["gameType": gameType]
        )
        Log.event(
          .actionTapped,
          level: .info,
          message: "Setup notification tapped",
          metadata: ["gameType": gameType.rawValue]
        )
      }
    }
    completionHandler()
  }
  
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .sound, .badge])
  }
}

@MainActor
private struct AppLifecycleModifier: ViewModifier {
  @Environment(\.scenePhase) private var scenePhase
  let liveGameStateManager: LiveGameStateManager
  
  func body(content: Content) -> some View {
    content
      .onChange(of: scenePhase) { oldPhase, newPhase in
        if newPhase == .background {
          Task {
            await liveGameStateManager.persistSessionOnly()
          }
        }
      }
      .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
        Task {
          await liveGameStateManager.handleAppWillTerminate()
        }
      }
  }
}
