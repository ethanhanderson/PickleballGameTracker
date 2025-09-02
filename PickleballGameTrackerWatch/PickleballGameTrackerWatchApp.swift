//
//  Pickleball_Score_TrackingApp.swift
//  Pickleball Score Tracking Watch App
//
//  Created by Ethan Anderson on 7/9/25.
//

import SwiftData
import SwiftUI
import GameTrackerWatchFeature

@main
struct Pickleball_Game_Tracking_Watch_AppApp: App {
  init() {
    Task { await LoggingService.shared.configure(sinks: [OSLogSink(), ConsoleSink()]) }
    Log.event(.appLaunch, level: .info, message: "Watch app launch")
  }
  var body: some Scene {
    WindowGroup {
      WatchGameCatalogView()
        .modelContainer(SwiftDataContainer.shared.modelContainer)
    }
  }
}
