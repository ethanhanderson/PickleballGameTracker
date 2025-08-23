# Active Game Feature

- **Document name**: Active Game Feature
- **Category**: features
- **Area**: cross-cutting (iOS, watchOS, SharedGameCore)

## Summary

- **Purpose**: Describe the active gameplay experience, controls, timer, and rule enforcement integrations.
- **Scope**: In-game UI/flows for iOS/watchOS and coordination with managers; excludes history and catalog.
- **Outcome**: Readers understand how scoring and game state are managed in the UI.

## Audience & Owners

- **Audience**: engineers, testers
- **Owners**: iOS/watchOS engineering
- **Last updated**: 2025-08-10
- **Status**: draft
- **Version**: v0.3 baseline

## Architecture Context

- **Layer**: presentation with domain integrations (`ActiveGameStateManager`, `SwiftDataGameManager`)
- **Entry points**: iOS `ActiveGameView` (sheet from `AppNavigationView`), watchOS `WatchActiveGameView`
- **Dependencies**: `SharedGameCore` managers/models, `DesignSystem`
- **Data flow**: Controls → `ActiveGameStateManager` → mutate `Game` and persist via `SwiftDataGameManager`/`SwiftDataStorage`

## Responsibilities

- **Core responsibilities**:
  - Present scoring controls, timer controls, and game toolbar/actions
  - Reflect and mutate current game state safely and responsively
- **Non-goals**:
  - Implement full rules engine in UI (handled in core; enforcement gaps noted below)

## Structure & Key Types

- **Primary types**:
  - iOS: `ActiveGameView`, components (`ActiveGameToolbar`, `TeamScoreCard`, `ServeBezel`, `TimerCard`, `ScoreControlsGrid`)
  - watchOS: `WatchActiveGameView`, `WatchActiveGameSettingsView`
  - Core: `ActiveGameStateManager`, `SwiftDataGameManager`
- **File locations**: iOS `Views/Components/Game/ActiveGame/*`, iOS core `Views/Core/Game/ActiveGame/*`, watchOS `Watch App/Views/*`, core services under `SharedGameCore/Services/*`
- **Initialization**: Managers configured in iOS `AppNavigationView` and used by active game views; watchOS uses `ActiveGameStateManager.shared`

## Platform Sections (use as needed)

- **iOS**: Full‑screen cover presentation from the TabView bottom accessory with a native zoom navigation transition for opening; custom drag handle and swipe interaction emulate sheet behavior. See Apple docs: [View.containerBackground(\_:for:)](<https://developer.apple.com/documentation/swiftui/view/containerbackground(_:for:)>), [ZoomNavigationTransition](https://developer.apple.com/documentation/swiftui/zoomnavigationtransition), and [NavigationTransition](https://developer.apple.com/documentation/swiftui/navigationtransition).
- **watchOS**: Two-tab internal view (controls/score); settings sheet for game options

## Data & Persistence

- **Models**: `Game` as SwiftData `@Model`
- **Container**: Provided at app root
- **Storage**: Saves and updates via `SwiftDataGameManager` → `SwiftDataStorage`

## State & Concurrency

- **UI isolation**: `@MainActor`
- **Observable state**: Managers are `@Observable`; bindable game state via `@Bindable`
- **Actors/Sendable**: All shared types `Sendable`; no cross-actor shared mutation

## Navigation & UI

- **Patterns**: iOS sheet with `NavigationStack`; watchOS `NavigationStack` inside tabs
- **Destinations**: Internal settings sheet (watchOS)
- **Components**: Toolbar, score cards, serve bezel, timer card, grid controls
- **Design System**: All styling via tokens

## Systems Integration

- **Logging**: Events for actions (start/pause/reset/end, score changes)
- **Sync**: `ActiveGameSyncService` awareness via state manager
- **Haptics**: Feedback on scoring and key actions via `HapticFeedbackService`

## Error Handling

- **Typed errors**: Storage errors surfaced; minimal user prompts (alerts)
- **User surfaces**: End game alert; error surfaces when persistence fails

## Testing & Performance

- **Tests**: Basic scoring flow, timer behavior, persistence updates
- **Performance**: Keep updates snappy; avoid heavy work in `body`; debounce animations

## Open Questions & Future Work

- **Gaps**: Serving rotation is modeled but not enforced in UI (tracked in 1.3-a)
- **Planned extensions**: Enforce serving rotation; prepare hooks for realtime collaboration (v1.0)

---

## Enforcement semantics (v0.3)

- UI enforces legal transitions with friendly surfaces and logs; no blocking spinners.
- Score changes are allowed only when `Game.gameState == .playing`. Attempts when paused throw `GameError.cannotScoreWhenPaused` and are surfaced via non-blocking UI feedback. Haptics optional.
- Manual server/player changes are only allowed when not actively playing (pause required). Attempts during play throw `GameError.illegalServerChangeDuringPlay` or `GameError.illegalServingPlayerChangeDuringPlay`.
- Side switching follows variation rule `GameVariation.sideSwitchingRule` and is applied automatically in `Game.scorePoint{1,2}`; when a side switch occurs we emit `LogEvent.sidesSwitched` and trigger a subtle serve-change haptic.
- All user actions are logged via `LoggingService` (`ConsoleSink`/`OSLogSink`). No `print`.

### Code anchors

- `SharedGameCore/Services/SwiftDataGameManager.swift` — enforcement/typed errors
- `SharedGameCore/Models/Game.swift` — rotation/side switching calculation
- iOS/watchOS Active Game views — display-only; actions delegate to managers and surface errors

### Validation checklist (enforcement)

- Illegal scoring while paused is blocked with a friendly message; no crashes.
- Manual serving changes during play are blocked; changes allowed when paused.
- Logs present for score, serve changes, side switches; haptics on serve/score where enabled.

## References

- **Code**: iOS `Views/Components/Game/ActiveGame/*`, iOS `Views/Core/Game/ActiveGame/*`, watchOS `Watch App/Views/*`, core services in `SharedGameCore/Services/*`
- **Related docs**: `docs/features/games.md`, `docs/systems/runtime/state-management.md`

## Code path anchors

- `Pickleball Score Tracking/Views/Core/Game/ActiveGame/ActiveGameView.swift`
- `Pickleball Score Tracking/Views/Components/Game/ActiveGame/ServeBezel.swift`
- `SharedGameCore/Sources/SharedGameCore/Services/ActiveGameStateManager.swift`

## Starter queries

- Where is serving rotation logic enforced in UI vs core?
- Where do score changes persist to storage?
- How does the timer interact with save checkpoints?

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
