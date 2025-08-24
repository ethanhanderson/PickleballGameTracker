import Foundation

extension Notification.Name {
  public static let deepLinkRequested = Notification.Name("DeepLinkRequested")
}

enum DeepLinkPayloadKey {
  static let destination = "destination"
}

public enum DeepLinkBus {
  /// Post a deep link destination for in-app navigation.
  /// - Parameter destination: The resolved destination to navigate to.
  public static func post(_ destination: DeepLinkDestination) {
    NotificationCenter.default.post(
      name: .deepLinkRequested,
      object: nil,
      userInfo: [DeepLinkPayloadKey.destination: destination]
    )
  }

  /// Observe deep link requests with a NotificationCenter token.
  /// - Note: Caller is responsible for retaining and removing the observer when done.
  /// - Parameter handler: Callback invoked on main queue with the destination.
  /// - Returns: An opaque observer token to remove when done.
  @discardableResult
  public static func observe(
    using handler: @escaping @Sendable (DeepLinkDestination) -> Void
  ) -> any NSObjectProtocol {
    NotificationCenter.default.addObserver(forName: .deepLinkRequested, object: nil, queue: .main) {
      note in
      if let dest = note.userInfo?[DeepLinkPayloadKey.destination] as? DeepLinkDestination {
        handler(dest)
      }
    }
  }

  /// Async sequence of deep link destinations.
  /// - Returns: A tuple of `(stream, cancel)`; call `cancel()` to terminate the stream.
  public static func makeStream() -> (
    stream: AsyncStream<DeepLinkDestination>,
    cancel: () -> Void
  ) {
    var token: (any NSObjectProtocol)?

    let stream = AsyncStream<DeepLinkDestination> { continuation in
      token = NotificationCenter.default.addObserver(
        forName: .deepLinkRequested, object: nil, queue: .main
      ) { note in
        if let dest = note.userInfo?[DeepLinkPayloadKey.destination] as? DeepLinkDestination {
          continuation.yield(dest)
        }
      }
    }

    let cancel = {
      if let token { NotificationCenter.default.removeObserver(token) }
    }

    return (stream, cancel)
  }
}
