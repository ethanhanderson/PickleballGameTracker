# Game Variations Feature

- **Document name**: Game Variations Feature
- **Category**: features
- **Area**: cross-cutting (SharedGameCore, iOS)

## Summary

- **Purpose**: Document how game rule presets/variations are modeled and surfaced in the app.
- **Scope**: Model and display of variations; excludes realtime or cloud sharing of variations.
- **Outcome**: Readers understand the model and how variations influence rules display.

## Audience & Owners

- **Audience**: engineers, testers
- **Owners**: iOS engineering
- **Last updated**: 2025-08-10
- **Status**: draft
- **Version**: v0.3 baseline

## Architecture Context

- **Layer**: domain (models) and presentation (display)
- **Entry points**: `GameVariation` (model), iOS `GameDetail` components that render rules
- **Dependencies**: `SharedGameCore` models, `DesignSystem`
- **Data flow**: Selection of a game type/variation → display parameters → applied to active game state manager and storage

## Responsibilities

- **Core responsibilities**:
  - Define configurable rule parameters (win conditions, serve rules, side switches)
  - Display variation details in the iOS detail screens
- **Non-goals**:
  - Enforcing all rules in UI (some enforcement pending)

## Structure & Key Types

- **Primary types**: `GameVariation`, `GameType`, iOS components `GameRulesSection`, `GameTypeDetails`
- **File locations**: `SharedGameCore/Models/*`, `Pickleball Score Tracking/Views/Components/Game/GameDetail/*`
- **Initialization**: Variations provided via `GameType` presets; apps read and present

## Platform Sections (use as needed)

- **iOS**: Rules are rendered in detail screens prior to game start

## Data & Persistence

- **Models**: `GameVariation`, `GameType`
- **Container**: N/A
- **Storage**: Variation selections influence saved `Game` configuration at creation time

## State & Concurrency

- **UI isolation**: `@MainActor` views
- **Observable state**: Presented read-only; applied via managers at creation
- **Actors/Sendable**: Models are `Sendable`

## Navigation & UI

- **Patterns**: iOS `NavigationStack` into Game Detail
- **Destinations**: From catalog/list to detail
- **Components**: Rules section and details renderer
- **Design System**: Tokens for visual consistency

## Systems Integration

- **Logging**: Selection/view events for variations
- **Sync**: N/A (local-first at v0.3)
- **Haptics**: Optional feedback on selections

## Error Handling

- **Typed errors**: N/A
- **User surfaces**: Informational only

## Testing & Performance

- **Tests**: Rendering of rules based on selected variation; correct mapping to created game config
- **Performance**: Lightweight rendering

## Open Questions & Future Work

- **Gaps**: Serving rotation/side switching enforcement during gameplay
- **Planned extensions**: Custom user-defined variations; cloud templates (v0.6+)

## References

- **Code**: `SharedGameCore/Sources/SharedGameCore/Models/*`, `Pickleball Score Tracking/Views/Components/Game/GameDetail/*`
- **Related docs**: `docs/features/active-game.md`

---

## Validation checklist (must meet for acceptance)

- **Swift 6.2 strict; iOS 17+ / watchOS 11+ targets** respected; no concurrency warnings
- **UI on `@MainActor`**; shared types are **`Sendable`**; actor boundaries clear
- **Modern SwiftUI**: `NavigationStack`, `@Observable`/`@Bindable`
- **DesignSystem-first**: no hardcoded colors/spacing/typography
- **SwiftData**: single app-level container; proper schema usage
- **Typed errors** with `LocalizedError` where user-visible
- **Tests**: persistence, concurrency, and core UI behaviors covered
