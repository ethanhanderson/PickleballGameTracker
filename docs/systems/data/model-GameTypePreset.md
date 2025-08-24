# GameTypePreset Model (SwiftData)

- Document name: GameTypePreset Model
- Category: systems/data
- Model: `GameTypePreset`
- Persistence: SwiftData `@Model`
- App versions: iOS/watchOS v0.3+
- Status: draft

## Summary

- Purpose: Persist reusable starting configurations (game type + optional preselected teams and notes).
- Scope: Attributes, relationships to `TeamProfile`, mapping from `gameTypeRaw` to `GameType`.

## Structure

- Type: `@Model public final class GameTypePreset`
- Identity: `@Attribute(.unique) id: UUID`
- Attributes: `name`, `notes`, `isArchived`, `gameTypeRaw`, `createdDate`, `lastModified`
- Relationships: `@Relationship team1: TeamProfile?`, `@Relationship team2: TeamProfile?`
- Computed: `gameType` bridging to/from `gameTypeRaw`

## Persistence & Usage

- Create presets for quick-start flows; archive/restore to manage catalog visibility.
- Use in iOS/watchOS start screens to seed a new `Game`.

## Versioning

- v0.3: baseline fields and team relationships.

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

- Preset can reference up to two teams; bridging to `GameType` works
- Archive/restore toggles flags and updates `lastModified`
- Tests cover creation and basic read usage
