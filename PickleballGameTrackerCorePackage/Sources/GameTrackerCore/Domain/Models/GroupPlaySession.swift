//
//  GroupPlaySession.swift
//  GameTrackerCore
//
//  Session model and supporting types for Group Play (random pairings or tournament).
//

import Foundation
import SwiftData

// MARK: - GroupPlay Enumerations (stored as raw values on the model)

public enum GroupPlayFormat: String, Codable, Sendable {
  case randomPairings
  case tournamentBracket
}

public enum GroupPlayPlayMode: String, Codable, Sendable {
  case singles
  case doubles
  case twoVOne
}

public enum GroupPlaySessionStatus: String, Codable, Sendable {
  case planned
  case inProgress
  case completed
}

public enum ScheduledMatchStatus: String, Codable, Sendable {
  case scheduled
  case inProgress
  case completed
}

// MARK: - Standings Entry

@Model
public final class GroupStandingEntry {
  @Attribute(.unique) public var id: UUID
  public var entryId: UUID          // Player or Team ID depending on play mode/participants
  public var wins: Int
  public var losses: Int
  public var pointsFor: Int
  public var pointsAgainst: Int
  
  public init(
    id: UUID = UUID(),
    entryId: UUID,
    wins: Int = 0,
    losses: Int = 0,
    pointsFor: Int = 0,
    pointsAgainst: Int = 0
  ) {
    self.id = id
    self.entryId = entryId
    self.wins = wins
    self.losses = losses
    self.pointsFor = pointsFor
    self.pointsAgainst = pointsAgainst
  }
}

// MARK: - Scheduled Match

@Model
public final class ScheduledMatch {
  @Attribute(.unique) public var id: UUID
  
  // Participants: use either players or teams per side
  public var participantModeRaw: String // "players" or "teams"
  public var side1PlayerIds: [UUID]
  public var side2PlayerIds: [UUID]
  public var side1TeamId: UUID?
  public var side2TeamId: UUID?
  
  // Status/progression
  public var orderIndex: Int
  public var statusRaw: String // ScheduledMatchStatus
  public var linkedGameId: UUID?
  
  // Back-reference (optional navigation)
  @Relationship(inverse: \GroupPlaySession.schedule) public var session: GroupPlaySession?
  
  public init(
    id: UUID = UUID(),
    participantModeRaw: String,
    side1PlayerIds: [UUID] = [],
    side2PlayerIds: [UUID] = [],
    side1TeamId: UUID? = nil,
    side2TeamId: UUID? = nil,
    orderIndex: Int = 0,
    statusRaw: String = ScheduledMatchStatus.scheduled.rawValue,
    linkedGameId: UUID? = nil,
    session: GroupPlaySession? = nil
  ) {
    self.id = id
    self.participantModeRaw = participantModeRaw
    self.side1PlayerIds = side1PlayerIds
    self.side2PlayerIds = side2PlayerIds
    self.side1TeamId = side1TeamId
    self.side2TeamId = side2TeamId
    self.orderIndex = orderIndex
    self.statusRaw = statusRaw
    self.linkedGameId = linkedGameId
    self.session = session
  }
  
  public var participantMode: ParticipantMode {
    ParticipantMode(rawValue: participantModeRaw) ?? .players
  }
  
  public var status: ScheduledMatchStatus {
    ScheduledMatchStatus(rawValue: statusRaw) ?? .scheduled
  }
  
  public func setStatus(_ status: ScheduledMatchStatus) {
    self.statusRaw = status.rawValue
  }
}

// MARK: - Group Play Session

@Model
public final class GroupPlaySession {
  @Attribute(.unique) public var id: UUID
  
  // Identity & lifecycle
  public var createdDate: Date
  public var lastModified: Date
  public var statusRaw: String // GroupPlaySessionStatus
  
  // Configuration
  public var formatRaw: String // GroupPlayFormat
  public var playModeRaw: String // GroupPlayPlayMode
  
  // Options
  public var isPartnerRotation: Bool // random pairings sub-option A
  public var isTeamRoundRobin: Bool  // random pairings sub-option B
  public var isSeeded: Bool          // tournament seeding preference (true=seeded, false=random)
  
  // Roster and teams (when applicable)
  public var rosterPlayerIds: [UUID]
  public var fixedTeamIds: [UUID] // if teams are pre-formed for team-vs-team formats
  
  // Schedule/progression
  @Relationship public var schedule: [ScheduledMatch]
  public var currentIndex: Int
  public var linkedGameIds: [UUID]
  
  // Standings
  @Relationship public var standings: [GroupStandingEntry]
  
  public init(
    id: UUID = UUID(),
    createdDate: Date = Date(),
    lastModified: Date = Date(),
    statusRaw: String = GroupPlaySessionStatus.planned.rawValue,
    formatRaw: String,
    playModeRaw: String,
    isPartnerRotation: Bool = true,
    isTeamRoundRobin: Bool = false,
    isSeeded: Bool = false,
    rosterPlayerIds: [UUID],
    fixedTeamIds: [UUID] = [],
    schedule: [ScheduledMatch] = [],
    currentIndex: Int = 0,
    linkedGameIds: [UUID] = [],
    standings: [GroupStandingEntry] = []
  ) {
    self.id = id
    self.createdDate = createdDate
    self.lastModified = lastModified
    self.statusRaw = statusRaw
    self.formatRaw = formatRaw
    self.playModeRaw = playModeRaw
    self.isPartnerRotation = isPartnerRotation
    self.isTeamRoundRobin = isTeamRoundRobin
    self.isSeeded = isSeeded
    self.rosterPlayerIds = rosterPlayerIds
    self.fixedTeamIds = fixedTeamIds
    self.schedule = schedule
    self.currentIndex = currentIndex
    self.linkedGameIds = linkedGameIds
    self.standings = standings
  }
  
  public var format: GroupPlayFormat {
    GroupPlayFormat(rawValue: formatRaw) ?? .randomPairings
  }
  
  public var playMode: GroupPlayPlayMode {
    GroupPlayPlayMode(rawValue: playModeRaw) ?? .doubles
  }
  
  public var status: GroupPlaySessionStatus {
    GroupPlaySessionStatus(rawValue: statusRaw) ?? .planned
  }
  
  public func setStatus(_ status: GroupPlaySessionStatus) {
    self.statusRaw = status.rawValue
    self.lastModified = Date()
  }
  
  public func advanceIndex() {
    self.currentIndex = min(self.currentIndex + 1, max(0, schedule.count - 1))
    self.lastModified = Date()
  }
}


