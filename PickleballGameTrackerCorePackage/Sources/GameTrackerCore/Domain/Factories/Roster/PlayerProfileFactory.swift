//
//  PlayerProfileFactory.swift
//  GameTrackerCore
//
//  Created on September 30, 2025
//

import Foundation
import SwiftData
import SwiftUI

/// Factory for generating player profile instances with realistic variety.
///
/// ## Overview
/// Provides diverse player generation with 100+ unique names, realistic skill
/// distributions, and configurable roster sizes from minimal (4) to performance (100+).
///
/// ## Basic Usage
/// ```swift
/// let player = PlayerProfileFactory()
///     .name("Sarah")
///     .skillLevel(.advanced)
///     .generate()
/// ```
///
/// ## Roster Generation
/// ```swift
/// let roster = PlayerProfileFactory.realisticRoster(count: 12)
/// ```
@MainActor
public struct PlayerProfileFactory {

    private static let firstNames: [String] = [
        "Ethan", "Liam", "Noah", "Oliver", "James", "William", "Benjamin", "Lucas",
        "Henry", "Alexander", "Mason", "Michael", "Elijah", "Daniel", "Matthew",
        "Jackson", "Sebastian", "Jack", "Aiden", "Owen", "Samuel", "Joseph",
        "David", "Carter", "Wyatt", "Luke", "Jayden", "Dylan", "Grayson",
        "Ryan", "Nathan", "Isaac", "Christian", "Hunter", "Aaron", "Thomas",
        "Charles", "Caleb", "Josiah", "Andrew", "Connor", "Robert", "Cameron",
        "Jordan", "Justin", "Adrian", "Adam", "Nicholas", "Brandon", "Christopher",

        "Emma", "Olivia", "Ava", "Isabella", "Sophia", "Charlotte", "Mia", "Amelia",
        "Harper", "Evelyn", "Abigail", "Emily", "Elizabeth", "Sofia", "Ella",
        "Madison", "Scarlett", "Victoria", "Grace", "Chloe", "Camila", "Penelope",
        "Riley", "Layla", "Lillian", "Nora", "Zoey", "Mila", "Aubrey",
        "Hannah", "Lily", "Addison", "Eleanor", "Natalie", "Luna", "Savannah",
        "Brooklyn", "Leah", "Zoe", "Stella", "Hazel", "Ellie", "Paisley",
        "Audrey", "Skylar", "Violet", "Claire", "Bella", "Aurora", "Lucy"
    ]

    private static let sportsIcons: [String] = [
        "tennis.racket", "figure.tennis", "figure.walk", "medal.fill",
        "trophy.fill", "figure.pickleball", "sportscourt.fill",
        "person.fill", "star.fill", "flame.fill", "bolt.fill",
        "figure.run", "figure.strengthtraining.traditional"
    ]

    private static let accentColors: [Color] = [
        .blue, .green, .orange, .purple, .red, .pink, .teal, .indigo,
        .cyan, .mint, .yellow, .brown
    ]

    private static var usedNames: Set<String> = []

    private var _name: String?
    private var _skillLevel: PlayerSkillLevel?
    private var _preferredHand: PlayerHandedness?
    private var _iconSymbol: String?
    private var _accentColor: Color?
    private var _isArchived: Bool = false
    private var _notes: String?
    private var _context: ModelContext?
    private var _skillDistribution: SkillDistribution = .realistic

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
        return copy
    }

    public func names(matching prefix: String) -> Self {
        var copy = self
        let matching = Self.firstNames.filter { $0.hasPrefix(prefix) }
        copy._name = matching.randomElement()
        return copy
    }

    public func skillLevel(_ level: PlayerSkillLevel) -> Self {
        var copy = self
        copy._skillLevel = level
        return copy
    }

    public func randomSkillLevel() -> Self {
        var copy = self
        copy._skillLevel = nil
        return copy
    }

    public func skillDistribution(_ distribution: SkillDistribution) -> Self {
        var copy = self
        copy._skillDistribution = distribution
        return copy
    }

    public func preferredHand(_ hand: PlayerHandedness) -> Self {
        var copy = self
        copy._preferredHand = hand
        return copy
    }

    public func leftHanded() -> Self {
        var copy = self
        copy._preferredHand = .left
        return copy
    }

    public func rightHanded() -> Self {
        var copy = self
        copy._preferredHand = .right
        return copy
    }

    public func randomHandedness() -> Self {
        var copy = self
        copy._preferredHand = nil
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

    private func generateRandomName() -> String {
        let availableNames = Self.firstNames.filter { name in
            !Self.usedNames.contains(name)
        }

        if availableNames.isEmpty {
            let baseName = Self.firstNames.randomElement()!
            let suffix = Int.random(in: 1...999)
            let uniqueName = "\(baseName) \(suffix)"
            Self.usedNames.insert(uniqueName)
            return uniqueName
        }

        let name = availableNames.randomElement()!
        Self.usedNames.insert(name)
        return name
    }

    private func generateSkillLevel() -> PlayerSkillLevel {
        let roll = Int.random(in: 1...100)

        switch _skillDistribution {
        case .realistic:
            switch roll {
            case 1...15: return .beginner
            case 16...65: return .intermediate
            case 66...90: return .advanced
            default: return .expert
            }
        case .beginnerHeavy:
            switch roll {
            case 1...60: return .beginner
            case 61...90: return .intermediate
            default: return .advanced
            }
        case .expertHeavy:
            switch roll {
            case 1...50: return .expert
            case 51...80: return .advanced
            default: return .intermediate
            }
        case .uniform:
            return [.beginner, .intermediate, .advanced, .expert].randomElement()!
        }
    }

    private func generateHandedness() -> PlayerHandedness {
        Int.random(in: 1...10) == 1 ? .left : .right
    }

    public static func resetNamePool() {
        usedNames.removeAll()
    }

    public func generate() -> PlayerProfile {
        let name = _name ?? generateRandomName()
        let skillLevel = _skillLevel ?? generateSkillLevel()
        let preferredHand = _preferredHand ?? generateHandedness()
        let iconSymbol = _iconSymbol ?? Self.sportsIcons.randomElement()
        let accentColor = _accentColor ?? Self.accentColors.randomElement()!

        let player = PlayerProfile(
            name: name,
            notes: _notes,
            isArchived: _isArchived,
            avatarImageData: nil,
            iconSymbolName: iconSymbol,
            accentColor: StoredRGBAColor(accentColor),
            skillLevel: skillLevel,
            preferredHand: preferredHand
        )

        if let context = _context {
            context.insert(player)
        }

        return player
    }

    public static func batch(count: Int) -> [PlayerProfile] {
        resetNamePool()
        return (0..<count).map { _ in PlayerProfileFactory().generate() }
    }

    public static func batch(count: Int, configure: (PlayerProfileFactory) -> PlayerProfileFactory) -> [PlayerProfile] {
        resetNamePool()
        return (0..<count).map { _ in configure(PlayerProfileFactory()).generate() }
    }

    public static func realisticRoster(count: Int = 12, includeArchived: Bool = true) -> [PlayerProfile] {
        resetNamePool()

        var players: [PlayerProfile] = []

        for index in 0..<count {
            let shouldArchive = includeArchived && (index >= Int(Double(count) * 0.9))

            let player = PlayerProfileFactory()
                .randomName()
                .randomSkillLevel()
                .skillDistribution(.realistic)
                .randomHandedness()
                .randomIconSymbol()
                .randomAccentColor()
                .archived(shouldArchive)
                .generate()

            players.append(player)
        }

        return players
    }

    public static func minimalRoster() -> [PlayerProfile] {
        realisticRoster(count: 4, includeArchived: false)
    }

    public static func smallRoster() -> [PlayerProfile] {
        realisticRoster(count: 8, includeArchived: true)
    }

    public static func mediumRoster() -> [PlayerProfile] {
        realisticRoster(count: 16, includeArchived: true)
    }

    public static func largeRoster() -> [PlayerProfile] {
        realisticRoster(count: 32, includeArchived: true)
    }

    public static func performanceRoster() -> [PlayerProfile] {
        realisticRoster(count: 100, includeArchived: true)
    }

    public static func beginnerRoster(count: Int = 8) -> [PlayerProfile] {
        batch(count: count) { factory in
            factory.skillLevel(.beginner)
        }
    }

    public static func expertRoster(count: Int = 6) -> [PlayerProfile] {
        batch(count: count) { factory in
            factory.skillLevel(.expert)
        }
    }

    public static func mixedSkillRoster(count: Int = 12) -> [PlayerProfile] {
        realisticRoster(count: count, includeArchived: false)
    }
}

public enum SkillDistribution {
    case realistic
    case beginnerHeavy
    case expertHeavy
    case uniform
}

