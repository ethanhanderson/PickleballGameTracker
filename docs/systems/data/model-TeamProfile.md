# TeamProfile Model (SwiftData)

- Document name: TeamProfile Model
- Category: systems/data
- Model: `TeamProfile`
- Persistence: SwiftData `@Model`
- App versions: iOS/watchOS v0.3+
- Status: draft

## Summary

- Purpose: Persist team identities composed of players and optional visual identity.
- Scope: Attributes, relationships, usage, and version.

## Structure

- Type: `@Model public final class TeamProfile`
- Identity: `@Attribute(.unique) id: UUID`
- Attributes: `name`, `notes`, `isArchived`, visuals (`avatarImageData`, `iconSymbolName`, `iconTintHex`), `suggestedGameTypeRaw`, `createdDate`, `lastModified`
- Relationships: `@Relationship players: [PlayerProfile]`
- Computed: `teamSize`, `suggestedGameType`

## Persistence & Usage

- Create/edit via roster flows using `PlayerTeamManager`; teams referenced by presets and games.
- Persisted and queried through `SwiftDataStorage` (not directly via `ModelContext` in views).
- Suggested game type helps quick-start recommendations.

### In application (runtime)

```swift
@State private var rosterManager = PlayerTeamManager()
RosterHomeView(manager: rosterManager)
```

### In previews (bind to preview ModelContainer)

```swift
let container = PreviewGameData.createPreviewContainer(with: [])
let rosterManager = PlayerTeamManager(storage: SwiftDataStorage(modelContainer: container))

AppNavigationView(rosterManager: rosterManager)
  .modelContainer(container)
```

## Versioning

- v0.3: baseline team composition and suggestion fields.

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

- Players relationship persists order/content
- Suggested game type bridges correctly
- Tests cover create/edit/relationship persistence; storage APIs used (no raw context in views)
