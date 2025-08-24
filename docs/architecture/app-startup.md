# App startup refactor — remove initialization splash and background sync

- Goal: Launch directly into `GameHomeView` with no blocking initialization UI; perform logging setup, store validation/recovery, and sync enablement in the background.
- Scope: iOS app root (`Pickleball_Score_TrackingApp.swift`) and related initialization surfaces; confirm watchOS remains instant with background logging/sync.
- Outcomes: Faster perceived launch, resilient background initialization, and clean logging with zero concurrency warnings.

## Summary

The current iOS startup gates UI on `InitializationView` while `initializeApp()` configures logging, validates SwiftData, and loads initial data. This task replaces the blocking splash with immediate navigation to `AppNavigationView`, moving initialization to a non‑blocking background task. Errors surface via structured logs and lightweight, non‑blocking UI (e.g., banner/toast) instead of a full‑screen error.

## Structure & key types

- iOS entry point: `Pickleball Score Tracking/App/Pickleball_Score_TrackingApp.swift`
- Initialization UI (to remove): `Pickleball Score Tracking/App/Initialization/InitializationView.swift`
- App shell: `Pickleball Score Tracking/App/Navigation/AppNavigationView.swift`
- Storage/runtime:
  - `SharedGameCore/Sources/SharedGameCore/Services/SwiftDataContainer.swift`
  - `SharedGameCore/Sources/SharedGameCore/Services/Logging/*`
  - `SharedGameCore/Sources/SharedGameCore/Services/ActiveGameStateManager.swift`
  - `SharedGameCore/Sources/SharedGameCore/Views/SyncStatusIndicator.swift` (optional, non‑blocking status)
- watchOS entry point (unchanged behavior): `Pickleball Score Tracking Watch App/App/Pickleball_Score_TrackingApp.swift`

## Behavioral changes

- Replace the conditional root that shows `InitializationView` with direct `AppNavigationView`.
- Kick off initialization in a background `task` at app root or in `AppNavigationView.onAppear`:
  - Configure `LoggingService` sinks.
  - Validate/recover SwiftData store (`SwiftDataContainer.validateAndRecoverStore`).
  - Fetch container diagnostics, log at debug.
  - Optionally pre‑warm queries in the background.
  - Enable device sync via `ActiveGameStateManager.setSyncEnabled(true)` once context is available.
- Error handling: log via `Log.error` and optionally present a non‑blocking banner/toast; do not block navigation.
- Remove `InitializationView` usage from iOS root; keep the file temporarily if previews are useful, or delete in a follow‑up cleanup.

## Deterministic commands

```bash
# iOS — build & tests (pinned destination)
cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && \
  xcodebuild -project "Pickleball Score Tracking.xcodeproj" \
  -scheme "Pickleball Score Tracking" \
  -destination "platform=iOS Simulator,name=iPhone 16" test

# watchOS — build (pinned destination) to ensure no regressions
cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && \
  xcodebuild -project "Pickleball Score Tracking.xcodeproj" \
  -scheme "Pickleball Score Tracking Watch App" \
  -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)" build
```

## Test touchpoints

- `Pickleball Score TrackingUITests/BasicSmokeUITests.swift` (cold launch → Games tab visible)
- `SharedGameCore/Tests/SharedGameCoreTests/SwiftDataIntegrationTests.swift` (container health)
- `SharedGameCore/Tests/SharedGameCoreTests/GameCoreTests.swift` (no regressions)

## Change impact

- iOS app root logic updates to decouple UI from initialization completion.
- Potential removal of `InitializationView`; if retained temporarily, it should not be referenced by app root.
- Logging and container validation occur post‑launch; ensure operations are safe and respect Swift 6.2 strict concurrency.
- watchOS unchanged; verify background logging setup remains non‑blocking.

## Risks and mitigations

- Risk: Early UI interacts with storage before validation completes.
  - Mitigation: `SwiftDataContainer.shared.modelContainer` must be usable immediately; validation runs in background, with degraded‑mode logging if needed.
- Risk: User sees errors that previously were gated.
  - Mitigation: Use non‑blocking banner/toast; log details.
- Risk: Concurrency issues.
  - Mitigation: Keep UI on `@MainActor`; use actors/services for background work; ensure types are `Sendable`.

## Validation checklist

- [ ] Cold launch shows `AppNavigationView` → `GameHomeView` immediately; no `InitializationView` appears.
- [ ] Logging sinks configured and app/storage diagnostics logged without blocking UI.
- [ ] SwiftData store validation/recovery runs in background; app remains responsive; no crashes.
- [ ] Sync enablement occurs in background once context available; optional status can be shown via `SyncStatusIndicator` without blocking.
- [ ] iOS and watchOS builds green on pinned destinations; tests pass; zero Swift 6.2 concurrency warnings.
