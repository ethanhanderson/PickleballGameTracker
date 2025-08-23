# Glossary — Core Types and Paths

- Purpose: Quick reference for domain/types and where to find their code.
- Scope: High-signal list; link to files and related docs.

## Models (SwiftData `@Model`)

- Game: `SharedGameCore/Sources/SharedGameCore/Models/Game.swift`
- GameType: `SharedGameCore/Sources/SharedGameCore/Models/GameType.swift`
- GameVariation: `SharedGameCore/Sources/SharedGameCore/Models/GameVariation.swift`
- User: `SharedGameCore/Sources/SharedGameCore/Models/User.swift`

## Services (SharedGameCore)

- SwiftDataContainer: `SharedGameCore/Sources/SharedGameCore/Services/SwiftDataContainer.swift`
- SwiftDataStorageProtocol: `SharedGameCore/Sources/SharedGameCore/Services/SwiftDataStorageProtocol.swift`
- SwiftDataStorage: `SharedGameCore/Sources/SharedGameCore/Services/SwiftDataStorage.swift`
- SwiftDataGameManager: `SharedGameCore/Sources/SharedGameCore/Services/SwiftDataGameManager.swift`
- ActiveGameStateManager: `SharedGameCore/Sources/SharedGameCore/Services/ActiveGameStateManager.swift`
- ActiveGameSyncService: `SharedGameCore/Sources/SharedGameCore/Services/ActiveGameSyncService.swift`
- HapticFeedbackService: `SharedGameCore/Sources/SharedGameCore/Services/HapticFeedbackService.swift`

## Logging

- LoggingService & sinks: `SharedGameCore/Sources/SharedGameCore/Services/Logging/*`
- Docs: `docs/systems/observability/logging.md`

## Navigation

- iOS AppNavigation: `Pickleball Score Tracking/Views/Infrastructure/Navigation/AppNavigationView.swift`
- Destinations: `Pickleball Score Tracking/Views/Infrastructure/Navigation/NavigationTypes.swift`, `.../GameSectionDestination.swift`
- Docs: `docs/systems/ux/navigation.md`

## Design System

- Tokens: `SharedGameCore/Sources/SharedGameCore/DesignSystem.swift`
- Docs: `docs/systems/ux/design-system.md`

## Persistence & Storage

- Container: `SharedGameCore/Sources/SharedGameCore/Services/SwiftDataContainer.swift`
- Storage API: `SharedGameCore/Sources/SharedGameCore/Services/SwiftDataStorageProtocol.swift`
- Storage impl: `SharedGameCore/Sources/SharedGameCore/Services/SwiftDataStorage.swift`
- Docs: `docs/systems/data/persistence.md`, `docs/systems/data/storage.md`

## State & Sync

- State managers: `SharedGameCore/Sources/SharedGameCore/Services/SwiftDataGameManager.swift`, `.../ActiveGameStateManager.swift`
- Sync: `SharedGameCore/Sources/SharedGameCore/Services/ActiveGameSyncService.swift`
- Docs: `docs/systems/runtime/state-management.md`, `docs/systems/runtime/sync.md`

## Features (selected entry points)

- Active Game: `Pickleball Score Tracking/Views/Core/Game/ActiveGame/ActiveGameView.swift` (iOS), `Pickleball Score Tracking Watch App/Views/WatchActiveGameView.swift`
- History: `Pickleball Score Tracking/Views/Core/History/GameHistoryView.swift`
- Completed Game: `docs/features/completed-game-view.md` (doc), views under `.../Views/Core/History/*`
- Statistics: `docs/features/statistics.md` (doc), iOS views under `.../Views/Core/...` (to be added)
- Author Profiles: `docs/features/author-profiles.md`

## Errors & Telemetry

- Error handling doc: `docs/systems/observability/error-and-telemetry.md`

## Testing & Performance

- Doc: `docs/systems/observability/testing-and-performance.md`

## Build & DevX

- Build & CI: `docs/systems/devx/build-and-ci.md`
- Chat Kickoff: `docs/systems/devx/chat-kickoff.md`
- Roadmap governance: `docs/systems/devx/roadmap-governance.md`
- Quick check script: `docs/systems/devx/roadmap-quick-check.sh`
