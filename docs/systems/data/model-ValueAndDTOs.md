# Value and DTO Types (Non-persisted)

- Document name: Value and DTO Types
- Category: systems/data
- App versions: iOS/watchOS v0.3+
- Status: draft

## Summary

- Purpose: Enumerate value semantics types and DTOs used alongside SwiftData models.
- Scope: Enums and structs that are not `@Model` persisted types.

## Value/Enum Types (not SwiftData)

- `GameType`: enum (Codable, Hashable, Sendable) — categorizes game scenarios and UI tokens
- `ServerPosition`, `SideOfCourt`, `GameState`: enums (Codable, Sendable) — serving/state enums for `Game`
- `ScoringType`, `ServingRotation`, `SideSwitchingRule`: enums (Codable, Sendable) — rules for `GameVariation`
- `PlayerSkillLevel`, `PlayerHandedness`: enums (Codable, Sendable) — preferences for `PlayerProfile`

## DTOs (not SwiftData)

- `ActiveGameStateDTO`: struct (Codable, Sendable) — sync payload for active game
- `HistoryGameDTO`: struct (Codable, Sendable) — compact history payload for sync
- `SyncMessage`, `SyncMessageType`: enums (Codable, Sendable) — transport wrappers for sync

## Notes

- These types are stored as fields of SwiftData models when needed (e.g., raw values), or used for serialization.
- They must remain `Sendable` and `Codable` to satisfy concurrency and sync requirements.

## Validation checklist

- No UI logic embedded; types remain platform-agnostic
- Conformances: `Codable`, `Sendable` where required
- Tests updated if payload shapes change
