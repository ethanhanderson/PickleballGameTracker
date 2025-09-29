import SwiftUI

public enum Accessibility {
    // MARK: - VoiceOver Labels
    public enum Labels {
        public static let scorePlayer1 = "Player 1 Score"
        public static let scorePlayer2 = "Player 2 Score"
        public static let incrementScore = "Increment Score"
        public static let decrementScore = "Decrement Score"
        public static let undoLastPoint = "Undo Last Point"
        public static let finishGame = "Finish Game"
        public static let saveAndReturn = "Save and Return to Menu"
        public static let backToMenu = "Back to Menu"
        public static let newGame = "Start New Game"
        public static let gameHistory = "View Game History"
        public static let resumeGame = "Resume Current Game"
        public static let selectGameType = "Select Game Type"
        public static let gameComplete = "Game Complete"
        public static let winner = "Winner"
        public static let duration = "Game Duration"
        public static let rallies = "Total Rallies"
        public static let currentRally = "Current Rally"
        public static let playingTo = "Playing to"
        public static let winBy = "Win by"
        public static let gameTypeIcon = "Game Type Icon"
        public static let filterGames = "Filter Games"
        public static let resetFilters = "Reset Filters"
    }

    // MARK: - VoiceOver Hints
    public enum Hints {
        public static let scoreButton = "Double tap to add a point"
        public static let undoButton = "Double tap to undo the last point"
        public static let gameTypeButton = "Double tap to select this game type"
        public static let navigationButton = "Double tap to navigate"
        public static let filterButton = "Double tap to filter by this option"
        public static let gameRow = "Double tap to view game details"
    }
}

public extension View {
    // MARK: - Score Display Accessibility
    func scoreAccessibility(
        score: Int,
        playerLabel: String,
        isWinner: Bool = false
    ) -> some View {
        self
            .accessibilityLabel("\(playerLabel): \(score) points")
            .accessibilityValue(isWinner ? "Winner" : "")
    }

    // MARK: - Action Button Accessibility
    func actionButtonAccessibility(
        label: String,
        hint: String? = nil,
        isEnabled: Bool = true
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
    }

    // MARK: - Navigation Button Accessibility
    func navigationButtonAccessibility(
        label: String,
        hint: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? Accessibility.Hints.navigationButton)
    }

    // MARK: - Game Type Selection Accessibility
    func gameTypeSelectionAccessibility(
        gameType: GameType,
        isSelected: Bool
    ) -> some View {
        self
            .accessibilityLabel(
                "\(gameType.displayName) - \(gameType.description)"
            )
            .accessibilityHint(Accessibility.Hints.gameTypeButton)
    }

    // MARK: - Game Status Accessibility
    func gameStatusAccessibility(
        status: String,
        additionalInfo: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(status)
            .accessibilityValue(additionalInfo ?? "")
    }

    // MARK: - Filter Accessibility
    func filterAccessibility(
        title: String,
        isSelected: Bool
    ) -> some View {
        self
            .accessibilityLabel(title)
            .accessibilityHint(Accessibility.Hints.filterButton)
    }

    // MARK: - Game History Row Accessibility
    func gameHistoryRowAccessibility(
        game: Game,
        rank: Int? = nil
    ) -> some View {
        let rankText = rank != nil ? "Rank \(rank!). " : ""
        let statusText = game.isCompleted ? "Completed" : "In Progress"
        let scoreText =
            "\(game.gameType.playerLabel1) \(game.score1), \(game.gameType.playerLabel2) \(game.score2)"
        let winnerText = game.winner != nil ? ". Winner: \(game.winner!)" : ""
        let durationText =
            game.formattedDuration != nil
            ? ". Duration: \(game.formattedDuration!)" : ""

        return
            self
            .accessibilityLabel(
                "\(rankText)\(game.gameType.displayName) game. \(statusText). \(scoreText)\(winnerText). \(game.formattedDate)\(durationText)"
            )
            .accessibilityHint(Accessibility.Hints.gameRow)
    }

    // MARK: - Header Accessibility
    func headerAccessibility(title: String) -> some View {
        self
            .accessibilityLabel(title)
    }
}


