# watchOS App Architecture

- **Document name**: watchOS App Architecture
- **Category**: architecture
- **Area**: watchOS

## Summary

- **Purpose**: Describe watchOS app composition, navigation, container injection, and integration with `SharedGameCore`.
- **Scope**: watchOS-specific structure and behaviors; excludes iOS and shared-core internals.
- **Outcome**: Readers can navigate code and understand watchOS responsibilities and boundaries.

## Audience & Owners

- **Audience**: engineers, testers
- **Owners**: watchOS engineering
- **Last updated**: 2025-08-10
- **Status**: draft
- **Version**: v0.3 baseline

## Architecture Context

- **Layer**: presentation with thin UI; delegates business logic to shared services
- **Entry points**: `Pickleball_Score_Tracking_Watch_AppApp`, `WatchGameCatalogView` (toolbar links to Statistics and History)
- **Dependencies**: SwiftUI, SwiftData, `SharedGameCore`
- **Data flow**: Views → `ActiveGameStateManager`/`SwiftDataGameManager` → `SwiftDataStorage` → SwiftData

## Responsibilities

- **Core responsibilities**:
  - Provide watchOS navigation (`NavigationStack`) and core screens (Game Catalog, Active Game, Settings)
  - Inject and wire shared services and container
- **Non-goals**:
  - Implement domain/business rules (lives in `SharedGameCore`)

## Structure & Key Types

- **Primary types**: `WatchGameCatalogView`, `WatchActiveGameView`, `WatchActiveGameSettingsView`
- **File locations**: `Pickleball Score Tracking Watch App/Views/...`
- **Initialization**: `.modelContainer(SwiftDataContainer.shared.modelContainer)` at root; uses `ActiveGameStateManager.shared`

## Platform Sections (use as needed)

- **watchOS**: Simplified flows, touch-friendly controls, inline alerts; internal two-tab view in `WatchActiveGameView` for controls/score

## Data & Persistence

- **Models**: Consumes `SharedGameCore` `@Model` types (e.g., `Game`)
- **Container**: Uses `SwiftDataContainer.shared.modelContainer`
- **Storage**: Interacts via `SwiftDataStorageProtocol` through managers

## State & Concurrency

- **UI isolation**: `@MainActor` views
- **Observable state**: `@Observable` managers; `@Environment(\.modelContext)` access
- **Actors/Sendable**: Adheres to Sendable requirements; no cross-actor mutable sharing

## Navigation & UI

- **Patterns**: `NavigationStack`; vertical page browsing for catalog cards; pressing Play opens a sheet to choose presets or start a new game by composing teams from existing players
- **Destinations**: Minimal, enum-free direct view transitions
- **Components**: Catalog cards and active game controls/settings
- **Design System**: `DesignSystem` tokens for color, typography, spacing

## Systems Integration

- **Logging**: Configured at app init; uses `LoggingService` sinks
- **Sync**: Uses `ActiveGameStateManager` and `ActiveGameSyncService` for device sync visibility
- **Haptics**: `HapticFeedbackService` used by interactive controls

## Error Handling

- **Typed errors**: Surfaced from storage/managers
- **User surfaces**: Alerts and minimal error surfaces

## Testing & Performance

- **Tests**: UI behaviors and persistence integration
- **Performance**: Lightweight screens, minimal layout depth, animations kept subtle

## Open Questions & Future Work

- **Gaps**: Serving rotation/side switching enforcement
- **Planned extensions**: v0.6 direct cloud sync participation; v1.0 realtime spectators/participants

## References

- **Code**: `Pickleball Score Tracking Watch App/Pickleball_Score_TrackingApp.swift`, `Pickleball Score Tracking Watch App/Views/...`
- **Related docs**: `docs/features/*`, `docs/systems/*`
- **Runtime rules**: `docs/systems/runtime/watchos-runtime-rules.md`

---

## Validation checklist (must meet for acceptance)

- Baseline validation: see `docs/systems/observability/validation-baseline.md`
- **Swift 6.2 strict; iOS 17+ / watchOS 11+ targets** respected; no concurrency warnings
- **UI on `@MainActor`**; shared types are **`Sendable`**; actor boundaries clear
- **Modern SwiftUI**: `NavigationStack`, `@Observable`/`@Bindable`
- **DesignSystem-first**: no hardcoded colors/spacing/typography
- **SwiftData**: single app-level container; proper schema usage
- **Typed errors** with `LocalizedError` where user-visible
- **Tests**: persistence, concurrency, and core UI behaviors covered
