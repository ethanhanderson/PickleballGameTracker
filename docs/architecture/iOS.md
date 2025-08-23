# iOS App Architecture

- **Document name**: iOS App Architecture
- **Category**: architecture
- **Area**: iOS

## Summary

- **Purpose**: Describe iOS app composition, navigation, container injection, and integration with `SharedGameCore`.
- **Scope**: iOS-specific structure and behaviors; excludes watchOS and shared-core internals.
- **Outcome**: Readers can navigate code and understand iOS responsibilities and boundaries.

## Audience & Owners

- **Audience**: engineers, testers
- **Owners**: iOS engineering
- **Last updated**: 2025-08-10
- **Status**: draft
- **Version**: v0.3 baseline

## Architecture Context

- **Layer**: presentation with thin UI; delegates business logic to shared services
- **Entry points**: `Pickleball_Score_TrackingApp`, `AppNavigationView`
- **Dependencies**: SwiftUI, SwiftData, `SharedGameCore`
- **Data flow**: Views → `SwiftDataGameManager`/`ActiveGameStateManager` → `SwiftDataStorage` → SwiftData; Statistics aggregates derived metrics; History uses infinite loading with 30‑day local retention and on‑demand fetch

## Responsibilities

- **Core responsibilities**:
  - Provide iOS navigation (`TabView` + `NavigationStack`) and screens (Games, History, Players & Teams, Statistics, Search, Active Game)
  - Inject and wire shared services and container
- **Non-goals**:
  - Implement domain/business rules (lives in `SharedGameCore`)

## Structure & Key Types

- **Primary types**: `AppNavigationView`, `GameHomeView`, `GameSectionDetailView`, `GameDetailView`, `GameHistoryView`, `GameSearchView`, `ActiveGameView`
- **File locations**: `Pickleball Score Tracking/Views/...`
- **Initialization**: `.modelContainer(SwiftDataContainer.shared.modelContainer)` applied at root; state managers configured in `AppNavigationView`

## Platform Sections (use as needed)

- **iOS**: Rich layouts, sheet for Active Game, bottom accessory preview controls

## Data & Persistence

- **Models**: Consumes `SharedGameCore` `@Model` types (e.g., `Game`)
- **Container**: Uses `SwiftDataContainer.shared.modelContainer`
- **Storage**: Interacts via `SwiftDataStorageProtocol` through managers

## State & Concurrency

- **UI isolation**: `@MainActor` views
- **Observable state**: `@Observable` managers; `@Bindable` where needed; `@Environment(\.modelContext)` access
- **Actors/Sendable**: Adheres to Sendable requirements; no cross-actor mutable sharing

## Navigation & UI

- **Patterns**: `TabView` (Games, History, Players & Teams, Statistics, Search) with `NavigationStack` within; sheet presents `ActiveGameView`
- **Destinations**: `GameSectionDestination`, `GameHistoryDestination`
- **Components**: `GamePreviewControls`, `GameOptionCard`, `GameSection`, `GameDetail*` components
- **Design System**: `DesignSystem` tokens for color, typography, spacing; accent color usage

## Systems Integration

- **Logging**: Configured at app init; uses `LoggingService` sinks
- **Sync**: `ActiveGameSyncService` enabled via `ActiveGameStateManager` when appropriate
- **Haptics**: `HapticFeedbackService` used by interactive controls

## Error Handling

- **Typed errors**: Surfaced from storage/managers; mapped to `ErrorView` where suitable
- **User surfaces**: Initialization error path and in-view alerts

## Testing & Performance

- **Tests**: UI behaviors and integration with persistence
- **Performance**: Lazy stacks, stable IDs, minimized work in `body`

## Open Questions & Future Work

- **Gaps**: Serving rotation/side switching enforcement
- **Planned extensions**: v0.6 auth/sync UI; v1.0 realtime game participation UX

## References

- **Code**: `Pickleball Score Tracking/Pickleball_Score_TrackingApp.swift`, `Pickleball Score Tracking/Views/Infrastructure/Navigation/AppNavigationView.swift`, `Pickleball Score Tracking/Views/...`
- **Related docs**: `docs/features/*`, `docs/systems/*`

---

## Validation checklist (must meet for acceptance)

- Baseline validation: see `docs/systems/observability/validation-baseline.md`
- **Swift 6.2 strict; iOS 17+ / watchOS 11+ targets** respected; no concurrency warnings
- **UI on `@MainActor`**; shared types are **`Sendable`**; actor boundaries clear
- **Modern SwiftUI**: `NavigationStack`, `@Observable`/`@Bindable`, `@Query` when needed
- **DesignSystem-first**: no hardcoded colors/spacing/typography
- **SwiftData**: single app-level container; proper schema usage
- **Typed errors** with `LocalizedError` where user-visible
- **Tests**: persistence, concurrency, and core UI behaviors covered
