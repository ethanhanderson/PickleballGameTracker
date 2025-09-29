import GameTrackerCore
import SwiftData
import SwiftUI

// MARK: - Deep Link Destination View

@MainActor
struct DeepLinkDestinationView: View {
  @Environment(\.modelContext) private var modelContext
  let destination: DeepLinkDestination?
  let gameManager: SwiftDataGameManager
  let activeGameStateManager: LiveGameStateManager

  var body: some View {
    switch destination {
    case .gameType(let id):
      if let gameType = GameType(rawValue: id) {
        GameDetailView(
          gameType: gameType,
          onStartGame: { variation, matchup in
            Task { @MainActor in
              do {
                let newGame: Game
                if case .players(let a, let b) = matchup.mode, a.isEmpty && b.isEmpty {
                  newGame = try await gameManager.createGame(variation: variation)
                } else {
                  newGame = try await gameManager.createGame(variation: variation, matchup: matchup)
                }
                activeGameStateManager.setCurrentGame(newGame)
                Log.event(
                  .viewAppear,
                  level: .info,
                  message: "Deep link → started game",
                  context: .current(gameId: newGame.id)
                )
              } catch {
                Log.error(
                  error,
                  event: .saveFailed,
                  metadata: ["phase": "deepLinkStartGame"]
                )
              }
            }
          }
        )
        .navigationTitle(gameType.displayName)
        .navigationBarTitleDisplayMode(.inline)
      } else {
        DeepLinkErrorView(message: "Game Type not found.")
      }

    case .completedGame(let id, _):
      if let uuid = UUID(uuidString: id), let game = fetchGame(by: uuid) {
        CompletedGameDetailView(game: game)
      } else {
        DeepLinkErrorView(message: "Completed game not found.")
      }

    case .author(let id):
      DeepLinkErrorView(message: "Author profile (\(id)) will arrive in v0.6.")

    case .statistics(let gameId, let gameTypeId):
      StatisticsDeepLinkRouter(gameId: gameId, gameTypeId: gameTypeId)

    case .none:
      DeepLinkErrorView(message: "Invalid link.")
    }
  }

  private func fetchGame(by id: UUID) -> Game? {
    let descriptor = FetchDescriptor<Game>(predicate: #Predicate { $0.id == id })
    return try? modelContext.fetch(descriptor).first
  }
}

// MARK: - Deep Link Error / Statistics Router Views

struct DeepLinkErrorView: View {
  let message: String
  var body: some View {
    SectionContainer(title: "Link Error") {
      VStack(spacing: 16) {
        Image(systemName: "link.badge.plus")
          .font(.system(size: 24, weight: .semibold))
          .foregroundStyle(.secondary)
        Text(message)
          .font(.body)
          .foregroundStyle(.primary)
      }
    }
  }
}

struct StatisticsDeepLinkRouter: View {
  let gameId: String?
  let gameTypeId: String?
  var body: some View {
    SectionContainer(title: "Statistics") {
      VStack(spacing: 12) {
        Image(systemName: "chart.bar")
          .font(.system(size: 22, weight: .semibold))
          .foregroundStyle(.secondary)
        Text("Statistics will open here with filters applied.")
          .font(.body)
          .foregroundStyle(.primary)
        if let gameId {
          Text("gameId: \(gameId)")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        if let gameTypeId {
          Text("gameType: \(gameTypeId)")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
  }
}
