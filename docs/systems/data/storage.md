# Storage (SwiftDataStorage)

- **Document name**: Storage (SwiftDataStorage)
- **Category**: systems
- **Area**: SharedGameCore

## Summary

- **Purpose**: Define the storage API contract and concrete implementation for data operations.
- **Scope**: `SwiftDataStorageProtocol` and `SwiftDataStorage` details; excludes container config.
- **Outcome**: Readers can use and extend storage operations correctly.

## Audience & Owners

- **Audience**: engineers, testers
- **Owners**: iOS/watchOS engineering
- **Last updated**: 2025-08-10
- **Status**: draft
- **Version**: v0.3 baseline

## Architecture Context

- **Layer**: data
- **Entry points**: `SwiftDataStorageProtocol`, `SwiftDataStorage`
- **Dependencies**: SwiftData, logging
- **Data flow**: App managers call storage methods that use `ModelContainer.mainContext`; supports paginated history queries and remote fetch when local retention window (30 days) is exceeded

## Responsibilities

- **Core responsibilities**:
  - Provide typed async APIs for CRUD, search, and statistics
  - Emit structured logging for operations
- **Non-goals**:
  - UI-specific formatting or navigation

## Structure & Key Types

- **Primary types**: `SwiftDataStorageProtocol`, `SwiftDataStorage`, `GameStatistics`, `StorageStatistics`, `StorageError`
- **File locations**: `SharedGameCore/Sources/SharedGameCore/Services/*`
- **Initialization**: `SwiftDataStorage.shared` uses `SwiftDataContainer.shared`

## Platform Sections (use as needed)

- **SharedGameCore**: Exposes protocol and implementation
- **iOS/watchOS**: Consume via `SwiftDataGameManager` and views

## Data & Persistence

- **Models**: `Game` fetch/insert/update/delete via SwiftData
- **Container**: Accesses `ModelContainer.mainContext`
- **Storage**: Implements efficient descriptors and logs duration

## State & Concurrency

- **UI isolation**: `@MainActor` API
- **Observable state**: N/A
- **Actors/Sendable**: Result types are `Sendable`; errors typed

## Navigation & UI

- **Patterns**: N/A
- **Design System**: N/A

## Systems Integration

- **Logging**: emits events like `saveStarted`, `saveSucceeded`, `loadStarted` with metadata
- **Sync**: N/A (storage is local; sync is higher layer)
- **Haptics**: N/A

## Error Handling

- **Typed errors**: `StorageError` with user-facing descriptions via `LocalizedError`
- **User surfaces**: Apps display via their error views

## Testing & Performance

- **Tests**: Integration tests for save/load/delete and stats
- **Performance**: Batches and descriptors; measure latency in logs

## Open Questions & Future Work

- **Gaps**: Advanced indexing and partial fetches for large histories
- **Planned extensions**: Player/team storage (v0.6)

## References

- **Code**: `SharedGameCore/Services/SwiftDataStorage*.swift`
- **Related docs**: `docs/systems/data/persistence.md`, `docs/systems/runtime/state-management.md`

---

## Validation checklist (must meet for acceptance)

- **Swift 6.2 strict; iOS 17+ / watchOS 11+ targets** respected; no concurrency warnings
- **UI on `@MainActor`**; shared types are **`Sendable`**; actor boundaries clear
- **Modern SwiftUI**: `@Query` when used in views
- **DesignSystem-first**: no hardcoded colors/spacing/typography
- **SwiftData**: single app-level container; proper schema usage
- **Typed errors** with `LocalizedError` where user-visible
- **Tests**: persistence, concurrency, and core UI behaviors covered
