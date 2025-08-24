# PlayerProfile Model (SwiftData)

- Document name: PlayerProfile Model
- Category: systems/data
- Model: `PlayerProfile`
- Persistence: SwiftData `@Model`
- App versions: iOS/watchOS v0.3+
- Status: draft

## Summary

- Purpose: Persist player identities and preferences for team assembly and statistics.
- Scope: Attributes (identity, visuals, preferences), versioning, basic usage.

## Structure

- Type: `@Model public final class PlayerProfile`
- Identity: `@Attribute(.unique) id: UUID`
- Attributes: `name`, `notes`, `isArchived`, visuals (`avatarImageData`, `iconSymbolName`, `iconTintHex`), preferences (`skillLevel`, `preferredHand`), `createdDate`, `lastModified`
- Enums: `PlayerSkillLevel`, `PlayerHandedness` (`Codable`, `Sendable`)

## Persistence & Usage

- Create/edit via roster flows using `PlayerTeamManager`; archive/restore manage availability.
- Persisted and queried through `SwiftDataStorage` (not directly via `ModelContext` in views).
- Used by `TeamProfile.players` relationship.

### In application (runtime)

```swift
// Construct the manager once at app root or feature entry
@State private var rosterManager = PlayerTeamManager()

// Pass to views that need it
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

- v0.3: baseline player identity and preferences.

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

- Archived players excluded from default team pickers
- Visuals optionality respected in UI
- Tests cover create/edit/archive paths; storage APIs used (no raw context in views)
