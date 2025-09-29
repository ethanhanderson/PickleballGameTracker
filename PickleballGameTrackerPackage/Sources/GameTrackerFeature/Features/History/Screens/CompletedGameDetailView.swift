//
//  CompletedGameDetailView.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 8/10/25.
//

import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct CompletedGameDetailView: View {
  @Bindable var game: Game
  @Environment(SwiftDataGameManager.self) private var gameManager
  @State private var editingNotes: String = ""
  @State private var isEditingNotes = false
  @State private var isSaving = false
  @State private var saveError: (any Error)? = nil
  @State private var showDeleteConfirm = false

  var body: some View {
    ScrollView {
      VStack(spacing: DesignSystem.Spacing.lg) {
        header
        SectionContainer(title: "Score") {
          scoreSection
        }
        SectionContainer(title: "Summary") {
          summaryMetrics
        }
        SectionContainer(title: "Actions") {
          actions
        }
        SectionContainer(title: "Notes") {
          notesSection
        }
      }
      .padding(.horizontal, DesignSystem.Spacing.md)
      .padding(.top, DesignSystem.Spacing.lg)
    }
    .navigationTitle("Completed Game")
    .navigationBarTitleDisplayMode(.inline)
    .task { Log.event(.viewAppear, level: .info, context: .current(gameId: game.id)) }
    .alert("Delete game?", isPresented: $showDeleteConfirm) {
      Button("Delete", role: .destructive) {
        Task { await confirmDelete() }
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This action cannot be undone.")
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
      HStack(spacing: DesignSystem.Spacing.md) {
        Image(systemName: game.gameType.iconName)
          .font(.system(size: 40, weight: .medium))
          .foregroundStyle(game.gameType.color.gradient)
          .shadow(color: game.gameType.color.opacity(0.3), radius: 6, x: 0, y: 3)

        Text(game.gameType.displayName)
          .font(.largeTitle)
          .fontWeight(.bold)
          .foregroundStyle(.primary)
      }

      VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
        Text(game.formattedDate)
          .font(.caption)
          .foregroundStyle(.secondary)
        if let duration = game.formattedDuration {
          Text("Duration: \(duration)")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
    .padding(DesignSystem.Spacing.md)
    .background(Color.gray.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
  }

  private var scoreSection: some View {
    HStack(spacing: DesignSystem.Spacing.lg) {
      HistoryScoreDisplay(
        score: game.score1,
        label: game.effectivePlayerLabel1,
        color: .blue,
        size: .large,
        isWinner: (game.score1 > game.score2)
      )
      HistoryScoreDisplay(
        score: game.score2,
        label: game.effectivePlayerLabel2,
        color: .green,
        size: .large,
        isWinner: (game.score2 > game.score1)
      )
    }
    .cardGradientStyle()
  }

  private var summaryMetrics: some View {
    VStack(spacing: DesignSystem.Spacing.md) {
      HStack {
        GameMetricRow(
          icon: "arrow.triangle.2.circlepath", title: "Rallies", value: "\(game.totalRallies)")
        Spacer()
        GameMetricRow(
          icon: "flag", title: "To", value: "\(game.winningScore) \(game.winByTwo ? "+2" : "")")
      }
      HStack {
        GameMetricRow(
          icon: "figure.pickleball", title: "Server", value: game.currentServingPlayerShortLabel)
        Spacer()
        GameMetricRow(
          icon: "arrow.left.arrow.right", title: "Side", value: game.sideOfCourt.displayName)
      }
    }
    .cardGradientStyle()
  }

  private var actions: some View {
    VStack(spacing: DesignSystem.Spacing.sm) {
      Button("View Statistics for These Players", systemImage: "chart.bar") {
        Log.event(
          .actionTapped, level: .info, message: "completed → stats",
          context: .current(gameId: game.id))
        DeepLinkBus.post(
          .statistics(gameId: game.id.uuidString, gameTypeId: game.gameType.rawValue))
      }
      .primaryButton()

      HStack(spacing: DesignSystem.Spacing.sm) {
        ShareLink(
          item: URL(string: "https://example.com/g/\(game.id.uuidString)?t=local-stub")!
        ) {
          Label("Share", systemImage: "square.and.arrow.up")
        }
        .secondaryButton()

        Button(
          game.isArchived ? "Restore" : "Archive",
          systemImage: game.isArchived ? "arrow.uturn.left" : "archivebox"
        ) {
          Log.event(
            .actionTapped, level: .info, message: game.isArchived ? "restore" : "archive",
            context: .current(gameId: game.id))
          Task { await toggleArchive() }
        }
        .secondaryButton()

        Button("Delete", systemImage: "trash") {
          Log.event(
            .actionTapped, level: .warn, message: "delete", context: .current(gameId: game.id))
          showDeleteConfirm = true
        }
        .secondaryButton()
      }

      Button(
        isEditingNotes ? "Cancel" : "Edit Notes",
        systemImage: isEditingNotes ? "xmark" : "square.and.pencil"
      ) {
        if isEditingNotes {
          editingNotes = game.notes ?? ""
          isEditingNotes = false
        } else {
          editingNotes = game.notes ?? ""
          isEditingNotes = true
        }
      }
      .secondaryButton()
    }
  }

  private var notesSection: some View {
    VStack(spacing: DesignSystem.Spacing.sm) {
      HistoryInfoCard(title: "Notes", value: getNotesDisplayText())
    }
  }

  private func getNotesDisplayText() -> String {
    if isEditingNotes {
      return editingNotes
    } else if let notes = game.notes, !notes.isEmpty {
      return notes
    } else {
      return "No notes yet."
    }
  }

  private func saveNotes() async {
    isSaving = true
    saveError = nil
    do {
      game.notes = editingNotes.trimmingCharacters(in: .whitespacesAndNewlines)
      game.lastModified = Date()
      try await gameManager.updateGame(game)
      Log.event(
        .saveSucceeded, level: .info, message: "Notes saved", context: .current(gameId: game.id))
      isEditingNotes = false
    } catch {
      saveError = error
      Log.error(
        error, event: .saveFailed, context: .current(gameId: game.id),
        metadata: ["phase": "saveNotes"])
    }
    isSaving = false
  }

  private func toggleArchive() async {
    do {
      if game.isArchived {
        try await gameManager.restoreGame(game)
      } else {
        try await gameManager.archiveGame(game)
      }
    } catch {
      Log.error(
        error, event: .saveFailed, context: .current(gameId: game.id),
        metadata: ["phase": "toggleArchive"]
      )
    }
  }

  private func confirmDelete() async {
    do {
      try await gameManager.deleteGame(game)
    } catch {
      Log.error(
        error, event: .saveFailed, context: .current(gameId: game.id), metadata: ["phase": "delete"]
      )
    }
  }
}

#Preview("Completed Game") {
  let ctx = try! PreviewGameData.makeActiveGameContext(game: PreviewGameData.completedGame)
  return NavigationStack {
    CompletedGameDetailView(game: ctx.game)
  }
  .modelContainer(ctx.container)
  .environment(ctx.gameManager)
  .environment(ctx.activeGameStateManager)
  .accentColor(.green)
}
