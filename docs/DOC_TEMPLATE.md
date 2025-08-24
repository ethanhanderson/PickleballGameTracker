# Title

- **Document name**: [replace with concise, specific title]
- **Category**: architecture | features | systems
- **Area**: SharedGameCore | iOS | watchOS | cross-cutting

## Summary

- **Purpose**: [one sentence explaining the why]
- **Scope**: [what this covers and does not cover]
- **Outcome**: [what readers should understand or be able to do]

## Audience & Owners

- **Audience**: [engineers, designers, QA]
- **Owners**: [names or roles]
- **Last updated**: [YYYY-MM-DD]
- **Status**: draft | final | deprecated
- **Version**: v0.3 | v0.6 | v1.0 (as applicable)

## Architecture Context

- **Layer**: presentation | domain | data (choose relevant)
- **Entry points**: [primary types/views/modules]
- **Dependencies**: [internal modules and external frameworks]
- **Data flow**: [brief description of inputs → processing → outputs]

## Responsibilities

- **Core responsibilities**:
  - [responsibility 1]
  - [responsibility 2]
- **Non-goals**:
  - [explicitly call out what this does not handle]

## Structure & Key Types

- **Primary types**: [list key types like views, services, models]
- **File locations**: [paths like `Pickleball Score Tracking/Views/...` or `SharedGameCore/...`]
- **Initialization**: [how this is constructed/injected]

## Platform Sections (use as needed)

- **SharedGameCore**: [notes relevant to shared logic]
- **iOS**: [platform-specific behavior/UX]
- **watchOS**: [platform-specific behavior/UX]

## Data & Persistence

- **Models**: [SwiftData `@Model` types used]
- **Container**: [`SwiftDataContainer` usage]
- **Storage**: [`SwiftDataStorageProtocol` operations invoked]

## State & Concurrency

- **UI isolation**: `@MainActor` usage
- **Observable state**: `@Observable`, `@Bindable`, environment
- **Actors/Sendable**: shared types and actor boundaries

## Navigation & UI

- **Patterns**: `NavigationStack`, iOS `TabView` (if applicable)
- **Destinations**: [destination enums/types]
- **Components**: [reusable UI components involved]
- **Design System**: tokens for color/typography/spacing

## Systems Integration

- **Logging**: events, sinks (`OSLogSink`, `ConsoleSink`)
- **Sync**: `ActiveGameSyncService` (if applicable)
- **Haptics**: `HapticFeedbackService` (if applicable)

## Error Handling

- **Typed errors**: domains used and user messaging
- **User surfaces**: views/alerts used (`ErrorView`, alerts)

## Testing & Performance

- **Tests**: persistence, concurrency/actors, UI flows
- **Performance**: lazy containers, stable ids, main-thread safety

## Deterministic Commands

- **Build/Test (examples)**:
  - iOS: `cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking" -destination "platform=iOS Simulator,name=iPhone 16" test`
  - watchOS: `cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking Watch App" -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)" test`

## Test touchpoints

- **Suites/files to extend**: [list existing test files]
- **New tests to add**: [brief description]

## Change impact

- **Affected modules**: [SharedGameCore, iOS, watchOS]
- **Risks & mitigations**: [concurrency, persistence, navigation, etc.]

## Open Questions & Future Work

- **Gaps**: [known limitations]
- **Planned extensions**: [tie to roadmap items]

## References

- **Code**: [file paths/types]
- **Related docs**: [cross-links within `docs/`]

## Code path anchors (optional)

- [most-touched file #1]
- [most-touched file #2]

## Starter queries (optional)

- [Where is X routed from Y?]
- [Where is Z computed or persisted?]

---

## Validation checklist (must meet for acceptance)

- Baseline validation: see `docs/systems/observability/validation-baseline.md`
- **Swift 6.2 strict; iOS 17+ / watchOS 11+ targets** respected; no concurrency warnings
- **UI on `@MainActor`**; shared types are **`Sendable`**; actor boundaries clear
- **Modern SwiftUI**: `NavigationStack`, `@Observable`/`@Bindable`, `@Query` when needed
- **DesignSystem-first**: no hardcoded colors/spacing/typography
- **SwiftData**: single app-level container; proper schema usage
- **Typed errors** with `LocalizedError` where user-visible
- **Tests**: persistence, concurrency, and core UI behaviors covered

---

## Authoring guidance (delete before finalizing)

- Keep it concise and high-signal; favor lists over prose
- Use platform sections only when differences matter
- Cite code with backticks and paths (e.g., `SharedGameCore/Services/SwiftDataStorage.swift`)
- Prefer normative language (MUST/SHOULD); avoid duplication across docs
