# Navigation

- **Document name**: Navigation
- **Category**: systems
- **Area**: cross-cutting (iOS, watchOS)

## Summary

- **Purpose**: Describe navigation patterns and types across iOS and watchOS.
- **Scope**: Tab + stack on iOS; simple stack on watchOS; destination types.
- **Outcome**: Readers can follow and extend navigation safely.

## Audience & Owners

- **Audience**: engineers, testers
- **Owners**: iOS/watchOS engineering
- **Last updated**: 2025-08-12
- **Status**: draft
- **Version**: v0.3 baseline

## Architecture Context

- **Layer**: presentation
- **Entry points**: iOS `AppNavigationView`; watchOS `WatchGameCatalogView`
- **Dependencies**: SwiftUI
- **Data flow**: User actions → destination types → view pushes/sheets

## Responsibilities

- **Core responsibilities**:
  - Provide predictable, platform-appropriate navigation
  - Encapsulate destinations in typed enums
- **Non-goals**:
  - Business logic inside navigation

## Structure & Key Types

- **Primary types**: iOS `AppNavigationView`, `AppTab`, `GameSectionDestination`, `GameHistoryDestination`; `NavigationDestinationFactory` (if used)
- **File locations**: `Pickleball Score Tracking/Views/Infrastructure/Navigation/*`
- **Initialization**: `NavigationStack` per tab on iOS; single stack on watchOS

## Platform Sections (v0.3)

- **iOS**: `TabView` (Games, History, Search, Statistics) each hosting a `NavigationStack`; Search uses trailing `.search` role. Deep‑link requests can switch to the Statistics tab. The Active Game opens as a full‑screen cover with a native zoom navigation transition originating from the TabView bottom accessory (Game Preview); a custom drag handle provides sheet‑like swipe‑to‑dismiss. See Apple docs: [ZoomNavigationTransition](https://developer.apple.com/documentation/swiftui/zoomnavigationtransition), [NavigationTransition](https://developer.apple.com/documentation/swiftui/navigationtransition).
- **watchOS**: Single `NavigationStack`; page-style catalog navigation

## Data & Persistence

- **Models**: N/A
- **Container**: N/A
- **Storage**: N/A

## State & Concurrency

- **UI isolation**: `@MainActor`
- **Observable state**: `AppNavigationState` stores `NavigationPath`
- **Actors/Sendable**: Destination types `Hashable`/`Sendable`

## Navigation & UI

- **Patterns**: Use value-typed destinations; prefer programmatic pushes via state
- **Destinations**: `GameSectionDestination`, `GameHistoryDestination`
- **Components**: N/A
- **Design System**: Tabs and titles styled with tokens; container backgrounds applied within feature views using `DesignSystem.Colors.primary.gradient` (avoid attaching backgrounds at the TabView level).

## SwiftUI Preview Stability (guardrails)

- **Stable identities (MUST)**: Any grouped/list item types MUST have stable, content-derived `id` (e.g., `var id: String { title }`). Avoid `UUID()` for `Identifiable` unless the instance is persistent across recomputations.
- **Destination placement (MUST)**: Attach `.navigationDestination(for:)` directly to the `NavigationStack` (or immediately chained) instead of deep inside child containers.
- **Nested scroll/lazy views (SHOULD NOT)**: Avoid nested `ScrollView` and nested `LazyVStack`/`LazyHStack`. Prefer a single outer `ScrollView` with inner `VStack` sections. History implements this via `GameHistoryView` → `ScrollView` and `GameHistoryContent`/`GameHistoryGroupedList` using `VStack`.
- **Lazy to non-lazy (SHOULD)**: If previews show recursion or AttributeGraph churn, replace inner `LazyVStack` with `VStack` in subsections.
- **Icons/labels (MUST)**: Never pass empty SF Symbols to `Label(systemImage:)`. Use conditional `HStack { Image(...); Text(...) }` instead.

### Preview acceptance checklist (additive)

- **Stable IDs**: Lists/sections use stable identifiers (no regenerating `UUID()`).
- **Single scroll owner**: Only one `ScrollView` in the composition tree for a screen.
- **Destinations**: `.navigationDestination` is chained at the `NavigationStack` level.
- **No empty symbols**: No `Label(systemImage: "")`.
- **History conformance**: `GameHistoryView` attaches destinations at stack level; groups use content-derived stable IDs; child sections are `VStack`.

## Systems Integration

- **Logging**: Track navigation events in `AppNavigationState`
- **Sync**: Active game sheet entry when game present
- **Haptics**: Optional feedback on selection

## Error Handling

- **Typed errors**: N/A
- **User surfaces**: Graceful fallbacks for missing destinations

## Testing & Performance

- **Tests**: Destination routing and path management
- **Performance**: Keep stacks shallow on watchOS; avoid heavy view trees

## Open Questions & Future Work

- **Gaps**: Universal link hosting and server-side token validation (planned v0.6)
- **Planned extensions**: Search route expansion

## References

- **Code**: `.../Navigation/AppNavigationView.swift`, `.../Navigation/NavigationTypes.swift`, `.../Navigation/GameSectionDestination.swift`
- **Related docs**: `docs/features/*`, `docs/systems/ux/deep-linking.md`

## Code path anchors

- `Pickleball Score Tracking/Views/Infrastructure/Navigation/AppNavigationView.swift`
- `Pickleball Score Tracking/Views/Infrastructure/Navigation/NavigationTypes.swift`
- `Pickleball Score Tracking/Views/Infrastructure/Navigation/GameSectionDestination.swift`

## Starter queries

- Where are navigation events logged?
- How does a deep link become a typed destination?

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
