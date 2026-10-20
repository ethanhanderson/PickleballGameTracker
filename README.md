# Pickleball Game Tracker

Native SwiftUI pickleball game tracker for iOS and watchOS.

I built this as a local-first scoring app for iPhone and Apple Watch. You pick a game type, set the sides (including guest players), keep score on either device, and WatchConnectivity keeps the live game and roster in sync. Games, history, and identities persist in SwiftData. I have not published it on the App Store.

## Features

- **Game catalog and setup.** Game types: recreational, tournament, training, social, custom, cutthroat, and group play. Each type has rules, presets, and a setup flow. Catalog sections are ranked by a personalization engine from recent play.
- **Live scoring.** Side scores, a centisecond timer on iPhone, event log, serve indicator, and a winner chip when the game ends.
- **Tournament brackets.** Group play can generate random pairings or a first-round single-elimination bracket (seeded or shuffled, with byes). The bracket screen lists that first round.
- **History.** Completed games with filters, grouping, and an archive.
- **Rosters and stats.** Players and teams with photo or icon avatars, archive/restore, and identity sharing. The Statistics tab reports win rate, serve-win %, streaks, and 7/30-day trends from completed games.
- **Watch scoring.** Live score controls on watchOS, a HealthKit workout (heart rate and energy), and a WatchKit extended runtime session so scoring can stay in the foreground.
- **iPhone / Watch sync.** `WatchConnectivity` transport, `LiveSyncCoordinator` for live snapshots and deltas, phone-owned roster snapshots, and `TimerDriftResolver` for timer alignment.
- **Live Activities.** `GameLiveActivityWidget` shows each side’s name, avatar, and score, plus elapsed time and the latest event. Dynamic Island on iPhone.

## Architecture

Xcode workspace, thin app shells, a shared Swift package, platform feature packages, and a widget extension:

```
PickleballGameTracker.xcworkspace
├── PickleballGameTracker.xcodeproj
├── Config/                                  # xcconfig + entitlements
├── PickleballGameTracker/                   # iOS @main
├── PickleballGameTrackerWatch/              # watchOS @main
├── PickleballGameTrackerWidgetExtension/    # Live Activities
├── PickleballGameTrackerCorePackage/        # GameTrackerCore
├── PickleballGameTrackerPackage/            # GameTrackerFeature (iOS UI)
├── PickleballGameTrackerWatchPackage/       # GameTrackerWatchFeature (watchOS UI)
├── PickleballGameTrackerUITests/
└── PickleballGameTrackerWatchUITests/
```

`GameTrackerCore` owns models, SwiftData persistence, serve and score rules, group-play and bracket engines, sync DTOs, logging, and Live Activity attributes. The iOS and watchOS apps import their feature packages and inject `LiveGameStateManager`, `SwiftDataGameManager`, `LiveSyncCoordinator`, and the roster manager. The phone is the roster source of truth.

## Tech stack

- Swift 6.2, SwiftUI, Swift Concurrency (`@Observable`, `@MainActor`)
- SwiftData
- WatchConnectivity
- HealthKit (watch workout)
- ActivityKit / WidgetKit (Live Activities, Dynamic Island)
- UserNotifications
- Swift Package Manager inside an Xcode workspace
- xcconfig plus a declarative entitlements file (HealthKit, app group)
- Swift Testing for unit tests; XCTest for UI tests
- Package and app targets: iOS 26, watchOS 26

## Testing

Unit tests live in `PickleballGameTrackerCorePackage/Tests/GameTrackerCoreTests/` and use Swift Testing:

| File | What it covers |
| --- | --- |
| `GameServeLogicTests` | Singles and doubles serve-fault rotation |
| `LiveSyncCoordinatorTests` | Phone/watch snapshots and pairing |
| `TimerDriftResolverTests` | Snap, ignore, and glide |
| `SwiftDataGameManagerTests` | Scoring and persistence |
| `LiveGameStateManagerWatchTests` | Watch live-state when a game is detached or deleted |

The core `Package.swift` declares the library target only, so these files are not registered as an SPM test target. Feature-package tests were removed.

The Xcode project has two UI test targets. Both launch the app:

- `PickleballGameTrackerUITests` (iOS)
- `PickleballGameTrackerWatchUITests` (watchOS)

## Build and run

You need Xcode 26 or later (Swift 6.2, iOS 26, watchOS 26).

1. Clone this repo.
2. Open `PickleballGameTracker.xcworkspace`, not the `.xcodeproj`.
3. Select the `PickleballGameTracker` scheme for iPhone, or `PickleballGameTrackerWatch` for Watch plus the iPhone companion.
4. Choose a simulator or a paired device and run (⌘R).

Catalog, setup, live scoring, history, roster, and stats run on the iOS Simulator. WatchConnectivity, HealthKit, and Live Activities need a paired iPhone and Apple Watch to exercise fully.

## Status

I paused this project after the last commit on 14 December 2025 (pushed 15 December 2025). There are no GitHub releases and no App Store listing. Persistence is local SwiftData. Cloud types are not implemented (`SupabaseTypes.swift` is empty).

## Roadmap

Open issues still include leftover local work: serving rotation in the live UI ([#11](https://github.com/ethanhanderson/PickleballGameTracker/issues/11)), roster polish ([#9](https://github.com/ethanhanderson/PickleballGameTracker/issues/9)), player/team participants ([#39](https://github.com/ethanhanderson/PickleballGameTracker/issues/39)), identity stats ([#38](https://github.com/ethanhanderson/PickleballGameTracker/issues/38)), UX and accessibility ([#33](https://github.com/ethanhanderson/PickleballGameTracker/issues/33)), advanced statistics ([#32](https://github.com/ethanhanderson/PickleballGameTracker/issues/32)), and platform polish ([#19](https://github.com/ethanhanderson/PickleballGameTracker/issues/19)).

Phase 2 is cloud accounts and sync. None of it is built:

- [2.1 Authentication UI](https://github.com/ethanhanderson/PickleballGameTracker/issues/27)
- [2.2 Supabase client and schema](https://github.com/ethanhanderson/PickleballGameTracker/issues/28)
- [2.3 Local-to-cloud migration](https://github.com/ethanhanderson/PickleballGameTracker/issues/29)
- [2.4 Cloud sync](https://github.com/ethanhanderson/PickleballGameTracker/issues/30)

[3.1 Realtime game synchronization](https://github.com/ethanhanderson/PickleballGameTracker/issues/31) is the Phase 3 follow-on.

---

Ethan Anderson · [ehadev.com](https://ehadev.com) · [github.com/ethanhanderson](https://github.com/ethanhanderson)
