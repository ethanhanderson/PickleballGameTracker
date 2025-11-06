import GameTrackerCore
import Foundation

public struct SetupSheetToken: Identifiable {
    public let id: String
    public let gameType: GameType

    public init(id: String, gameType: GameType) {
        self.id = id
        self.gameType = gameType
    }
}


