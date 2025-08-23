# Game Model (SwiftData)

- Document name: Game Model
- Category: systems/data
- Model: `Game`
- Persistence: SwiftData `@Model`
- App versions: iOS/watchOS v0.3+
- Status: draft

## Summary

- Purpose: Persist active and completed games including scoring, rules, serving state, and metadata.
- Scope: Attributes, relationships, usage patterns, and validation behavior.

## Structure

- Type: `@Model public final class Game`
- Identity: `@Attribute(.unique) id: UUID`
- Attributes (selected): `gameType`, `score1`, `score2`, `isCompleted`, `isArchived`, `createdDate`, `completedDate`, `lastModified`, `duration`, serving state (`currentServer`, `serverNumber`, `serverPosition`, `sideOfCourt`, `isFirstServiceSequence`), rules (`winningScore`, `winByTwo`, `kitchenRule`, `doubleBounceRule`), `notes`, `totalRallies`
- Relationships: optional `@Relationship gameVariation: GameVariation?`
- Derived: helpers like `formattedScore`, `winner`, `shouldComplete`, serving helpers

## Persistence & Usage

- Create: `Game(gameType: .recreational)` or `Game(gameVariation: someVariation)`
- Mutate: `scorePoint1()`, `scorePoint2()`, `undoLastPoint()`, `pauseGame()`, `resumeGame()`, `completeGame()`
- Persist: Use `SwiftDataStorage.shared` APIs; autosave is enabled, storage saves explicitly as needed.

## Versioning

- v0.3: baseline attributes and `GameVariation` relationship; local-only store.

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

- `Game` is included in `SwiftDataContainer` schema
- Business logic stays out of views; UI on `@MainActor`
- Tests cover create/save/query and completion summary path
