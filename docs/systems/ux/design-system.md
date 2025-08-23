# Design System

- **Document name**: Design System
- **Category**: systems
- **Area**: SharedGameCore

## Summary

- **Purpose**: Define semantic tokens and usage patterns for styling across platforms.
- **Scope**: Tokens (colors, typography, spacing) and component helpers; excludes per-feature UI.
- **Outcome**: Consistent, maintainable styling without hardcoded values.

## Audience & Owners

- **Audience**: engineers, designers
- **Owners**: iOS/watchOS engineering
- **Last updated**: 2025-08-10
- **Status**: draft
- **Version**: v0.3 baseline

## Architecture Context

- **Layer**: presentation foundation
- **Entry points**: `SharedGameCore.DesignSystem`
- **Dependencies**: SwiftUI
- **Data flow**: N/A

## Responsibilities

- **Core responsibilities**:
  - Provide semantic colors, typography, spacing, and button/layout helpers
  - Offer platform-aware variants via conditional compilation
- **Non-goals**:
  - Hardcoded styling in feature views

## Structure & Key Types

- **Primary types**: `DesignSystem` (nested types `Colors`, `Typography`, `Spacing`)
- **File locations**: `SharedGameCore/Sources/SharedGameCore/DesignSystem.swift`
- **Initialization**: Static access; imported as `typealias DesignSystem = SharedGameCore.DesignSystem`

### Color tokens (semantic and utilities)

- Brand
  - `primary`, `primaryLight`, `primaryDark` (tied to AccentColor — system green) [iOS/watchOS]
- Accents
  - `secondary`, `tertiary` (+ `Light`/`Dark`), `info`
- Semantic
  - `success` (= `primary`), `warning`, `error`
  - `paused` (neutral for paused/disabled states)
- Surfaces & Text
  - `surface`, `surfaceSecondary`, `surfaceTertiary`
  - `neutralSurface`, `neutralBorder`
  - `textPrimary`, `textSecondary`, `textTertiary`
- Container fills (platform-aware)
  - `containerFillSecondary` (iOS: `.secondarySystemBackground`)
  - `containerFillTertiary` (iOS: `.tertiarySystemFill`)
  - watchOS provides neutral fallbacks
- Overlays & utilities
  - `overlay`, `overlayLight`, `clear`, `transparent`
- Rule UI helpers
  - `rulePositive` (success), `ruleCaution` (warning), `ruleNegative` (error), `ruleInfo` (info)
- Feature utilities
  - `gameType(_:)` → maps `GameType` to a semantic accent (recreational→success, tournament→warning, training→info, social→tertiary, custom→secondary)

### Usage guidance

- Always use `DesignSystem.Colors.*` instead of hardcoded `Color.*` or `Color(._)`.
- Prefer semantic tokens over raw hues. Example: use `success` instead of `green`.
- For disabled/paused affordances, use `paused` rather than arbitrary gray.
- For glass/background fills, use `containerFillSecondary`/`containerFillTertiary` so watchOS/iOS adapt appropriately.
- For game-themed accents, use `gameType(type)` instead of `type.color` or hardcoded values.

## Platform Sections (use as needed)

- **SharedGameCore**: Owns tokens and platform variants
- **iOS/watchOS**: Consume tokens in all views/components

## Data & Persistence

- **Models**: N/A
- **Container**: N/A
- **Storage**: N/A

## State & Concurrency

- **UI isolation**: N/A
- **Observable state**: N/A
- **Actors/Sendable**: N/A

## Navigation & UI

- **Patterns**: Use tokens instead of hardcoded values; apply semantic roles
- **Destinations**: N/A
- **Components**: Button/layout helpers. Follow component sizing guidance in `docs/architecture/overview.md#project-structure-code-map` — avoid micro-components; extract only when the view represents a coherent chunk (typically 5+ elements and/or nested groups) or is reused across screens.
- **Design System**: Central source of truth

## Systems Integration

- **Logging**: N/A
- **Sync**: N/A
- **Haptics**: N/A

## Error Handling

- **Typed errors**: N/A
- **User surfaces**: N/A

## Testing & Performance

- **Tests**: Presence and basic rendering of tokens
- **Performance**: Token access is static and cheap

## Open Questions & Future Work

- **Gaps**: Additional components (forms, list styles)
- **Planned extensions**: Dark mode variants and accessibility tuning

## References

- **Code**: `SharedGameCore/DesignSystem.swift`
- **Related docs**: `docs/features/*`

---

## Validation checklist (must meet for acceptance)

- Baseline validation: see `docs/systems/observability/validation-baseline.md`
- **Swift 6.2 strict; iOS 17+ / watchOS 11+ targets** respected; no concurrency warnings
- **UI on `@MainActor`**; shared types are **`Sendable`**; actor boundaries clear
- **Modern SwiftUI**: `NavigationStack`, `@Observable`/`@Bindable` where applicable
- **DesignSystem-first**: no hardcoded colors/spacing/typography
- **SwiftData**: single app-level container; proper schema usage
- **Typed errors** with `LocalizedError` where user-visible
- **Tests**: persistence, concurrency, and core UI behaviors covered
