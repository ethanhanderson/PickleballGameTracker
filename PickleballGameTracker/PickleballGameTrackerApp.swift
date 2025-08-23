import GameTrackerFeature
import SwiftUI

@main
struct PickleballGameTrackerApp: App {
  var body: some Scene {
    WindowGroup {
      AppNavigationView()
        .environment(ActiveGameStateManager.shared)
    }
  }
}
