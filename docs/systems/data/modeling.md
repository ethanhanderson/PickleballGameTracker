# Data Modeling & SwiftData Usage

- Document name: Data Modeling & SwiftData Usage
- Category: systems
- Area: SharedGameCore, iOS, watchOS
- Version: v0.3 baseline
- Status: draft

## Summary

- Purpose: Define how app data is modeled and persisted using SwiftData across iOS/watchOS.
- Scope: Modeling principles, registered models, relationships, and how to use SwiftData via our services and views.
- Outcome: Consistent, safe data modeling; clear guidance for CRUD, queries, and migrations.

## Audience & Owners

- Audience: engineers, testers
- Owners: iOS/watchOS engineering

## Architecture Context

- Layer: data
- Entry points: `SwiftDataContainer`, `SwiftDataStorageProtocol`, `SwiftDataStorage`, `SwiftDataGameManager`
- Dependencies: SwiftData, SharedGameCore services, LoggingService
- Data flow: Apps → Managers/Storage → SwiftData `ModelContainer.mainContext` → Store

## Structure & Key Types

- Primary types:
  - Models (SwiftData `@Model`): `Game`, `GameSummary`, `GameVariation`, `GameTypePreset`, `PlayerProfile`, `TeamProfile`
  - Value/enum types (not persisted): `GameType`, `ServerPosition`, `SideOfCourt`, `GameState`, `ScoringType`, `ServingRotation`, `SideSwitchingRule`
  - DTOs (not persisted): `ActiveGameStateDTO`, `HistoryGameDTO`, `SyncMessage`, `SyncMessageType`
- File locations: `SharedGameCore/Sources/SharedGameCore/Models/*`
- Container: Single `ModelContainer` via `SwiftDataContainer.shared`

## Model Catalog (v0.3)

- SwiftData models:
  - [`Game`](../../systems/data/model-Game.md)
  - [`GameSummary`](../../systems/data/model-GameSummary.md)
  - [`GameVariation`](../../systems/data/model-GameVariation.md)
  - [`GameTypePreset`](../../systems/data/model-GameTypePreset.md)
  - [`PlayerProfile`](../../systems/data/model-PlayerProfile.md)
  - [`TeamProfile`](../../systems/data/model-TeamProfile.md)
- Value and DTO types:
  - [`Value and DTO Types`](../../systems/data/model-ValueAndDTOs.md)

## Deterministic Commands

```bash
cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && \
xcodebuild -project "Pickleball Score Tracking.xcodeproj" \
  -scheme "Pickleball Score Tracking" \
  -destination "platform=iOS Simulator,name=iPhone 16" test
```

```bash
cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && \
xcodebuild -project "Pickleball Score Tracking.xcodeproj" \
  -scheme "Pickleball Score Tracking Watch App" \
  -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)" test
```

## Modeling Principles (v0.3)

- Single `ModelContainer` across the app; no per-view containers.
- Prefer small, explicit `@Model` classes for persisted entities; keep enums/DTOs value-based.
- Use relationships for composition:
  - `Game` → optional `GameVariation`
  - `GameTypePreset` → `TeamProfile` (team1/team2)
  - `TeamProfile` → `[PlayerProfile]`
- Derived/projection tables: `GameSummary` holds KPIs for completed games.
- ID strategy: `UUID` unique attributes for primary identity on persisted models.
- Local-first: No CloudKit in v0.3; future sync maps through DTOs.

## Using SwiftData

- Container access: `SwiftDataContainer.shared.modelContainer` (apps apply `.modelContainer(...)` at root).
- Storage API: Call `SwiftDataStorage.shared` from managers/services; avoid raw context usage in features.
- UI queries: Use `@Environment(\.modelContext)` and `@Query` for simple reads in views where appropriate.
- Fetching: Use `FetchDescriptor<T>` with predicates/sort descriptors for performance-sensitive paths.
- Inserts/updates: Perform on main context under `@MainActor`; rely on autosave or `try context.save()`.
- Summaries: On game save/complete, persist/update a `GameSummary` row for list/history performance.

### Example: Save and query via Storage (recommended)

```swift
// Insert
let game = Game(gameType: .recreational)
try await SwiftDataStorage.shared.saveGame(game)

// Query
let games = try await SwiftDataStorage.shared.loadGames()
```

### Example: UI list via @Query (simple lists)

```swift
@Query(FetchDescriptor<Game>(
  predicate: #Predicate { $0.isArchived == false },
  sortBy: [SortDescriptor(\.lastModified, order: .reverse)]
)) private var games: [Game]
```

## Versioning & Migrations

- Current schema: v0.3 (local-only store). Models: `Game`, `GameSummary`, `GameVariation`, `GameTypePreset`, `PlayerProfile`, `TeamProfile`.
- Future work: plan migrations for additional indices/attributes; prefer additive changes and backfill via services.

## Testing Touchpoints

- Extend `SharedGameCore/Tests` persistence and integration tests when model shapes change.
- Add migration tests when schema evolves.

## Change Impact

- Changes to `@Model` types impact storage, queries, and UI lists; update `SwiftDataContainer` schema if models are added/removed.
- When adding relationships, review fetch descriptors and summary write paths.

## Validation checklist

- Single app-level `ModelContainer` injected into both targets
- All persisted entities are `@Model`; value types remain enums/structs
- Relationships defined as documented; no duplicate containers
- Strict Swift 6.2 concurrency; UI on `@MainActor`
- Deterministic commands pass for iOS and watchOS
- Tests updated for persistence and summaries
