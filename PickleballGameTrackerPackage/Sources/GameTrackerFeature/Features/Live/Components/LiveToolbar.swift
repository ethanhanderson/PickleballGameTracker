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
                GameEventsHistoryView(game: game)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }

            Menu {
                Section("Display Options") {
                    Button {
                    } label: {
                        Label("Show Timer", systemImage: "timer")
                    }

                    Button {
                    } label: {
                        Label(
                            "Show Score Controls",
                            systemImage: "numbers.rectangle"
                        )
                    }

                    Button {
                    } label: {
                        Label(
                            "Show Serving Indicator",
                            systemImage: "tennis.racket"
                        )
                    }
                }

                Section("Layout") {
                    Button {
                    } label: {
                        Label(
                            "Compact View",
                            systemImage: "rectangle.compress.vertical"
                        )
                    }

                    Button {
                    } label: {
                        Label(
                            "Expanded View",
                            systemImage: "rectangle.expand.vertical"
                        )
                    }
                }

                Section("Game Settings") {
                    Button {
                    } label: {
                        Label("Game Rules", systemImage: "list.clipboard")
                    }

                    Button {
                    } label: {
                        Label("Sound Effects", systemImage: "speaker.wave.2")
                    }

                    Button {
                    } label: {
                        Label(
                            "Haptic Feedback",
                            systemImage: "iphone.radiowaves.left.and.right"
                        )
                    }
                }

                Section("Serving Control") {
                    Button {
                        switchServer()
                    } label: {
                        Label(
                            "Switch Server",
                            systemImage: "arrow.2.squarepath"
                        )
                    }
                    .disabled(game.isCompleted || game.gameState != .paused)

                    Button {
                        setServerToTeam1()
                    } label: {
                        Label("Team 1 Serves", systemImage: "1.circle.fill")
                    }
                    .disabled(
                        game.isCompleted || game.currentServer == 1
                            || game.gameState != .paused
                    )

                    Button {
                        setServerToTeam2()
                    } label: {
                        Label("Team 2 Serves", systemImage: "2.circle.fill")
                    }
                    .disabled(
                        game.isCompleted || game.currentServer == 2
                            || game.gameState != .paused
                    )
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
                Button("End Game", role: .destructive) {
                    endGame()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(
                    "Are you sure you want to end this game? This cannot be undone."
                )
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

    private func switchServer() {
        Task { @MainActor in
            do {
                try await gameManager.switchServer(in: game)
            } catch {
                Log.error(
                    error,
                    event: .serverSwitched,
                    context: .current(gameId: game.id),
                    metadata: ["action": "switchServer"]
                )
            }
        }
    }

    private func setServerToTeam1() {
        Task { @MainActor in
            do {
                try await gameManager.setServer(to: 1, in: game)
            } catch {
                Log.error(
                    error,
                    event: .serverSwitched,
                    context: .current(gameId: game.id),
                    metadata: ["action": "setServer", "team": "1"]
                )
            }
        }
    }

    private func setServerToTeam2() {
        Task { @MainActor in
            do {
                try await gameManager.setServer(to: 2, in: game)
            } catch {
                Log.error(
                    error,
                    event: .serverSwitched,
                    context: .current(gameId: game.id),
                    metadata: ["action": "setServer", "team": "2"]
                )
            }
        }
    }
}
