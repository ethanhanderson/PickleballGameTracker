# Player & Team Management

- **Document name**: Player & Team Management
- **Category**: features
- **Area**: cross-cutting (iOS authoring; watchOS composition)

## Summary

- **Purpose**: Manage player profiles and teams; bind them to game types and presets to speed game creation.
- **Scope**: iOS can add/edit/delete (archive) players and teams; watchOS composes new teams from existing players and starts games from presets.
- **Outcome**: Faster, consistent setup with rich identity (avatars/icons) and safe history.

## Audience & Owners

- **Audience**: engineers, testers, designers
- **Owners**: iOS/watchOS engineering
- **Last updated**: 2025-08-15
- **Status**: implemented (v0.3)
- **Version**: v0.3

## Architecture Context

- **Layer**: presentation (management UIs) | domain (profiles/teams/presets) | data (local-first; cloud-ready)
- **Entry points**: iOS `Players & Teams` tab → Player/Team lists → Detail/Edit; iOS Game Detail actions → Start from Preset; watchOS catalog → Start Game sheet (Presets or New)
- **Dependencies**: `SharedGameCore` storage/managers, `DesignSystem`, logging, persistence
- **Data flow**: Create/edit/archive → persist → available in presets and start flows; history references archived players immutably

## Responsibilities

- **Core responsibilities**:
  - Player profiles: name (required); optional avatar (photo/library/files), icon (curated/SF Symbols/emoji + background), skill, preferred hand, notes
  - Teams: named collections of players (any length), optional avatar/icon/metadata; suggest recent compatible game types
  - Presets: bind players/teams to a specific game type; editable and local to user
  - WatchOS: compose teams from existing players; start from preset or pick players/teams
  - Duplicates & archival: merge/ignore duplicate players; archive players tied to history instead of hard-delete
- **Non-goals**:
  - Public sharing of players/teams (local to user)
  - Complex roster permissions

## Structure & Key Types

- **Primary types**: `PlayerProfile`, `TeamProfile`, `GameTypePreset`
- **File locations**: Core models/services under `SharedGameCore/Sources/SharedGameCore/*`; iOS tab views under `Pickleball Score Tracking/Views/...`
- **Initialization**: Managers expose CRUD; views bind via `@Environment(\.modelContext)` and observable state

## Platform Sections (use as needed)

- **iOS**: Full CRUD for players/teams; preset creation from Game Detail actions (preset is first button); duplicate merge tool; archive/restore players
- **watchOS**: Start sheet lists presets; or compose new team from existing players per game type requirements; no new player creation

## Data & Persistence

- **Models**: Player/Team with optional media and attributes; presets map to `GameType` IDs
- **Container**: Standard app container; schema forward-compatible with cloud
- **Storage**: Saved locally and mirrored to database in future; anonymous players allowed and persisted

## State & Concurrency

- **UI isolation**: `@MainActor` views
- **Observable state**: Lists with filters/search; edit forms with validation
- **Actors/Sendable**: Value types for identities; safe references from history

## Navigation & UI

- **Patterns**: Tab lists → detail/edit; Game Detail action group with “Start from Preset” first; watchOS catalog → play → sheet for presets or new
- **Destinations**: Player detail, Team detail, Preset editor, Merge duplicates
- **Components**: Avatar/icon pickers (photo/library/files/SF Symbols/emoji with color), compatibility suggestions for teams
- **Design System**: Use tokens; consistent cards/lists/forms

## Systems Integration

- **Logging**: CRUD and merge events; preset usage; anonymous player flags (non-PII)
- **Sync**: Local-first; mirror to cloud later; IDs stable for migration
- **Haptics**: Feedback on merges, saves, and start-from-preset

## Error Handling

- **Typed errors**: Validation, media import failures, merge conflicts; `LocalizedError`
- **User surfaces**: Inline field errors, conflict resolution sheets

## Testing & Performance

- **Tests**: CRUD flows; preset binding; duplicate detection/merge; archival references in history
- **Performance**: Lazy lists; debounce searches; efficient media handling

## Deterministic Commands

- iOS (pinned):
  - `cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking" -destination "platform=iOS Simulator,name=iPhone 16" test`
- watchOS (pinned):
  - `cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking Watch App" -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)" test`

## Test touchpoints

- Extend: `SharedGameCore/Tests/SharedGameCoreTests/SwiftDataIntegrationTests.swift`
- New (as needed): Player/Team CRUD, preset binding, duplicate merge scenarios
- Added: `SharedGameCore/Tests/SharedGameCoreTests/PlayerTeamManagerTests.swift`

## Change impact

- **Affected modules**: SharedGameCore, iOS
- **Risks & mitigations**:
  - Concurrency across actors when mutating storage → isolate via `SwiftDataGameManager` APIs
  - Data integrity during merges → deterministic rules; tests cover edge cases

## Open Questions & Future Work

- **Gaps**: Automatic duplicate detection heuristics; team compatibility scoring
- **Planned extensions**: Cloud merge rules; sharing presets within an account in v0.6+

## References

- **Code**: Core models/services; iOS views (to be added)
- **Related docs**: `docs/features/games.md`, `docs/systems/data/persistence.md`, `docs/systems/runtime/state-management.md`

## Validation checklist (must meet for acceptance)

- **Swift 6.2 strict; iOS 17+ / watchOS 11+ targets** respected; no concurrency warnings
- **UI on `@MainActor`**; shared types are **`Sendable`**; actor boundaries clear
- **Modern SwiftUI**: `NavigationStack`, `@Observable`/`@Bindable`
- **DesignSystem-first**: no hardcoded colors/spacing/typography
- **SwiftData**: single app-level container; proper schema usage
- **Typed errors** with `LocalizedError` where user-visible
- **Tests**: CRUD, merge, presets, archival referenced by history covered
