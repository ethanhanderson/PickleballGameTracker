# Search Feature

- **Document name**: Search Feature
- **Category**: features
- **Area**: iOS (tab with trailing `.search` role)

## Summary

- **Purpose**: Describe the in-app game search experience and supporting utilities/components.
- **Scope**: iOS search list, fuzzy matching, recent searches; excludes watchOS (not present).
- **Outcome**: Readers understand how search is implemented and navigates to details.

## Audience & Owners

- **Audience**: engineers, testers
- **Owners**: iOS engineering
- **Last updated**: 2025-08-10
- **Status**: draft
- **Version**: v0.3 baseline

## Architecture Context

- **Layer**: presentation with local utility for fuzzy filtering
- **Entry points**: `GameSearchView`
- **Dependencies**: `FuzzySearchUtility`, `DesignSystem`, `AppNavigationState`
- **Data flow**: Input text → filter via utility → show results → navigate to detail; recent searches persisted locally

## Responsibilities

- **Core responsibilities**:
  - Provide fast, fuzzy search over `GameType`
  - Manage recent searches and navigation to game details
- **Non-goals**:
  - Full-text search over stored games (future system-level search)

## Structure & Key Types

- **Primary types**: `GameSearchView`, components (`SearchResultsList`, `RecentSearchesSection`, `CustomContentUnavailableView`), utility (`FuzzySearchUtility`)
- **File locations**: `Pickleball Score Tracking/Views/Core/Search/GameSearchView.swift`, `.../Views/Components/UI/*`
- **Initialization**: Injects `AppNavigationState`; uses `@State` for search text/history

## Platform Sections (use as needed)

- **iOS**: Search tab with dedicated `NavigationStack`

## Data & Persistence

- **Models**: `GameType`
- **Container**: N/A
- **Storage**: Recent searches persisted via user defaults or local state (as implemented)

## State & Concurrency

- **UI isolation**: `@MainActor`
- **Observable state**: `@Bindable` for navigation state; local view state
- **Actors/Sendable**: Uses `Sendable` primitives and enums

## Navigation & UI

- **Patterns**: `NavigationStack` within Search tab
- **Destinations**: Navigate to game detail
- **Components**: Results list and recent searches section
- **Design System**: All styling via tokens

## Systems Integration

- **Logging**: Search started, selection, and navigation events
- **Sync**: Not applicable
- **Haptics**: Optional feedback on selection

## Error Handling

- **Typed errors**: N/A
- **User surfaces**: Empty state and no-results state with guidance

## Testing & Performance

- **Tests**: Fuzzy search correctness, recent history management, navigation events
- **Performance**: Debounced filtering; light UI

## Open Questions & Future Work

- **Gaps**: Cross-feature search (history, variations) could be added later
- **Planned extensions**: Federated search across local/cloud after v0.6

## References

- **Code**: `Pickleball Score Tracking/Views/Core/Search/GameSearchView.swift`, `.../Views/Components/UI/*`
- **Related docs**: `docs/features/games.md`

---

## Validation checklist (must meet for acceptance)

- **Swift 6.2 strict; iOS 17+ / watchOS 11+ targets** respected; no concurrency warnings
- **UI on `@MainActor`**; shared types are **`Sendable`**; actor boundaries clear
- **Modern SwiftUI**: `NavigationStack`, `@Observable`/`@Bindable`
- **DesignSystem-first**: no hardcoded colors/spacing/typography
- **SwiftData**: single app-level container; proper schema usage
- **Typed errors** with `LocalizedError` where user-visible
- **Tests**: persistence, concurrency, and core UI behaviors covered
