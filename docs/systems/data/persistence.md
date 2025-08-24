# Persistence (SwiftData)

- **Document name**: Persistence (SwiftData)
- **Category**: systems
- **Area**: cross-cutting (SharedGameCore, iOS, watchOS)

## Summary

- **Purpose**: Document how SwiftData is configured and used across the app.
- **Scope**: Model container setup, schema, preview container; excludes storage API details (see storage).
- **Outcome**: Readers can understand and safely extend persistence configuration.

## Audience & Owners

- **Audience**: engineers, testers
- **Owners**: iOS/watchOS engineering
- **Last updated**: 2025-08-10
- **Status**: draft
- **Version**: v0.3 baseline

## Architecture Context

- **Layer**: data
- **Entry points**: `SwiftDataContainer`
- **Dependencies**: SwiftData
- **Data flow**: Managers/services use `ModelContainer.mainContext` for fetch/save; History lists use paginated fetch with 30‑day local retention and on‑demand remote fetch for older games

## Responsibilities

- **Core responsibilities**:
  - Create and configure the single application `ModelContainer`
  - Define schema and storage location
- **Non-goals**:
  - Provide feature-specific CRUD APIs (handled by storage and managers)

## Structure & Key Types

- **Primary types**: `SwiftDataContainer`
- **File locations**: `SharedGameCore/Sources/SharedGameCore/Services/SwiftDataContainer.swift`
- **Initialization**: Access via `SwiftDataContainer.shared.modelContainer`; injected into app roots

## Platform Sections (use as needed)

- **SharedGameCore**: Owns container creation and configuration
- **iOS**: Applies `.modelContainer(...)` at root; views use `@Environment(\.modelContext)`
- **watchOS**: Same pattern as iOS

## Data & Persistence

- **Models**: `Game`, `GameSummary`, `PlayerProfile`, `TeamProfile`, `GameTypePreset` registered in schema; `GameVariation` is also a SwiftData `@Model` used by `Game` via relationship
- **Container**: Named store, configured URL, no CloudKit for v0.3
- **Storage**: Consumers use contexts via storage/manager abstractions

## State & Concurrency

- **UI isolation**: UI reads/writes via main context under `@MainActor`
- **Observable state**: N/A
- **Actors/Sendable**: Container access guarded at app edges; operations on main context

## Navigation & UI

- **Patterns**: N/A
- **Design System**: N/A

## Systems Integration

- **Logging**: Container creation logs store path and fallbacks
- **Sync**: Local-only for v0.3; future cloud integration lives elsewhere
- **Haptics**: N/A

## Error Handling

- **Typed errors**: Fallback container path when initialization fails; upstream surfaces errors via storage/managers
- **User surfaces**: Initialization error screen in iOS app

## Testing & Performance

- **Tests**: Integration tests create/save/fetch `Game`
- **Performance**: Indexed fields and efficient fetch descriptors (where applicable)

## Open Questions & Future Work

- **Gaps**: Schema migrations for v0.6 players/teams
- **Planned extensions**: Cloud-backed stores as optional configs

## References

- **Code**: `SharedGameCore/Services/SwiftDataContainer.swift`
- **Related docs**: `docs/systems/data/storage.md`

---

## Validation checklist (must meet for acceptance)

- **Swift 6.2 strict; iOS 17+ / watchOS 11+ targets** respected; no concurrency warnings
- **UI on `@MainActor`**; shared types are **`Sendable`**; actor boundaries clear
- **Modern SwiftUI**: `@Environment(\.modelContext)` where needed
- **DesignSystem-first**: no hardcoded colors/spacing/typography
- **SwiftData**: single app-level container; proper schema usage
- **Typed errors** with `LocalizedError` where user-visible
- **Tests**: persistence, concurrency, and core UI behaviors covered
