# Pickleball Score Tracking — Kanban Roadmap

- Purpose: A single source of truth for feature development planning that links to authoritative docs, keeps work organized by app version, and guides LLM agents to ship safely.
- Scope: Features and cross-cutting systems for iOS, watchOS, and `SharedGameCore`.
- Editing rule: This file is the only planning board. Keep details in `docs/architecture/*`, `docs/features/*`, and `docs/systems/*` and link to them from cards.
- Last updated: 2025-08-17

## How to use this board

1. Pick the correct version lane (v0.3, v0.6, v1.0).
2. Ensure the card meets the Definition of Ready (see `docs/systems/devx/roadmap-governance.md#definition-of-ready-dor`).
3. Move only the card(s) you are actively working on to In Progress (respect WIP limits).
4. Update the card’s Status, Notes, and Acceptance as you progress. Keep cards small (S/M/L/XL).
5. All implementation details live in linked docs/code. If scope changes, update the linked docs first, then reflect the card here.
6. When a card hits Done, ensure acceptance is met and all links are correct. Add a brief completion note.

## Board columns and rules

- Backlog: Approved work, ready to pick up next.
- In Progress (WIP ≤ 3 across all lanes): Actively developed. Keep scope tight.
- Blocked: Waiting on dependency or decision. Must list a clear unblocking step.
- In Review: Code and docs updated; validating builds/tests and UX.
- Done: Accepted against the version’s criteria; all cross-links valid.
- Parked: Deferred. Keep rationale and re-evaluate date.

Definition of Done (all must be true)

- Linked docs updated and lint-clean; acceptance checklist satisfied in the linked doc(s)
- iOS/watchOS build green with Swift 6.2 strict concurrency and no critical warnings
- Tests updated/passing where applicable
- Logging via `LoggingService` (no `print`)

## Card schema (copy for new work)

```roadmap-card
id: <version>.<sequence>               # e.g., 1.3 for v0.3 task group; 2.1 for v0.6; 3.4 for v1.0
title: <concise task name>
version: v0.3 | v0.6 | v1.0
area: iOS | watchOS | SharedGameCore | cross-cutting
status: Backlog | In Progress | Blocked | In Review | Done | Parked
priority: P0 | P1 | P2
size: S | M | L | XL
owners: <roles or names>
dependencies: [<card ids>]
links:
  docs: [paths under docs/*]
  code: [paths under app/* or SharedGameCore/*]
  commands:                       # deterministic commands (iOS & watchOS)
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking" -destination "platform=iOS Simulator,name=iPhone 16" test
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking Watch App" -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)" test
acceptance:
  - Criterion 1
  - Criterion 2
validation:
  refs:
    - docs/some-doc.md#validation-checklist
tests:
  touchpoints:
    - SharedGameCore/Tests/SomeSuite.swift
notes:
  - Brief context, decisions, or clarifications
```

Tag taxonomy

- tags: [ui, storage, sync, logging, testing, navigation, analytics, auth, players, teams, variations, statistics, history, active-game, watch]

Conventions

- IDs match version lanes: 1.x = v0.3, 2.x = v0.6, 3.x = v1.0
- Prefer one observable outcome per card. Split large efforts into sequential cards.
- Keep acceptance minimal but testable; point to authoritative checklists in linked docs.
- See `docs/systems/devx/chat-kickoff.md` for a step-by-step new-chat guide and `docs/systems/devx/build-and-ci.md` for deterministic commands.

---

## v0.3 Finalization Lane

### Backlog (v0.3)

Recommended starting points (low deps):

// (none at this time — see In Review/Done)

```roadmap-card
id: 1.29
title: Scan and reorganize SwiftUI views; apply component sizing guidance
version: v0.3
area: cross-cutting
status: Done
priority: P1
size: M
owners: iOS/watchOS engineering
links:
  docs:
    - docs/architecture/overview.md#project-structure-code-map
    - docs/systems/ux/design-system.md
  code:
    - Pickleball Score Tracking/App/**
    - Pickleball Score Tracking/Features/**
    - Pickleball Score Tracking/UI/**
    - Pickleball Score Tracking Watch App/App/**
    - Pickleball Score Tracking Watch App/Features/**
    - Pickleball Score Tracking Watch App/UI/**
  commands:
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking" -destination "platform=iOS Simulator,name=iPhone 16" build
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking Watch App" -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)" build
acceptance:
  - Views adhere to feature-first structure; unnecessary micro-components removed; worthy components extracted per sizing guidance
  - Shared elements live under `UI/Components/` only when reused across features; otherwise remain feature-scoped
  - iOS and watchOS builds succeed on pinned destinations with no new warnings
validation:
  refs:
    - docs/architecture/overview.md#project-structure-code-map
tests:
  touchpoints:
    - Pickleball Score TrackingUITests/BasicSmokeUITests.swift
notes:
  - Perform a pass across iOS and watchOS targets: collapse trivial headers (1–3 elements) back inline; extract complex cards (5+ elements and nested groups) to `Components/`. Ensure `DesignSystem` tokens are used throughout.
  - Completed: Promoted `GameOptionCard` to `UI/Components/GameOptionCard.swift`; removed feature-local duplicate; references remain valid. iOS build triggered; observed unrelated `SharedGameCore` protocol conformance error to be fixed separately.
  - Completed: Acceptance verified — iOS and watchOS builds/tests green on pinned simulators (watch UI test bundle skipped). Scans performed; consolidations applied where warranted; no over-generalization of feature-scoped components.
```

```roadmap-card
id: 1.26
title: Unify previews using shared PreviewData across iOS/watchOS
version: v0.3
area: cross-cutting
status: Done
priority: P1
size: S
owners: iOS/watchOS engineering
links:
  docs:
    - docs/architecture/overview.md#project-structure-code-map
    - docs/systems/ux/navigation.md
    - docs/systems/ux/previews.md
  code:
    - SharedGameCore/Sources/SharedGameCore/PreviewData.swift
    - Pickleball Score Tracking/Features/**
    - Pickleball Score Tracking Watch App/Features/**
  commands:
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking" -destination "platform=iOS Simulator,name=iPhone 16" test
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking Watch App" -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)" build
acceptance:
  - All SwiftUI previews reference a shared `PreviewData` source; per-file duplicated preview fixtures removed
  - iOS and watchOS previews render consistent Normal/Empty/Error variants where applicable
  - Builds/tests green on pinned destinations; no new warnings
validation:
  refs:
    - docs/architecture/overview.md#project-structure-code-map
    - docs/systems/ux/navigation.md#swiftui-preview-stability-guardrails
    - docs/systems/ux/previews.md#validation-checklist-must-meet-for-acceptance
tests:
  touchpoints:
    - Pickleball Score TrackingUITests/BasicSmokeUITests.swift
notes:
  - Consolidate preview macros to use the shared provider `SharedGameCore/PreviewData.swift` across platforms; remove any app‑level duplicate providers or make them thin wrappers that delegate to the shared provider only.
  - Completed: All previews now use `PreviewGameData` with in‑memory `.modelContainer(...)`; app‑level duplicate provider removed; iOS and watchOS builds succeeded on pinned simulators.
```

```roadmap-card
id: 1.27
title: Extract reusable leaf views and helpers into dedicated files per project organization
version: v0.3
area: cross-cutting
status: Backlog
priority: P1
size: M
owners: iOS/watchOS engineering
dependencies: [1.3]
links:
  docs:
    - docs/architecture/overview.md#project-structure-code-map
    - docs/systems/ux/previews.md
  code:
    - Pickleball Score Tracking/Features/**/Screens/*.swift
    - Pickleball Score Tracking/Features/**/Components/
    - Pickleball Score Tracking/UI/Components/
    - Pickleball Score Tracking Watch App/Features/**/Screens/*.swift
    - Pickleball Score Tracking Watch App/UI/Components/
  commands:
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking" -destination "platform=iOS Simulator,name=iPhone 16" build
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking Watch App" -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)" build
acceptance:
  - Top-level screen files no longer declare nested reusable `View` structs; extracted into `Components/` (feature) or `UI/Components/` (shared)
  - Generalized helpers (non-view) moved into their own files with clear names; no ad-hoc inline utilities in screens
  - Project tree aligns with documented structure; builds green on pinned destinations with no new warnings
validation:
  refs:
    - docs/architecture/overview.md#project-structure-code-map
    - docs/systems/ux/previews.md#validation-checklist-must-meet-for-acceptance
tests:
  touchpoints:
    - Pickleball Score TrackingUITests/BasicSmokeUITests.swift
notes:
  - Follow feature-first structure; keep views thin and route any business logic to `SharedGameCore` services.
```

```roadmap-card
id: 1.28
title: Refactor and adopt shared preview data provider across all previews
version: v0.3
area: cross-cutting
status: Done
priority: P0
size: M
owners: iOS/watchOS engineering
links:
  docs:
    - docs/systems/ux/previews.md
    - docs/architecture/overview.md#project-structure-code-map
  code:
    - SharedGameCore/Sources/SharedGameCore/PreviewData.swift
    - Pickleball Score Tracking/Features/**/Screens/*.swift
    - Pickleball Score Tracking Watch App/Features/**/Screens/*.swift
  commands:
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking" -destination "platform=iOS Simulator,name=iPhone 16" build
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking Watch App" -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)" build
acceptance:
  - Shared provider compiles against current SwiftData models and scenarios; no stale fields/relationships
  - All view previews in both app targets use the shared provider (or thin app wrappers that delegate to it)
  - Normal/Empty/Error preview variants present for key screens; builds green on pinned destinations
validation:
  refs:
    - docs/systems/ux/previews.md#validation-checklist-must-meet-for-acceptance
tests:
  touchpoints:
    - Pickleball Score TrackingUITests/BasicSmokeUITests.swift
notes:
  - Update provider scenarios to match current `Game`/`GameVariation` models; remove any stale or deprecated fields and fix compile errors.
  - Completed: Provider updated and consumed across iOS/watchOS previews; stale references fixed; pinned builds green. Removed app‑level `Infrastructure/Fixtures/PreviewData.swift`.
```

```roadmap-card
id: 1.25
title: Refactor app startup to remove initialization splash (background init)
version: v0.3
area: iOS
status: Backlog
priority: P0
size: S
owners: iOS engineering
links:
  docs:
    - docs/architecture/app-startup.md
  code:
    - Pickleball Score Tracking/App/Pickleball_Score_TrackingApp.swift
    - Pickleball Score Tracking/App/Navigation/AppNavigationView.swift
    - Pickleball Score Tracking/App/Initialization/InitializationView.swift
    - SharedGameCore/Sources/SharedGameCore/Services/SwiftDataContainer.swift
    - SharedGameCore/Sources/SharedGameCore/Services/Logging/
  commands:
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking" -destination "platform=iOS Simulator,name=iPhone 16" test
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking Watch App" -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)" build
acceptance:
  - Cold launch shows Games home immediately; no initialization screen appears
  - Logging and store validation/recovery occur in background with structured logs; UI remains responsive
  - Builds/tests green on pinned destinations; zero Swift 6.2 concurrency warnings
validation:
  refs:
    - docs/architecture/app-startup.md#validation-checklist
tests:
  touchpoints:
    - Pickleball Score TrackingUITests/BasicSmokeUITests.swift
    - SharedGameCore/Tests/SharedGameCoreTests/SwiftDataIntegrationTests.swift
notes:
  - Replace blocking `InitializationView` with background `task` at root/onAppear; surface errors via logs/toast, not full-screen gate.
```

```roadmap-card
id: 1.20
title: Consolidate and adopt Design System color tokens across iOS/watchOS
version: v0.3
area: cross-cutting
status: Done
priority: P0
size: M
owners: iOS/watchOS engineering
links:
  docs:
    - docs/systems/ux/design-system.md
  code:
    - SharedGameCore/Sources/SharedGameCore/DesignSystem.swift
    - Pickleball Score Tracking/**
    - Pickleball Score Tracking Watch App/**
  commands:
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking" -destination "platform=iOS Simulator,name=iPhone 16" test
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking Watch App" -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)" build
acceptance:
  - All hardcoded `Color.*` and `Color(._)` usages replaced by `DesignSystem.Colors` tokens/utilities where applicable
  - `GameType.color` routes through `DesignSystem.Colors.gameType(_)`
  - Stats and glass backgrounds use `containerFillSecondary/Tertiary` tokens
  - Builds green on pinned destinations; no visual regressions in core flows
validation:
  refs:
    - docs/systems/ux/design-system.md#validation-checklist
tests:
  touchpoints:
    - Pickleball Score TrackingUITests/BasicSmokeUITests.swift
    - SharedGameCore/Tests/SharedGameCoreTests/GameCoreTests.swift
notes:
  - Introduced `paused`, `containerFillSecondary/Tertiary`, rule tokens, and `gameType(_)` mapping; updated iOS/watchOS views to consume tokens. iOS & watchOS builds succeeded on pinned simulators. iOS test run earlier hit a simulator runner issue; compile remains green.
```

```roadmap-card
id: 1.21
title: Player creation & editing (iOS)
version: v0.3
area: iOS
status: Done
priority: P0
size: M
owners: iOS engineering
dependencies: [1.13, 1.18]
links:
  docs:
    - docs/features/player-team-management.md
  code:
    - Pickleball Score Tracking/Features/Roster/
    - SharedGameCore/Sources/SharedGameCore/Services/PlayerTeamManager.swift
  commands:
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking" -destination "platform=iOS Simulator,name=iPhone 16" test
acceptance:
  - New Player sheet flows: name required, optional icon/avatar, skill/hand, notes; persists via `PlayerTeamManager`
  - Edit Player sheet updates fields; lastModified refreshes; list auto-updates
  - Structured logs on create/update/cancel; no concurrency warnings; UI on @MainActor
validation:
  refs:
    - docs/features/player-team-management.md#validation-checklist
tests:
  touchpoints:
    - SharedGameCore/Tests/SharedGameCoreTests/SwiftDataIntegrationTests.swift
    - SharedGameCore/Tests/SharedGameCoreTests/PlayerTeamManagerTests.swift
notes:
  - Keep creation UI simple in v0.3; photo picking can be stubbed/optional; ensure accessibility labels and VoiceOver hints
  - Completed: Added `PlayerEditorView` for create/edit with validation and structured logs; wired into `RosterHomeView` (create/edit, archive). Updated `PlayerTeamManager.updatePlayer` to refresh state; added test for `lastModified`. iOS tests green; watchOS build/tests unaffected; SharedGameCore package tests green.
```

```roadmap-card
id: 1.22
title: Team creation, editing, and membership management (iOS)
version: v0.3
area: iOS
status: In Progress
priority: P0
size: M
owners: iOS engineering
dependencies: [1.13, 1.21]
links:
  docs:
    - docs/features/player-team-management.md
  code:
    - Pickleball Score Tracking/Features/Roster/
    - SharedGameCore/Sources/SharedGameCore/Services/PlayerTeamManager.swift
  commands:
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking" -destination "platform=iOS Simulator,name=iPhone 16" build
acceptance:
  - New Team sheet: name required; select existing players; persists via `createTeam`; list updates
  - Edit Team sheet: rename; add/remove members; lastModified refresh; suggestions render
  - Duplicate team detection prompts using `findDuplicateTeams`; structured logs
validation:
  refs:
    - docs/features/player-team-management.md#validation-checklist
tests:
  touchpoints:
    - SharedGameCore/Tests/SharedGameCoreTests/SwiftDataIntegrationTests.swift
    - SharedGameCore/Tests/SharedGameCoreTests/PlayerTeamManagerTests.swift
notes:
  - Member picker can reuse simple multiselect from in-memory list; ensure stable IDs and lazy containers
```

```roadmap-card
id: 1.23
title: Roster UX polish: duplicate merge, archive/restore, preset hook
version: v0.3
area: iOS
status: Backlog
priority: P1
size: S
owners: iOS engineering
dependencies: [1.21, 1.22]
links:
  docs:
    - docs/features/player-team-management.md
  code:
    - Pickleball Score Tracking/Features/Roster/
    - SharedGameCore/Sources/SharedGameCore/Services/PlayerTeamManager.swift
  commands:
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking" -destination "platform=iOS Simulator,name=iPhone 16" build
acceptance:
  - Duplicate merge UX for players and teams using manager `merge*` APIs; logs success/failure
  - Archive/restore swipe actions; queries exclude archived by default; lists update
  - Quick action on team row: "Use in preset…" opens `PresetPickerView` with team prefilled
validation:
  refs:
    - docs/features/player-team-management.md#validation-checklist
tests:
  touchpoints:
    - SharedGameCore/Tests/SharedGameCoreTests/SwiftDataIntegrationTests.swift
notes:
  - Keep flows lightweight; defer complex conflict UI to v0.6 sync work
```

```roadmap-card
id: 1.3
title: Adopt feature-first project organization
version: v0.3
area: cross-cutting
status: Done
priority: P0
size: M
owners: iOS/watchOS engineering
links:
  docs:
    - docs/architecture/overview.md#project-structure-code-map
  code:
    - Pickleball Score Tracking/**
    - Pickleball Score Tracking Watch App/**
  commands:
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking" -destination "platform=iOS Simulator,name=iPhone 16" test
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking Watch App" -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)" build
acceptance:
  - iOS/watchOS targets follow the documented structure; no files left under legacy `Views/` roots
  - Builds/tests green on pinned destinations; no new warnings
validation:
  refs:
    - docs/architecture/overview.md#project-structure-code-map
tests:
  touchpoints:
    - Pickleball Score TrackingUITests/BasicSmokeUITests.swift
notes:
  - Completed: Removed empty legacy `Views/` root in iOS target; verified all UI files live under `App/`, `Features/`, or `UI/`. iOS tests passed on iPhone 16; watchOS build succeeded on Apple Watch Series 10 (46mm). No new warnings.
```

```roadmap-card
id: 1.4
title: Enforce serving rotation in active game UI
version: v0.3
area: cross-cutting
status: Done
priority: P0
size: M
owners: iOS/watchOS engineering
links:
  docs:
    - docs/features/active-game.md
  code:
    - Pickleball Score Tracking/Features/ActiveGame/Screens/ActiveGameView.swift
    - Pickleball Score Tracking Watch App/Features/ActiveGame/Screens/WatchActiveGameView.swift
    - SharedGameCore/Sources/SharedGameCore/Services/ActiveGameStateManager.swift
  commands:
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking" -destination "platform=iOS Simulator,name=iPhone 16" test
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking Watch App" -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)" -skip-testing:"Pickleball Score Tracking Watch AppUITests" test
acceptance:
  - UI enforces legal server/order transitions based on variation settings
  - Tests cover rotation across common variations
  - No concurrency warnings; logs emitted on state transitions
validation:
  refs:
    - docs/features/active-game.md#validation-checklist
tests:
  touchpoints:
    - SharedGameCore/Tests/SharedGameCoreTests/ActiveGameStateManagerTests.swift
    - Pickleball Score TrackingTests/Pickleball_Score_TrackingTests.swift
notes:
  - UI enforcement added: serving controls disabled during play; serving-player adjustments gated to paused state (`ActiveGameToolbar`, `TeamScoreCard`). Core rules validated via manager-level tests; iOS tests green; watchOS tests green with UI test bundle excluded; strict concurrency clean.
```

```roadmap-card
id: 1.5
title: Enforce side switching at configured intervals
version: v0.3
area: cross-cutting
status: Done
priority: P1
size: S
owners: iOS/watchOS engineering
links:
  docs:
    - docs/features/active-game.md
  code:
    - Pickleball Score Tracking/Features/ActiveGame/Components/ServeBezel.swift
    - SharedGameCore/Sources/SharedGameCore/Services/ActiveGameStateManager.swift
  commands:
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking" -destination "platform=iOS Simulator,name=iPhone 16" test
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking Watch App" -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)" test
acceptance:
  - Side switching is applied automatically when rule triggers
  - Visual cue and optional haptic feedback on switch
validation:
  refs:
    - docs/features/active-game.md#validation-checklist
tests:
  touchpoints:
    - SharedGameCore/Tests/SharedGameCoreTests/ActiveGameStateManagerTests.swift
notes:
  - Keep logic in core; UI renders state and effects
  - Completed: Side switching enforced via `Game.nextServer` using `GameVariation.sideSwitchingRule`; `SwiftDataGameManager` emits `.sidesSwitched` and triggers haptics; iOS `ServeBezel` shows side label with pulse animation on change. iOS unit + UI tests green; watchOS build green.
```

```roadmap-card
id: 1.6
title: Integrate structured logging for key user actions
version: v0.3
area: cross-cutting
status: Done
priority: P1
size: S
owners: iOS/watchOS engineering
links:
  docs:
    - docs/systems/observability/logging.md
  code:
    - SharedGameCore/Sources/SharedGameCore/Services/Logging/*
    - Pickleball Score Tracking/App/**
    - Pickleball Score Tracking/Features/**
    - Pickleball Score Tracking/UI/**
    - Pickleball Score Tracking Watch App/Features/**
  commands:
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking" -destination "platform=iOS Simulator,name=iPhone 16" test
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking Watch App" -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)" test
acceptance:
  - Start/pause/reset/end, score changes, navigation events emit structured logs
  - No raw print statements in app targets
validation:
  refs:
    - docs/systems/observability/logging.md#validation-checklist
tests:
  touchpoints:
    - SharedGameCore/Tests/SharedGameCoreTests/HapticFeedbackServiceTests.swift
    - SharedGameCore/Tests/SharedGameCoreTests/GameCoreTests.swift
notes:
  - Route via `OSLogSink` and `ConsoleSink` per environment
  - Replaced raw prints in app targets (iOS/watchOS) and core with `LoggingService`; builds/tests green
  - Acceptance satisfied: start/pause/reset/end, score changes, navigation logs present; no app-target prints
```

```roadmap-card
id: 1.7
title: Implement deep linking (local resolver and routes)
version: v0.3
area: cross-cutting
status: Done
priority: P1
size: S
owners: Shared core + iOS
links:
  docs:
    - docs/systems/ux/deep-linking.md
    - docs/systems/ux/navigation.md
  code:
    - SharedGameCore/Sources/SharedGameCore/Services/
  commands:
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking" -destination "platform=iOS Simulator,name=iPhone 16" test
acceptance:
  - URL parsing resolves to typed destinations for game types, authors, and completed games
  - Time-limited token query param parsed (validation can be local-stubbed for v0.3)
  - Unit tests cover parser happy/edge paths
validation:
  refs:
    - docs/systems/ux/deep-linking.md#validation-checklist
    - docs/systems/ux/navigation.md#validation-checklist
tests:
  touchpoints:
    - SharedGameCore/Tests/SharedGameCoreTests/DeepLinkResolverTests.swift
notes:
  - Implemented resolver with `.statistics` support; app root presents destinations and switches to Statistics. Tests added for path/query variants; SharedGameCore tests green. Universal link hosting/token validation remains for v0.6.
```

```roadmap-card
id: 1.8
title: Add preview stability guardrails for navigation and history
version: v0.3
area: iOS
status: Done
priority: P0
size: S
owners: iOS engineering
links:
  docs:
    - docs/systems/ux/navigation.md  # guardrails section
    - docs/features/history.md       # preview stability section
  code:
    - Pickleball Score Tracking/Features/History/Screens/GameHistoryView.swift
    - Pickleball Score Tracking/Features/History/Components/*
  commands:
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking" -destination "platform=iOS Simulator,name=iPhone 16" build
acceptance:
  - Docs include stable-id rule, single scroll owner, destination placement guidance
  - History groups use stable ids; no nested lazy stacks/scrolls in previews
  - Preview renders without recursion on `GameHistoryView`
validation:
  refs:
    - docs/systems/ux/navigation.md#swiftui-preview-stability-guardrails
    - docs/features/history.md#preview-stability-guardrails
notes:
  - Guardrails documented and verified: `GameHistoryView` attaches destinations at stack level; `GameHistoryContent`/`GameHistoryGroupedList` use stable IDs and `VStack` for child sections; iOS build green.
```

```roadmap-card
id: 1.9
title: Statistics Overview and Detail scaffolding
version: v0.3
area: iOS
status: Done
priority: P0
size: M
owners: iOS engineering
dependencies: [1.10]
links:
  docs:
    - docs/features/statistics.md
    - docs/features/completed-game-view.md
  code:
    - Pickleball Score Tracking/Features/Statistics/Screens/StatisticsHomeView.swift
    - Pickleball Score Tracking/App/Navigation/AppNavigationView.swift
    - Pickleball Score Tracking/App/Navigation/NavigationTypes.swift
  commands:
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking" -destination "platform=iOS Simulator,name=iPhone 16" test
acceptance:
  - Overview screen renders grouped stat cards (scaffold groups: Results, Serving, Trends, Streaks)
  - Tapping a card navigates to a per‑stat Detail view (empty chart placeholders acceptable at this stage)
  - Deep link from Completed Game opens the appropriate Detail with filters applied (route-only; placeholder data acceptable)
validation:
  refs:
    - docs/features/statistics.md#validation-checklist
tests:
  touchpoints:
    - SharedGameCore/Tests/SharedGameCoreTests/GameCoreTests.swift
notes:
  - Implemented grouped Overview with `StatCard`s for Results/Serving/Trends/Streaks in `StatisticsHomeView`, wired `NavigationStack` destinations to placeholder Detail views (`WinRateDetailView`, `ServeWinDetailView`, `TrendsDetailView`, `StreaksDetailView`). Programmatic navigation to default Results detail (Win Rate) activates when opened via deep link with pre‑applied filters. iOS tests green on iPhone 16.
```

```roadmap-card
id: 1.16
title: Implement Statistics deep-link router and filter plumbing
version: v0.3
area: iOS
status: Done
priority: P0
size: S
owners: iOS engineering
dependencies: [1.9]
links:
  docs:
    - docs/features/statistics.md
    - docs/features/completed-game-view.md
    - docs/systems/ux/deep-linking.md
  code:
    - Pickleball Score Tracking/App/Navigation/AppNavigationView.swift
    - Pickleball Score Tracking/App/Navigation/NavigationTypes.swift
    - Pickleball Score Tracking/Features/Statistics/Screens/
  commands:
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking" -destination "platform=iOS Simulator,name=iPhone 16" test
acceptance:
  - `StatisticsDeepLinkRouter` routes to the correct per‑stat Detail and applies filters (gameId/gameTypeId)
  - In-app `.statistics` deep-link requests and URLs switch to the Statistics tab and open the correct Detail without an intermediate sheet
validation:
  refs:
    - docs/features/statistics.md#validation-checklist
    - docs/features/completed-game-view.md#validation-checklist
tests:
  touchpoints:
    - SharedGameCore/Tests/SharedGameCoreTests/DeepLinkResolverTests.swift
notes:
  - Deep-link flow completed: `DeepLinkResolver` supports stats routes and query params; in-app and URL deep links set `statisticsFilter` and switch to the Statistics tab without an intermediate sheet. Default per‑stat target is Win Rate (Results) for v0.3 per docs. Added lightweight `StatisticsDeepLinkRouter` placeholder for non‑tab sheet presentation paths; filters applied end‑to‑end. iOS tests green on iPhone 16.
```

```roadmap-card
id: 1.10
title: Add Completed Game detail view from History
version: v0.3
area: iOS
status: Done
priority: P0
size: M
owners: iOS engineering
links:
  docs:
    - docs/features/history.md
    - docs/features/completed-game-view.md
  code:
    - Pickleball Score Tracking/Features/History/Screens/GameHistoryView.swift
    - Pickleball Score Tracking/Features/History/Components/*
  commands:
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking" -destination "platform=iOS Simulator,name=iPhone 16" test
acceptance:
  - Detail screen accessible from History list
  - Shows participants, scores, and summary metrics
  - Deep links into Statistics open with pre-applied filters (no intermediate sheet)
validation:
  refs:
    - docs/features/completed-game-view.md#validation-checklist
tests:
  touchpoints:
    - SharedGameCore/Tests/SharedGameCoreTests/GameCoreTests.swift
notes:
  - Deep-link action in `CompletedGameDetailView` posts `.statistics(gameId:gameTypeId:)`; `AppNavigationView` now routes directly to the Statistics tab with pre-applied filters. iOS tests green.
```

```roadmap-card
id: 1.12
title: Polish platform and performance
version: v0.3
area: cross-cutting
status: Done
priority: P2
size: S
owners: iOS/watchOS engineering
links:
  docs:
    - docs/systems/observability/testing-and-performance.md
  code:
    - Pickleball Score Tracking/**
    - SharedGameCore/Sources/SharedGameCore/**
  commands:
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking" -destination "platform=iOS Simulator,name=iPhone 16" build
acceptance:
  - Lazy stacks/lists where appropriate; stable IDs
  - No main-thread heavy work in view bodies
  - Build output shows no critical warnings
validation:
  refs:
    - docs/systems/observability/testing-and-performance.md#validation-checklist
notes:
  - Completed: Verified lazy containers and stable IDs in lists; no main-thread heavy work in view bodies.
  - Builds/tests green: iOS build succeeded; fast tests passed; Swift 6.2 strict concurrency clean.
```

### In Progress (WIP ≤ 3)

// (none)

### Blocked

// (none)

### In Review

// (none)

```roadmap-card
id: 1.13
title: Implement players and teams (models, CRUD, presets)
version: v0.3
area: cross-cutting
status: Done
priority: P1
size: L
owners: Shared core + iOS
links:
  docs:
    - docs/features/player-team-management.md
  code:
    - SharedGameCore/Sources/SharedGameCore/Models/
    - SharedGameCore/Sources/SharedGameCore/Services/
    - Pickleball Score Tracking/Features/
  commands:
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking" -destination "platform=iOS Simulator,name=iPhone 16" build
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking Watch App" -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)" build
acceptance:
  - CRUD flows for players and teams; presets bound to game types
  - Duplicate detection/merge; archive instead of hard delete; history maintains immutable references
validation:
  refs:
    - docs/features/player-team-management.md#validation-checklist
tests:
  touchpoints:
    - SharedGameCore/Tests/SharedGameCoreTests/SwiftDataIntegrationTests.swift
notes:
  - Implemented `PlayerProfile`, `TeamProfile`, `GameTypePreset`; added `PlayerTeamManager` with CRUD, duplicate detection, and merge (archive source, preserve history). Updated `SwiftDataContainer` schema. Added tests `PlayerTeamManagerTests` covering CRUD and merge flows. iOS and watchOS pinned tests succeeded; SharedGameCore tests passed.
```

```roadmap-card
id: 1.14
title: Decide statistics set and grouping for Overview
version: v0.3
area: cross-cutting
status: Done
priority: P0
size: S
owners: iOS/watchOS engineering + product
links:
  docs:
    - docs/features/statistics.md
  code:
    - (n/a — documentation and design decision)
  commands:
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking" -destination "platform=iOS Simulator,name=iPhone 16" build
acceptance:
  - Documented list of initial stats and grouped taxonomy in `docs/features/statistics.md` (Results, Serving, Trends, Streaks)
  - Decision on hard‑coded groups with dynamic intra‑group ordering and guarded inter‑group reordering — documented behavior
validation:
  refs:
    - docs/features/statistics.md#validation-checklist
notes:
  - Decisions captured under “Initial stats (v0.3)” and “Grouping and ordering policy (v0.3)”.
```

```roadmap-card
id: 1.15
title: Implement Statistics aggregation and Detail visualizations with deep-link filters
version: v0.3
area: iOS
status: Done
priority: P0
size: M
owners: Shared core + iOS
dependencies: [1.14]
links:
  docs:
    - docs/features/statistics.md
    - docs/features/completed-game-view.md
  code:
    - SharedGameCore/Sources/SharedGameCore/Services/
    - Pickleball Score Tracking/Features/Statistics/Screens/
  commands:
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking" -destination "platform=iOS Simulator,name=iPhone 16" -skip-testing:"Pickleball Score TrackingUITests" test
acceptance:
  - Aggregations for the decided initial stats computed and persisted on game save
  - Detail views render charts/tables using aggregations; filters work
  - Completed Game deep links open the correct Detail with filters applied
validation:
  refs:
    - docs/features/statistics.md#validation-checklist
tests:
  touchpoints:
    - SharedGameCore/Tests/SharedGameCoreTests/StatisticsAggregatorTests.swift
    - SharedGameCore/Tests/SharedGameCoreTests/SwiftDataIntegrationTests.swift
notes:
  - Implemented `GameSummary` model and persistence on save/update/delete. Aggregator computes win rate, 7/30‑day trends, point differential trend, and streaks (prefers summaries, falls back to games). Wired `WinRateDetailView`, `TrendsDetailView`, `StreaksDetailView`, and proxied `ServeWinDetailView`. iOS tests green on pinned simulator; SPM tests build and run.
```

```roadmap-card
id: 1.17
title: Completed Game actions — notes editor, share links, archive/restore, delete
version: v0.3
area: iOS
status: Done
priority: P0
size: M
owners: iOS engineering
links:
  docs:
    - docs/features/completed-game-view.md
    - docs/features/history.md
  code:
    - Pickleball Score Tracking/Features/History/Screens/CompletedGameDetailView.swift
    - SharedGameCore/Sources/SharedGameCore/Services/SwiftDataStorage.swift
    - SharedGameCore/Sources/SharedGameCore/Services/SwiftDataGameManager.swift
    - SharedGameCore/Sources/SharedGameCore/Models/Game.swift
  commands:
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking" -destination "platform=iOS Simulator,name=iPhone 16" -skip-testing:"Pickleball Score TrackingUITests" test
acceptance:
  - Notes editing persists and renders; basic validation and logging
  - Share action surfaces a time‑limited link param (locally stubbed) and logs share
  - Archive/restore toggles visibility (via `isArchived`); delete gated by confirmation
validation:
  refs:
    - docs/features/completed-game-view.md#validation-checklist
tests:
  touchpoints:
    - SharedGameCore/Tests/SharedGameCoreTests/SwiftDataIntegrationTests.swift
notes:
  - Implemented `Game.isArchived`; storage queries exclude archived; manager exposes archive/restore. CompletedGameDetailView uses ShareLink, archive/restore toggle, and delete confirmation. iOS build green on pinned simulator; tests run with UI tests skipped.
```

```roadmap-card
id: 1.18
title: Wire Players & Teams tab UI and preset start integration
version: v0.3
area: iOS
status: Done
priority: P1
size: M
owners: iOS engineering
dependencies: [1.13]
links:
  docs:
    - docs/features/player-team-management.md
    - docs/features/games.md
  code:
    - Pickleball Score Tracking/App/Navigation/AppNavigationView.swift
    - Pickleball Score Tracking/Features/
  commands:
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking" -destination "platform=iOS Simulator,name=iPhone 16" build
acceptance:
  - Players & Teams tab appears with list screens wired (placeholder rows acceptable if 1.13 UI not ready)
  - Game Detail actions include “Start from Preset” path that routes to preset selection/editor
validation:
  refs:
    - docs/features/player-team-management.md#validation-checklist
notes:
  - Completed: Added `Roster` tab in `AppNavigationView` rendering placeholder Players/Teams lists via `PlayerTeamManager` with navigation to placeholder detail screens (`RosterHomeView`). Implemented `PresetPickerView` and wired "Start from Preset" in `GameDetailView` to open the picker and start with preset defaults. iOS build/tests green on pinned simulator; watch build unaffected.
```

### Done

```roadmap-card
id: 1.1
title: Implement core models and storage
version: v0.3
area: SharedGameCore
status: Done
priority: P0
size: L
owners: Shared core
links:
  docs:
    - docs/systems/data/persistence.md
    - docs/systems/data/storage.md
  code:
    - SharedGameCore/Sources/SharedGameCore/Models/*
    - SharedGameCore/Sources/SharedGameCore/Services/SwiftDataStorage*.swift
acceptance:
  - Games save/load; protocol-driven storage in place; tests pass
notes:
  - Foundation ready for players/teams (v0.6)
```

```roadmap-card
id: 1.2
title: Implement game scoring UI for iOS and watchOS
version: v0.3
area: iOS/watchOS
status: Done
priority: P0
size: L
owners: iOS/watchOS engineering
links:
  docs:
    - docs/features/active-game.md
  code:
    - Pickleball Score Tracking/Features/ActiveGame/**
    - Pickleball Score Tracking Watch App/Features/ActiveGame/**
acceptance:
  - Real-time scoring works; basic completion flow; UX responsive
notes:
  - Enforcement gaps tracked in 1.4/1.5
```

---

## v0.6 Account Integration Lane

### Backlog (v0.6)

```roadmap-card
id: 2.1
title: Implement authentication UI
version: v0.6
area: iOS
status: Backlog
priority: P1
size: M
owners: iOS engineering
links:
  docs:
    - docs/implementation-roadmap.md  # Link back to board for status
  code:
    - (to be added)
  commands:
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking" -destination "platform=iOS Simulator,name=iPhone 16" build
acceptance:
  - Sign up/in/out flows; guest vs authenticated modes; error handling
validation:
  refs:
    - docs/architecture/iOS.md#validation-checklist
notes:
  - Depends on Supabase client (2.2)
```

```roadmap-card
id: 2.2
title: Implement Supabase client and schema
version: v0.6
area: SharedGameCore
status: Backlog
priority: P1
size: L
owners: Shared core
links:
  docs:
    - docs/architecture/shared-core.md
  code:
    - (to be added)
  commands:
    - mcp_XcodeBuildMCP_swift_package_build(packagePath: "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking/SharedGameCore")
acceptance:
  - Auth and DB connectivity; resilient error handling and retries
validation:
  refs:
    - docs/architecture/shared-core.md#validation-checklist
notes:
  - Establish typed API surface with `Sendable` DTOs
```

```roadmap-card
id: 2.3
title: Implement data migration service (local to cloud)
version: v0.6
area: cross-cutting
status: Backlog
priority: P0
size: L
owners: Shared core + iOS
dependencies: [2.2]
links:
  docs:
    - docs/systems/runtime/sync.md
    - docs/systems/data/storage.md
  code:
    - (to be added)
  commands:
    - mcp_XcodeBuildMCP_swift_package_build(packagePath: "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking/SharedGameCore")
acceptance:
  - Safe migration with progress, validation, and rollback
validation:
  refs:
    - docs/systems/runtime/sync.md#validation-checklist
    - docs/systems/data/storage.md#validation-checklist
notes:
  - Conflict resolution strategy documented in linked docs
```

<!-- Moved 2.6 to v0.3 as 1.13 -->

### Parked

```roadmap-card
id: 2.4
title: Implement cloud sync (automatic and manual)
version: v0.6
area: cross-cutting
status: Parked
priority: P2
size: L
owners: Shared core + iOS/watchOS
dependencies: [2.2, 2.3]
links:
  docs:
    - docs/systems/runtime/sync.md
acceptance:
  - Sync status indicators; offline-first behavior; conflict UI
validation:
  refs:
    - docs/systems/runtime/sync.md#validation-checklist
notes:
  - Re-evaluate after 2.2/2.3 land
```

---

## v1.0 Advanced Features Lane

### Backlog (v1.0)

```roadmap-card
id: 3.1
title: Implement realtime game synchronization
version: v1.0
area: cross-cutting
status: Backlog
priority: P1
size: XL
owners: Shared core + iOS/watchOS
links:
  docs:
    - docs/systems/runtime/sync.md
  code:
    - (to be added)
  commands:
    - mcp_XcodeBuildMCP_swift_package_build(packagePath: "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking/SharedGameCore")
acceptance:
  - Live updates across devices; conflict-free interactions; resilience
validation:
  refs:
    - docs/systems/runtime/sync.md#validation-checklist
notes:
  - Integrate with statistics and history without regressions
```

```roadmap-card
id: 3.5
title: Implement advanced statistics and analytics
version: v1.0
area: cross-cutting
status: Backlog
priority: P2
size: L
owners: Shared core + iOS
links:
  docs:
    - docs/features/statistics.md
  code:
    - (to be added)
  commands:
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking" -destination "platform=iOS Simulator,name=iPhone 16" build
acceptance:
  - Aggregations correct and performant; filterable views; tests
validation:
  refs:
    - docs/features/statistics.md#validation-checklist
notes:
  - Precompute summaries on save; paginate history queries
```

```roadmap-card
id: 3.6
title: Improve UX and accessibility
version: v1.0
area: cross-cutting
status: Backlog
priority: P2
size: M
owners: iOS/watchOS engineering
links:
  docs:
    - docs/systems/observability/testing-and-performance.md
  code:
    - (to be added)
  commands:
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking" -destination "platform=iOS Simulator,name=iPhone 16" build
acceptance:
  - Accessibility checks pass; animations refined; performance budgets met
validation:
  refs:
    - docs/systems/observability/testing-and-performance.md#validation-checklist
notes:
  - Track metrics in CI once available
```

```roadmap-card
id: 1.24
title: Roster view polish — empty state, add menu, brand background
version: v0.3
area: iOS
status: Done
priority: P2
size: S
owners: iOS engineering
links:
  docs:
    - docs/features/player-team-management.md
  code:
    - Pickleball Score Tracking/Features/Roster/Screens/RosterHomeView.swift
    - Pickleball Score Tracking/UI/Components/CustomContentUnavailableView.swift
  commands:
    - cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking" -destination "platform=iOS Simulator,name=iPhone 16" build
acceptance:
  - When no players and teams, `RosterHomeView` shows `CustomContentUnavailableView` card at top
  - Roster navigation background uses brand gradient (orange→transparent) via `navigationBrandGradient`
  - Toolbar menu (plus) exposes actions: New Player, New Team; actions log via `LoggingService`
  - Previews include Empty and With Players/Teams; build green on pinned simulator
validation:
  refs:
    - docs/features/player-team-management.md#validation-checklist
notes:
  - Implemented empty-state card, top-aligned layout, navigation gradient background, and trailing add menu. Logged actions only; creation/editing UIs deferred to tasks 1.21–1.23. iOS build verified on iPhone 16.
```

---

## Agent workflow quickstart

- Start here: Find a Backlog card in your version lane, confirm dependencies, and move it to In Progress.
- Update docs first: If behavior or architecture changes, update `docs/*` before code; then commit code and return here.
- Keep one focus: Stay under WIP limits. Prefer completing a card before starting another.
- Close the loop: When done, ensure builds/tests are green and acceptance criteria are met. Move card to Done and add a one-line completion note.

Automatic selection (when you say "start a new task")

- Lane: Uses the active version lane in focus (default v0.3) unless specified.
- Rule: Picks Backlog cards with all dependencies Done, ordered by priority (P0→P1→P2), then size (S→M→L→XL), then fewest dependencies, then lowest ID.
- WIP: If WIP is at limit, will propose finishing/parking an In Progress card first.

## Board index (by ID)

- v0.3: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 1.10, 1.11, 1.12, 1.13, 1.14, 1.15, 1.16, 1.17, 1.18, 1.21, 1.22, 1.23, 1.24, 1.25, 1.26, 1.27
- v0.3: 1.28, 1.29
- v0.6: 2.1, 2.2, 2.3, 2.4
- v1.0: 3.1, 3.5, 3.6
