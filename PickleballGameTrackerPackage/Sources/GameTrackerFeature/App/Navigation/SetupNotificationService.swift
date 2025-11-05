import Foundation
import UserNotifications
import GameTrackerCore

@MainActor
public final class SetupNotificationService {
    public static let shared = SetupNotificationService()
    
    private let notificationIdentifier = "watchSetupRequest"
    private let gameTypeKey = "gameType"
    
    private init() {}
    
    public func scheduleSetupNotification(for gameType: GameType) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        guard settings.authorizationStatus == .authorized else {
            Log.event(
                .saveFailed,
                level: .warn,
                message: "Cannot schedule setup notification: authorization denied",
                metadata: ["gameType": gameType.rawValue]
            )
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Game Setup Requested"
        content.body = "Your Apple Watch wants to start a \(gameType.displayName) game. Tap to open setup."
        content.sound = .default
        content.userInfo = [gameTypeKey: gameType.rawValue]
        content.categoryIdentifier = "SETUP_REQUEST"
        
        let request = UNNotificationRequest(
            identifier: notificationIdentifier,
            content: content,
            trigger: nil
        )
        
        do {
            try await center.add(request)
            Log.event(
                .actionTapped,
                level: .info,
                message: "Setup notification scheduled from watch",
                metadata: ["gameType": gameType.rawValue]
            )
        } catch {
            Log.error(
                error,
                event: .saveFailed,
                metadata: ["phase": "scheduleSetupNotification", "gameType": gameType.rawValue]
            )
        }
    }
    
    public func clearPendingNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
        center.removeDeliveredNotifications(withIdentifiers: [notificationIdentifier])
    }
}

extension Notification.Name {
    public static let setupNotificationTapped = Notification.Name("SetupNotificationTapped")
}

