import Foundation

extension Notification.Name {
  static let historyDeleteRequested = Notification.Name("HistoryDeleteRequested")
}

enum HistoryDeletionRequestBus {
  private enum Key {
    static let gameId = "gameId"
  }

  static func requestDelete(gameId: UUID) {
    NotificationCenter.default.post(
      name: .historyDeleteRequested,
      object: nil,
      userInfo: [Key.gameId: gameId]
    )
  }

  @discardableResult
  static func observeDeleteRequests(
    using handler: @escaping @Sendable (UUID) -> Void
  ) -> any NSObjectProtocol {
    NotificationCenter.default.addObserver(forName: .historyDeleteRequested, object: nil, queue: .main) {
      note in
      if let id = note.userInfo?[Key.gameId] as? UUID {
        handler(id)
      }
    }
  }
}


