import Foundation
import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct InlineMiniPreview: View {
    @Environment(LiveGameStateManager.self) private var activeGameStateManager
    @Environment(\.modelContext) private var modelContext
    let onTap: () -> Void

    var body: some View {
        if let gameTypeName = activeGameStateManager.currentGameTypeDisplayName,
            let score = activeGameStateManager.currentScore
        {
            Button(role: .destructive, action: onTap) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(gameTypeName)
                            .fontWeight(.semibold)

                        if let game = activeGameStateManager.currentGame {
                            let names: String = {
                                if game.gameType == .cutthroat {
                                    let side1Players = game.resolveSide1Players(context: modelContext) ?? []
                                    let side2Players = game.resolveSide2Players(context: modelContext) ?? []
                                    let allPlayers = side1Players + side2Players
                                    let playerNames = allPlayers.map { $0.name }
                                    return formatPlayerList(playerNames)
                                } else {
                                    return game.teamsWithLabels(
                                        context: modelContext
                                    ).map { $0.teamName }.joined(separator: " vs ")
                                }
                            }()
                            if names.isEmpty == false {
                                Text(names)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.leading, 4)

                    Spacer(minLength: DesignSystem.Spacing.sm)

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
                                .foregroundStyle(teamTintColor(forTeamIndex: 1))

                            Text("-")
                                .font(
                                    .system(
                                        size: 24,
                                        weight: .semibold,
                                        design: .rounded
                                    )
                                )

                            Text(String(scoreComponents[1]))
                                .font(
                                    .system(
                                        size: 30,
                                        weight: .bold,
                                        design: .rounded
                                    )
                                )
                                .foregroundStyle(teamTintColor(forTeamIndex: 2))
                        }
                    }
                }
                .padding(.trailing, 2)
                .padding(.horizontal)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("LiveGameMiniPreview.inline.button")
        }
    }
}

extension InlineMiniPreview {
    fileprivate func teamTintColor(forTeamIndex index: Int) -> Color {
        guard let game = activeGameStateManager.currentGame else {
            return Color.accentColor
        }
        return game.teamTintColor(for: index, context: modelContext)
    }
    
    fileprivate func formatPlayerList(_ names: [String]) -> String {
        guard !names.isEmpty else { return "" }
        if names.count == 1 {
            return names[0]
        } else if names.count == 2 {
            return "\(names[0]) and \(names[1])"
        } else {
            let allButLast = names.dropLast().joined(separator: ", ")
            return "\(allButLast), and \(names.last!)"
        }
    }
}

@MainActor
struct ExpandedMiniPreview: View {
    @Environment(LiveGameStateManager.self) private var activeGameStateManager
    @Environment(\.modelContext) private var modelContext
    let onTap: () -> Void

    var body: some View {
        if let gameTypeName = activeGameStateManager.currentGameTypeDisplayName,
            let score = activeGameStateManager.currentScore
        {
            Button(role: .destructive, action: onTap) {
                HStack {
                    Image(
                        systemName: activeGameStateManager.currentGameTypeIcon
                            ?? "figure.pickleball"
                    )
                    .frame(width: 32, height: 32)
                    .foregroundStyle(
                        activeGameStateManager.currentGameTypeColor
                            ?? Color.accentColor
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(gameTypeName)
                            .font(.headline)

                        if let game = activeGameStateManager.currentGame {
                            let names: String = {
                                if game.gameType == .cutthroat {
                                    let side1Players = game.resolveSide1Players(context: modelContext) ?? []
                                    let side2Players = game.resolveSide2Players(context: modelContext) ?? []
                                    let allPlayers = side1Players + side2Players
                                    let playerNames = allPlayers.map { $0.name }
                                    return formatPlayerList(playerNames)
                                } else {
                                    return game.teamsWithLabels(
                                        context: modelContext
                                    ).map { $0.teamName }.joined(separator: " vs ")
                                }
                            }()
                            if names.isEmpty == false {
                                Text(names)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.leading, 4)

                    if activeGameStateManager.isGameLive {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "timer")
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.leading, 4)

                            Text(activeGameStateManager.formattedElapsedTime)
                                .font(
                                    .system(
                                        size: 16,
                                        weight: .medium,
                                        design: .rounded
                                    )
                                )
                        }
                        .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: DesignSystem.Spacing.md)

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
                                .foregroundStyle(teamTintColor(forTeamIndex: 1))

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
                                .foregroundStyle(teamTintColor(forTeamIndex: 2))
                        }
                    }
                }
                .padding(.trailing, 2)
                .padding(.horizontal)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.primary)
            .accessibilityIdentifier("LiveGameMiniPreview.expanded.button")
        }
    }
}

extension ExpandedMiniPreview {
    fileprivate func teamTintColor(forTeamIndex index: Int) -> Color {
        guard let game = activeGameStateManager.currentGame else {
            return Color.accentColor
        }
        return game.teamTintColor(for: index, context: modelContext)
    }
    
    fileprivate func formatPlayerList(_ names: [String]) -> String {
        guard !names.isEmpty else { return "" }
        if names.count == 1 {
            return names[0]
        } else if names.count == 2 {
            return "\(names[0]) and \(names[1])"
        } else {
            let allButLast = names.dropLast().joined(separator: ", ")
            return "\(allButLast), and \(names.last!)"
        }
    }
}

@MainActor
struct LiveGameMiniPreview: View {
    @Environment(\.tabViewBottomAccessoryPlacement) var placement
    let onTap: () -> Void

    var body: some View {
        Group {
            switch placement {
            case .expanded:
                ExpandedMiniPreview(onTap: onTap)
            default:
                InlineMiniPreview(onTap: onTap)
            }
        }
    }
}

#Preview {
    @Previewable @State var showSheet = false

    let setup = PreviewContainers.liveGameSetup()

    LiveGameMiniPreview(
        onTap: { showSheet = true }
    )
    .modelContainer(setup.container)
    .environment(setup.liveGameManager)
    .tint(.green)
}
