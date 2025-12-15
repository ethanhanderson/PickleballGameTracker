import GameTrackerCore
import SwiftUI

@MainActor
struct LiveGameBottomAccessory: View {
    let hasLiveGame: Bool
    let onTap: () -> Void
    
    var body: some View {
        if hasLiveGame {
            LiveGameMiniPreview(onTap: onTap)
        }
    }
}

@MainActor
struct CustomLiveGameView: View {
    let hasLiveGame: Bool
    let onTap: () -> Void
    
    var body: some View {
        if hasLiveGame {
            InlineMiniPreview(onTap: onTap)
        }
    }
}

extension View {
    func applyLiveGameBottomAccessory(
        hasLiveGame: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        if #available(iOS 26.1, *) {
            return AnyView(
                self.tabViewBottomAccessory(isEnabled: hasLiveGame) {
                    LiveGameBottomAccessory(
                        hasLiveGame: hasLiveGame,
                        onTap: onTap
                    )
                }
            )
        } else if #available(iOS 26.0, *) {
            return AnyView(
                self.tabViewBottomAccessory {
                    LiveGameBottomAccessory(
                        hasLiveGame: hasLiveGame,
                        onTap: onTap
                    )
                }
            )
        } else {
            return AnyView(
                self.safeAreaInset(edge: .bottom) {
                    if hasLiveGame {
                        CustomLiveGameView(
                            hasLiveGame: hasLiveGame,
                            onTap: onTap
                        )
                        .background(.regularMaterial)
                    }
                }
            )
        }
    }
}
