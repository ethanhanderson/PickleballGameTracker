# Sync (Device & Future Cloud)

- **Document name**: Sync (Device & Future Cloud)
- **Category**: systems
- **Area**: SharedGameCore (device sync now; cloud later)

## Summary

- **Purpose**: Explain device-level sync hooks today and future cloud/realtime extension points.
- **Scope**: `ActiveGameSyncService` and integration with `ActiveGameStateManager`; excludes cloud until v0.6.
- **Outcome**: Readers know current capabilities and how to extend them.

## Audience & Owners

- **Audience**: engineers, testers
- **Owners**: iOS/watchOS engineering
- **Last updated**: 2025-08-10
- **Status**: draft
- **Version**: v0.3 baseline

## Architecture Context

- **Layer**: cross-cutting service
- **Entry points**: `ActiveGameSyncService`, `ActiveGameStateManager`
- **Dependencies**: Platform connectivity (abstracted), logging
- **Data flow**: State manager coordinates current game; sync service propagates state when enabled

## Responsibilities

- **Core responsibilities**:
  - Provide hooks to keep active game state visible across devices (where supported)
  - Expose clear toggle to enable/disable sync
- **Non-goals**:
  - Cloud account sync or realtime multiplayer (v0.6/v1.0)

## Structure & Key Types

- **Primary types**: `ActiveGameSyncService`, `ActiveGameStateManager`
- **File locations**: `SharedGameCore/Sources/SharedGameCore/Services/*`
- **Initialization**: State manager configures and controls sync enablement

## Platform Sections (use as needed)

- **iOS/watchOS**: Share awareness of an active game; keep UX in sync where possible

## Data & Persistence

- **Models**: `Game`
- **Container**: N/A
- **Storage**: N/A

## State & Concurrency

- **UI isolation**: UI remains on `@MainActor`; sync runs behind the scenes
- **Observable state**: State manager exposes flags for presence/active
- **Actors/Sendable**: Data sent across processes/devices must be `Sendable`

## Navigation & UI

- **Patterns**: Show preview controls on iOS when an active game exists
- **Destinations**: Tap preview to resume via sheet
- **Components**: `GamePreviewControls`
- **Design System**: Consistent indicators and badges

## Systems Integration

- **Logging**: Connection/status events recorded
- **Sync**: This document describes it
- **Haptics**: Optional feedback on resume

## Error Handling

- **Typed errors**: N/A (fail silently with logs where appropriate)
- **User surfaces**: Minimal; focus on resilience

## Testing & Performance

- **Tests**: State propagation tests where feasible
- **Performance**: Avoid heavy traffic; debounce sends

## Open Questions & Future Work

- **Gaps**: Conflict resolution strategy when both devices change state
- **Planned extensions**: v0.6 cloud sync; v1.0 realtime with optimistic updates

## References

- **Code**: `SharedGameCore/Services/ActiveGameSyncService.swift`, `.../ActiveGameStateManager.swift`
- **Related docs**: `docs/architecture/shared-core.md`

---

## Validation checklist (must meet for acceptance)

- **Swift 6.2 strict; iOS 17+ / watchOS 11+ targets** respected; no concurrency warnings
- **UI on `@MainActor`**; shared types are **`Sendable`**; actor boundaries clear
- **Modern SwiftUI**: `@Observable`/`@Bindable` where applicable
- **DesignSystem-first**: no hardcoded colors/spacing/typography
- **SwiftData**: single app-level container; proper schema usage
- **Typed errors** with `LocalizedError` where user-visible
- **Tests**: persistence, concurrency, and core UI behaviors covered
