# SwiftUI Preview Data System — Centralized and Cross‑Platform

- **Document name**: SwiftUI Preview Data System
- **Category**: systems
- **Area**: cross-cutting (iOS, watchOS, SharedGameCore)

## Summary

- **Purpose**: Define a single, centralized preview data system that all app targets use consistently, enabling fast, realistic, and deterministic SwiftUI previews across iOS and watchOS.
- **Scope**: How preview data is authored in `SharedGameCore`, how app targets consume it, and how SwiftData containers are set up for previews.
- **Outcome**: Previews render reliably using the same data scenarios; duplication and drift are eliminated.

## Audience & Owners

- **Audience**: engineers, testers
- **Owners**: iOS/watchOS engineering
- **Last updated**: 2025-08-17
- **Status**: draft
- **Version**: v0.3 baseline

## Architecture Context

- **Layer**: presentation (apps) + shared domain (core)
- **Entry points**: `SharedGameCore.PreviewGameData` (core provider); app previews in feature files
- **Dependencies**: SwiftUI, SwiftData
- **Data flow**: Preview → selects scenario(s) from `PreviewGameData` → creates in‑memory `ModelContainer` → injects into the previewed view

## Responsibilities

- **Core responsibilities**:
  - Provide reusable, realistic preview scenarios for games and collections
  - Provide factory functions to create an in‑memory `ModelContainer` preloaded with scenarios
  - Keep preview data synchronized with current SwiftData models
- **Non-goals**:
  - App navigation and production storage
  - Any mutation side effects beyond in‑memory previews

## Structure & Key Types

- **Primary types**:
  - `SharedGameCore/Sources/SharedGameCore/PreviewData.swift` → `PreviewGameData`
    - Static scenarios like `earlyGame`, `midGame`, `completedGame`, collections like `competitivePlayerGames`
    - Factory methods `createPreviewContainer(with:)`, `createFullPreviewContainer()`
  - App scaffolding (optional, additive): `Pickleball Score Tracking/Infrastructure/Fixtures/PreviewData.swift`
    - App‑specific grouping or scenario routing that still delegates to `PreviewGameData`
- **File locations**:
  - Core provider: `SharedGameCore/Sources/SharedGameCore/PreviewData.swift`
  - App fixtures (optional): `Pickleball Score Tracking/Infrastructure/Fixtures/PreviewData.swift`
- **Initialization**:
  - Use `ModelConfiguration(isStoredInMemoryOnly: true)` and preload models using the container’s `mainContext`

## Platform Sections (use as needed)

- **SharedGameCore**:
  - Owns scenario definitions and container factories
  - Must compile against current `@Model` types and valid attributes/relationships
- **iOS**:
  - Previews consume `PreviewGameData` scenarios; inject containers via `.modelContainer(...)`
  - Views access `@Environment(\.modelContext)` and `@Query` as usual
- **watchOS**:
  - Same consumption pattern; prefer lightweight scenarios suitable for watch UI

## Data & Persistence

- **Models**: Use the same SwiftData `@Model` types as production (e.g., `Game`, `GameVariation`)
- **Container**: In‑memory containers for previews only
  - Example snippet for factories (core):

```swift
@MainActor
public struct PreviewGameData {
  public static func createPreviewContainer(with games: [Game]) throws -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: Game.self, GameVariation.self, configurations: config)
    let context = container.mainContext
    for game in games { context.insert(game) }
    try context.save()
    return container
  }
}
```

## State & Concurrency

- **UI isolation**: Previews run UI on `@MainActor`
- **Actors/Sendable**: Preview factory APIs must be `@MainActor` safe; shared types conform to `Sendable`

## Navigation & UI

- **Patterns**: Use shared scenarios for Normal/Empty/Error states; attach `.navigationDestination` at the `NavigationStack` level per guardrails
- **Design System**: All styling via `DesignSystem` tokens
- **Guardrails**: See `docs/systems/ux/navigation.md#swiftui-preview-stability-guardrails`

## Usage in App Targets

- Prefer core scenarios directly in view previews. Keep previews thin: inject only what the view requires.

```swift
import SharedGameCore
import SwiftData

#Preview("Mid Game — iOS") {
  ActiveGameView()
    .modelContainer(try! PreviewGameData.createPreviewContainer(with: [PreviewGameData.midGame]))
}

#Preview("Empty State — History") {
  GameHistoryView()
    .modelContainer(try! PreviewGameData.createPreviewContainer(with: []))
}
```

- For list/collection previews, prefer predefined collections from the provider:

```swift
#Preview("Competitive Player — History") {
  GameHistoryView()
    .modelContainer(try! PreviewGameData.createPreviewContainer(with: PreviewGameData.competitivePlayerGames))
}
```

- If the app needs custom grouping, add light wrappers under `Infrastructure/Fixtures/` that delegate to the core provider. Avoid duplicating core scenarios.

## Systems Integration

- **Logging**: Do not use production logging in previews; use no‑ops where needed
- **Sync**: Not applicable to previews
- **Haptics**: Optional, but prefer disabled/no‑op in previews

## Error Handling

- **Typed errors**: Factory methods may `throw`; in previews prefer `try!` for simplicity while keeping scenarios valid
- **User surfaces**: Use an `ErrorView` in actual error preview scenarios if needed

## Testing & Performance

- **Tests**: Not required for preview data, but compile‑time coverage is expected; avoid heavy allocations
- **Performance**: Keep scenarios small; use minimal data needed to illustrate UI

## Change impact

- **Affected modules**: SharedGameCore, iOS, watchOS
- **Risks & mitigations**:
  - Drift from models → keep provider updated alongside model changes
  - Duplicate fixtures → consolidate to provider and thin app wrappers

## References

- **Code**:
  - `SharedGameCore/Sources/SharedGameCore/PreviewData.swift`
  - `Pickleball Score Tracking/Infrastructure/Fixtures/PreviewData.swift`
- **Related docs**:
  - `docs/architecture/overview.md#project-structure-code-map`
  - `docs/systems/ux/navigation.md#swiftui-preview-stability-guardrails`

---
