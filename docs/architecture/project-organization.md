# Project organization — feature-first, agent-friendly

Purpose: Define a deterministic, uniform file layout for iOS and watchOS that is easy to navigate, enforces thin-UI/strong-core separation, and optimizes LLM agent development speed. Inherits developer persona and Swift 6.2 rules; UI on @MainActor, business logic in `SharedGameCore`.

## Structure overview

Top-level targets follow the same shape. Keep names stable and feature scopes small.

```text
Pickleball Score Tracking/                    # iOS target root
  App/                                        # app entry, navigation, and app-scoped state
    Initialization/
    Navigation/
    State/
    Pickleball_Score_TrackingApp.swift
  Features/                                   # feature-first folders (Screens + Components)
    ActiveGame/
      Screens/
      Components/
    GameDetails/
      Screens/
      Components/
    GamesHome/
      Screens/
      Components/
    History/
      Screens/
      Components/
    Search/
      Screens/
      Components/
    Statistics/
      Screens/
  UI/                                         # shared UI elements not tied to a feature
    Components/
  Infrastructure/
    Fixtures/                                 # preview data, seed catalog, local fixtures only

Pickleball Score Tracking Watch App/          # watchOS target root
  App/
    Pickleball_Score_TrackingApp.swift
  Features/
    ActiveGame/
      Screens/
    GamesHome/
      Screens/
  UI/
    Components/
```

Notes

- Features own their `Screens` (entry points) and `Components` (reusable leaf views) to keep boundaries clear.
- App-scoped concerns live under `App/` only (initialization, navigation, cross-feature state). No business logic here.
- Shared UI that spans features goes under `UI/Components/` and must use tokens from `SharedGameCore/DesignSystem.swift`.
- Testable business logic remains in `SharedGameCore` (actors/services). App targets stay UI-only.

## Component sizing & reuse guidance (MUST)

- Prefer meaningful components over micro-components. Do not create separate files for trivial UI fragments.
- Too small (keep inline): simple header/section with ~1–3 lightweight elements (e.g., a `HStack` title + subtitle). Keeping these inline improves readability.
- Worth extracting (separate file): compositions with ~5+ visual elements and/or a few nested groups (e.g., a card with header, body rows, footers), or views reused across multiple screens/features, or views that encapsulate their own interactions/state.
- Scope: Extract to `Features/<Feature>/Components/` when feature-specific; promote to `UI/Components/` only when shared by multiple features.
- Avoid deep fragmentation. Aim for components that represent coherent, reusable chunks—not every `HStack`/`VStack`.

## Naming and code layout rules (enforced)

- Screen files end with `View` and live under `Features/<Feature>/Screens/`.
- Reusable leaf views live under `Features/<Feature>/Components/` or `UI/Components/`. Do not extract micro-components that fail the sizing guidance above.
- App bootstrap files live under `App/` (e.g., `Pickleball_Score_TrackingApp.swift`).
- No SwiftData `ModelContainer` initialization outside app root. Views use `@Environment(\.modelContext)` and `@Query`.
- UI types and updates are `@MainActor`. Shared mutable state is isolated in `SharedGameCore` actors.
- Errors are typed (`Error & Sendable`); user-facing errors adopt `LocalizedError`.
- Logging uses `LoggingService` (no `print`).

## Deterministic commands

- iOS (pinned):
  - `cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking" -destination "platform=iOS Simulator,name=iPhone 16" test`
- watchOS (pinned):
  - `cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking Watch App" -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)" build`

## Change impact

- iOS: View files are grouped by feature with consistent `Screens/Components` split; navigation/state moved under `App/`.
- watchOS: Mirrors iOS structure with a smaller feature set (ActiveGame, GamesHome). Future features (e.g., History) follow the same pattern.
- Xcode project uses file-system synchronized groups; physical moves are reflected automatically. No module names or targets changed.

## Test touchpoints

- Existing suites remain valid; add tests only when feature boundaries change behavior in `SharedGameCore` or navigation.
- Prefer integration tests in `SharedGameCore/Tests/*` for logic and minimal UI smoke tests for screen wiring.

## Validation checklist

- [ ] iOS builds and tests pass with pinned destination; no new warnings.
- [ ] watchOS build succeeds with pinned destination; no new warnings.
- [ ] All app UI files reside under `App/`, `Features/`, or `UI/` (no stray files under `Views/`).
- [ ] Shared UI components use `DesignSystem` (no hardcoded styling).
- [ ] No business logic in app targets; domain logic confined to `SharedGameCore`.
- [ ] Swift 6.2 strict concurrency clean; UI types isolated to `@MainActor`.
