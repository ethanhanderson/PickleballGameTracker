# GameSummary Model (SwiftData)

- Document name: GameSummary Model
- Category: systems/data
- Model: `GameSummary`
- Persistence: SwiftData `@Model`
- App versions: iOS/watchOS v0.3+
- Status: draft

## Summary

- Purpose: Persist lightweight KPIs for completed games to power history lists and stats.
- Scope: Attributes, usage, write-path from storage on game completion.

## Structure

- Type: `@Model public final class GameSummary`
- Identity: `@Attribute(.unique) gameId: UUID`
- Attributes: `gameTypeId`, `completedDate`, KPIs (`winningTeam`, `pointDifferential`, `duration`, `totalRallies`)
- Relationships: none (projection table)

## Persistence & Usage

- Write: Created/updated by storage when a `Game` is saved as completed.
- Read: Used for history queries and stats aggregation.

## Versioning

- v0.3: initial summary projection for completed games.

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

- Summary is updated on game completion in storage
- History lists use summaries where appropriate for performance
- Tests cover summary creation and query paths
