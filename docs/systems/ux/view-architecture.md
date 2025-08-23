# View Architecture — Modern SwiftUI, Thin UI, DesignSystem‑First

- **Document name**: View Architecture
- **Category**: systems
- **Area**: presentation (iOS, watchOS)

## Summary

- **Purpose**: Provide authoritative guidelines for creating and structuring SwiftUI views in this app.
- **Scope**: Screens and reusable components in iOS and watchOS targets; integration with shared services and tokens.
- **Outcome**: Consistent, maintainable, performant views that are thin, testable, and aligned to `SharedGameCore`.

## Audience & Owners

- **Audience**: engineers, reviewers
- **Owners**: iOS/watchOS engineering
- **Last updated**: 2025-08-17
- **Status**: draft
- **Version**: v0.3 baseline

## Checklist (use before starting a new view)

- Define the view’s role and where it lives (feature screen vs reusable component)
- Identify state and data sources; keep UI on `@MainActor`, route logic to `SharedGameCore`
- Apply `DesignSystem` tokens for all colors/spacing/typography
- Decide component boundaries (avoid micro-components; extract substantial, reusable chunks)
- Wire navigation via typed destinations; prepare guardrail-safe previews
- Add validation and deterministic build commands (iOS + watchOS)

## Architecture Context

- **Layer**: presentation
- **Dependencies**: SwiftUI, SwiftData (queries only), `SharedGameCore` services, `DesignSystem`
- **Entry points**: Screens under `Features/<Feature>/Screens`; components under `Features/<Feature>/Components` or shared `UI/Components`

## Responsibilities

- **Core responsibilities**:
  - Compose UI with SwiftUI using `DesignSystem` tokens; keep views thin and declarative
  - Fetch/persist data via SwiftData `@Query` and service calls; no business logic in views
  - Integrate cross-cutting systems (logging, haptics, deep links) through typed facades
- **Non-goals**:
  - Implement domain rules or multi-actor coordination in UI; use `SharedGameCore` actors/services instead

## Structure & Key Types

- **Screens**: `Features/<Feature>/Screens/<Name>View.swift` (e.g., `GameHistoryView`)
- **Feature components**: `Features/<Feature>/Components/<Component>.swift`
- **Shared components**: `UI/Components/<Component>.swift` (only if reused across features)
- **State**: Use `@Observable` types co-located with the feature only for UI state orchestration; domain state lives in `SharedGameCore`

### Component sizing guidance (authoritative)

- Do not extract trivial fragments. Keep small headers/sections (~1–3 lightweight elements) inline for readability.
- Extract to a component when the UI contains ~5+ elements and/or nested groups, encapsulates interactions/state, or is reused.
- Place feature-specific components under `Features/<Feature>/Components/`; promote to `UI/Components/` only when shared.
- Reference: `docs/architecture/project-organization.md#component-sizing--reuse-guidance-must`

## Integration with Existing Systems

- **Design System**: Always style via `DesignSystem` tokens; no hardcoded values.
- **Logging**: Use `LoggingService` for structured logs (no `print`). Example: log user actions, navigation, and error surfaces.
- **Haptics**: Call `HapticFeedbackService` for lightweight confirmation; avoid long vibrations on watchOS.
- **Deep Links**: Views react to typed destinations; resolution handled by `DeepLinkResolver`/routers upstream.
- **Persistence**: Use `@Environment(\\.modelContext)` and `@Query` for SwiftData reads; write via service APIs.
- **Navigation**: Attach `.navigationDestination(for:)` at the stack level; avoid deep attachment inside children.

## Using the Design System & Tokens

- **Colors**: `DesignSystem.Colors.*` (brand, accents, semantic, surfaces)
- **Typography**: Prefer system typography helpers via `DesignSystem` (when present) or platform defaults; never hardcode sizes
- **Spacing**: Use spacing constants/utilities from `DesignSystem` (e.g., small/medium/large)
- **Theming by domain**: Use helpers like `DesignSystem.Colors.gameType(_:)` for consistent mapping

```swift
import SharedGameCore
import SwiftUI

@MainActor
struct StatCard: View {
  let title: String
  let value: String

  var body: some View {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
      Text(title)
        .foregroundStyle(DesignSystem.Colors.textSecondary)
      Text(value)
        .foregroundStyle(DesignSystem.Colors.textPrimary)
    }
    .padding(DesignSystem.Spacing.medium)
    .background(DesignSystem.Colors.containerFillSecondary)
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
}
```

## Data & Persistence

- Use SwiftData in views only via `@Query` and the injected `modelContext`.
- Do not create `ModelContainer` in views; the container is app-level.
- For non-trivial mutations/queries, call `SharedGameCore` service APIs (e.g., `SwiftDataGameManager`, `PlayerTeamManager`).

```swift
@Environment(\\.modelContext) private var modelContext
@Query(sort: \\GameSummary.date, order: .reverse) private var summaries: [GameSummary]
```

## State & Concurrency

- UI types run on `@MainActor`.
- Use `@Observable` for UI orchestration when needed; keep logic minimal and forward to services/actors.
- Use structured concurrency; avoid detached tasks. Do not mutate shared state across `await` without actor isolation.
- Ensure shared types crossing actor boundaries conform to `Sendable`.

## Error Handling

- Define typed errors (`enum` conforming to `Error & Sendable`), and map user-facing messages via `LocalizedError`.
- Surface errors with lightweight UI (e.g., `ErrorView` component) rather than printouts or blocking flows.

## Navigation Patterns (guardrails)

- Use `NavigationStack` and typed destinations.
- Attach `.navigationDestination(for:)` at the stack level; keep stacks shallow on watchOS.
- Reference: `docs/systems/ux/navigation.md#swiftui-preview-stability-guardrails`.

## Previews

- Use `SharedGameCore.PreviewGameData` to build in-memory containers; keep previews thin.
- Provide Normal/Empty/Error variants where meaningful.
- Reference: `docs/systems/ux/previews.md`.

```swift
#Preview("Mid Game — iOS") {
  ActiveGameView()
    .modelContainer(try! PreviewGameData.createPreviewContainer(with: [PreviewGameData.midGame]))
}
```

## Testing & Performance

- Prefer integration tests in `SharedGameCore` for logic; keep UI tests light (smoke, navigation wiring).
- Ensure stable IDs in lists; avoid nested scroll views and heavy work in `body`.
- Reference: `docs/systems/observability/testing-and-performance.md`.

## Deterministic Commands

- iOS (pinned):
  - `cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking" -destination "platform=iOS Simulator,name=iPhone 16" build`
- watchOS (pinned):
  - `cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking Watch App" -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)" build`

## Change impact

- **Affected modules**: iOS, watchOS (presentation), `SharedGameCore` (referenced services only)
- **Risks & mitigations**:
  - Over-fragmented UI → follow component sizing guidance and keep trivial elements inline
  - Styling drift → enforce `DesignSystem` tokens; review diffs for hardcoded values
  - Concurrency issues → keep UI on `@MainActor`; use actors/services for async work

## Test touchpoints

- UI smoke/navigation:
  - `Pickleball Score TrackingUITests/BasicSmokeUITests.swift`
- Shared logic (as needed for affected flows):
  - `SharedGameCore/Tests/SharedGameCoreTests/*`

## References

- **Code**:
  - iOS target: `Pickleball Score Tracking/Features/**`
  - watchOS target: `Pickleball Score Tracking Watch App/Features/**`
  - Shared tokens/services: `SharedGameCore/Sources/SharedGameCore/**`
- **Related docs**:
  - `docs/architecture/project-organization.md`
  - `docs/systems/ux/design-system.md`
  - `docs/systems/ux/navigation.md`
  - `docs/systems/ux/previews.md`
  - `docs/systems/observability/logging.md`
  - `docs/systems/observability/testing-and-performance.md`

---

## Validation checklist (must meet for acceptance)

- View is thin: no business logic; uses `SharedGameCore` services/actors for work
- UI runs on `@MainActor`; no concurrency warnings; shared types are `Sendable`
- All styling uses `DesignSystem` tokens; no hardcoded colors/spacing/typography
- Component boundaries follow sizing guidance; no trivial micro-components extracted
- Navigation uses typed destinations with guardrails; previews cover Normal/Empty/Error
- SwiftData usage: `@Query` and injected `modelContext` only; no local containers
- Pinned builds (iOS + watchOS) succeed with no new warnings
