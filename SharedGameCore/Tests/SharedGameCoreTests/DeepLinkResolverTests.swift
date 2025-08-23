import XCTest

@testable import SharedGameCore

final class DeepLinkResolverTests: XCTestCase {
  private let resolver = DeepLinkResolver()

  func test_resolvesGameTypeUniversalLink() throws {
    let url = URL(string: "https://matchtally.app/gametype/abc123")!
    let dest = try resolver.resolve(url)
    XCTAssertEqual(dest, .gameType(id: "abc123"))
  }

  func test_resolvesAuthorAppScheme() throws {
    let url = URL(string: "matchtally://author/author987")!
    let dest = try resolver.resolve(url)
    XCTAssertEqual(dest, .author(id: "author987"))
  }

  func test_resolvesCompletedGameWithToken() throws {
    let url = URL(string: "https://matchtally.app/game/game42?token=t123")!
    let dest = try resolver.resolve(url)
    XCTAssertEqual(dest, .completedGame(id: "game42", token: "t123"))
  }

  func test_resolvesStatisticsPathVariants() throws {
    let url1 = URL(string: "matchtally://stats/game/DEADBEEF-DEAD-BEEF-DEAD-BEEFDEADBEEF")!
    let url2 = URL(string: "matchtally://statistics/gametype/singles")!
    let d1 = try resolver.resolve(url1)
    let d2 = try resolver.resolve(url2)
    XCTAssertEqual(d1, .statistics(gameId: "DEADBEEF-DEAD-BEEF-DEAD-BEEFDEADBEEF", gameTypeId: nil))
    XCTAssertEqual(d2, .statistics(gameId: nil, gameTypeId: "singles"))
  }

  func test_resolvesStatisticsQueryVariants() throws {
    let url = URL(string: "https://matchtally.app/stats?gameId=G1&gameType=singles")!
    let d = try resolver.resolve(url)
    XCTAssertEqual(d, .statistics(gameId: "G1", gameTypeId: "singles"))
  }

  func test_unsupportedRouteThrows() {
    let url = URL(string: "https://matchtally.app/unknown/123")!
    XCTAssertThrowsError(try resolver.resolve(url)) { error in
      XCTAssertEqual(error as? DeepLinkError, .unsupportedRoute)
    }
  }

  func test_missingIdentifierThrows() {
    let url = URL(string: "https://matchtally.app/gametype/")!
    XCTAssertThrowsError(try resolver.resolve(url)) { error in
      XCTAssertEqual(error as? DeepLinkError, .unsupportedRoute)
    }
  }
}
