import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct SideScoreTopCard: View {
    @Bindable var game: Game
    let teamNumber: Int
    let teamName: String
    let isGameActive: Bool
    let showTapIndicator: Bool
    let gameManager: SwiftDataGameManager
    let tintOverride: Color?

    @State private var matchLabelVisible: Bool = false
    @State private var serveLabelVisible: Bool = false
    @State private var hasAppeared: Bool = false
    @State private var matchAnimationTick: Int = 0
    @State private var wasJustResumed: Bool = false
    @State private var previousScore: Int = 0

    private var cardTintColor: Color {
        tintOverride ?? game.teamTintColor(for: teamNumber)
    }

    private var score: Int { game.score(for: teamNumber) }
    private var isAtMatchPoint: Bool { game.isAtMatchPoint(for: teamNumber) }
    private var isServing: Bool { game.isServing(teamNumber: teamNumber) }
    private var servingIndicatorVisible: Bool {
        game.shouldShowServingIndicator(for: teamNumber)
    }
    private var servingAnimate: Bool {
        game.gameState == .playing && !wasJustResumed
    }
    private var isWinningTeam: Bool {
        game.isWinningTeam(teamNumber: teamNumber)
    }

    private var scoreIsDecreasing: Bool {
        score < previousScore
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            HStack(alignment: .center, spacing: DesignSystem.Spacing.md) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Group {
                        AvatarView(
                            configuration: .init(
                                symbolName: "person.fill",
                                tintColor: cardTintColor,
                                style: .small
                            )
                        )
                    }

                    Text(teamName)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }

                Spacer()
            }

            HStack(spacing: DesignSystem.Spacing.md) {
                HStack(
                    spacing: (matchLabelVisible || serveLabelVisible)
                        ? DesignSystem.Spacing.xs : 4
                ) {
                    StatusIndicatorCapsule(
                        icon: "target",
                        label: "MATCH POINT",
                        tint: cardTintColor.opacity(0.14),
                        visible: isAtMatchPoint,
                        animate: !hasAppeared || isGameActive,
                        triggerAnimationId: matchAnimationTick,
                        accessibilityId:
                            "SideScoreCard.status.matchPoint.team\(teamNumber)",
                        onLabelVisibilityChange: { isVisible in
                            matchLabelVisible = isVisible
                        },
                        shouldDefer: {
                            (isServing && !game.isCompleted)
                                && serveLabelVisible
                        }
                    )

                    StatusIndicatorCapsule(
                        icon: "figure.pickleball",
                        label: "SERVING",
                        tint: cardTintColor.opacity(0.3),
                        visible: servingIndicatorVisible,
                        animate: servingAnimate,
                        triggerAnimationId: 0,
                        accessibilityId:
                            "SideScoreCard.status.serving.team\(teamNumber)",
                        onLabelVisibilityChange: { isVisible in
                            serveLabelVisible = isVisible
                        },
                        shouldDefer: {
                            (isAtMatchPoint && isGameActive)
                                && matchLabelVisible
                        }
                    )
                }
                .animation(
                    .snappy(duration: 0.25, extraBounce: 0.0),
                    value: matchLabelVisible || serveLabelVisible
                )

                ZStack {
                    Text("\(score)")
                        .font(
                            .system(
                                size: 34,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(.primary)
                        .monospacedDigit()
                        .scaleEffect(isGameActive ? 1.0 : 0.85)
                        .opacity(isGameActive ? 1.0 : 0.5)
                        .contentTransition(.numericText(countsDown: scoreIsDecreasing))
                        .animation(
                            .easeInOut(duration: 0.3),
                            value: isGameActive
                        )
                        .accessibilityIdentifier(
                            "SideScoreCard.score.team\(teamNumber)"
                        )

                    if game.isCompleted, isWinningTeam {
                        WinnerChip(game: game, teamTintColor: cardTintColor)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, DesignSystem.Spacing.md)
        .padding(.leading, DesignSystem.Spacing.md)
        .padding(.trailing, DesignSystem.Spacing.lg)
        .glassEffect(
            .regular.tint(cardTintColor.opacity(isGameActive ? 0.2 : 0.05)).interactive(),
            in: .capsule
        )
        .contentShape(.capsule)
        .onAppear {
            previousScore = score
        }
        .onChange(of: score) { _, newScore in
            previousScore = newScore
        }
        .onTapGesture {
            Task {
                guard !game.isCompleted else { return }
                do {
                    // Always delegate to manager; it enforces allowed states
                    if game.currentServer != teamNumber {
                        try await gameManager.setServer(to: teamNumber, in: game)
                    }
                } catch {
                    print("Failed to update server: \(error.localizedDescription)")
                }
            }
        }
    }
}
