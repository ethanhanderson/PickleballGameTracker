# Logging

- **Document name**: Logging
- **Category**: systems
- **Area**: SharedGameCore

## Summary

- **Purpose**: Describe structured logging, sinks, and how logs are emitted across the app.
- **Scope**: `LoggingService`, sinks, events, contexts; excludes analytics.
- **Outcome**: Readers can emit, filter, and route logs consistently.

## Audience & Owners

- **Audience**: engineers, testers
- **Owners**: iOS/watchOS engineering
- **Last updated**: 2025-08-10
- **Status**: draft
- **Version**: v0.3 baseline

## Architecture Context

- **Layer**: cross-cutting service
- **Entry points**: `LoggingService`, `LogEvent`, `LogContext`, `LogLevel`, `LogSink`
- **Dependencies**: OSLog
- **Data flow**: Callers emit log events; service fans out to sinks

## Responsibilities

- **Core responsibilities**:
  - Centralize logging configuration and emission
  - Support multiple sinks (OSLog, Console) with levels and metadata
- **Non-goals**:
  - User analytics or PII collection

## Structure & Key Types

- **Primary types**: `LoggingService`, `OSLogSink`, `ConsoleSink`, `LogEvent`, `LogContext`, `LogLevel`
- **File locations**: `SharedGameCore/Sources/SharedGameCore/Services/Logging/*`
- **Initialization**: Configure sinks at app startup; `LoggingService.shared.configure(...)`

## Platform Sections (use as needed)

- **iOS/watchOS**: Configure sinks early in app lifecycle

## Data & Persistence

- **Models**: N/A
- **Container**: N/A
- **Storage**: N/A

## State & Concurrency

- **UI isolation**: N/A
- **Observable state**: N/A
- **Actors/Sendable**: Log data structures are `Sendable`

## Navigation & UI

- **Patterns**: Emit logs on navigation and actions for debugging
- **Design System**: N/A

## Systems Integration

- **Logging**: This document is the logging system
- **Sync**: Logs connection/operation outcomes
- **Haptics**: Optional logs for feedback triggers

## Error Handling

- **Typed errors**: N/A (errors are logged; apps surface user messages separately)
- **User surfaces**: N/A

## Testing & Performance

- **Tests**: Verify logs emitted for key operations
- **Performance**: Avoid heavy string work on hot paths; level gating

## Open Questions & Future Work

- **Gaps**: Runtime sink toggles and remote log routing
- **Planned extensions**: Additional sinks (file, network) if needed

## References

- **Code**: `SharedGameCore/Services/Logging/*`
- **Related docs**: `docs/systems/observability/error-and-telemetry.md`

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
