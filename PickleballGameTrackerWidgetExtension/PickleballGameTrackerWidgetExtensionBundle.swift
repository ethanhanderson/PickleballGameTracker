//
//  PickleballGameTrackerWidgetExtensionBundle.swift
//  PickleballGameTrackerWidgetExtension
//
//  Widget bundle for registering all widgets and Live Activities
//  Supports both iOS and watchOS platforms
//

import WidgetKit
import SwiftUI
#if canImport(ActivityKit)
@preconcurrency import ActivityKit
#endif

@main
struct PickleballGameTrackerWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        #if canImport(ActivityKit)
        if #available(iOS 16.1, watchOS 9.1, *) {
            GameLiveActivityWidget()
        }
        #endif
    }
}
