import Foundation

@MainActor
@Observable
public final class AppActivityTracker {
    public static let shared = AppActivityTracker()
    
    public private(set) var isActive: Bool = false
    
    private init() {}
    
    public func setActive(_ active: Bool) {
        isActive = active
    }
}


