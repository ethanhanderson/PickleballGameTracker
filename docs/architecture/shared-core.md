# SharedGameCore Architecture

- **Document name**: SharedGameCore Architecture
- **Category**: architecture
- **Area**: SharedGameCore

## Summary

- **Purpose**: Describe the package structure, core models, services, and boundaries of `SharedGameCore`.
- **Scope**: Package internals and how apps consume them; excludes app-specific views.
- **Outcome**: Readers understand what lives in `SharedGameCore` and how to use it safely.

## Audience & Owners

- **Audience**: engineers, testers
- **Owners**: iOS/watchOS engineering
- **Last updated**: 2025-08-10
- **Status**: draft
- **Version**: v0.3 baseline

## Architecture Context

- **Layer**: domain and data; shared UI tokens and small components
- **Entry points**: `SharedGameCore.swift` (module index)
- **Dependencies**: SwiftUI, SwiftData, SwiftCharts (for data series preparation)
- **Data flow**: Apps → `SwiftDataGameManager`/`ActiveGameStateManager` → `SwiftDataStorage` → SwiftData store

## Responsibilities

- **Core responsibilities**:
  - Define models (`@Model` and `Sendable` types)
  - Provide storage protocols/implementations and game management services
  - Expose logging, sync hooks, haptics, and design system tokens
- **Non-goals**:
  - App navigation and screens
  - Platform-specific styling outside tokens

## Structure & Key Types

- **Primary types**:
  - Models: `Game`, `GameType`, `GameVariation`, `User`, `SupabaseTypes`, `SyncTypes`
  - Services: `SwiftDataContainer`, `SwiftDataStorageProtocol`, `SwiftDataStorage`, `SwiftDataGameManager`, `ActiveGameStateManager`, `ActiveGameSyncService`, `HapticFeedbackService`
  - Logging: `LoggingService`, `LogEvent`, `LogContext`, `LogLevel`, `OSLogSink`, `ConsoleSink`
  - Design System: `DesignSystem` (colors, typography, spacing)
  - Shared UI: `SyncStatusIndicator`
  - Statistics: Aggregation service to compute KPIs and series for SwiftCharts
- **File locations**: `SharedGameCore/Sources/SharedGameCore/...`
- **Initialization**: `SwiftDataContainer.shared` for container; `SwiftDataStorage.shared` for storage; managers created by apps

## Platform Sections (use as needed)

- **SharedGameCore**: Cross-platform by design; no platform UI code outside small shared components
- **iOS**: Consumes services and tokens
- **watchOS**: Consumes services and tokens

## Data & Persistence

- **Models**: `Game` is a SwiftData `@Model` with relationships/attributes
- **Container**: `SwiftDataContainer` creates and configures a single `ModelContainer`
- **Storage**: `SwiftDataStorageProtocol` defines operations; `SwiftDataStorage` implements CRUD, search, and stats

## State & Concurrency

- **UI isolation**: All UI usage from apps must remain on `@MainActor`
- **Observable state**: `SwiftDataGameManager` and `ActiveGameStateManager` are `@MainActor` and `@Observable` where applicable
- **Actors/Sendable**: Shared types are `Sendable`; services avoid shared mutable state across actors

## Navigation & UI

- **Patterns**: No app navigation here; exposes reusable `SyncStatusIndicator`
- **Design System**: `DesignSystem` provides semantic tokens consumed by apps

## Systems Integration

- **Logging**: `LoggingService` with sinks; structured events/contexts
- **Sync**: `ActiveGameSyncService` for device sync now (extension point for cloud/realtime later)
- **Haptics**: `HapticFeedbackService` for local feedback

## Error Handling

- **Typed errors**: Storage and domain errors conform to `LocalizedError` where user-visible
- **User surfaces**: Provided by apps; core exposes error values only

## Testing & Performance

- **Tests**: Persistence and service tests in `SharedGameCore/Tests/`
- **Performance**: Efficient SwiftData descriptors; minimal main-thread work; strict concurrency

## Open Questions & Future Work

- **Gaps**: Serving rotation/side switching enforcement delegated to app UIs
- **Planned extensions**: v0.6 auth/sync services; v1.0 realtime and analytics services

## References

- **Code**: `SharedGameCore/Sources/SharedGameCore/*`
- **Related docs**: `docs/systems/*`, `docs/features/*`

---

## Validation checklist (must meet for acceptance)

- Baseline validation: see `docs/systems/observability/validation-baseline.md`
- **Swift 6.2 strict; iOS 17+ / watchOS 11+ targets** respected; no concurrency warnings
- **UI on `@MainActor`**; shared types are **`Sendable`**; actor boundaries clear
- **Modern SwiftUI**: `NavigationStack`, `@Observable`/`@Bindable`, `@Query` when needed (by apps)
- **DesignSystem-first**: no hardcoded colors/spacing/typography
- **SwiftData**: single app-level container; proper schema usage
- **Typed errors** with `LocalizedError` where user-visible in apps
- **Tests**: persistence, concurrency, and core behaviors covered
