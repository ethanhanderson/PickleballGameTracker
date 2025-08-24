# Architecture Overview

- **Document name**: Architecture Overview
- **Category**: architecture
- **Area**: cross-cutting

## Summary

- **Purpose**: Provide a high-level map of layers, boundaries, and data flow across iOS, watchOS, and `SharedGameCore`.
- **Scope**: Cross-platform architecture and boundaries; excludes feature specifics (see `docs/features/`) and system deep-dives (see `docs/systems/`).
- **Outcome**: Readers understand where responsibilities live and how data moves through the system.

## Audience & Owners

- **Audience**: engineers, testers
- **Owners**: iOS/watchOS engineering
- **Last updated**: 2025-08-10
- **Status**: draft
- **Version**: v0.3 baseline (notes for v0.6/v1.0 where relevant)

- **Layer**: presentation (SwiftUI views) | domain (managers, rules) | data (SwiftData storage)
- **Entry points**: `Pickleball_Score_TrackingApp` (iOS), `Pickleball_Score_Tracking_Watch_AppApp` (watchOS)
- **Dependencies**: SwiftUI, SwiftData, `SharedGameCore`, SwiftCharts
- **Data flow**: UI → `SwiftDataGameManager`/`ActiveGameStateManager` → `SwiftDataStorage` → SwiftData store; events via `LoggingService`; device sync via `ActiveGameSyncService`; Statistics aggregates derived metrics (Overview of grouped stat cards → per‑stat Detail). In v0.3, History displays all local completed games (archived hidden by default) with an Archive screen accessible from the toolbar; lazy/infinite loading and offload to cloud are deferred to v0.6. Completed Game deep links open a specific Statistics Detail with filters applied.

## Responsibilities

- **Core responsibilities**:
  - Define layered boundaries and platform responsibilities
  - Centralize shared logic in `SharedGameCore` with strict concurrency
- **Non-goals**:
  - Feature UI details (see `docs/features/`)
  - Deep system configuration (see `docs/systems/`)

## Structure & Key Types

- **Primary types**:
  - Presentation: `AppNavigationView`, `GameHomeView`, `GameHistoryView`, `GameSearchView`, `ActiveGameView` (iOS); `WatchGameCatalogView`, `WatchActiveGameView` (watchOS)
  - Domain: `SwiftDataGameManager`, `ActiveGameStateManager`
  - Data: `SwiftDataContainer`, `SwiftDataStorageProtocol`, `SwiftDataStorage`
- **File locations**: `Pickleball Score Tracking/Views/...`, `Pickleball Score Tracking Watch App/Views/...`, `SharedGameCore/...`
- **Initialization**: Single SwiftData container injected via `.modelContainer(SwiftDataContainer.shared.modelContainer)` in both app targets

## Platform Sections (use as needed)

- **SharedGameCore**: Models, services, logging, sync hooks, and design system; all shared business logic lives here.
- **iOS**: Tab-based navigation with `NavigationStack` per tab; richer layouts and components. Tabs: Games, History, Players & Teams, Statistics, and Search (Search uses a trailing `.search` role). Statistics presents an Overview of grouped stat cards; tapping a card drills into a per‑stat Detail.
- **watchOS**: Simplified `NavigationStack` and touch-friendly interactions; active game focused.

## Data & Persistence

- **Models**: `Game` (SwiftData `@Model`)
- **Container**: `SwiftDataContainer` provides a single app-level `ModelContainer`
- **Storage**: `SwiftDataStorageProtocol` with `SwiftDataStorage` implementation for CRUD, search, and stats

## State & Concurrency

- **UI isolation**: `@MainActor` for all UI types
- **Observable state**: `@Observable` types for view state and managers; `@Bindable` in views
- **Actors/Sendable**: Shared types are `Sendable`; cross-actor boundaries respected; strict Swift 6.2 concurrency

## Navigation & UI

- **Patterns**: iOS `TabView` + `NavigationStack`; watchOS `NavigationStack`
- **Destinations**: Typed destinations for history and game sections
- **Components**: Reusable view components under platform `Views/Components`
- **Design System**: All styling via `SharedGameCore.DesignSystem` tokens

## Systems Integration

- **Logging**: `LoggingService` with sinks (`OSLogSink`, `ConsoleSink`)
- **Sync**: `ActiveGameSyncService` device sync; future cloud sync (v0.6) and realtime (v1.0)
- **Haptics**: `HapticFeedbackService` for local interactions

## Error Handling

- **Typed errors**: Storage and domain errors surfaced with user-readable messages
- **User surfaces**: Initialization error view on iOS; alerts and `ErrorView` component

## Testing & Performance

- **Tests**: Persistence, concurrency/actors, UI behaviors, statistics aggregation, and history pagination in package and app test targets
- **Performance**: Lazy containers, stable IDs, minimal work in `body`, pre-aggregation for charts, and paginated history fetch with background prefetch

## Open Questions & Future Work

- **Gaps**: Serving rotation and side switching not fully enforced in UI (v0.3)
- **Planned extensions**: v0.6 cloud accounts/sync; v1.0 realtime and social features

## References

- **Code**: `Pickleball Score Tracking/Pickleball_Score_TrackingApp.swift`, `Pickleball Score Tracking/Views/Infrastructure/Navigation/AppNavigationView.swift`, `Pickleball Score Tracking Watch App/Pickleball_Score_TrackingApp.swift`, `SharedGameCore/Services/...`
- **Related docs**: `docs/systems/*`, `docs/features/*`, `docs/implementation-roadmap.md`, `docs/systems/devx/roadmap-governance.md`, `docs/systems/devx/build-and-ci.md`

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
