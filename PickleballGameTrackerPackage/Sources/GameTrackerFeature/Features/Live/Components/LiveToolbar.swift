//
//  LiveToolbar.swift
//

import GameTrackerCore
import SwiftUI

struct LiveToolbar: ToolbarContent {
    let game: Game
    let gameManager: SwiftDataGameManager
    let activeGameStateManager: LiveGameStateManager
    let onEndGame: () async -> Void
    @Binding var showEventsHistory: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var showEndGameConfirmation = false
    @State private var isEndingGame = false

    var body: some ToolbarContent {
        ToolbarItemGroup {
            Button("Events", systemImage: "list.bullet.rectangle.portrait") {
                showEventsHistory = true
            }
            .sheet(isPresented: $showEventsHistory) {
                GameEventsView(game: game)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }

            Menu {
                Section("Game Settings") {
                    Button {
                    } label: {
                        Label("Game Rules", systemImage: "list.clipboard")
                    }
                }

                Section("Game Actions") {
                    Button(role: .destructive) {
                        showEndGameConfirmation = true
                    } label: {
                        Label("End Game", systemImage: "flag.checkered")
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(.primary)
            }
            .confirmationDialog(
                "End Game",
                isPresented: $showEndGameConfirmation,
                titleVisibility: .visible
            ) {
                Button("End", role: .destructive) { endGame() }
                    .disabled(isEndingGame)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("End this game? It will be saved to your history unless no activity occurred.")
            }
        }
    }

    private func endGame() {
        guard !isEndingGame else { return }
        isEndingGame = true
        dismiss()

        Task { @MainActor in
            await onEndGame()
            isEndingGame = false
        }
    }
}
