# watchOS Runtime Rules

- **Document name**: watchOS Runtime Rules
- **Category**: systems
- **Area**: watchOS

## Summary

- **Purpose**: Define normative runtime rules for the watchOS app covering state, concurrency, navigation, persistence, and systems integration.
- **Scope**: watchOS runtime behaviors and guardrails; excludes iOS-specific UX and shared-core internals beyond interface contracts.
- **Outcome**: Engineers can implement and review watchOS features with consistent patterns that satisfy Swift 6.2 strict concurrency and the validation baseline.

## Audience & Owners

- **Audience**: engineers, reviewers, QA
- **Owners**: watchOS engineering
- **Last updated**: 2025-08-22
- **Status**: draft
- **Version**: v0.3 baseline

## Architecture Context

- **Layer**: presentation orchestrating domain services from `SharedGameCore`
- **Entry points**: `Pickleball_Score_Tracking_Watch_AppApp`, root catalog/navigation views
- **Dependencies**: SwiftUI, SwiftData, `SharedGameCore` services (storage, logging, sync, haptics)
- **Data flow**: Views → state managers → `SwiftDataStorageProtocol` → SwiftData

## Responsibilities

- **Core responsibilities**:
  - Provide fast, glanceable interactions with minimal navigation depth
  - Maintain correctness with structured concurrency and actor isolation
  - Persist user actions via `SwiftData` using the shared container
  - Integrate logging, haptics, and sync in a battery- and latency-conscious way
- **Non-goals**:
  - Re-implement business rules (lives in `SharedGameCore`)
  - Introduce divergent navigation patterns from iOS unless watch-first UX requires

## Structure & Key Types

- **Primary types**: catalog, active game, game settings views; state managers (`ActiveGameStateManager`, storage/sync actors)
- **File locations**: `Pickleball Score Tracking Watch App/`
- **Initialization**: `.modelContainer(SwiftDataContainer.shared.modelContainer)` at app root; service singletons are injected or resolved at the boundary

## State & Concurrency Rules

- **UI isolation (MUST)**: All SwiftUI views and view models that mutate UI state are `@MainActor`.
- **Observable state (SHOULD)**: Use `@Observable` and `@Bindable` for local UI state; avoid `@StateObject` unless interoperating with `ObservableObject` APIs.
- **Actors (MUST)**: Cross-thread/shared mutable logic resides in actors. Storage, sync, and long-running services are actor-isolated and `Sendable`.
- **Sendable (MUST)**: All shared types crossing actor boundaries conform to `Sendable`. Avoid non-final classes unless actor-isolated.
- **Async/await (MUST)**: Use async functions with structured concurrency. No detached tasks; prefer `.task(id:)` or `Task { @MainActor in ... }` when updating UI.
- **Cancellation (SHOULD)**: Respect cooperative cancellation with `Task.checkCancellation()` in loops and long operations.
- **Haptics (MUST)**: Trigger haptics from the main actor and debounce rapid repeats to preserve battery and UX.

## Navigation & UI Rules

- **NavigationStack (MUST)**: Use `NavigationStack` with shallow hierarchies. Avoid deep push stacks; prefer sheets for transient flows.
- **Minimal destinations (SHOULD)**: Keep destination types simple; avoid large enums unless necessary for testability.
- **Accessibility (MUST)**: Large tap targets, VoiceOver labels, and minimal scrolling. Favor single-screen operations where possible.
- **Design System (MUST)**: Use `DesignSystem` tokens for color/typography/spacing. No hardcoded values.
- **Animations (SHOULD)**: Subtle and interruptible; avoid heavy or continuous animations.

## Data & Persistence Rules

- **Single container (MUST)**: Use the shared app-level `SwiftDataContainer.shared.modelContainer`.
- **Context access (SHOULD)**: Use `@Environment(\.modelContext)` within views; delegate persistence to manager/actor layers.
- **Schema discipline (MUST)**: Only persist `@Model` types defined in shared core; never create watch-only divergent schemas.
- **Batching (SHOULD)**: Batch writes where possible to reduce disk wake-ups; prefer actor-coordinated saves.

## Systems Integration Rules

- **Logging (MUST)**: Emit typed events via `LoggingService` with configurable sinks (`OSLogSink`, `ConsoleSink`). No print statements.
- **Sync (SHOULD)**: Use `ActiveGameSyncService` to surface sync state; the watch participates passively unless explicitly in active sync flows.
- **Haptics (MUST)**: Route through `HapticFeedbackService` and centralize patterns for consistent feel.
- **Network (SHOULD)**: Avoid background network on watch unless user-initiated and short-lived.

## Error Handling Rules

- **Typed errors (MUST)**: Use domain-specific error types conforming to `LocalizedError` when user-visible.
- **User surfaces (SHOULD)**: Prefer lightweight alerts or inline error banners; avoid complex forms.
- **Recovery (SHOULD)**: Provide single-action recovery where possible (Retry, Dismiss) with sensible defaults.

## Testing & Performance Rules

- **Tests (MUST)**: Cover persistence boundaries, actor isolation, and critical UI flows. Use modern Swift Testing with `@Test` and `#expect`.
- **Determinism (MUST)**: No global mutable state in tests; inject fakes with the same protocols.
- **Performance (SHOULD)**: Favor low view depth, stable `id`s, and memoized subviews. Keep tasks short and cancelable.
- **Battery (SHOULD)**: Minimize haptics frequency and network usage; coalesce storage writes.

## Deterministic Commands

- iOS build/test:
  - `cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking" -destination "platform=iOS Simulator,name=iPhone 16" test`
- watchOS build/test:
  - `cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking Watch App" -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)" test`

## Test touchpoints

- **Suites/files to extend**: `PickleballGameTrackerUITests/`, `Pickleball Score Tracking Watch AppTests/`
- **New tests to add**: actor isolation tests for storage/sync; UI flows for active game interactions

## Change impact

- **Affected modules**: SharedGameCore, watchOS
- **Risks & mitigations**: concurrency pitfalls (mitigate with actors and Sendable); persistence contention (mitigate with batching and single container); navigation regressions (mitigate with shallow stacks and tests)

## Open Questions & Future Work

- **Gaps**: Cloud sync authoring from watch; offline-first conflict resolution UX
- **Planned extensions**: v0.6 refined sync participation; v1.0 live spectators/participants from watch

## References

- **Code**: `Pickleball Score Tracking Watch App/`, `SharedGameCore/`
- **Related docs**: `docs/architecture/watchOS.md`, `docs/systems/runtime/state-management.md`, `docs/systems/runtime/sync.md`

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
