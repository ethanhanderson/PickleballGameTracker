# Games Feature

- **Document name**: Games Feature
- **Category**: features
- **Area**: cross-cutting (iOS, watchOS, SharedGameCore)

## Summary

- **Purpose**: Describe the games home/catalog flows and sectioning across platforms.
- **Scope**: Games discovery, sections, navigation into details; excludes active gameplay and history.
- **Outcome**: Readers can trace how users discover and start games.

## Audience & Owners

- **Audience**: engineers, testers
- **Owners**: iOS/watchOS engineering
- **Last updated**: 2025-08-10
- **Status**: draft
- **Version**: v0.3 baseline

## Architecture Context

- **Layer**: presentation (views) using domain services from `SharedGameCore`
- **Entry points**: iOS `GameHomeView`; watchOS `WatchGameCatalogView`
- **Dependencies**: `SharedGameCore` models/services; `DesignSystem`
- **Data flow**: UI → `AppNavigationState`/`ActiveGameStateManager` → navigation destinations and game creation

## Responsibilities

- **Core responsibilities**:
  - Present curated game sections and types
  - Navigate to game detail/setup screens
- **Non-goals**:
  - Enforcing rules or scoring (handled in Active Game)

## Structure & Key Types

- **Primary types**:
  - iOS views: `GameHomeView`, `GameSectionDetailView`, `GameDetailView`
  - iOS components: `GameSection`, `GameOptionCard`, `GameDetailHeader`, `GameTypeDetails`, `GameRulesSection`
  - watchOS views: `WatchGameCatalogView`
- **File locations**: `Pickleball Score Tracking/Views/Core/Game/...`, `Pickleball Score Tracking/Views/Components/Game/...`, `Pickleball Score Tracking Watch App/Views/...`
- **Initialization**: Uses `@Environment(\.modelContext)` and state; managers created as needed

## Platform Sections (use as needed)

- **iOS**: Grid/scroll sections with horizontal carousels; taps navigate via `NavigationStack` to details. Game Detail shows a creator header (avatar/name, created-on, plays count) for public/user-created types; tapping opens the Author Profile with their other types.
- **watchOS**: Vertical page-style catalog; card tap logs selection and can start flow

## Data & Persistence

- **Models**: Consumes `Game`, `GameType`, `GameVariation` for display
- **Container**: Provided at app root; not directly managed here
- **Storage**: Read-only consumption for lists; creation delegated to managers

## State & Concurrency

- **UI isolation**: `@MainActor` views
- **Observable state**: `AppNavigationState` for iOS; local `@State` for watchOS paging
- **Actors/Sendable**: Uses `Sendable` models from core

## Navigation & UI

- **Patterns**: iOS `NavigationStack` pushes `GameSectionDestination`; watchOS `NavigationStack` with page-style `TabView`
- **Destinations**: `GameSectionDestination` and `GameHistoryDestination` types
- **Components**: Cards/headers/rules section use `DesignSystem` tokens
- **Design System**: Colors/typography/spacing via `DesignSystem`

## Systems Integration

- **Logging**: `Log.event` on selection and view appears
- **Sync**: Not applicable
- **Haptics**: Optional click feedback on tap

## Error Handling

- **Typed errors**: N/A (lists are static from enums/config)
- **User surfaces**: Content unavailable view when needed

## Testing & Performance

- **Tests**: Navigation to details, list rendering correctness
- **Performance**: Lazy stacks and carousels; stable IDs

## Open Questions & Future Work

- **Gaps**: Direct start-from-catalog flow on watchOS may be expanded
- **Planned extensions**: Game setup parameters and presets

## References

- **Code**: `Pickleball Score Tracking/Views/Core/Game/GameList/GameHomeView.swift`, `.../GameSectionDetailView.swift`, `.../GameDetailView.swift`, `.../Components/Game/GamesHome/*`
- **Related docs**: `docs/features/active-game.md`, `docs/features/variations.md`, `docs/features/game-type-creation.md`, `docs/features/author-profiles.md`, `docs/systems/ux/deep-linking.md`

## Code path anchors

- `Pickleball Score Tracking/Views/Core/Game/GameList/GameHomeView.swift`
- `Pickleball Score Tracking/Views/Core/Game/GameList/GameSectionDetailView.swift`
- `Pickleball Score Tracking/Views/Core/Game/GameDetail/GameDetailView.swift`

## Starter queries

- Where is Game Detail push handled for a selected Game Type?
- Where are author profile routes generated from Game Detail?

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
