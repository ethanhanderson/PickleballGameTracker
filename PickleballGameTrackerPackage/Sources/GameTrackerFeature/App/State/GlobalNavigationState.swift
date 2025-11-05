import Foundation
import SwiftUI

@MainActor
@Observable
public final class GlobalNavigationState {
    public static let shared = GlobalNavigationState()

    // High-level navigation context
    public private(set) var currentTab: AppTab = .games
    public private(set) var currentRootViewId: String? = nil
    public private(set) var isAppActive: Bool = false

    // Sheet tracking across the app
    private var openSheetIdentifiers: Set<String> = []

    private init() {}

    // MARK: - App lifecycle
    public func setActive(_ active: Bool) {
        isAppActive = active
    }

    // MARK: - Navigation context
    public func setCurrentTab(_ tab: AppTab) {
        currentTab = tab
    }

    public func setCurrentRootView(_ identifier: String?) {
        currentRootViewId = identifier
    }

    // MARK: - Sheet tracking
    public func registerSheet(_ identifier: String) {
        openSheetIdentifiers.insert(identifier)
    }

    public func unregisterSheet(_ identifier: String) {
        openSheetIdentifiers.remove(identifier)
    }

    public var hasOpenSheet: Bool {
        !openSheetIdentifiers.isEmpty
    }

    public func isSheetOpen(_ identifier: String) -> Bool {
        openSheetIdentifiers.contains(identifier)
    }
}


