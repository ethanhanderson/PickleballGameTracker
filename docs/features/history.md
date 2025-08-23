# History Feature

- **Document name**: History Feature
- **Category**: features
- **Area**: cross-cutting (iOS, SharedGameCore)

## Summary

- **Purpose**: Describe game history list/detail and summary insights on iOS.
- **Scope**: Completed games browsing and details; excludes active gameplay and search.
- **Outcome**: Readers understand how history data is presented and loaded.

## Audience & Owners

- **Audience**: engineers, testers
- **Owners**: iOS engineering
- **Last updated**: 2025-08-14
- **Status**: draft
- **Version**: v0.3 baseline

## Architecture Context

- **Layer**: presentation with data from `SwiftDataGameManager`/`SwiftDataStorage`
- **Entry points**: `GameHistoryView`
- **Dependencies**: `SharedGameCore`, `DesignSystem`
- **Data flow**: UI → paginated fetch via manager/storage → display grouped list with infinite loading (30‑day local retention; older games fetched from database) → navigate to Completed Game detail

## Responsibilities

- **Core responsibilities**:
  - Present completed games with grouping and insights
  - Show game detail with final scores and metadata
  - Respect archive visibility: archived games (`Game.isArchived == true`) are excluded from default history queries
- **Non-goals**:
  - Editing completed games beyond deletion

## Structure & Key Types

- **Primary types**: `GameHistoryView`, components (`GameHistoryContent`, `GameHistoryGroupedList`, `GameHistoryRow`, `GameHistorySummary`, `GameInsightsCard`), `CompletedGameDetailView`
- **File locations**: `Pickleball Score Tracking/Features/History/*`, `.../Features/History/Components/*`
- **Initialization**: Uses `@Environment(\.modelContext)` and manager-provided data

## Platform Sections (use as needed)

- **iOS**: Dedicated History tab with navigation to detail

## Data & Persistence

- **Models**: `Game`
- **Container**: Provided at app root
- **Storage (v0.3)**: Fetch via `SwiftDataStorage` or manager abstractions; History excludes archived games by default. A dedicated Archive screen is accessible from the toolbar to view archived games.
- **Deferred (v0.6)**: Lazy/infinite loading and 30‑day local retention with on‑demand fetch from the database (cloud sync).

## State & Concurrency

- **UI isolation**: `@MainActor`
- **Observable state**: Manager state for lists; local state for UI
- **Actors/Sendable**: Uses `Sendable` models

## Navigation & UI

- **Patterns**: `NavigationStack` from History tab into detail
- **Destinations**: History detail destination type; Archive list
- **Components**: Grouped list; insights moved to Statistics tab; Completed Game detail link
- **Design System**: All styling via tokens

## Preview Stability (guardrails)

- **Stable group IDs (MUST)**: `GroupedGames` and similar types must derive id from content (e.g., `title`) and NOT use fresh `UUID()`.
- **Single scroll owner (MUST)**: Only the outer `ScrollView` owns scrolling. Child sections use `VStack` (as implemented in `GameHistoryContent` and `GameHistoryGroupedList`).
- **No nested lazy stacks (SHOULD)**: Prefer `VStack` inside grouped sections in previews.
- **Destination placement (MUST)**: `.navigationDestination(for:)` is attached at the `NavigationStack` level in `GameHistoryView`.
- **No empty symbols (MUST)**: Avoid empty `Label(systemImage:)` configurations in history components.

## Systems Integration

- **Logging**: View appearance and selection events
- **Sync**: Not applicable
- **Haptics**: Optional feedback on selection

## Error Handling

- **Typed errors**: Storage errors surfaced to error UI
- **User surfaces**: ErrorView on load failure; deletion confirmations

## Testing & Performance

- **Tests**: Fetching and rendering; deletion flow; archive visibility
- **Performance**: Lazy lists; efficient sort/descriptors

## Open Questions & Future Work

- **Gaps**: Advanced filters and stats may be added later
- **Planned extensions**: Player/team filtering post v0.6

## References

- **Code**: `Pickleball Score Tracking/Features/History/*`, `.../Features/History/Components/*`
- **Related docs**: `docs/systems/data/persistence.md`, `docs/features/games.md`, `docs/features/completed-game-view.md`, `docs/features/statistics.md`, `docs/systems/ux/deep-linking.md`

## Code path anchors

- `Pickleball Score Tracking/Features/History/Screens/GameHistoryView.swift`
- `Pickleball Score Tracking/Features/History/Components/GameHistoryContent.swift`
- `SharedGameCore/Sources/SharedGameCore/Services/SwiftDataStorage.swift`

## Starter queries

- How does the infinite loader request the next page?
- Where is Completed Game detail navigation triggered from the list?

---

## Validation checklist (must meet for acceptance)

- Baseline validation: see `docs/systems/observability/validation-baseline.md`
- **Swift 6.2 strict; iOS 17+ / watchOS 11+ targets** respected; no concurrency warnings
- **UI on `@MainActor`**; shared types are **`Sendable`**; actor boundaries clear
- **Modern SwiftUI**: `NavigationStack`, `@Observable`/`@Bindable`
- **DesignSystem-first**: no hardcoded colors/spacing/typography
- **SwiftData**: single app-level container; proper schema usage
- **Typed errors** with `LocalizedError` where user-visible
- **Tests**: persistence, concurrency, and core UI behaviors covered; archived games excluded from default history; Archive screen lists archived games
- **Preview stability**: Stable ids for groups; single scroll owner; no nested lazy stacks
  - `.navigationDestination` is attached at `NavigationStack`
  - No empty `Label(systemImage:)`
