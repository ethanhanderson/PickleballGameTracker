//
//  RosterSnapshotBuilder.swift
//  GameTrackerCore
//

import Foundation
import SwiftData

@MainActor
public struct RosterSnapshotBuilder: Sendable {
  private let context: ModelContext

  public init(storage: any SwiftDataStorageProtocol) {
    self.context = storage.modelContainer.mainContext
  }

  public init(modelContext: ModelContext) {
    self.context = modelContext
  }

  public func build(includeArchived: Bool = false, includeGuests: Bool = false) throws -> RosterSnapshotDTO {
    let rosterStore = RosterStore(context: context)

    // Players (optionally include guests)
    let players = try rosterStore.players(includeArchived: includeArchived, includeGuests: includeGuests)
    let playersDTO = players.map(BackupPlayerDTO.init(from:))

    // Teams
    let teams = try rosterStore.teams(includeArchived: includeArchived)
    let teamsDTO = teams.map(BackupTeamDTO.init(from:))

    // Presets
    let fd = FetchDescriptor<GameTypePreset>(predicate: includeArchived ? #Predicate { _ in true } : #Predicate { $0.isArchived == false }, sortBy: [SortDescriptor(\.lastModified, order: .reverse)])
    let presets = try context.fetch(fd)
    let presetsDTO = presets.map(BackupPresetDTO.init(from:))

    return RosterSnapshotDTO(
      players: playersDTO,
      teams: teamsDTO,
      presets: presetsDTO
    )
  }
}


