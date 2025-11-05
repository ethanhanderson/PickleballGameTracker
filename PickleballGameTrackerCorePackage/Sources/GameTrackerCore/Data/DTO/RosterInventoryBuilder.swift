//
//  RosterInventoryBuilder.swift
//  GameTrackerCore
//

import Foundation
import SwiftData

@MainActor
public struct RosterInventoryBuilder: Sendable {
  private let context: ModelContext

  public init(storage: any SwiftDataStorageProtocol) {
    self.context = storage.modelContainer.mainContext
  }

  public init(modelContext: ModelContext) {
    self.context = modelContext
  }

  public func build(includeArchived: Bool = false, includeGuests: Bool = false) throws -> RosterInventoryDTO {
    let rosterStore = RosterStore(context: context)

    // Players
    let players = try rosterStore.players(includeArchived: includeArchived, includeGuests: includeGuests)
    let playersMap = Dictionary(uniqueKeysWithValues: players.map { ($0.id, $0.lastModified) })

    // Teams
    let teams = try rosterStore.teams(includeArchived: includeArchived)
    let teamsMap = Dictionary(uniqueKeysWithValues: teams.map { ($0.id, $0.lastModified) })

    // Presets
    let fd = FetchDescriptor<GameTypePreset>(
      predicate: includeArchived ? #Predicate { _ in true } : #Predicate { $0.isArchived == false }
    )
    let presets = try context.fetch(fd)
    let presetsMap = Dictionary(uniqueKeysWithValues: presets.map { ($0.id, $0.lastModified) })

    return RosterInventoryDTO(
      players: playersMap,
      teams: teamsMap,
      presets: presetsMap
    )
  }
}

