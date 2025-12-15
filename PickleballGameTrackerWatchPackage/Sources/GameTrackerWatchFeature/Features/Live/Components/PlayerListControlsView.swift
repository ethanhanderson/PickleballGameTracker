import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct PlayerListControlsView: View {
  @Bindable var game: Game
  let liveGameStateManager: LiveGameStateManager
  let isGamePaused: Bool
  let onHapticFeedback: () -> Void
  let onScorePoint: ((Int) -> Void)?
  let onDecrementScore: ((Int) -> Void)?

  @Environment(\.modelContext) private var modelContext
  @Environment(SwiftDataGameManager.self) private var gameManager
  @Environment(LiveSyncCoordinator.self) private var syncCoordinator
  @Environment(LiveGameStateManager.self) private var envLiveGameStateManager

  init(
    game: Game,
    liveGameStateManager: LiveGameStateManager,
    isGamePaused: Bool = false,
    onHapticFeedback: @escaping () -> Void,
    onScorePoint: ((Int) -> Void)? = nil,
    onDecrementScore: ((Int) -> Void)? = nil
  ) {
    self.game = game
    self.liveGameStateManager = liveGameStateManager
    self.isGamePaused = isGamePaused
    self.onHapticFeedback = onHapticFeedback
    self.onScorePoint = onScorePoint
    self.onDecrementScore = onDecrementScore
  }

  var body: some View {
    Group {
      if game.isDetachedFromContext {
        Color.clear
      } else {
        LazyVGrid(columns: gridColumns, spacing: DesignSystem.Spacing.md) {
          ForEach(playerRows, id: \.player.id) { row in
            PlayerScoreCard(
              game: game,
              player: row.player,
              teamNumber: row.teamNumber,
              tint: row.tint,
              score: playerScore(for: row.player),
              isGamePaused: isGamePaused,
              onScore: {
                onHapticFeedback()
                scorePoint(for: row.player, teamNumber: row.teamNumber)
              },
              onDecrement: {
                onHapticFeedback()
                decrementScore(for: row.teamNumber)
              },
              onOut: {
                onHapticFeedback()
                logOut(for: row.teamNumber)
              }
            )
          }
        }
        .padding(.horizontal)
      }
    }
  }

  private struct PlayerRow: Hashable {
    let player: PlayerProfile
    let teamNumber: Int
    let tint: Color
  }

  private var playerRows: [PlayerRow] {
    guard !game.isDetachedFromContext else { return [] }
    return game
      .participantRows(context: modelContext)
      .map { PlayerRow(player: $0.player, teamNumber: $0.teamNumber, tint: $0.player.accentColor) }
  }

  private var gridColumns: [GridItem] {
    [GridItem(.flexible(), spacing: DesignSystem.Spacing.md),
     GridItem(.flexible(), spacing: DesignSystem.Spacing.md)]
  }

  private func logOut(for team: Int) {
    guard game.safeGameState == .playing else { return }
    let timestamp = liveGameStateManager.elapsedTime
    let teamAffected = team

    if GameEventType.ballOutOfBounds.typicallyChangesServe {
      Task { @MainActor in
        do {
          game.logEvent(.ballOutOfBounds, at: timestamp, teamAffected: teamAffected)
          try? await syncCoordinator.publish(delta: LiveGameDeltaDTO(
            gameId: game.id,
            timestamp: timestamp,
            operation: .fault(event: .ballOutOfBounds, team: teamAffected)
          ))
          try await gameManager.handleServiceFault(in: game)
          syncCoordinator.noteLocalServeMutation()
        } catch {
          // swallow
        }
      }
    } else {
      game.logEvent(.ballOutOfBounds, at: timestamp, teamAffected: teamAffected)
    }
  }

  private func playerScore(for player: PlayerProfile) -> Int {
    game.playerScore(for: player)
  }

  private func scorePoint(for player: PlayerProfile, teamNumber: Int) {
    guard !game.safeIsCompleted else { return }
    
    if let onScorePoint = onScorePoint {
      onScorePoint(teamNumber)
    } else {
      let timestamp = envLiveGameStateManager.elapsedTime

      Task { @MainActor in
        do {
          // Include player name in description to allow per-player score derivation
          try await gameManager.scorePointAndLogEvent(
            for: teamNumber,
            in: game,
            at: timestamp,
            customDescription: "\(player.name) scored"
          )
          syncCoordinator.noteLocalScoreMutation()
          Task { @MainActor in
            try? await liveGameStateManager.setServer(to: teamNumber)
            syncCoordinator.noteLocalServeMutation()
            let target = LiveScoreTarget.player(team: teamNumber, player: player)
            try? await syncCoordinator.publishScoreAssignment(
              for: game,
              target: target,
              timestamp: timestamp
            )
          }
        } catch {
          // Swallow errors for watch quick-tap UX
        }
      }
    }
  }

  private func decrementScore(for teamNumber: Int) {
    guard !game.safeIsCompleted else { return }
    
    if let onDecrementScore = onDecrementScore {
      onDecrementScore(teamNumber)
    } else {
      let timestamp = envLiveGameStateManager.elapsedTime
      let currentScore = teamNumber == 1 ? game.score1 : game.score2
      guard currentScore > 0 else { return }

      Task { @MainActor in
        do {
          try await gameManager.decrementScore(for: teamNumber, in: game)
          syncCoordinator.noteLocalScoreMutation()
          Task { @MainActor in
            try? await syncCoordinator.publishDecrementDelta(
              for: game,
              team: teamNumber,
              timestamp: timestamp
            )
          }
        } catch {
          // Swallow errors for watch quick-tap UX
        }
      }
    }
  }
}

// MARK: - PlayerScoreCard

private struct PlayerScoreCard: View {
  let game: Game
  let player: PlayerProfile
  let teamNumber: Int
  let tint: Color
  let score: Int
  let isGamePaused: Bool
  let onScore: () -> Void
  let onDecrement: () -> Void
  let onOut: () -> Void
  
  @State private var previousScore: Int = 0
  private var scoreIsDecreasing: Bool { score < previousScore }

  var isCutthroat: Bool {
    game.gameType == .cutthroat
  }
  
  private var isDisabled: Bool {
    game.safeIsCompleted || isGamePaused
  }

  var body: some View {
    VStack(spacing: DesignSystem.Spacing.sm) {
      Text(player.name)
        .font(.caption)
        .fontWeight(.medium)
        .foregroundStyle(.white)
        .lineLimit(1)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, alignment: .center)
        .allowsHitTesting(false)

      if isCutthroat {
        cutthroatScoreButton
      } else {
        standardScoreButtons
      }
    }
    .frame(maxWidth: .infinity, alignment: .center)
    .onAppear {
      previousScore = score
    }
    .onChange(of: score) { _, newScore in
      previousScore = newScore
    }
  }

  @ViewBuilder
  private var cutthroatScoreButton: some View {
    Button {
      guard !isDisabled else { return }
      onScore()
    } label: {
      Text("\(score)")
        .font(.system(size: 22, weight: .bold, design: .rounded))
        .foregroundStyle(.white)
        .monospacedDigit()
        .contentTransition(.numericText(countsDown: scoreIsDecreasing))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .glassEffect(
          isGamePaused
            ? .regular.tint(tint.opacity(0.25))
            : .regular.tint(tint.opacity(0.5)).interactive()
        )
    }
    .buttonStyle(.plain)
    .disabled(isDisabled)
    .contentShape(.rect)
    .onTapGesture(count: 2) {
      guard !isDisabled else { return }
      guard score > 0 else { return }
      onDecrement()
    }
    .simultaneousGesture(
      DragGesture()
        .onEnded { value in
          guard !isDisabled else { return }
          if value.translation.height < -30 {
            onScore()
          } else if value.translation.height > 30 && score > 0 {
            onDecrement()
          }
        }
    )
  }

  @ViewBuilder
  private var standardScoreButtons: some View {
    HStack(spacing: DesignSystem.Spacing.sm) {
      Button {
        onScore()
      } label: {
        VStack(spacing: DesignSystem.Spacing.xs) {
          Text("\(score)")
            .font(.system(size: 22, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .contentTransition(.numericText(countsDown: scoreIsDecreasing))
            .frame(width: 28, height: 28)
          Text("Score")
            .font(.caption2)
            .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .glassEffect(.regular.tint(tint.opacity(0.5)))
      }
      .buttonStyle(.plain)

      Button {
        onOut()
      } label: {
        VStack(spacing: DesignSystem.Spacing.xs) {
          Image(systemName: "xmark.circle.fill")
            .font(.title3)
            .foregroundStyle(tint)
            .frame(width: 24, height: 24)
          Text("Out")
            .font(.caption2)
            .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .glassEffect(.regular.tint(tint.opacity(0.5)))
      }
      .buttonStyle(.plain)
    }
  }
}

// MARK: - Previews

#Preview {
  let setup = PreviewContainers.standardSetup()
  let syncCoordinator = LiveSyncCoordinator(service: NoopSyncService())
  let game = PreviewContainers.exampleGame(
    in: setup.container,
    type: .cutthroat,
    desiredState: .playing,
    cutthroatPlayers: 5
  )
  
  PlayerListControlsView(
    game: game,
    liveGameStateManager: setup.liveGameManager,
    onHapticFeedback: {},
    onScorePoint: { team in
      Task { @MainActor in
        try? await setup.liveGameManager.scorePoint(for: team)
      }
    },
    onDecrementScore: { team in
      Task { @MainActor in
        try? await setup.liveGameManager.decrementScore(for: team)
      }
    }
  )
  .modelContainer(setup.container)
  .environment(setup.liveGameManager)
  .environment(setup.gameManager)
  .environment(syncCoordinator)
  .task {
    await setup.liveGameManager.setCurrentGame(game)
  }
}

