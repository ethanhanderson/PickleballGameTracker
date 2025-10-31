import GameTrackerCore
import SwiftData
import SwiftUI

// MARK: - Deep Link Destination View

@MainActor
struct DeepLinkDestinationView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(SwiftDataGameManager.self) private var gameManager
  @Environment(LiveGameStateManager.self) private var activeGameStateManager
  @Environment(LiveSyncCoordinator.self) private var syncCoordinator
  let destination: DeepLinkDestination?

  var body: some View {
    switch destination {
    case .gameType(let id):
      if let gameType = GameType(rawValue: id) {
        GameDetailView(
          gameType: gameType,
          onStartGame: { gameType, rules, matchup in
            Task { @MainActor in
              do {
                let config = GameStartConfiguration(
                  gameType: gameType,
                  matchup: matchup,
                  rules: rules
                )
                let newGame = try await activeGameStateManager.startNewGame(with: config)

                Log.event(
                  .viewAppear,
                  level: .info,
                  message: "Deep link → started game",
                  context: .current(gameId: newGame.id)
                )

                // Standardize live presentation trigger
                NotificationCenter.default.post(
                  name: Notification.Name("OpenLiveGameRequested"),
                  object: nil
                )

                // Mirror game start on companion
                let rosterBuilder = RosterSnapshotBuilder(storage: SwiftDataStorage.shared)
                if let roster = try? rosterBuilder.build(includeArchived: false) {
                  try? await syncCoordinator.publishRoster(roster)
                }
                let cfgWithId = GameStartConfiguration(
                  gameId: newGame.id,
                  gameType: config.gameType,
                  teamSize: config.teamSize,
                  participants: config.participants,
                  notes: config.notes,
                  rules: config.rules
                )
                try? await syncCoordinator.publishStart(cfgWithId)
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

    case .setup(let gameTypeId):
      if let gameType = GameType(rawValue: gameTypeId) {
        SetupView(
          gameType: gameType,
          onStartGame: { gameType, rules, matchup in
            Task { @MainActor in
              do {
                let config = GameStartConfiguration(
                  gameType: gameType,
                  matchup: matchup,
                  rules: rules
                )
                let game = try await activeGameStateManager.startNewGame(with: config)
                
                Log.event(
                  .viewAppear,
                  level: .info,
                  message: "Deep link → setup completed",
                  context: .current(gameId: game.id)
                )
                
                // Standardize live presentation trigger
                NotificationCenter.default.post(
                  name: Notification.Name("OpenLiveGameRequested"),
                  object: nil
                )

                // Mirror game start on companion
                let rosterBuilder = RosterSnapshotBuilder(storage: SwiftDataStorage.shared)
                if let roster = try? rosterBuilder.build(includeArchived: false) {
                  try? await syncCoordinator.publishRoster(roster)
                }
                let cfg = GameStartConfiguration(
                  gameId: game.id,
                  gameType: game.gameType,
                  teamSize: TeamSize(playersPerSide: game.effectiveTeamSize) ?? .doubles,
                  participants: {
                    switch game.participantMode {
                    case .players:
                      return Participants(side1: .players(game.side1PlayerIds), side2: .players(game.side2PlayerIds))
                    case .teams:
                      return Participants(side1: .team(game.side1TeamId!), side2: .team(game.side2TeamId!))
                    case .anonymous:
                      return Participants(side1: .players([]), side2: .players([]))
                    }
                  }(),
                  rules: try? GameRules.createValidated(
                    winningScore: game.winningScore,
                    winByTwo: game.winByTwo,
                    kitchenRule: game.kitchenRule,
                    doubleBounceRule: game.doubleBounceRule,
                    servingRotation: game.servingRotation,
                    sideSwitchingRule: game.sideSwitchingRule,
                    scoringType: game.scoringType,
                    timeLimit: game.timeLimit,
                    maxRallies: game.maxRallies
                  )
                )
                try? await syncCoordinator.publishStart(cfg)
              } catch {
                Log.error(
                  error,
                  event: .saveFailed,
                  metadata: ["phase": "deepLinkSetup"]
                )
              }
            }
          }
        )
        .navigationTitle("Setup \(gameType.displayName)")
        .navigationBarTitleDisplayMode(.inline)
      } else {
        DeepLinkErrorView(message: "Game Type not found.")
      }

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
