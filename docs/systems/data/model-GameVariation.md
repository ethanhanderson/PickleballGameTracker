# GameVariation Model (SwiftData)

- Document name: GameVariation Model
- Category: systems/data
- Model: `GameVariation`
- Persistence: SwiftData `@Model`
- App versions: iOS/watchOS v0.3+
- Status: draft

## Summary

- Purpose: Persist rule and format customizations for games (team size, scoring, side-switching, etc.).
- Scope: Attributes, enums for rules, validation helpers.

## Structure

- Type: `@Model public final class GameVariation`
- Identity: `@Attribute(.unique) id: UUID`
- Attributes: identity, `name`, `gameType`, team configuration, scoring rules, game rules, format options, flags (`isDefault`, `isCustom`, etc.), metadata, tags
- Relationships: none outbound; referenced by `Game`
- Enums: `ScoringType`, `ServingRotation`, `SideSwitchingRule` (value types, `Codable`, `Sendable`)

## Persistence & Usage

- Create via `createValidated(...)` or direct init, then assign to `Game(gameVariation:)`.
- Validate before save to ensure consistent rules.

## Versioning

- v0.3: baseline customizable rules; referenced from `Game`.

## Deterministic Commands

```bash
cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && \
xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking" -destination "platform=iOS Simulator,name=iPhone 16" test
```

```bash
cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking" && \
xcodebuild -project "Pickleball Score Tracking.xcodeproj" -scheme "Pickleball Score Tracking Watch App" -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)" test
```

## Validation checklist

- Variation IDs stable; `Game` uses variation for defaults when present
- Validation enforces bounds (scores, time limits, team size)
- Tests cover creation, validation, and compatibility helpers
