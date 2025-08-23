import Foundation

public enum DeepLinkDestination: Sendable, Equatable {
  case gameType(id: String)
  case author(id: String)
  case completedGame(id: String, token: String?)
  case statistics(gameId: String?, gameTypeId: String?)
}

public enum DeepLinkError: LocalizedError, Sendable, Equatable {
  case invalidURL
  case unsupportedRoute
  case missingIdentifier

  public var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "The link could not be parsed."
    case .unsupportedRoute:
      return "This link is not supported."
    case .missingIdentifier:
      return "The link is missing a required identifier."
    }
  }
}

public struct DeepLinkResolver: Sendable {
  public init() {}

  public func resolve(_ url: URL) throws -> DeepLinkDestination {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
      throw DeepLinkError.invalidURL
    }

    // Accept both universal (hosted) and custom scheme formats
    let rawPathComponents = components.path.split(separator: "/").map(String.init)
    let host = components.host

    let knownEntities: Set<String> = ["gametype", "author", "game", "stats", "statistics"]

    // Determine entity and identifier with smarter precedence:
    // - If host is a known entity (custom scheme like matchtally://stats/...), prefer host
    // - Else, use the first path segment as entity
    // - Identifier is the next segment when present; may be nil for stats with only query params
    let (entityOpt, identifierOpt): (String?, String?) = {
      if let host, knownEntities.contains(host.lowercased()) {
        return (host, rawPathComponents.first)
      }
      if rawPathComponents.count >= 2 {
        return (rawPathComponents[0], rawPathComponents[1])
      }
      if rawPathComponents.count == 1 {
        return (rawPathComponents[0], nil)
      }
      return (nil, nil)
    }()

    guard let entityRaw = entityOpt, !entityRaw.isEmpty else { throw DeepLinkError.unsupportedRoute }
    let identifier = identifierOpt ?? ""

    let token = components.queryItems?.first(where: { $0.name == "token" })?.value

    switch entityRaw.lowercased() {
    case "gametype":
      guard !identifier.isEmpty else { throw DeepLinkError.unsupportedRoute }
      return .gameType(id: identifier)
    case "author":
      guard !identifier.isEmpty else { throw DeepLinkError.unsupportedRoute }
      return .author(id: identifier)
    case "game":
      guard !identifier.isEmpty else { throw DeepLinkError.unsupportedRoute }
      return .completedGame(id: identifier, token: token)
    case "stats", "statistics":
      // Support formats:
      //  - matchtally://stats/game/<id>
      //  - matchtally://stats/gametype/<id>
      //  - https://matchtally.app/stats?gameId=...&gameType=...
      let lower = identifier.lowercased()
      var gameId: String? = nil
      var gameTypeId: String? = nil

      if lower == "game" || lower == "gametype" {
        // Path style with an additional value component
        if rawPathComponents.count >= 2 {
          // When host is stats, rawPathComponents starts with [lower, value]
          let value = rawPathComponents.dropFirst().first
          if lower == "game" { gameId = value } else { gameTypeId = value }
        }
      } else if !lower.isEmpty {
        // stats/<id> ambiguous → treat as gameId
        gameId = identifier
      }

      // Override from query if provided
      if let qGameId = components.queryItems?.first(where: { $0.name == "gameId" })?.value {
        gameId = qGameId
      }
      if let qGameType = components.queryItems?.first(where: { $0.name == "gameType" })?.value {
        gameTypeId = qGameType
      }

      return .statistics(gameId: gameId, gameTypeId: gameTypeId)
    default:
      throw DeepLinkError.unsupportedRoute
    }
  }
}
