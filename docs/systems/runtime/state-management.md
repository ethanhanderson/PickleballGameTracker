# State Management

- **Document name**: State Management
- **Category**: systems
- **Area**: cross-cutting

## Summary

- **Purpose**: Define how state flows through views and services using modern SwiftUI and strict concurrency.
- **Scope**: `@Observable`, `@Bindable`, `@MainActor`, managers; excludes per-feature details.
- **Outcome**: Readers can reason about state and avoid race conditions.

## Audience & Owners

- **Audience**: engineers, testers
- **Owners**: iOS/watchOS engineering
- **Last updated**: 2025-08-10
- **Status**: draft
- **Version**: v0.3 baseline

## Architecture Context

- **Layer**: presentation and domain
- **Entry points**: `SwiftDataGameManager`, `ActiveGameStateManager`, `AppNavigationState`
- **Dependencies**: SwiftUI observation, `SharedGameCore`
- **Data flow**: Views bind to observable managers; managers call storage

## Responsibilities

- **Core responsibilities**:
  - Keep UI on `@MainActor` and expose observable state
  - Coordinate current game and history
- **Non-goals**:
  - Embedding business logic in views

## Structure & Key Types

- **Primary types**: `SwiftDataGameManager` (`@Observable`, `@MainActor`), `ActiveGameStateManager` (shared singleton), `AppNavigationState` (`@Observable`)
- **File locations**: core services under `SharedGameCore/Services/*`; app states under `.../Views/Infrastructure/State/*`
- **Initialization**: Managers created in app root/views and configured with model context

## Platform Sections (use as needed)

- **iOS**: Wires managers in `AppNavigationView` and passes to views
- **watchOS**: Uses `ActiveGameStateManager.shared`

## Data & Persistence

- **Models**: Observed `Game` instances via `@Bindable` when edited
- **Container**: Provided at app root
- **Storage**: Managers delegate to storage for persistence

## State & Concurrency

- **UI isolation**: All state mutations from UI occur on `@MainActor`
- **Observable state**: `@Observable` and `@Bindable` used; avoid legacy patterns
- **Actors/Sendable**: Shared types are `Sendable`; avoid shared mutable state across actors

## Navigation & UI

- **Patterns**: `NavigationStack` state lives in observable objects where needed
- **Design System**: N/A

## Systems Integration

- **Logging**: Managers emit logs for significant events
- **Sync**: Active game state aware of device sync
- **Haptics**: Triggered from user interactions via services

## Error Handling

- **Typed errors**: Managers capture lastError; apps render `ErrorView`
- **User surfaces**: Alerts and error components

## Testing & Performance

- **Tests**: Concurrency isolation tests and integration tests for state changes
- **Performance**: Keep state minimal; avoid heavy processing on main thread

## Open Questions & Future Work

- **Gaps**: Enforcement of certain rules in UI
- **Planned extensions**: Additional observable states for players/teams (v0.6)

## References

- **Code**: `SharedGameCore/Services/SwiftDataGameManager.swift`, `.../ActiveGameStateManager.swift`, app states under `Views/Infrastructure/State/*`
- **Related docs**: `docs/systems/data/storage.md`

---

## Validation checklist (must meet for acceptance)

- **Swift 6.2 strict; iOS 17+ / watchOS 11+ targets** respected; no concurrency warnings
- **UI on `@MainActor`**; shared types are **`Sendable`**; actor boundaries clear
- **Modern SwiftUI**: `@Observable`, `@Bindable`
- **DesignSystem-first**: no hardcoded colors/spacing/typography
- **SwiftData**: single app-level container; proper schema usage
- **Typed errors** with `LocalizedError` where user-visible
- **Tests**: persistence, concurrency, and core UI behaviors covered
