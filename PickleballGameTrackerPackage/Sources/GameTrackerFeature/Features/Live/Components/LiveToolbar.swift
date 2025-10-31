//
//  LiveToolbar.swift
//

import GameTrackerCore
import SwiftUI

struct LiveToolbar: ToolbarContent {
    let game: Game
    let gameManager: SwiftDataGameManager
    let activeGameStateManager: LiveGameStateManager
    @Binding var showEventsHistory: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var showEndGameConfirmation = false

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
                Button("End", role: .destructive) {
                    endGame()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("End this game? It will be saved to your history and included in your statistics.")
            }
        }
    }

    private func endGame() {
        Task { @MainActor in
            do {
                try await activeGameStateManager.completeCurrentGame()
                dismiss()
            } catch {
                Log.error(
                    error,
                    event: .saveFailed,
                    context: .current(gameId: game.id),
                    metadata: ["action": "endGame"]
                )
            }
        }
    }
}
