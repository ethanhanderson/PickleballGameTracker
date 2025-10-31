//
//  CompletedGameFactory.swift
//  GameTrackerCore
//
//  Created by Agent on 9/29/25.
//

import Foundation
import SwiftData

/// Factory for generating completed game instances with realistic data for previews and testing.
///
/// The factory provides a fluent builder-style API that defaults to generating randomized data
/// while allowing any property to be explicitly specified. This ensures preview data remains
/// realistic and varied while supporting specific testing scenarios.
///
/// ## Basic Usage
///
/// Generate a random completed game:
/// ```swift
/// let game = CompletedGameFactory().generate()
/// ```
///
/// Generate a specific scenario:
/// ```swift
/// let game = CompletedGameFactory()
///     .gameType(.tournament)
///     .scores(winner: 15, loser: 13)
///     .timestamp(hoursAgo: 2)
///     .duration(minutes: 35)
///     .generate()
/// ```
///
/// ## Batch Generation
///
/// Generate multiple games at once:
/// ```swift
/// let games = CompletedGameFactory.batch(count: 10)
/// ```
///
/// Generate games with specific constraints:
/// ```swift
/// let recentGames = CompletedGameFactory.batch(count: 5) { factory in
///     factory
///         .gameType(.recreational)
///         .timestamp(withinDays: 3)
/// }
/// ```
///
/// ## Realistic Data
///
/// The factory generates data that reflects real-world pickleball:
/// - Scores respect winning score rules and win-by-two requirements
/// - Duration correlates with score differential and rally count
/// - Rally counts are proportional to total points scored
/// - Timestamps can be distributed across hours, days, or weeks
///
/// ## Integration with Roster
///
/// When a ModelContext is provided, the factory can assign games to real players/teams:
/// ```swift
/// // Auto-assign random players for singles
/// let game = CompletedGameFactory(context: modelContext)
///     .withPlayers()
///     .generate()
///
/// // Auto-assign random teams for doubles
/// let game = CompletedGameFactory(context: modelContext)
///     .withTeams()
///     .generate()
/// ```
///
/// Or assign specific entities:
/// ```swift
/// // Assign specific players
/// let game = CompletedGameFactory(context: modelContext)
///     .assignPlayers(player1, player2)
///     .generate()
///
/// // Assign specific teams
/// let game = CompletedGameFactory(context: modelContext)
///     .assignTeams(team1, team2)
///     .generate()
/// ```
@MainActor
public struct CompletedGameFactory {
    
    // MARK: - Configuration
    
    private var _gameType: GameType?
    private var _rules: GameRules?
    private var _score1: Int?
    private var _score2: Int?
    private var _winningScore: Int?
    private var _winByTwo: Bool?
    private var _hoursAgo: Int?
    private var _daysAgo: Int?
    private var _specificDate: Date?
    private var _duration: TimeInterval?
    private var _rallies: Int?
    private var _notes: String?
    private var _context: ModelContext?
    private var _assignPlayersFromRoster: Bool = false
    private var _assignTeamsFromRoster: Bool = false
    private var _player1: PlayerProfile?
    private var _player2: PlayerProfile?
    private var _team1: TeamProfile?
    private var _team2: TeamProfile?
    
    // MARK: - Initialization
    
    /// Creates a new factory instance.
    ///
    /// - Parameter context: Optional ModelContext for accessing roster data. When provided,
    ///   the factory can assign games to existing players or teams.
    public init(context: ModelContext? = nil) {
        self._context = context
    }
    
    // MARK: - Game Type Configuration
    
    /// Sets the game type for the generated game.
    ///
    /// If not specified, a random game type will be selected from all available types.
    ///
    /// - Parameter type: The game type (recreational, tournament, training, social, custom)
    /// - Returns: Self for method chaining
    public func gameType(_ type: GameType) -> Self {
        var copy = self
        copy._gameType = type
        return copy
    }
    
    /// Sets custom rules for the generated game.
    ///
    /// The rules will be used for the game. If not specified,
    /// standard rules for the game type will be used.
    ///
    /// - Parameter rules: A GameRules instance with custom rules
    /// - Returns: Self for method chaining
    public func rules(_ rules: GameRules) -> Self {
        var copy = self
        copy._rules = rules
        return copy
    }
    
    // MARK: - Score Configuration
    
    /// Sets specific scores for both teams.
    ///
    /// The factory will use these exact scores. If not specified, realistic random scores
    /// will be generated based on the winning score rules.
    ///
    /// - Parameters:
    ///   - score1: Score for team/player 1
    ///   - score2: Score for team/player 2
    /// - Returns: Self for method chaining
    public func scores(_ score1: Int, _ score2: Int) -> Self {
        var copy = self
        copy._score1 = score1
        copy._score2 = score2
        return copy
    }
    
    /// Sets scores by specifying winner and loser scores.
    ///
    /// This is useful for generating games where you want to control the outcome
    /// without worrying about which team number wins.
    ///
    /// - Parameters:
    ///   - winner: Score for the winning team
    ///   - loser: Score for the losing team
    /// - Returns: Self for method chaining
    public func scores(winner: Int, loser: Int) -> Self {
        var copy = self
        if Bool.random() {
            copy._score1 = winner
            copy._score2 = loser
        } else {
            copy._score1 = loser
            copy._score2 = winner
        }
        return copy
    }
    
    /// Sets the winning score rule for the game.
    ///
    /// If not specified, defaults to 11 (standard pickleball) or the variation's winning score.
    ///
    /// - Parameter score: Points needed to win (typically 7, 11, 15, or 21)
    /// - Returns: Self for method chaining
    public func winningScore(_ score: Int) -> Self {
        var copy = self
        copy._winningScore = score
        return copy
    }
    
    /// Sets whether the game requires winning by two points.
    ///
    /// If not specified, defaults to true (standard pickleball rules).
    ///
    /// - Parameter required: Whether win-by-two is required
    /// - Returns: Self for method chaining
    public func winByTwo(_ required: Bool) -> Self {
        var copy = self
        copy._winByTwo = required
        return copy
    }
    
    // MARK: - Timestamp Configuration
    
    /// Sets the completion timestamp relative to now by hours.
    ///
    /// - Parameter hours: Number of hours before now (e.g., 2 means 2 hours ago)
    /// - Returns: Self for method chaining
    public func timestamp(hoursAgo hours: Int) -> Self {
        var copy = self
        copy._hoursAgo = hours
        copy._daysAgo = nil
        copy._specificDate = nil
        return copy
    }
    
    /// Sets the completion timestamp relative to now by days.
    ///
    /// - Parameter days: Number of days before now (e.g., 3 means 3 days ago)
    /// - Returns: Self for method chaining
    public func timestamp(daysAgo days: Int) -> Self {
        var copy = self
        copy._daysAgo = days
        copy._hoursAgo = nil
        copy._specificDate = nil
        return copy
    }
    
    /// Sets the completion timestamp to a random time within the specified number of days.
    ///
    /// Useful for generating varied history data across a time period.
    ///
    /// - Parameter days: Maximum days in the past (e.g., 7 generates timestamps within the last week)
    /// - Returns: Self for method chaining
    public func timestamp(withinDays days: Int) -> Self {
        var copy = self
        let randomDays = Int.random(in: 0...days)
        let randomHours = Int.random(in: 0...23)
        copy._daysAgo = randomDays
        copy._hoursAgo = randomHours
        copy._specificDate = nil
        return copy
    }
    
    /// Sets an explicit completion date/time.
    ///
    /// - Parameter date: The exact date and time the game was completed
    /// - Returns: Self for method chaining
    public func timestamp(_ date: Date) -> Self {
        var copy = self
        copy._specificDate = date
        copy._hoursAgo = nil
        copy._daysAgo = nil
        return copy
    }
    
    // MARK: - Game Details Configuration
    
    /// Sets the game duration.
    ///
    /// - Parameter seconds: Duration in seconds
    /// - Returns: Self for method chaining
    public func duration(seconds: TimeInterval) -> Self {
        var copy = self
        copy._duration = seconds
        return copy
    }
    
    /// Sets the game duration in minutes.
    ///
    /// - Parameter minutes: Duration in minutes
    /// - Returns: Self for method chaining
    public func duration(minutes: Int) -> Self {
        var copy = self
        copy._duration = TimeInterval(minutes * 60)
        return copy
    }
    
    /// Sets the game duration with both minutes and seconds for precise timing.
    ///
    /// This allows for more realistic game durations like "25 minutes and 30 seconds"
    /// which better reflects actual game timing.
    ///
    /// - Parameters:
    ///   - minutes: Duration in minutes
    ///   - seconds: Additional seconds (0-59)
    /// - Returns: Self for method chaining
    public func duration(minutes: Int, seconds: Int) -> Self {
        var copy = self
        copy._duration = TimeInterval(minutes * 60 + seconds)
        return copy
    }
    
    /// Sets the total rally count for the game.
    ///
    /// If not specified, rally count will be estimated based on scores.
    ///
    /// - Parameter count: Number of rallies played
    /// - Returns: Self for method chaining
    public func rallies(_ count: Int) -> Self {
        var copy = self
        copy._rallies = count
        return copy
    }
    
    /// Adds notes/description to the game.
    ///
    /// - Parameter text: Notes about the game
    /// - Returns: Self for method chaining
    public func notes(_ text: String) -> Self {
        var copy = self
        copy._notes = text
        return copy
    }
    
    // MARK: - Player/Team Assignment
    
    /// Assigns the game to random players from the roster.
    ///
    /// Requires a ModelContext to be provided during initialization. The factory will
    /// select two random players for a singles game and create a variation with their names.
    ///
    /// - Returns: Self for method chaining
    public func withPlayers() -> Self {
        var copy = self
        copy._assignPlayersFromRoster = true
        return copy
    }
    
    /// Assigns the game to random teams from the roster.
    ///
    /// Requires a ModelContext to be provided during initialization. The factory will
    /// select two random teams and create a variation with their names.
    ///
    /// - Returns: Self for method chaining
    public func withTeams() -> Self {
        var copy = self
        copy._assignTeamsFromRoster = true
        return copy
    }
    
    /// Assigns specific players to the game.
    ///
    /// Appropriate for singles games or when you want to assign specific players.
    ///
    /// - Parameters:
    ///   - player1: Player for team 1
    ///   - player2: Player for team 2
    /// - Returns: Self for method chaining
    public func assignPlayers(_ player1: PlayerProfile, _ player2: PlayerProfile) -> Self {
        var copy = self
        copy._player1 = player1
        copy._player2 = player2
        return copy
    }
    
    /// Assigns specific teams to the game.
    ///
    /// Appropriate for doubles games or when you want to assign specific teams.
    ///
    /// - Parameters:
    ///   - team1: Team for side 1
    ///   - team2: Team for side 2
    /// - Returns: Self for method chaining
    public func assignTeams(_ team1: TeamProfile, _ team2: TeamProfile) -> Self {
        var copy = self
        copy._team1 = team1
        copy._team2 = team2
        return copy
    }
    
    // MARK: - Generation
    
    /// Result of generating a completed game, containing both the game and its completion date.
    public struct GeneratedGame {
        public let game: Game
        public let completionDate: Date
    }
    
    /// Generates a completed game with the configured settings.
    ///
    /// Any settings not explicitly specified will be randomly generated within realistic bounds.
    ///
    /// The game is created in a pre-completed state with all data configured, but `isCompleted`
    /// is left as `false` so that `GameStore.complete()` can properly finalize it and create
    /// the associated `GameSummary` record.
    ///
    /// - Returns: A GeneratedGame containing the game and its intended completion date
    public func generateWithDate() -> GeneratedGame {
        let gameType = _gameType ?? GameType.allCases.randomElement()!
        let rules = _rules
        let winningScore = _winningScore ?? rules?.winningScore ?? gameType.defaultWinningScore
        let winByTwo = _winByTwo ?? rules?.winByTwo ?? gameType.defaultWinByTwo
        
        let (score1, score2) = generateScores(winningScore: winningScore, winByTwo: winByTwo)
        let completedDate = generateCompletedDate()
        let rallies = _rallies ?? estimateRallies(score1: score1, score2: score2)
        let duration = _duration ?? estimateDuration(score1: score1, score2: score2, rallies: rallies)
        
        let game: Game
        if let rules = rules {
            game = Game(gameType: gameType, rules: rules)
        } else {
            game = Game(gameType: gameType)
        }
        
        game.score1 = score1
        game.score2 = score2
        game.lastModified = completedDate
        game.createdDate = completedDate.addingTimeInterval(-duration)
        game.duration = duration
        game.totalRallies = rallies
        game.notes = _notes
        game.gameState = .completed
        
        assignRosterEntities(to: game)
        
        return GeneratedGame(game: game, completionDate: completedDate)
    }
    
    /// Generates a completed game with the configured settings.
    ///
    /// Any settings not explicitly specified will be randomly generated within realistic bounds.
    ///
    /// - Returns: A Game instance (for backwards compatibility with existing code)
    public func generate() -> Game {
        generateWithDate().game
    }
    
    // MARK: - Batch Generation
    
    /// Generates multiple completed games with randomized data, including completion dates.
    ///
    /// Each game will have different scores, timestamps, and durations to create
    /// realistic variety in preview data.
    ///
    /// - Parameter count: Number of games to generate
    /// - Returns: Array of GeneratedGame instances with games and their completion dates
    public static func batchWithDates(count: Int) -> [GeneratedGame] {
        (0..<count).map { _ in CompletedGameFactory().generateWithDate() }
    }
    
    /// Generates multiple completed games with a configuration closure, including completion dates.
    ///
    /// The closure is called for each game, allowing you to customize the factory
    /// while still maintaining randomness in other properties.
    ///
    /// Example:
    /// ```swift
    /// let generated = CompletedGameFactory.batchWithDates(count: 10) { factory in
    ///     factory.gameType(.recreational).timestamp(withinDays: 7)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - count: Number of games to generate
    ///   - configure: Closure that configures each factory instance
    /// - Returns: Array of GeneratedGame instances
    public static func batchWithDates(count: Int, configure: (CompletedGameFactory) -> CompletedGameFactory) -> [GeneratedGame] {
        (0..<count).map { _ in configure(CompletedGameFactory()).generateWithDate() }
    }
    
    /// Generates multiple completed games with randomized data.
    ///
    /// Each game will have different scores, timestamps, and durations to create
    /// realistic variety in preview data.
    ///
    /// - Parameter count: Number of games to generate
    /// - Returns: Array of completed Game instances
    public static func batch(count: Int) -> [Game] {
        (0..<count).map { _ in CompletedGameFactory().generate() }
    }
    
    /// Generates multiple completed games with a configuration closure.
    ///
    /// The closure is called for each game, allowing you to customize the factory
    /// while still maintaining randomness in other properties.
    ///
    /// Example:
    /// ```swift
    /// let games = CompletedGameFactory.batch(count: 10) { factory in
    ///     factory.gameType(.recreational).timestamp(withinDays: 7)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - count: Number of games to generate
    ///   - configure: Closure that configures each factory instance
    /// - Returns: Array of completed Game instances
    public static func batch(count: Int, configure: (CompletedGameFactory) -> CompletedGameFactory) -> [Game] {
        (0..<count).map { _ in configure(CompletedGameFactory()).generate() }
    }
    
    // MARK: - Private Helpers
    
    private func generateScores(winningScore: Int, winByTwo: Bool) -> (Int, Int) {
        if let s1 = _score1, let s2 = _score2 {
            return (s1, s2)
        }
        
        let winner = winningScore
        let loserMax = winByTwo ? winner - 2 : winner - 1
        let loserMin = max(0, loserMax - 8)
        let loser = Int.random(in: loserMin...loserMax)
        
        if Bool.random() {
            return (winner, loser)
        } else {
            return (loser, winner)
        }
    }
    
    private func generateCompletedDate() -> Date {
        if let date = _specificDate {
            return date
        }
        
        var components = DateComponents()
        
        if let hours = _hoursAgo {
            components.hour = -hours
        }
        
        if let days = _daysAgo {
            components.day = -days
        }
        
        if components.hour == nil && components.day == nil {
            let randomDays = Int.random(in: 0...30)
            components.day = -randomDays
        }
        
        return Calendar.current.date(byAdding: components, to: Date()) ?? Date()
    }
    
    private func estimateRallies(score1: Int, score2: Int) -> Int {
        let totalPoints = score1 + score2
        let baseRallies = totalPoints
        let variance = Int.random(in: -3...5)
        return max(totalPoints, baseRallies + variance)
    }
    
    private func estimateDuration(score1: Int, score2: Int, rallies: Int) -> TimeInterval {
        let totalPoints = score1 + score2
        let baseMinutes = totalPoints + 10
        let rallyFactor = Double(rallies - totalPoints) * 0.5
        let variance = Double.random(in: -5...10)
        let minutes = max(10, Double(baseMinutes) + rallyFactor + variance)
        return minutes * 60
    }
    
    private func assignRosterEntities(to game: Game) {
        guard let context = _context else { return }
        
        if let p1 = _player1, let p2 = _player2 {
            game.participantMode = .players
            game.side1PlayerIds = [p1.id]
            game.side2PlayerIds = [p2.id]
            return
        }
        
        if let t1 = _team1, let t2 = _team2 {
            game.participantMode = .teams
            game.side1TeamId = t1.id
            game.side2TeamId = t2.id
            return
        }
        
        if _assignPlayersFromRoster {
            let fetchDescriptor = FetchDescriptor<PlayerProfile>(
                predicate: #Predicate { !$0.isArchived }
            )
            
            guard let players = try? context.fetch(fetchDescriptor),
                  players.count >= 2 else {
                return
            }
            
            let shuffled = players.shuffled()
            let p1 = shuffled[0]
            let p2 = shuffled[1]
            
            game.participantMode = .players
            game.side1PlayerIds = [p1.id]
            game.side2PlayerIds = [p2.id]
            return
        }
        
        if _assignTeamsFromRoster {
            let fetchDescriptor = FetchDescriptor<TeamProfile>(
                predicate: #Predicate { !$0.isArchived }
            )
            
            guard let teams = try? context.fetch(fetchDescriptor),
                  teams.count >= 2 else {
                return
            }
            
            let shuffled = teams.shuffled()
            let t1 = shuffled[0]
            let t2 = shuffled[1]
            
            game.participantMode = .teams
            game.side1TeamId = t1.id
            game.side2TeamId = t2.id
        }
    }
}

// MARK: - Convenience Presets

extension CompletedGameFactory {
    
    /// Generates a recent competitive win (last few hours, close score).
    ///
    /// Perfect for testing views that show recent game results.
    public static func recentCompetitiveWin() -> Game {
        CompletedGameFactory()
            .gameType(.recreational)
            .scores(winner: 11, loser: 9)
            .timestamp(hoursAgo: Int.random(in: 1...4))
            .duration(minutes: Int.random(in: 25...35))
            .generate()
    }
    
    /// Generates a dominant victory (large point differential).
    ///
    /// Useful for testing statistics views and victory celebration screens.
    public static func dominantVictory() -> Game {
        CompletedGameFactory()
            .scores(winner: 11, loser: Int.random(in: 2...5))
            .timestamp(daysAgo: Int.random(in: 1...5))
            .duration(minutes: Int.random(in: 18...25))
            .generate()
    }
    
    /// Generates a training session (quick game to 7).
    ///
    /// Perfect for testing training-specific features and quick game views.
    public static func trainingSession() -> Game {
        CompletedGameFactory()
            .gameType(.training)
            .winningScore(7)
            .winByTwo(false)
            .timestamp(withinDays: 7)
            .duration(minutes: Int.random(in: 12...20))
            .generate()
    }
    
    /// Generates a tournament match (15 or 21 points).
    ///
    /// Ideal for testing tournament-related features and longer game scenarios.
    public static func tournamentMatch() -> Game {
        let winningScore = [15, 21].randomElement()!
        return CompletedGameFactory()
            .gameType(.tournament)
            .winningScore(winningScore)
            .timestamp(withinDays: 14)
            .duration(minutes: Int.random(in: 35...50))
            .generate()
    }
    
    /// Generates a collection with realistic variety for history views.
    ///
    /// Creates a mix of game types, score differentials, and timestamps distributed
    /// over the specified time period. This is perfect for previewing history lists,
    /// statistics dashboards, and search functionality.
    ///
    /// The distribution includes:
    /// - 60% recreational games
    /// - 20% training sessions
    /// - 15% tournament matches
    /// - 5% social games
    ///
    /// - Parameters:
    ///   - count: Number of games to generate (default: 20)
    ///   - withinDays: Days to distribute games across (default: 30)
    /// - Returns: Array of GeneratedGame instances with realistic variety
    public static func realisticHistory(count: Int = 20, withinDays: Int = 30) -> [GeneratedGame] {
        (0..<count).map { _ in
            let roll = Int.random(in: 1...100)
            let gameType: GameType
            
            switch roll {
            case 1...60: gameType = .recreational
            case 61...80: gameType = .training
            case 81...95: gameType = .tournament
            default: gameType = .social
            }
            
            return CompletedGameFactory()
                .gameType(gameType)
                .timestamp(withinDays: withinDays)
                .generateWithDate()
        }
    }
    
    /// Generates a balanced mix of wins and losses.
    ///
    /// Creates games where roughly half result in wins and half in losses,
    /// useful for testing balanced statistics and win/loss filtering.
    ///
    /// - Parameter count: Number of games to generate (default: 10)
    /// - Returns: Array of GeneratedGame instances with balanced outcomes
    public static func balancedWinLoss(count: Int = 10) -> [GeneratedGame] {
        (0..<count).map { index in
            let shouldWin = index % 2 == 0
            let winnerScore = 11
            let loserScore = Int.random(in: 6...9)
            
            return CompletedGameFactory()
                .scores(
                    shouldWin ? winnerScore : loserScore,
                    shouldWin ? loserScore : winnerScore
                )
                .timestamp(withinDays: 14)
                .generateWithDate()
        }
    }
    
    /// Generates games with progressively improving performance.
    ///
    /// Useful for testing statistics views that show player improvement over time.
    /// Earlier games have larger point differentials against the player, while
    /// later games show closer matches and eventual wins.
    ///
    /// - Parameter count: Number of games to generate (default: 10)
    /// - Returns: Array of GeneratedGame instances showing progression
    public static func improvementProgression(count: Int = 10) -> [GeneratedGame] {
        (0..<count).map { index in
            let progression = Double(index) / Double(count)
            
            let winnerScore = 11
            let loserScoreRange: ClosedRange<Int>
            let playerWins: Bool
            
            switch progression {
            case 0..<0.3:
                loserScoreRange = 3...5
                playerWins = false
            case 0.3..<0.6:
                loserScoreRange = 6...8
                playerWins = Bool.random()
            case 0.6..<0.8:
                loserScoreRange = 8...10
                playerWins = Bool.random()
            default:
                loserScoreRange = 9...10
                playerWins = true
            }
            
            let loserScore = Int.random(in: loserScoreRange)
            
            return CompletedGameFactory()
                .scores(
                    playerWins ? winnerScore : loserScore,
                    playerWins ? loserScore : winnerScore
                )
                .timestamp(daysAgo: count - index)
                .generateWithDate()
        }
    }
}

// MARK: - Advanced Composition Methods

extension CompletedGameFactory {
    
    /// Generates a matchup history between two specific players.
    ///
    /// Creates a series of games between the same two players with controlled win ratios,
    /// realistic temporal distribution, and competitive score patterns.
    ///
    /// ## Use Cases
    /// - Testing player statistics and head-to-head records
    /// - Previewing rivalry/matchup views
    /// - Generating realistic player relationship data
    ///
    /// - Parameters:
    ///   - player1: First player
    ///   - player2: Second player
    ///   - gameCount: Number of games to generate
    ///   - player1WinRatio: Ratio of games player1 wins (0.0-1.0)
    ///   - withinDays: Days to distribute games across
    ///   - context: Optional ModelContext for game creation
    /// - Returns: Array of GeneratedGame instances with proper completion dates
    public static func matchupHistory(
        player1: PlayerProfile,
        player2: PlayerProfile,
        gameCount: Int,
        player1WinRatio: Double = 0.5,
        withinDays: Int = 60,
        context: ModelContext? = nil
    ) -> [GeneratedGame] {
        let player1Wins = Int(Double(gameCount) * player1WinRatio)
        
        var results: [Bool] = Array(repeating: true, count: player1Wins)
        results += Array(repeating: false, count: gameCount - player1Wins)
        results.shuffle()
        
        return (0..<gameCount).map { index in
            let player1Won = results[index]
            let isClose = Double.random(in: 0...1) < 0.6
            let winnerScore = 11
            let loserScore = isClose ? Int.random(in: 8...10) : Int.random(in: 4...7)
            
            return CompletedGameFactory(context: context)
                .assignPlayers(player1, player2)
                .scores(
                    player1Won ? winnerScore : loserScore,
                    player1Won ? loserScore : winnerScore
                )
                .gameType([.recreational, .tournament].randomElement()!)
                .timestamp(withinDays: withinDays)
                .generateWithDate()
        }
    }
    
    /// Generates a player journey showing improvement over time.
    ///
    /// Creates games that demonstrate gradual player improvement through:
    /// - Increasing win rate over time
    /// - Better scores in later games
    /// - Shorter game durations (more decisive wins)
    ///
    /// ## Use Cases
    /// - Testing progression tracking features
    /// - Demonstrating statistical trends
    /// - Creating engaging demo data
    ///
    /// - Parameters:
    ///   - player: Player showing improvement
    ///   - opponent: Consistent opponent
    ///   - gameCount: Number of games in journey
    ///   - withinDays: Days to distribute across
    ///   - context: Optional ModelContext
    /// - Returns: Array of games showing improvement trend
    public static func playerJourney(
        player: PlayerProfile,
        opponent: PlayerProfile,
        gameCount: Int,
        withinDays: Int = 90,
        trend: ImprovementTrend = .improving,
        context: ModelContext? = nil
    ) -> [GeneratedGame] {
        (0..<gameCount).map { index in
            let progress = Double(index) / Double(gameCount)
            let winProbability: Double
            
            switch trend {
            case .improving:
                winProbability = 0.2 + (progress * 0.6)
            case .declining:
                winProbability = 0.8 - (progress * 0.6)
            case .stable:
                winProbability = 0.5
            }
            
            let playerWins = Double.random(in: 0...1) < winProbability
            let competitiveness = 1.0 - (progress * 0.3)
            let isClose = Double.random(in: 0...1) < competitiveness
            
            let winnerScore = 11
            let loserScore = isClose ? Int.random(in: 8...10) : Int.random(in: 5...7)
            
            let daysAgo = withinDays - Int(Double(withinDays) * progress)
            
            return CompletedGameFactory(context: context)
                .assignPlayers(player, opponent)
                .scores(
                    playerWins ? winnerScore : loserScore,
                    playerWins ? loserScore : winnerScore
                )
                .timestamp(daysAgo: daysAgo)
                .generateWithDate()
        }
    }
    
    /// Generates a winning or losing streak.
    ///
    /// Creates a series of consecutive wins or losses for statistical testing.
    ///
    /// - Parameters:
    ///   - player: Player on the streak
    ///   - opponent: Opponent(s) - can be same or different
    ///   - length: Number of games in streak
    ///   - streakType: .winning or .losing
    ///   - withinDays: Days to distribute across
    ///   - context: Optional ModelContext
    /// - Returns: Array of games forming a streak
    public static func streak(
        player: PlayerProfile,
        opponent: PlayerProfile,
        length: Int,
        streakType: StreakType,
        withinDays: Int = 14,
        context: ModelContext? = nil
    ) -> [GeneratedGame] {
        let playerWins = streakType == .winning
        
        return (0..<length).map { index in
            let winnerScore = 11
            let loserScore = Int.random(in: 6...9)
            let daysAgo = withinDays - (index * (withinDays / length))
            
            return CompletedGameFactory(context: context)
                .assignPlayers(player, opponent)
                .scores(
                    playerWins ? winnerScore : loserScore,
                    playerWins ? loserScore : winnerScore
                )
                .timestamp(daysAgo: daysAgo)
                .generateWithDate()
        }
    }
    
    /// Generates alternating win/loss pattern.
    ///
    /// Useful for testing statistical edge cases and patterns.
    ///
    /// - Parameters:
    ///   - player: Player in the pattern
    ///   - opponent: Opponent
    ///   - count: Number of games
    ///   - startsWithWin: Whether player wins first game
    ///   - context: Optional ModelContext
    /// - Returns: Array of games with alternating outcomes
    public static func alternatingPattern(
        player: PlayerProfile,
        opponent: PlayerProfile,
        count: Int,
        startsWithWin: Bool = true,
        withinDays: Int = 30,
        context: ModelContext? = nil
    ) -> [GeneratedGame] {
        (0..<count).map { index in
            let playerWins = (index % 2 == 0) == startsWithWin
            let winnerScore = 11
            let loserScore = Int.random(in: 7...9)
            
            return CompletedGameFactory(context: context)
                .assignPlayers(player, opponent)
                .scores(
                    playerWins ? winnerScore : loserScore,
                    playerWins ? loserScore : winnerScore
                )
                .timestamp(withinDays: withinDays)
                .generateWithDate()
        }
    }
    
    /// Generates games with realistic time-of-day distribution.
    ///
    /// Most games in evenings (6-9 PM) and weekends, mimicking real pickleball patterns.
    ///
    /// - Parameters:
    ///   - count: Number of games
    ///   - days: Days to distribute across
    ///   - context: Optional ModelContext
    /// - Returns: Array of games with realistic temporal distribution
    public static func realisticSchedule(
        count: Int,
        days: Int = 30,
        context: ModelContext? = nil
    ) -> [GeneratedGame] {
        (0..<count).map { _ in
            let daysAgo = Int.random(in: 0..<days)
            let isWeekend = Double.random(in: 0...1) < 0.4
            
            let hour: Int
            if isWeekend {
                hour = Int.random(in: 9...20)
            } else {
                hour = Double.random(in: 0...1) < 0.7 ? Int.random(in: 17...21) : Int.random(in: 6...9)
            }
            
            let baseDate = Date().addingTimeInterval(-Double(daysAgo * 24 * 3600))
            var components = Calendar.current.dateComponents([.year, .month, .day], from: baseDate)
            components.hour = hour
            components.minute = Int.random(in: 0...59)
            let completionDate = Calendar.current.date(from: components) ?? baseDate
            
            let generated = CompletedGameFactory(context: context)
                .generate()
            
            return GeneratedGame(game: generated, completionDate: completionDate)
        }
    }
}

// MARK: - Supporting Types

extension CompletedGameFactory {
    /// Trend direction for player journey generation
    public enum ImprovementTrend {
        case improving
        case declining
        case stable
    }
    
    /// Streak type for streak generation
    public enum StreakType {
        case winning
        case losing
    }
}
