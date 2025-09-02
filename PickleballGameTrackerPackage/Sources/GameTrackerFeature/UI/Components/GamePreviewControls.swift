//
//  GamePreviewControls.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 8/1/25.
//

import SwiftUI

@MainActor
struct InlineGamePreviewControls: View {
    @Environment(ActiveGameStateManager.self) private var activeGameStateManager
    let onTap: () -> Void
    let animation: Namespace.ID

    var body: some View {
        if let gameTypeName = activeGameStateManager.currentGameTypeDisplayName,
            let score = activeGameStateManager.currentScore
        {
            Button(action: onTap) {
                HStack {
                    Text(gameTypeName)
                        .fontWeight(.semibold)
                        .padding(.leading, 4)
                        .foregroundColor(DesignSystem.Colors.textPrimary)

                    Spacer()

                    HStack(spacing: DesignSystem.Spacing.xs) {
                        let scoreComponents = score.split(separator: " - ")
                        if scoreComponents.count == 2 {
                            Text(String(scoreComponents[0]))
                                .font(
                                    .system(
                                        size: 30,
                                        weight: .bold,
                                        design: .rounded
                                    )
                                )
                                .foregroundStyle(
                                    DesignSystem.Colors.scorePlayer1
                                )

                            Text("-")
                                .font(
                                    .system(
                                        size: 24,
                                        weight: .semibold,
                                        design: .rounded
                                    )
                                )
                                .foregroundStyle(.secondary)

                            Text(String(scoreComponents[1]))
                                .font(
                                    .system(
                                        size: 30,
                                        weight: .bold,
                                        design: .rounded
                                    )
                                )
                                .foregroundStyle(
                                    DesignSystem.Colors.scorePlayer2
                                )
                        }
                    }
                }
                .padding(.trailing, 2)
                .padding(.horizontal)
            }
            .buttonStyle(.borderless)
            .matchedTransitionSource(id: "sheet", in: animation)
            .accessibilityIdentifier("GamePreviewControls.inline.button")
        }
    }
}

@MainActor
struct ExpandedGamePreviewControls: View {
    @Environment(ActiveGameStateManager.self) private var activeGameStateManager
    let onTap: () -> Void
    let animation: Namespace.ID

    var body: some View {
        if let gameTypeName = activeGameStateManager.currentGameTypeDisplayName,
            let score = activeGameStateManager.currentScore
        {
            Button(action: onTap) {
                HStack {
                    Image(
                        systemName: activeGameStateManager.currentGameTypeIcon
                            ?? "gamecontroller.fill"
                    )
                    .frame(width: 32, height: 32)
                    .foregroundColor(
                        activeGameStateManager.currentGameTypeColor
                            ?? DesignSystem.Colors.primary
                    )

                    Text(gameTypeName)
                        .font(.headline)
                        .padding(.leading, 4)
                        .foregroundColor(DesignSystem.Colors.textPrimary)

                    if activeGameStateManager.isGameActive {
                        Image(systemName: "timer")
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.leading, 4)
                            .foregroundStyle(.secondary)

                        Text(activeGameStateManager.formattedElapsedTime)
                            .font(
                                .system(
                                    size: 16,
                                    weight: .medium,
                                    design: .rounded
                                )
                            )
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    HStack(spacing: DesignSystem.Spacing.xs) {
                        let scoreComponents = score.split(separator: " - ")
                        if scoreComponents.count == 2 {
                            Text(String(scoreComponents[0]))
                                .font(
                                    .system(
                                        size: 30,
                                        weight: .bold,
                                        design: .rounded
                                    )
                                )
                                .foregroundStyle(
                                    DesignSystem.Colors.scorePlayer1
                                )

                            Text("-")
                                .font(
                                    .system(
                                        size: 24,
                                        weight: .semibold,
                                        design: .rounded
                                    )
                                )
                                .foregroundStyle(.secondary)

                            Text(String(scoreComponents[1]))
                                .font(
                                    .system(
                                        size: 30,
                                        weight: .bold,
                                        design: .rounded
                                    )
                                )
                                .foregroundStyle(
                                    DesignSystem.Colors.scorePlayer2
                                )
                        }
                    }
                }
                .padding(.trailing, 2)
                .padding(.horizontal)
            }
            .buttonStyle(.borderless)
            .matchedTransitionSource(id: "sheet", in: animation)
            .accessibilityIdentifier("GamePreviewControls.expanded.button")
        }
    }
}

@MainActor
struct GamePreviewControls: View {
    @Environment(\.tabViewBottomAccessoryPlacement) var placement
    let onTap: () -> Void
    let animation: Namespace.ID

    var body: some View {
        switch placement {
        case .expanded:
            ExpandedGamePreviewControls(onTap: onTap, animation: animation)
        default:
            InlineGamePreviewControls(onTap: onTap, animation: animation)
        }
    }
}

#Preview("Active Game") {
    @Previewable @Namespace var animation

    // Create a preview with mock active game
    let manager = ActiveGameStateManager.shared

    return NavigationStack {
        GamePreviewControls(
            onTap: {
                Log.event(
                    .actionTapped,
                    level: .debug,
                    message: "Tapped active game preview"
                )
            },
            animation: animation
        )
        .onAppear {
            let game = PreviewGameData.trainingGame
            game.score1 = 8
            game.score2 = 6
            manager.setCurrentGame(game)
        }
    }
}

#Preview("No Active Game") {
    @Previewable @Namespace var animation

    let manager = ActiveGameStateManager.shared
    manager.clearCurrentGame()

    return NavigationStack {
        GamePreviewControls(
            onTap: {
                Log.event(
                    .actionTapped,
                    level: .debug,
                    message: "Tapped - no active game"
                )
            },
            animation: animation
        )
    }
}
