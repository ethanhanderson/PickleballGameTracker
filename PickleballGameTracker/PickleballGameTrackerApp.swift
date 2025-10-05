import GameTrackerCore
import GameTrackerFeature
import SwiftData
import SwiftUI

@main
struct PickleballGameTrackerApp: App {
  private let liveGameStateManager = LiveGameStateManager.production()
  private let rosterManager = PlayerTeamManager()
  
  init() {
    Task { await LoggingService.shared.configure(sinks: [OSLogSink(), ConsoleSink()]) }
    Log.event(.appLaunch, level: .info, message: "iOS app launch")
  }

  var body: some Scene {
    WindowGroup {
      AppNavigationView()
        .modelContainer(SwiftDataContainer.shared.modelContainer)
        .environment(liveGameStateManager)
        .environment(liveGameStateManager.gameManager!)
        .environment(rosterManager)
    }
  }
}
