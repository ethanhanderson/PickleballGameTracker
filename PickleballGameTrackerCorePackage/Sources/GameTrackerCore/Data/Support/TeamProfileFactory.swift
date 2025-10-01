//
//  TeamProfileFactory.swift
//  GameTrackerCore
//
//  Created on September 30, 2025
//

import Foundation
import SwiftData
import SwiftUI

/// Factory for generating team profiles with automatic player pairing.
///
/// ## Overview
/// Creates teams from player pools using various pairing strategies. Automatically
/// generates team names from player names or creative pool. Ensures SwiftData
/// relationship integrity.
///
/// ## Basic Usage
/// ```swift
/// let team = TeamProfileFactory()
///     .players([player1, player2])
///     .nameFromPlayers()
///     .generate()
/// ```
///
/// ## Roster Generation
/// ```swift
/// let (players, teams) = TeamProfileFactory.realisticTeams(playerCount: 12, teamSize: 2)
/// ```
@MainActor
public struct TeamProfileFactory {

    private static let creativeTeamNames: [String] = [
        "Dink Masters", "Court Kings", "Kitchen Crushers", "Net Ninjas",
        "Rally Rebels", "Serve Squad", "Paddle Warriors", "Baseline Bandits",
        "Smash Bros", "Drop Shot Crew", "Spin Doctors", "Ace Aces",
        "Power Players", "Pickleball Pros", "Slam Squad", "Volley Vipers",
        "Game Changers", "The Smashers", "Point Makers", "Fast Hands",
        "Court Jesters", "Paddle Pushers", "Net Results", "The Volleys"
    ]

    private static let teamIcons: [String] = [
        "person.2.fill", "figure.mind.and.body", "sportscourt.fill",
        "trophy.fill", "star.fill", "bolt.fill", "flame.fill"
    ]

    private static let accentColors: [Color] = [
        .blue, .green, .orange, .purple, .red, .pink, .teal, .indigo,
        .cyan, .mint, .yellow, .brown
    ]

    private static var teamCounter: Int = 1

    private var _name: String?
    private var _players: [PlayerProfile]?
    private var _suggestedGameType: GameType?
    private var _iconSymbol: String?
    private var _accentColor: Color?
    private var _isArchived: Bool = false
    private var _notes: String?
    private var _context: ModelContext?
    private var _namingStrategy: TeamNamingStrategy = .playerNames

    public init(context: ModelContext? = nil) {
        self._context = context
    }

    public func name(_ name: String) -> Self {
        var copy = self
        copy._name = name
        return copy
    }

    public func randomName() -> Self {
        var copy = self
        copy._name = nil
        copy._namingStrategy = .creative
        return copy
    }

    public func nameFromPlayers() -> Self {
        var copy = self
        copy._name = nil
        copy._namingStrategy = .playerNames
        return copy
    }

    public func players(_ players: [PlayerProfile]) -> Self {
        var copy = self
        copy._players = players
        return copy
    }

    public func selectPlayersFromContext(count: Int = 2) -> Self {
        var copy = self
        if let context = _context {
            let descriptor = FetchDescriptor<PlayerProfile>(
                predicate: #Predicate { !$0.isArchived }
            )
            if let allPlayers = try? context.fetch(descriptor) {
                copy._players = Array(allPlayers.shuffled().prefix(count))
            }
        }
        return copy
    }

    public func randomPlayersFromPool(_ pool: [PlayerProfile], count: Int = 2) -> Self {
        var copy = self
        copy._players = Array(pool.shuffled().prefix(count))
        return copy
    }

    public func suggestedGameType(_ type: GameType) -> Self {
        var copy = self
        copy._suggestedGameType = type
        return copy
    }

    public func iconSymbol(_ symbol: String) -> Self {
        var copy = self
        copy._iconSymbol = symbol
        return copy
    }

    public func randomIconSymbol() -> Self {
        var copy = self
        copy._iconSymbol = nil
        return copy
    }

    public func accentColor(_ color: Color) -> Self {
        var copy = self
        copy._accentColor = color
        return copy
    }

    public func randomAccentColor() -> Self {
        var copy = self
        copy._accentColor = nil
        return copy
    }

    public func archived(_ archived: Bool = true) -> Self {
        var copy = self
        copy._isArchived = archived
        return copy
    }

    public func notes(_ text: String) -> Self {
        var copy = self
        copy._notes = text
        return copy
    }

    private func generateTeamName(from players: [PlayerProfile]) -> String {
        switch _namingStrategy {
        case .playerNames:
            if players.count == 2 {
                return "\(players[0].name) & \(players[1].name)"
            } else if players.count == 1 {
                return players[0].name
            } else {
                return players.map { $0.name }.joined(separator: ", ")
            }

        case .creative:
            return Self.creativeTeamNames.randomElement()!

        case .numbered:
            let number = Self.teamCounter
            Self.teamCounter += 1
            return "Team \(number)"

        case .skill:
            let avgSkill = players.map { $0.skillLevel.rawValue }.reduce(0, +) / players.count
            let skillName: String
            switch avgSkill {
            case 0: skillName = "Beginner"
            case 1: skillName = "Intermediate"
            case 2: skillName = "Advanced"
            default: skillName = "Expert"
            }
            return "\(skillName) \(players.count == 2 ? "Duo" : "Squad")"
        }
    }

    public static func resetTeamCounter() {
        teamCounter = 1
    }

    public func generate() -> TeamProfile {
        let players = _players ?? []
        let name = _name ?? generateTeamName(from: players)
        let iconSymbol = _iconSymbol ?? Self.teamIcons.randomElement()
        let accentColor = _accentColor ?? Self.accentColors.randomElement()!

        let team = TeamProfile(
            name: name,
            notes: _notes,
            isArchived: _isArchived,
            avatarImageData: nil,
            iconSymbolName: iconSymbol,
            accentColor: StoredRGBAColor(accentColor),
            players: players,
            suggestedGameType: _suggestedGameType
        )

        if let context = _context {
            context.insert(team)
        }

        return team
    }

    public static func batch(count: Int, fromPlayers players: [PlayerProfile]) -> [TeamProfile] {
        resetTeamCounter()

        guard !players.isEmpty else { return [] }

        let teamSize = 2
        let playerGroups = pairSequentially(players, teamSize: teamSize)

        return playerGroups.prefix(count).map { playerGroup in
            TeamProfileFactory()
                .players(playerGroup)
                .nameFromPlayers()
                .generate()
        }
    }

    public static func batch(count: Int, configure: (TeamProfileFactory) -> TeamProfileFactory) -> [TeamProfile] {
        resetTeamCounter()
        return (0..<count).map { _ in configure(TeamProfileFactory()).generate() }
    }

    public static func teamsFromPlayers(_ players: [PlayerProfile], teamSize: Int = 2, strategy: TeamPairingStrategy = .sequential) -> [TeamProfile] {
        resetTeamCounter()

        let playerGroups: [[PlayerProfile]]

        switch strategy {
        case .sequential:
            playerGroups = pairSequentially(players, teamSize: teamSize)
        case .random:
            playerGroups = pairRandomly(players, teamSize: teamSize)
        case .skillMatched:
            playerGroups = pairBySkill(players, teamSize: teamSize)
        case .skillMixed:
            playerGroups = pairMixedSkill(players, teamSize: teamSize)
        case .balanced:
            playerGroups = pairBalanced(players, teamSize: teamSize)
        }

        return playerGroups.map { playerGroup in
            TeamProfileFactory()
                .players(playerGroup)
                .nameFromPlayers()
                .generate()
        }
    }

    public static func realisticTeams(playerCount: Int = 12, teamSize: Int = 2) -> (players: [PlayerProfile], teams: [TeamProfile]) {
        resetTeamCounter()

        let players = PlayerProfileFactory.realisticRoster(count: playerCount, includeArchived: false)
        let teams = skillMatchedTeams(players: players)

        let archiveCount = max(1, teams.count / 7)
        for i in (teams.count - archiveCount)..<teams.count {
            teams[i].isArchived = true
        }

        return (players, teams)
    }
}

// MARK: - Supporting Types

public enum TeamNamingStrategy {
    case playerNames
    case creative
    case numbered
    case skill
}

public enum TeamPairingStrategy {
    case sequential
    case random
    case skillMatched
    case skillMixed
    case balanced
}

// MARK: - Pairing Algorithms

extension TeamProfileFactory {

    private static func pairSequentially(_ players: [PlayerProfile], teamSize: Int) -> [[PlayerProfile]] {
        stride(from: 0, to: players.count, by: teamSize).compactMap { start in
            let end = min(start + teamSize, players.count)
            guard end - start == teamSize else { return nil }
            return Array(players[start..<end])
        }
    }

    private static func pairRandomly(_ players: [PlayerProfile], teamSize: Int) -> [[PlayerProfile]] {
        pairSequentially(players.shuffled(), teamSize: teamSize)
    }

    private static func pairBySkill(_ players: [PlayerProfile], teamSize: Int) -> [[PlayerProfile]] {
        let sorted = players.sorted { $0.skillLevel.rawValue < $1.skillLevel.rawValue }
        return pairSequentially(sorted, teamSize: teamSize)
    }

    private static func pairMixedSkill(_ players: [PlayerProfile], teamSize: Int) -> [[PlayerProfile]] {
        let sorted = players.sorted { $0.skillLevel.rawValue > $1.skillLevel.rawValue }
        var teams: [[PlayerProfile]] = []
        var high = 0
        var low = sorted.count - 1

        while high < low {
            var team: [PlayerProfile] = []
            for _ in 0..<teamSize where high <= low {
                if team.count % 2 == 0 {
                    team.append(sorted[high])
                    high += 1
                } else {
                    team.append(sorted[low])
                    low -= 1
                }
            }
            if team.count == teamSize {
                teams.append(team)
            }
        }

        return teams
    }

    private static func pairBalanced(_ players: [PlayerProfile], teamSize: Int) -> [[PlayerProfile]] {
        let sorted = players.sorted { $0.skillLevel.rawValue > $1.skillLevel.rawValue }
        var teams: [[PlayerProfile]] = []
        var currentTeam: [PlayerProfile] = []
        var reverseOrder = false

        for player in sorted {
            currentTeam.append(player)
            if currentTeam.count == teamSize {
                teams.append(currentTeam)
                currentTeam = []
                reverseOrder.toggle()
            }
        }

        return teams
    }
}

// MARK: - Convenience Presets

extension TeamProfileFactory {

    public static func minimalTeams() -> (players: [PlayerProfile], teams: [TeamProfile]) {
        realisticTeams(playerCount: 4, teamSize: 2)
    }

    public static func smallTeamSet() -> (players: [PlayerProfile], teams: [TeamProfile]) {
        realisticTeams(playerCount: 8, teamSize: 2)
    }

    public static func mediumTeamSet() -> (players: [PlayerProfile], teams: [TeamProfile]) {
        realisticTeams(playerCount: 16, teamSize: 2)
    }

    public static func performanceTeamSet() -> (players: [PlayerProfile], teams: [TeamProfile]) {
        realisticTeams(playerCount: 50, teamSize: 2)
    }
}

// MARK: - Skill-Based Pairing

extension TeamProfileFactory {

    public static func skillMatchedTeams(players: [PlayerProfile]) -> [TeamProfile] {
        teamsFromPlayers(players, teamSize: 2, strategy: .skillMatched)
    }

    public static func mixedSkillTeams(players: [PlayerProfile]) -> [TeamProfile] {
        teamsFromPlayers(players, teamSize: 2, strategy: .skillMixed)
    }
}

