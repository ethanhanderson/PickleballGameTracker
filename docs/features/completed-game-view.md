# Completed Game View

- **Document name**: Completed Game View
- **Category**: features
- **Area**: iOS (primary), watchOS (lightweight detail)

## Summary

- **Purpose**: Provide a rich, navigable record of a finished game with links into Statistics for deeper insight.
- **Scope**: Detail page from History cards; toolbar actions; deep links; infinite history loading behavior.
- **Outcome**: Users can review who played, how it unfolded, and jump into analytics.

## Audience & Owners

- **Audience**: engineers, testers, designers
- **Owners**: iOS/watchOS engineering
- **Last updated**: 2025-08-14
- **Status**: current
- **Version**: v0.3

## Architecture Context

- **Layer**: presentation (detail views) | domain (metrics summarization) | data (history store + cloud offload)
- **Entry points**: Tap a History card → Completed Game; optional watchOS compact detail
- **Dependencies**: `SharedGameCore` storage/managers, `DesignSystem`, Statistics feature
- **Data flow**: Fetch game + participants → compute simple stats → render; provide deep links with pre-applied filters

## Responsibilities

- **Core responsibilities**:
  - Show teams, players, scores, and simple stats (serve rotations, out/kitchen counts when available)
  - Provide buttons to view Game Type detail and open Statistics filtered to this game
  - Support notes; share (time-limited links: e.g., 1 hour, 1 day, 7 days, 30 days, indefinite); archive/restore; permanent delete
  - Keep history indefinitely while entities exist; implement infinite loading in History with 30-day local retention before offloading

## v0.3 routing and view

- History row tap navigates to a new `CompletedGameDetailView`.
- Detail shows participants, final scores, summary metrics (rallies, playing-to, server, side), and a Statistics action that posts a deep-link request targeting a specific Statistics Detail view with filters such as `gameId`/`gameTypeId` pre-applied.
- Logs navigation and action events; no heavy computation in the view (metrics derived from `Game`).

### Code anchors

- `Pickleball Score Tracking/Features/History/Screens/CompletedGameDetailView.swift` — detail view (Statistics deep-link action, notes editor, share, archive/restore, delete)
- `SharedGameCore/Sources/SharedGameCore/Services/SwiftDataGameManager.swift` — archive/restore/delete methods
- `SharedGameCore/Sources/SharedGameCore/Services/SwiftDataStorage.swift` — queries exclude archived games; search excludes archived

### Actions (v0.3)

- **Notes**: Inline editor with Save/Discard; trims whitespace; logs save.
- **Share**: `ShareLink` with local-stubbed, time-limited URL (`?t=local-stub`). Real token generation will land post‑account integration.
- **Archive/Restore**: Toggle backed by `Game.isArchived`. Archived games are excluded from default history queries.
- **Delete**: Destructive action with confirmation alert; removes game and its summary rows.

### Validation checklist (v0.3)

- Tapping a history row pushes Completed Game detail.
- Detail renders participants, scores, metrics; Statistics action logs and deep links open the correct per‑stat Statistics Detail with pre‑applied filters without an intermediate sheet.
- Notes save persists and logs; share uses a link with a time‑limited token param (stubbed); archive/restore updates visibility; delete gated by confirmation.
- No blocking operations in body; uses `DesignSystem` tokens.

## Structure & Key Types

- **Primary types**: `CompletedGameDetailView`, `ShareLink` usage, `SwiftDataGameManager` archive/restore/delete
- **File locations**: iOS views under `Pickleball Score Tracking/Features/History/*`; core models in shared package
- **Initialization**: Navigated from `GameHistoryView` card tap

## Platform Sections (use as needed)

- **iOS**: Full detail with sections (Overview, Participants, Stats, Notes, Actions)
- **watchOS**: Compact summary with link to Stats tab defaults

## Data & Persistence

- **Models**: Completed `Game` with `isArchived` flag and `notes` text; simple metrics persisted during play
- **Container**: Standard app container; history offloaded after 30 days; fetch older games from database on demand
- **Storage**: Archive instead of delete players; maintain referential integrity

## State & Concurrency

- **UI isolation**: `@MainActor` views
- **Observable state**: Notes editor; share action; archive/restore and delete confirmation
- **Actors/Sendable**: Share tokens/links as value types; background fetch for infinite scroll

## Navigation & UI

- **Patterns**: History list → Completed Game → actions to Game Type detail / Stats; deep link builder applies filters
- **Destinations**: Game Type detail, Statistics tab (pre-filtered)
- **Components**: Stat rows, participants list, notes editor, share action, archive/restore, delete
- **Design System**: Consistent cards, colors by stat type

## Systems Integration

- **Logging**: View impressions; notes saves; share; archive/restore; delete
- **Sync**: Local records mirrored to cloud later; share links respect privacy
- **Haptics**: Feedback on archive/restore and share

## Error Handling

- **Typed errors**: Notes save, delete, storage operations
- **User surfaces**: Non-blocking alerts where appropriate; confirmation for delete

## Testing & Performance

- **Tests**: Notes persistence; share stub wiring; archive/restore visibility; deep link filters; delete flow
- **Performance**: Efficient fetch descriptors; no heavy work in view bodies

## Open Questions & Future Work

- **Gaps**: Attachment support; richer timelines of points
- **Planned extensions**: Timeline visualization; export PDF/snapshot; real share policy controls

## References

- **Code**:
  - Pickleball Score Tracking/Features/History/Screens/CompletedGameDetailView.swift
  - SharedGameCore/Sources/SharedGameCore/Services/SwiftDataStorage.swift
  - SharedGameCore/Sources/SharedGameCore/Services/SwiftDataGameManager.swift
- **Related docs**: `docs/features/history.md`, `docs/features/statistics.md`, `docs/systems/data/persistence.md`, `docs/systems/ux/deep-linking.md`

## Code path anchors

- `Pickleball Score Tracking/Features/History/Screens/CompletedGameDetailView.swift`
- `SharedGameCore/Sources/SharedGameCore/Services/SwiftDataStorage.swift`
- `SharedGameCore/Sources/SharedGameCore/Services/SwiftDataGameManager.swift`

## Starter queries

- How are archive/restore and delete wired from the view into the manager?
- How do storage queries exclude archived games from default history?

## Validation checklist (must meet for acceptance)

- **Swift 6.2 strict; iOS 17+ / watchOS 11+ targets** respected; no concurrency warnings
- **UI on `@MainActor`**; shared types are **`Sendable`**; actor boundaries clear
- **Modern SwiftUI**: `NavigationStack`, `@Observable`/`@Bindable`
- **DesignSystem-first**: no hardcoded colors/spacing/typography
- **SwiftData**: single app-level container; proper schema usage
- **Typed errors** with `LocalizedError` where user-visible
- **Tests**: notes, share stub, archive/restore, deep link filters, delete covered
