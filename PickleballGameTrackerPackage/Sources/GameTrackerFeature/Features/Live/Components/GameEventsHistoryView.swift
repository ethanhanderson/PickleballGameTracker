//
//  GameEventsHistoryView.swift
//  GameTrackerFeature
//
//  Created by Ethan Anderson on 7/9/25.
//

import GameTrackerCore
import SwiftUI

@MainActor
struct GameEventsHistoryView: View {
    @Bindable var game: Game

    var body: some View {
        NavigationStack {
            ZStack {
                if game.events.isEmpty {
                    emptyStateView
                } else {
                    eventsListView
                }
            }
            .navigationTitle("Game Events")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.secondary)

            Text("No Events Logged")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Game events will appear here when logged during play")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)
        }
    }

    private var eventsListView: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.md) {
                ForEach(game.eventsByTimestamp, id: \.id) { event in
                    GameEventRow(event: event, game: game)
                        .transition(.slide.combined(with: .opacity))
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
        }
    }

}

// MARK: - Preview

#Preview("Game Events History - Randomized") {
    GameEventsHistoryView(game: PreviewGameData.createGameWithRealisticEvents(rallyCount: 28))
        .minimalPreview(environment: PreviewEnvironment.liveGame())
}

@MainActor
private struct GameEventRow: View {
    let event: GameEvent
    let game: Game

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Primary + Secondary information with flexible layout
            ViewThatFits(in: .horizontal) {
                // Preferred: Keep on one line
                HStack(spacing: DesignSystem.Spacing.md) {
                    leadingTitleGroup
                    Spacer()
                    secondaryInfoGroup
                }

                // Fallback: Move secondary info below title
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        leadingTitleGroup
                        Spacer(minLength: 0)
                    }

                    secondaryInfoGroup
                }
            }

            // Detailed description (conditional, expandable)
            if let description = event.customDescription {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Text(description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineLimit(isExpanded ? nil : 2)

                    Spacer()

                    // Expand/collapse button if needed
                    if event.customDescription!.count > 50 {
                        Button {
                            withAnimation(
                                .spring(response: 0.3, dampingFraction: 0.7)
                            ) {
                                isExpanded.toggle()
                            }
                        } label: {
                            Image(
                                systemName: isExpanded
                                    ? "chevron.up" : "chevron.down"
                            )
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

        }
        .padding(.vertical, DesignSystem.Spacing.md)
        .padding(.horizontal, DesignSystem.Spacing.md)
        .glassEffect(
            .regular.tint(eventIconColor.opacity(0.08)),
            in: RoundedRectangle(
                cornerRadius: DesignSystem.CornerRadius.xl,
                style: .continuous
            )
        )
    }

    // MARK: - Subviews

    private var leadingTitleGroup: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: event.eventType.iconName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(eventIconColor)

            Text(event.eventType.displayName)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private var secondaryInfoGroup: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Time
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "clock")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text(event.formattedTimestamp)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
            }

            // Team affected
            if let teamAffected = event.teamAffected {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "person.2")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(teamColor(for: teamAffected))

                    Text(teamLabel(for: teamAffected))
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
            }

            // Serve change indicator
            if event.affectsServing {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Text("Serve Changed")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .lineLimit(1)
    }

    private var eventIconColor: Color {
        switch event.eventType {
        case .playerScored:
            return .green
        case .scoreUndone:
            return .orange
        case .ballOutOfBounds, .ballInKitchenOnServe, .serviceFault,
            .ballHitNet, .doubleBounce, .kitchenViolation:
            return .red
        case .injuryTimeout:
            return .yellow
        case .substitution, .delayPenalty:
            return .blue
        case .sideChange, .serveChange:
            return .gray
        case .gamePaused, .gameResumed:
            return .gray
        case .gameCompleted:
            return .green
        }
    }

    private func teamLabel(for teamNumber: Int) -> String {
        if teamNumber == 1 {
            return game.effectivePlayerLabel1
        } else {
            return game.effectivePlayerLabel2
        }
    }

    private func teamColor(for teamNumber: Int) -> Color {
        // Without embedded roster in Core v1, fallback to team tint color helper
        return game.teamTintColor(for: teamNumber)
    }
}
