import Foundation
import SwiftData

public enum ParticipantMode: String, Codable, Sendable {
  case players
  case teams
}

@Model
public final class Game: Hashable {
  @Attribute(.unique) public var id: UUID
  public var gameType: GameType

  public var score1: Int
  public var score2: Int
  public var isCompleted: Bool
  public var isArchived: Bool = false
  public var createdDate: Date
  public var completedDate: Date?
  public var lastModified: Date
  public var duration: TimeInterval?

  public var currentServer: Int
  public var serverNumber: Int
  public var serverPosition: ServerPosition
  public var sideOfCourt: SideOfCourt
  public var gameState: GameState
  public var isFirstServiceSequence: Bool
  public var teamSize: Int = 0

  public var winningScore: Int
  public var winByTwo: Bool
  public var kitchenRule: Bool
  public var doubleBounceRule: Bool
  public var sideSwitchingRule: SideSwitchingRule
  public var servingRotation: ServingRotation
  public var scoringType: ScoringType
  public var timeLimit: TimeInterval?
  public var maxRallies: Int?

  public var notes: String?

  public var totalRallies: Int = 0

  public var events: [GameEvent] = []

  public var participantMode: ParticipantMode = ParticipantMode.players
  public var side1PlayerIds: [UUID] = []
  public var side2PlayerIds: [UUID] = []
  public var side1TeamId: UUID?
  public var side2TeamId: UUID?
  
  public var sessionId: UUID?

  public init(
    id: UUID = UUID(),
    gameType: GameType,
    rules: GameRules? = nil,
    score1: Int = 0,
    score2: Int = 0,
    isCompleted: Bool = false,
    isArchived: Bool = false,
    createdDate: Date = Date(),
    lastModified: Date = Date(),
    currentServer: Int = 1,
    serverNumber: Int = 1,
    serverPosition: ServerPosition = .right,
    sideOfCourt: SideOfCourt = .side1,
    gameState: GameState = .initial,
    isFirstServiceSequence: Bool = true,
    teamSize: Int? = nil,
    winningScore: Int? = nil,
    winByTwo: Bool? = nil,
    kitchenRule: Bool? = nil,
    doubleBounceRule: Bool? = nil,
    sideSwitchingRule: SideSwitchingRule? = nil,
    servingRotation: ServingRotation? = nil,
    scoringType: ScoringType? = nil,
    timeLimit: TimeInterval? = nil,
    maxRallies: Int? = nil,
    notes: String? = nil
  ) {
    self.id = id
    self.gameType = gameType
    self.score1 = score1
    self.score2 = score2
    self.isCompleted = isCompleted
    self.createdDate = createdDate
    self.completedDate = nil
    self.lastModified = lastModified
    self.duration = nil
    self.isArchived = isArchived
    self.currentServer = currentServer
    self.serverNumber = serverNumber
    self.serverPosition = serverPosition
    self.sideOfCourt = sideOfCourt
    self.gameState = gameState
    self.isFirstServiceSequence = isFirstServiceSequence
    self.teamSize = teamSize ?? 0

    let defaultRules = rules ?? gameType.defaultRules
    self.winningScore = winningScore ?? defaultRules.winningScore
    self.winByTwo = winByTwo ?? defaultRules.winByTwo
    self.kitchenRule = kitchenRule ?? defaultRules.kitchenRule
    self.doubleBounceRule = doubleBounceRule ?? defaultRules.doubleBounceRule
    self.sideSwitchingRule = sideSwitchingRule ?? defaultRules.sideSwitchingRule
    self.servingRotation = servingRotation ?? defaultRules.servingRotation
    self.scoringType = scoringType ?? defaultRules.scoringType
    self.timeLimit = timeLimit ?? defaultRules.timeLimit
    self.maxRallies = maxRallies ?? defaultRules.maxRallies
    self.notes = notes

    if self.teamSize <= 0 {
      self.teamSize = gameType.defaultTeamSize
    }
  }

  public convenience init(gameType: GameType, rules: GameRules) {
    self.init(
      gameType: gameType,
      rules: rules,
      winningScore: rules.winningScore,
      winByTwo: rules.winByTwo,
      kitchenRule: rules.kitchenRule,
      doubleBounceRule: rules.doubleBounceRule,
      sideSwitchingRule: rules.sideSwitchingRule,
      servingRotation: rules.servingRotation,
      scoringType: rules.scoringType,
      timeLimit: rules.timeLimit,
      maxRallies: rules.maxRallies
    )
  }
}

// MARK: - Game Extensions

extension Game {
  /// Formatted score string for display
  public var formattedScore: String {
    return "\(score1) - \(score2)"
  }

  /// Formatted date string
  public var formattedDate: String {
    let calendar = Calendar.current
    let now = Date()

    if calendar.isDateInToday(createdDate) {
      let formatter = DateFormatter()
      formatter.dateFormat = "'Today at' h:mm a"
      return formatter.string(from: createdDate)
    }

    let daysSinceGame = calendar.dateComponents([.day], from: createdDate, to: now).day ?? 0
    if daysSinceGame < 7 && daysSinceGame > 0 {
      let formatter = DateFormatter()
      formatter.dateFormat = "EEEE 'at' h:mm a"
      return formatter.string(from: createdDate)
    }

    if daysSinceGame >= 7 && daysSinceGame < 14 {
      let formatter = DateFormatter()
      formatter.dateFormat = "'Last' EEE 'at' h:mm a"
      return formatter.string(from: createdDate)
    }

    let currentYear = calendar.component(.year, from: now)
    let gameYear = calendar.component(.year, from: createdDate)

    let formatter = DateFormatter()
    if gameYear == currentYear {
      formatter.dateFormat = "EEE, MMM d 'at' h:mm a"
    } else {
      formatter.dateFormat = "EEE, MMM d, yyyy 'at' h:mm a"
    }
    return formatter.string(from: createdDate)
  }

  /// Formatted duration string
  public var formattedDuration: String? {
    guard let duration = duration else { return nil }
    let hours = Int(duration) / 3600
    let minutes = Int(duration) % 3600 / 60
    let seconds = Int(duration) % 60

    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    } else {
      return String(format: "%d:%02d", minutes, seconds)
    }
  }

  /// Winner of the game (if completed)
  public var winner: String? {
    guard isCompleted else { return nil }

    if score1 > score2 {
      return effectivePlayerLabel1
    } else if score2 > score1 {
      return effectivePlayerLabel2
    } else {
      return "Tie"
    }
  }

  /// Get effective player labels based on game type
  public var effectivePlayerLabel1: String {
    let size = effectiveTeamSize
    return size == 1 ? "Player 1" : "Team 1"
  }

  public var effectivePlayerLabel2: String {
    let size = effectiveTeamSize
    return size == 1 ? "Player 2" : "Team 2"
  }

  /// Get effective team size from game type
  public var effectiveTeamSize: Int {
    if teamSize > 0 { return teamSize }
    if !side1PlayerIds.isEmpty { return max(1, min(6, side1PlayerIds.count)) }
    preconditionFailure("Team size is not set and cannot be inferred from participants. Ensure participants are set before using game state.")
  }

  /// Get the label for the currently serving player
  public var currentServingPlayerLabel: String {
    if effectiveTeamSize == 1 {
      return currentServer == 1 ? effectivePlayerLabel1 : effectivePlayerLabel2
    } else {
      let teamLabel = currentServer == 1 ? effectivePlayerLabel1 : effectivePlayerLabel2
      return "\(teamLabel) - Player \(serverNumber)"
    }
  }

  /// Get a short label for the currently serving player
  public var currentServingPlayerShortLabel: String {
    if effectiveTeamSize == 1 { return currentServer == 1 ? "P1" : "P2" }
    let teamPrefix = currentServer == 1 ? "T1" : "T2"
    return "\(teamPrefix)P\(serverNumber)"
  }

  /// Check if a specific player on a team is currently serving
  public func isPlayerServing(team: Int, player: Int) -> Bool {
    return currentServer == team && serverNumber == player
  }

  /// Check if game meets winning conditions
  public var shouldComplete: Bool {
    let standardWin = (score1 >= winningScore || score2 >= winningScore)
    let winByTwoSatisfied = !winByTwo || abs(score1 - score2) >= 2

    let timeLimitReached: Bool
    if let timeLimit = timeLimit,
      let duration = duration
    {
      timeLimitReached = duration >= timeLimit
    } else {
      timeLimitReached = false
    }

    let maxRalliesReached: Bool
    if let maxRallies = maxRallies {
      maxRalliesReached = totalRallies >= maxRallies
    } else {
      maxRalliesReached = false
    }

    return (standardWin && winByTwoSatisfied) || timeLimitReached || maxRalliesReached
  }

  /// Check if a specific team is at match point (one point away from winning)
  public func isAtMatchPoint(team: Int) -> Bool {
    guard !isCompleted else { return false }
    guard team == 1 || team == 2 else { return false }

    let simulatedScore1 = team == 1 ? score1 + 1 : score1
    let simulatedScore2 = team == 2 ? score2 + 1 : score2

    let standardWin = (simulatedScore1 >= winningScore || simulatedScore2 >= winningScore)
    let winByTwoSatisfied = !winByTwo || abs(simulatedScore1 - simulatedScore2) >= 2

    return standardWin && winByTwoSatisfied
  }

  /// Get the next server based on current game state and official pickleball rules
  public var nextServer:
    (
      server: Int, serverNumber: Int, position: ServerPosition,
      side: SideOfCourt
    )
  {
    let shouldSwitchSide = sideSwitchingRule.shouldSwitchSides(
      currentScore1: score1,
      currentScore2: score2,
      winningScore: winningScore
    )

    let newSide: SideOfCourt =
      shouldSwitchSide ? (sideOfCourt == .side1 ? .side2 : .side1) : sideOfCourt

    if effectiveTeamSize == 1 {
      let newPosition: ServerPosition = (score1 + score2) % 2 == 0 ? .right : .left
      return (server: currentServer, serverNumber: 1, position: newPosition, side: newSide)
    }

    let totalScore = score1 + score2
    let newPosition: ServerPosition = totalScore % 2 == 0 ? .right : .left

    return (server: currentServer, serverNumber: serverNumber, position: newPosition, side: newSide)
  }

  /// Complete the game
  public func completeGame(at date: Date = Date()) {
    isCompleted = true
    completedDate = date
    gameState = .completed
    duration = date.timeIntervalSince(createdDate)
    lastModified = Date()
  }

  /// Reset the game to initial state
  public func resetGame() {
    score1 = 0
    score2 = 0
    isCompleted = false
    completedDate = nil
    duration = nil
    currentServer = 1
    serverNumber = 1
    serverPosition = .right
    sideOfCourt = .side1
    gameState = .initial
    isFirstServiceSequence = true
    totalRallies = 0
    lastModified = Date()
  }

  /// Resume from pause
  public func resumeGame() {
    gameState = .playing
    lastModified = Date()
  }

  /// Pause the game
  public func pauseGame() {
    gameState = .paused
    lastModified = Date()
  }

  /// Score a point for team/player 1
  public func scorePoint1() {
    guard !isCompleted else { return }
    score1 += 1
    totalRallies += 1
    lastModified = Date()

    let nextServerInfo = nextServer
    currentServer = nextServerInfo.server
    serverNumber = nextServerInfo.serverNumber
    serverPosition = nextServerInfo.position
    sideOfCourt = nextServerInfo.side

    if gameState == .initial || gameState == .serving {
      gameState = .playing
    }

    if shouldComplete {
      completeGame()
    }
  }

  /// Score a point for team/player 2
  public func scorePoint2() {
    guard !isCompleted else { return }
    score2 += 1
    totalRallies += 1
    lastModified = Date()

    let nextServerInfo = nextServer
    currentServer = nextServerInfo.server
    serverNumber = nextServerInfo.serverNumber
    serverPosition = nextServerInfo.position
    sideOfCourt = nextServerInfo.side

    if gameState == .initial || gameState == .serving {
      gameState = .playing
    }

    if shouldComplete {
      completeGame()
    }
  }

  /// Undo the last point scored
  public func undoLastPoint() {
    guard totalRallies > 0 else { return }

    if score1 > score2 {
      score1 = max(0, score1 - 1)
    } else if score2 > score1 {
      score2 = max(0, score2 - 1)
    } else if score1 > 0 && score2 > 0 {
      score2 = max(0, score2 - 1)
    }

    totalRallies = max(0, totalRallies - 1)

    if totalRallies == 0 {
      currentServer = 1
      serverNumber = 1
      serverPosition = .right
      sideOfCourt = .side1
      gameState = .initial
      isFirstServiceSequence = true
    } else {
      let totalScore = score1 + score2

      if effectiveTeamSize == 1 {
        serverNumber = 1
      } else {
        currentServer = (totalScore % 2 == 0) ? 1 : 2
        serverNumber = 1
      }

      serverPosition = (totalScore % 2 == 0) ? .right : .left
      sideOfCourt = (score1 + score2) >= 6 ? .side2 : .side1
      gameState = .serving
      isFirstServiceSequence = (totalScore <= 2)
    }

    isCompleted = false
    completedDate = nil
    lastModified = Date()
  }

  /// Manually switch the serving team (for corrections or rule variations)
  public func switchServer() {
    guard !isCompleted else { return }
    currentServer = currentServer == 1 ? 2 : 1
    lastModified = Date()
  }

  /// Manually set the serving team (for game setup or corrections)
  public func setServer(to team: Int) {
    guard !isCompleted else { return }
    guard team == 1 || team == 2 else { return }
    currentServer = team
    lastModified = Date()
  }

  /// Switch the serving player within the current serving team (for doubles)
  public func switchServingPlayer() {
    guard !isCompleted else { return }
    guard effectiveTeamSize > 1 else { return }
    serverNumber = serverNumber == 1 ? 2 : 1
    lastModified = Date()
  }

  /// Set the serving player within the current serving team
  public func setServingPlayer(to player: Int) {
    guard !isCompleted else { return }
    guard player == 1 || player == 2 else { return }
    guard effectiveTeamSize > 1 else { return }
    serverNumber = player
    lastModified = Date()
  }

  /// Handle service fault - switches to partner or other team based on pickleball rules
  public func handleServiceFault() {
    guard !isCompleted else { return }
    guard effectiveTeamSize > 1 else {
      switchServer()
      return
    }

    if isFirstServiceSequence {
      currentServer = currentServer == 1 ? 2 : 1
      serverNumber = 1
      isFirstServiceSequence = false
    } else {
      if serverNumber == 1 {
        serverNumber = 2
      } else {
        currentServer = currentServer == 1 ? 2 : 1
        serverNumber = 1
      }
    }

    lastModified = Date()
  }

  // MARK: - Hashable Conformance

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  public static func == (lhs: Game, rhs: Game) -> Bool {
    return lhs.id == rhs.id
  }

  /// Log a game event with timestamp
  public func logEvent(
    _ eventType: GameEventType,
    at timestamp: TimeInterval,
    teamAffected: Int? = nil,
    description: String? = nil
  ) {
    let event = GameEvent(
      eventType: eventType,
      timestamp: timestamp,
      customDescription: description,
      teamAffected: teamAffected
    )
    event.game = self
    events.append(event)
    lastModified = Date()
  }

  /// Get events sorted by timestamp (most recent first)
  public var eventsByTimestamp: [GameEvent] {
    events.sorted { $0.timestamp > $1.timestamp }
  }

  /// Get events for a specific team
  public func eventsForTeam(_ teamNumber: Int) -> [GameEvent] {
    events.filter { $0.teamAffected == teamNumber }
  }

  /// Get events of a specific type
  public func eventsOfType(_ eventType: GameEventType) -> [GameEvent] {
    events.filter { $0.eventType == eventType }
  }

  /// Get recent events (last N events)
  public func recentEvents(count: Int = 10) -> [GameEvent] {
    Array(eventsByTimestamp.prefix(count))
  }

  /// Check if the game is unused (not actively played)
  /// A game is considered unused if:
  /// - Elapsed time is less than 5 minutes
  /// - No scores have been logged (totalRallies == 0)
  /// - No meaningful events have been logged (only automatic state changes like pause/resume)
  public func isUnused(elapsedTime: TimeInterval) -> Bool {
    let fiveMinutes: TimeInterval = 5 * 60
    
    guard elapsedTime < fiveMinutes else { return false }
    
    guard totalRallies == 0 else { return false }
    
    let meaningfulEvents = events.filter { event in
      event.eventType != .gamePaused &&
      event.eventType != .gameResumed &&
      event.eventType != .gameCompleted
    }
    
    return meaningfulEvents.isEmpty
  }
}

// MARK: - Participant Resolution

extension Game {
  /// Resolves side 1 players from stored UUIDs
  /// Returns players even if archived; returns nil if deleted
  public func resolveSide1Players(context: ModelContext) -> [PlayerProfile]? {
    guard !side1PlayerIds.isEmpty else { return nil }
    return resolvePlayerProfiles(ids: side1PlayerIds, context: context)
  }
  
  /// Resolves side 2 players from stored UUIDs
  public func resolveSide2Players(context: ModelContext) -> [PlayerProfile]? {
    guard !side2PlayerIds.isEmpty else { return nil }
    return resolvePlayerProfiles(ids: side2PlayerIds, context: context)
  }
  
  /// Resolves side 1 team from stored UUID
  public func resolveSide1Team(context: ModelContext) -> TeamProfile? {
    guard let teamId = side1TeamId else { return nil }
    return resolveTeamProfile(id: teamId, context: context)
  }
  
  /// Resolves side 2 team from stored UUID
  public func resolveSide2Team(context: ModelContext) -> TeamProfile? {
    guard let teamId = side2TeamId else { return nil }
    return resolveTeamProfile(id: teamId, context: context)
  }
  
  private func resolvePlayerProfiles(ids: [UUID], context: ModelContext) -> [PlayerProfile] {
    let descriptor = FetchDescriptor<PlayerProfile>(
      predicate: #Predicate { player in ids.contains(player.id) }
    )
    let fetched = (try? context.fetch(descriptor)) ?? []
    // Ensure stable ordering matches the provided IDs to avoid UI flicker or color swaps
    let indexById = Dictionary(uniqueKeysWithValues: ids.enumerated().map { ($0.element, $0.offset) })
    return fetched.sorted { lhs, rhs in
      guard let l = indexById[lhs.id], let r = indexById[rhs.id] else { return lhs.id.uuidString < rhs.id.uuidString }
      return l < r
    }
  }
  
  private func resolveTeamProfile(id: UUID, context: ModelContext) -> TeamProfile? {
    let descriptor = FetchDescriptor<TeamProfile>(
      predicate: #Predicate { $0.id == id }
    )
    return try? context.fetch(descriptor).first
  }
}
