# Error Handling & Telemetry

- **Document name**: Error Handling & Telemetry
- **Category**: systems
- **Area**: cross-cutting

## Summary

- **Purpose**: Define typed error patterns and how operational telemetry is captured.
- **Scope**: Error domains, user surfaces, and relation to logging; excludes analytics.
- **Outcome**: Consistent user messaging and reliable operational signals.

## Audience & Owners

- **Audience**: engineers, testers
- **Owners**: iOS/watchOS engineering
- **Last updated**: 2025-08-10
- **Status**: draft
- **Version**: v0.3 baseline

## Architecture Context

- **Layer**: cross-cutting
- **Entry points**: Storage errors (`StorageError`), `LoggingService`, UI error components
- **Dependencies**: SwiftUI, logging
- **Data flow**: Errors raised → surfaced to UI with localized description → logged

## Responsibilities

- **Core responsibilities**:
  - Use typed errors that conform to `LocalizedError` for user messages
  - Capture telemetry via structured logs (event, context, metadata)
- **Non-goals**:
  - Crash reporting/analytics backends (future)

## Structure & Key Types

- **Primary types**: `StorageError`, `ErrorView` (UI), logging types
- **File locations**: Errors in `SharedGameCore/Services/*` and views in app components
- **Initialization**: Error views used on-demand; logging configured at startup

## Platform Sections (use as needed)

- **iOS**: Initialization error path and in-view error surfaces
- **watchOS**: Inline alerts with short messages

## Data & Persistence

- **Models**: N/A
- **Container**: N/A
- **Storage**: Errors from `SwiftDataStorage` and managers

## State & Concurrency

- **UI isolation**: Errors surfaced on `@MainActor`
- **Observable state**: Managers keep `lastError` for rendering
- **Actors/Sendable**: Error types are `Sendable`

## Navigation & UI

- **Patterns**: Show actionable errors with optional retry
- **Destinations**: N/A
- **Components**: `ErrorView`, alerts
- **Design System**: Consistent visuals for error states

## Systems Integration

- **Logging**: Log errors with event context; avoid sensitive data
- **Sync**: Log sync failures for diagnosis
- **Haptics**: Optional warning haptics on critical failures

## Testing & Performance

- **Tests**: Verify user-visible descriptions; ensure retries call correct paths
- **Performance**: Avoid over-logging; structure logs for fast filtering

## Open Questions & Future Work

- **Gaps**: Unified error taxonomy across new services (auth/sync)
- **Planned extensions**: Crash reporting and analytics integrations post v0.6

## References

- **Code**: `SharedGameCore/Services/*`, app `Views/Components/UI/ErrorView.swift`
- **Related docs**: `docs/systems/observability/logging.md`

---

## Validation checklist (must meet for acceptance)

- Baseline validation: see `docs/systems/observability/validation-baseline.md`
- **Swift 6.2 strict; iOS 17+ / watchOS 11+ targets** respected; no concurrency warnings
- **UI on `@MainActor`**; shared types are **`Sendable`**; actor boundaries clear
- **Modern SwiftUI**: `@Observable`/`@Bindable` where applicable
- **DesignSystem-first**: no hardcoded colors/spacing/typography
- **SwiftData**: single app-level container; proper schema usage
- **Typed errors** with `LocalizedError` where user-visible
- **Tests**: persistence, concurrency, and core UI behaviors covered
