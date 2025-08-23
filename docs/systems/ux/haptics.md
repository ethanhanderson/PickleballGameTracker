# Haptics

- **Document name**: Haptics
- **Category**: systems
- **Area**: SharedGameCore

## Summary

- **Purpose**: Document how haptic feedback is provided across platforms.
- **Scope**: `HapticFeedbackService` usage; excludes custom per-feature effects.
- **Outcome**: Readers can trigger appropriate feedback consistently.

## Audience & Owners

- **Audience**: engineers, testers
- **Owners**: iOS/watchOS engineering
- **Last updated**: 2025-08-10
- **Status**: draft
- **Version**: v0.3 baseline

## Architecture Context

- **Layer**: cross-cutting UI service
- **Entry points**: `HapticFeedbackService`
- **Dependencies**: SwiftUI, platform feedback APIs
- **Data flow**: Views call service on user actions

## Responsibilities

- **Core responsibilities**:
  - Provide lightweight, platform-aware haptic feedback
  - Standardize which actions produce feedback
- **Non-goals**:
  - Complex feedback scheduling or audio integration

## Structure & Key Types

- **Primary types**: `HapticFeedbackService`
- **File locations**: `SharedGameCore/Sources/SharedGameCore/Services/HapticFeedbackService.swift`
- **Initialization**: Static/shared usage where convenient

## Platform Sections (use as needed)

- **iOS/watchOS**: Map actions to appropriate feedback types per platform

## Data & Persistence

- **Models**: N/A
- **Container**: N/A
- **Storage**: N/A

## State & Concurrency

- **UI isolation**: Called from `@MainActor` views
- **Observable state**: N/A
- **Actors/Sendable**: N/A

## Navigation & UI

- **Patterns**: Trigger on score increment, start/pause, and completion
- **Destinations**: N/A
- **Components**: Integrated with interactive controls
- **Design System**: Complements visual tokens; not a replacement

## Systems Integration

- **Logging**: Optional logs on trigger for debugging
- **Sync**: N/A
- **Haptics**: This document

## Error Handling

- **Typed errors**: N/A
- **User surfaces**: N/A

## Testing & Performance

- **Tests**: Validate invocation points; skip device-specific feedback in CI
- **Performance**: Minimal overhead; debounce if needed

## Open Questions & Future Work

- **Gaps**: Fine-grained feedback mapping per action
- **Planned extensions**: User settings for feedback intensity

## References

- **Code**: `SharedGameCore/Services/HapticFeedbackService.swift`
- **Related docs**: `docs/features/active-game.md`

---

## Validation checklist (must meet for acceptance)

- **Swift 6.2 strict; iOS 17+ / watchOS 11+ targets** respected; no concurrency warnings
- **UI on `@MainActor`**; shared types are **`Sendable`**; actor boundaries clear
- **Modern SwiftUI**: `@Observable`/`@Bindable` where applicable
- **DesignSystem-first**: no hardcoded colors/spacing/typography
- **SwiftData**: single app-level container; proper schema usage
- **Typed errors** with `LocalizedError` where user-visible
- **Tests**: persistence, concurrency, and core UI behaviors covered
