# Live Game Manager Implementation Plan (iOS)

## Summary

- **Goal**: Implement and integrate a standardized game start configuration flow so `LiveGameStateManager` receives `gameType`, `teamSize` (singles/doubles), and selected participants (players/teams), and powers `LiveView`/`ActiveGamePreviewBar` consistently on iOS.
- **Result**: New games are created via a single configuration contract at composition time; existing games continue to be resumed with `setCurrentGame(_:)`. UI reads live state (type, score, participants, timer) from the manager via environment.
- **Naming requirement**: The Live Game Manager remains `LiveGameStateManager` in the `Core` SPM product and is imported as `import Core` by platform targets.

## Scope & References

- **Targets**: `PickleballGameTracker` (iOS)
- **Packages**: `PickleballGameTrackerCorePackage` (product: `Core`), `PickleballGameTrackerPackage`
- **Project docs**:
  - Wiki: `features/games.md`, `features/active-game.md`, `features/player-team-management.md`
  - Wiki: `systems/runtime/live-game-manager.md`, `systems/runtime/state-management.md`, `architecture/overview.md`
  - This repo: `CORE_INTEGRATION_PLAN.md` (reference structure)
- **Apple docs**:
  - SwiftUI App and environment: [SwiftUI App](https://developer.apple.com/documentation/swiftui/app), [Environment](https://developer.apple.com/documentation/swiftui/environment)
  - SwiftUI async lifecycle: [.task](<https://developer.apple.com/documentation/swiftui/view/task(_:priority:_)>)
  - Haptics (SwiftUI): [SensoryFeedback](https://developer.apple.com/documentation/swiftui/sensoryfeedback)

---

## Current State (as scanned)

- iOS roots inject container and live manager; features consume via `@Environment`:

```swift
AppNavigationView()
  .modelContainer(SwiftDataContainer.shared.modelContainer)
  .environment(LiveGameStateManager.production())
```

- `AppNavigationView` provides `SwiftDataGameManager` via environment; features consume via `@Environment`.
- `LiveView` consumes `LiveGameStateManager` and currently uses `.task { activeGameStateManager.setCurrentGame(game) }` when an existing `Game` is provided.
- `ActiveGamePreviewBar` reads `currentGameTypeDisplayName`, `currentScore`, `currentGameTypeIcon`, and tints from the manager to render the inline/expanded bar.
- Game creation today: the presenter assembles or fetches a `Game` then presents `LiveView(game: ...)`. We need to centralize "new game creation" in `LiveGameStateManager` via a configuration contract.

---

## Required Updates

### Core (LiveGameStateManager)

- Add a game start configuration contract (conceptual types shown):
  - `struct GameStartConfiguration { gameType: GameType, teamSize: TeamSize, participants: Participants, notes: String? }`
  - `enum TeamSize { case singles, doubles }`
  - `struct Participants { side1: Participant, side2: Participant } // players or teams`
- Add/confirm manager APIs:
  - `func startNewGame(with config: GameStartConfiguration) async throws -> Game`
  - Keep `func setCurrentGame(_ game: Game)` for resuming existing games
- Ensure manager exposes UI-facing computed properties used by iOS components:
  - `currentGameTypeDisplayName`, `currentGameTypeIcon`, `currentGameTypeColor`
  - `currentScore` (formatted), `formattedElapsedTime[WithCentiseconds]`, `isGameActive`, `isTimerRunning`
  - Participant display strings and team tint helpers that match existing UI usage
- Enforce invariants at configuration time:
  - Team size compatibility with `gameType`
  - Participant count/shape matches `teamSize`
- Telemetry/haptics: continue logging serve/score events; trigger serve-change haptics on serving transitions.

### iOS

- Composition flow (Games → Start):
  - After selecting a game type, prompt for `teamSize` if the type supports multiple options.
  - Present participant pickers appropriate to `teamSize` (two players for singles; two teams for doubles).
  - Build `GameStartConfiguration` and call `await liveManager.startNewGame(with:)`.
  - Present `LiveView(game: createdGame, gameManager: swiftDataGameManager)` after successful creation.
- `LiveView` remains responsible for resuming an existing game via `.task { setCurrentGame(game) }`. For new games, the presenter passes the just-created `Game`.
- `ActiveGamePreviewBar` should continue to consume manager properties; verify names and availability match what UI reads today.
- Error surfaces: show non-blocking alerts/toasts if configuration or creation fails; avoid blocking spinners.
- Previews: extend `Core.PreviewEnvironment` scaffolding to include a sample `GameStartConfiguration` to demonstrate configured states, and randomly assign players or teams to live games so GameTrackerFeature previews can display participant names.

---

## SwiftUI and Concurrency Guidance (Apple‑aligned)

- Use `.task` for lifecycle-tied async work in presenters/composition; avoid `Task {}` in `.onAppear`.
- Keep UI isolated to `@MainActor`; route data mutations through `LiveGameStateManager` → `SwiftDataGameManager`.
- Inject environment services once at app/composition roots; do not construct managers inside leaf views.

---

## Concrete Actions

1. Core: Define `GameStartConfiguration`, `TeamSize`, and `Participants` (or equivalent) in `Core`.
2. Core: Implement `LiveGameStateManager.startNewGame(with:)` and validate invariants; persist initial `Game` via `SwiftDataGameManager`.
3. Core: Ensure/rename UI-facing computed properties consumed by `ActiveGamePreviewBar` and `LiveView` (type name/icon/color, score, participants, timer formatting).
4. iOS: In the game start coordinator (Games detail/start actions), collect `teamSize` and participants, build config, and call `startNewGame(with:)`.
5. iOS: Present `LiveView(game:createdGame, gameManager: ...)` on success; surface typed errors non-blocking on failure.
6. iOS: Verify `ActiveGamePreviewBar` reflects configured type/participants and continues to tint by team using manager helpers.
7. Previews: Add preview scenarios for configured singles and doubles games using `Core.PreviewEnvironment`, and update `PreviewEnvironment` to randomly assign players (singles) or teams (doubles) to live games so GameTrackerFeature previews render participant names.
8. Telemetry/Haptics: Confirm logs and serve-change haptics fire on serving transitions driven by configuration.
9. (Removed testing tasks)
10. (Removed testing tasks)

---

## Acceptance Criteria

- New games are created solely via `LiveGameStateManager.startNewGame(with:)` using a configuration containing `gameType`, `teamSize`, and participants.
- `LiveView` resumes existing games with `setCurrentGame(_:)`; for new games, the created `Game` is passed in.
- `ActiveGamePreviewBar` shows the configured game type and participant names, with correct team tints.
- No concurrency warnings; all UI mutations are on `@MainActor`; all persistence via `SwiftDataGameManager`.
- Preview scenarios compile and render configured singles and doubles games.
- Core and feature tests covering configuration validity and initial live state pass.

---

## Notes

- Keep the UI responsive: prefer non-blocking surfaces and fast creation paths; defer heavy computation to background tasks with proper `MainActor.run` bridges for UI updates.
- If legacy entry points still create `Game` directly, add a deprecation pathway that forwards to `startNewGame(with:)` or keep a single code path under the manager.

## Naming and Codebase Renaming: Active → Live (GameTrackerFeature)

### Scope

- Package: `PickleballGameTrackerPackage`
- Path: `Pickleball Game Tracker/PickleballGameTrackerPackage/Sources/GameTrackerFeature/**`
- Goal: Replace all user-facing and type identifiers using “Active Game” with “Live Game”.

### Inventory and targets

- Files to rename (examples):
  - `App/Navigation/Components/ActiveGamePreviewBar.swift` → `LiveGamePreviewBar.swift`
  - Any other `ActiveGame*.swift` files within the iOS feature package
- Types to rename:
  - `InlineActiveGamePreviewBar` → `InlineLiveGamePreviewBar`
  - `ExpandedActiveGamePreviewBar` → `ExpandedLiveGamePreviewBar`
  - `ActiveGamePreviewBar` → `LiveGamePreviewBar`
- Accessibility identifiers:
  - `ActiveGamePreviewBar.inline.button` → `LiveGamePreviewBar.inline.button`
  - `ActiveGamePreviewBar.expanded.button` → `LiveGamePreviewBar.expanded.button`

### Steps

1. Find usages

```bash
rg --hidden -n "ActiveGame" "Pickleball Game Tracker/PickleballGameTrackerPackage/Sources/GameTrackerFeature"
```

2. Rename files

```bash
git mv "Pickleball Game Tracker/PickleballGameTrackerPackage/Sources/GameTrackerFeature/App/Navigation/Components/ActiveGamePreviewBar.swift" \
       "Pickleball Game Tracker/PickleballGameTrackerPackage/Sources/GameTrackerFeature/App/Navigation/Components/LiveGamePreviewBar.swift"
```

3. Rename symbols (Xcode refactor preferred)

- Use Xcode’s “Refactor → Rename” to update symbols and references project-wide for:
  - `InlineActiveGamePreviewBar` → `InlineLiveGamePreviewBar`
  - `ExpandedActiveGamePreviewBar` → `ExpandedLiveGamePreviewBar`
  - `ActiveGamePreviewBar` → `LiveGamePreviewBar`

4. Update accessibility identifiers

- Replace string literals:

```bash
rg --hidden -n "ActiveGamePreviewBar\." "Pickleball Game Tracker/PickleballGameTrackerPackage/Sources/GameTrackerFeature" \
  | cut -d: -f1 | sort -u | xargs -I{} sed -i '' 's/ActiveGamePreviewBar\./LiveGamePreviewBar\./g' {}
```

5. Fix imports/references

- Update all call sites and previews referencing the renamed types/files
- Ensure `@testable import` or module references in tests use new names

6. (Removed testing tasks)

### Acceptance criteria

- The package builds with zero rename-related errors
- All references to `ActiveGame` in GameTrackerFeature are migrated to `LiveGame`
- UI behavior is unchanged; preview bars and LiveView still present identically
