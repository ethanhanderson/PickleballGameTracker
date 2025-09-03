//
//  CompletedGameDetailView.swift
//  Pickleball Score Tracking
//
//  Created by Assistant on 8/10/25.
//

import CorePackage
import SwiftData
import SwiftUI

struct CompletedGameDetailView: View {
  @Bindable var game: Game
  @Environment(\.modelContext) private var modelContext
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
    InfoCard(
      title: game.gameType.displayName, icon: game.gameType.iconName, style: .info,
      gameType: game.gameType
    ) {
      VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
        Text(game.formattedDate)
          .font(DesignSystem.Typography.caption)
          .foregroundColor(DesignSystem.Colors.textSecondary)
        if let duration = game.formattedDuration {
          Text("Duration: \(duration)")
            .font(DesignSystem.Typography.caption)
            .foregroundColor(DesignSystem.Colors.textSecondary)
        }
      }
    }
  }

  private var scoreSection: some View {
    HStack(spacing: DesignSystem.Spacing.lg) {
      ScoreDisplayView(
        score: game.score1,
        label: game.effectivePlayerLabel1,
        color: DesignSystem.Colors.scorePlayer1,
        size: .large,
        isWinner: (game.score1 > game.score2)
      )
      ScoreDisplayView(
        score: game.score2,
        label: game.effectivePlayerLabel2,
        color: DesignSystem.Colors.scorePlayer2,
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

  // metric view extracted to Features/History/Components/GameMetricRow.swift

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
      InfoCard(title: "Notes", icon: "note.text") {
        if isEditingNotes {
          VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            TextEditor(text: $editingNotes)
              .frame(minHeight: 120)
              .overlay(
                RoundedRectangle(cornerRadius: 8)
                  .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
              )
            HStack {
              Button("Save", systemImage: "tray.and.arrow.down.fill") { Task { await saveNotes() } }
                .primaryButton()
                .disabled(isSaving)
              Button("Discard", systemImage: "trash") {
                editingNotes = game.notes ?? ""
                isEditingNotes = false
              }
              .secondaryButton()
            }
          }
        } else {
          if let notes = game.notes, !notes.isEmpty {
            Text(notes)
              .font(DesignSystem.Typography.body)
              .foregroundColor(DesignSystem.Colors.textPrimary)
          } else {
            Text("No notes yet.")
              .font(DesignSystem.Typography.caption)
              .foregroundColor(DesignSystem.Colors.textSecondary)
          }
        }
      }
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
  NavigationStack {
    CompletedGameDetailView(game: PreviewGameData.completedGame)
  }
  .modelContainer(
    try! PreviewGameData.createPreviewContainer(with: [PreviewGameData.completedGame]))
}
