import GameTrackerCore
import SwiftUI

struct StatusIndicatorCapsule: View {
    let icon: String
    let label: String
    let tint: Color
    let visible: Bool
    let animate: Bool
    let triggerAnimationId: Int
    let accessibilityId: String
    var onLabelVisibilityChange: (Bool) -> Void = { _ in }
    var shouldDefer: () -> Bool = { false }

    @State private var show: Bool = false
    @State private var showLabel: Bool = false

    private var taskKey: Int {
        (triggerAnimationId &* 4) + (animate ? 2 : 0) + (visible ? 1 : 0)
    }

    var body: some View {
        Group {
            if visible || show {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                        .transition(.scale.combined(with: .opacity))

                    if showLabel {
                        Text(label)
                            .font(
                                .system(
                                    size: 11,
                                    weight: .bold,
                                    design: .rounded
                                )
                            )
                            .foregroundStyle(.primary)
                            .transition(
                                .move(edge: .trailing).combined(with: .opacity)
                            )
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .glassEffect(.regular.tint(tint), in: Capsule())
                .mask(Capsule())
                .opacity(show ? 1 : 0)
                .accessibilityHidden(!show)
                .task(id: taskKey) {
                    if visible {
                        if !show {
                            withAnimation(
                                .snappy(duration: 0.28, extraBounce: 0.05)
                            ) {
                                show = true
                            }
                        }
                        if animate {
                            await waitIfDeferred()
                            await appearSequence()
                        } else {
                            withAnimation(.none) {
                                showLabel = false
                            }
                        }
                    } else {
                        await hideSequence()
                    }
                }
                .onChange(of: showLabel) { _, newValue in
                    onLabelVisibilityChange(newValue)
                }
                .accessibilityIdentifier(accessibilityId)
            }
        }
        .animation(.smooth(duration: 0.22, extraBounce: 0.0), value: showLabel)
        .animation(.snappy(duration: 0.28, extraBounce: 0.05), value: show)
    }

    private func appearSequence() async {
        if !show {
            withAnimation(.snappy(duration: 0.28, extraBounce: 0.05)) {
                show = true
            }
        }
        withAnimation(.smooth(duration: 0.22, extraBounce: 0.0)) {
            showLabel = true
        }
        try? await Task.sleep(for: .seconds(3))
        withAnimation(.smooth(duration: 0.25, extraBounce: 0.0)) {
            showLabel = false
        }
    }

    private func hideSequence() async {
        withAnimation(.smooth(duration: 0.2, extraBounce: 0.0)) {
            showLabel = false
        }
        try? await Task.sleep(for: .milliseconds(50))
        withAnimation(.snappy(duration: 0.3, extraBounce: 0.0)) {
            show = false
        }
    }

    private func waitIfDeferred() async {
        if shouldDefer() {
            try? await Task.sleep(for: .milliseconds(120))
        }
        while shouldDefer() {
            if Task.isCancelled { return }
            try? await Task.sleep(for: .milliseconds(60))
        }
    }
}
