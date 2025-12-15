import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct LiveGameScreen: View {
    let gameId: UUID
    let onDismiss: (() -> Void)?

    @Query private var games: [Game]

    init(
        gameId: UUID,
        onDismiss: (() -> Void)? = nil
    ) {
        self.gameId = gameId
        self.onDismiss = onDismiss
        _games = Query(
            filter: #Predicate<Game> { $0.id == gameId }
        )
    }

    var body: some View {
        if let game = games.first {
            LiveView(
                game: game,
                onDismiss: onDismiss
            )
        } else {
            GameUnavailableView()
        }
    }
}

// MARK: - Unavailable Fallback

@MainActor
private struct GameUnavailableView: View {
    var body: some View {
        VStack {
            Spacer()
            EmptyStateView(
                icon: "flag.slash",
                title: "Game Unavailable",
                description: "The game could not be loaded or was removed. Please start a new game from the Games tab."
            )
            .padding()
            Spacer()
        }
    }
}


