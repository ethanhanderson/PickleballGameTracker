import Foundation

@MainActor
@Observable
public final class SheetStateManager {
    public static let shared = SheetStateManager()
    
    private var sheetStates: Set<String> = []
    public private(set) var currentRootViewId: String? = nil
    
    private init() {}
    
    public func registerSheet(_ identifier: String) {
        sheetStates.insert(identifier)
    }
    
    public func unregisterSheet(_ identifier: String) {
        sheetStates.remove(identifier)
    }
    
    public var hasOpenSheet: Bool {
        !sheetStates.isEmpty
    }

    public func setCurrentRootView(_ identifier: String?) {
        currentRootViewId = identifier
    }

    public func isSheetOpen(_ identifier: String) -> Bool {
        sheetStates.contains(identifier)
    }
}

