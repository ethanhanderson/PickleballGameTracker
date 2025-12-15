import SwiftData
import Testing
@testable import GameTrackerCore

@Suite("LiveGameStateManager Watch Resilience")
struct LiveGameStateManagerWatchTests {

  @Test("Detached game is not treated as live")
  @MainActor
  func detachedGameDisablesHasLiveGame() async {
    let manager = LiveGameStateManager()
    let detached = PreviewGameData.midGame
    #expect(detached.modelContext == nil)

    await manager.setCurrentGame(detached)

    #expect(manager.hasLiveGame == false)
  }

  @Test("Deleting current game clears live flag")
  @MainActor
  func deletingCurrentGameClearsLiveState() async throws {
    let container = try PreviewGameData.createPreviewContainer(with: [PreviewGameData.midGame])
    let context = container.mainContext
    let storedGames = try context.fetch(FetchDescriptor<Game>())
    #require(!storedGames.isEmpty)
    let storedGame = storedGames[0]

    let manager = LiveGameStateManager.preview(container: container)
    await manager.setCurrentGame(storedGame)

    #expect(manager.hasLiveGame)

    context.delete(storedGame)
    try context.save()

    #expect(storedGame.modelContext == nil)
    #expect(manager.hasLiveGame == false)
  }
}

