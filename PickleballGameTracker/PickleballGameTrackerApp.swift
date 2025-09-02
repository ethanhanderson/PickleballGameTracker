import GameTrackerFeature
import CorePackage
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
