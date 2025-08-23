import Foundation

public extension Notification.Name {
  static let deepLinkRequested = Notification.Name("DeepLinkRequested")
}

public enum DeepLinkPayloadKey {
  public static let destination = "destination"
}

public enum DeepLinkBus {
  public static func post(_ destination: DeepLinkDestination) {
    NotificationCenter.default.post(
      name: .deepLinkRequested,
      object: nil,
      userInfo: [DeepLinkPayloadKey.destination: destination]
    )
  }
}


