# Testing & Performance

- **Document name**: Testing & Performance
- **Category**: systems
- **Area**: cross-cutting

## Summary

- **Purpose**: Define test strategy and performance practices for the app and shared core.
- **Scope**: Persistence, concurrency/actors, UI behavior tests; performance guidelines.
- **Outcome**: Reliable regression safety and responsive UX.

## Audience & Owners

- **Audience**: engineers, testers
- **Owners**: iOS/watchOS engineering
- **Last updated**: 2025-08-10
- **Status**: draft
- **Version**: v0.3 baseline

## Architecture Context

- **Layer**: cross-cutting
- **Entry points**: `SharedGameCoreTests`, app UI tests and unit tests
- **Dependencies**: XCTest, SwiftData
- **Data flow**: Tests create and query via storage/managers; UI tests drive views

## Responsibilities

- **Core responsibilities**:
  - Ensure persistence flows work end-to-end
  - Validate concurrency isolation and actor usage
  - Verify UI behaviors and navigation
- **Non-goals**:
  - Trivial tests with little utility

## Structure & Key Types

- **Primary types**: Test suites under `SharedGameCore/Tests/*`, app `*Tests` targets
- **File locations**: As above
- **Initialization**: Use preview containers or test containers

## Platform Sections (use as needed)

- **iOS/watchOS**: Platform-specific UI tests where relevant

## Data & Persistence

- **Models**: Test `Game` persistence and queries
- **Container**: Use isolated stores for tests
- **Storage**: Exercise all storage operations

## State & Concurrency

- **UI isolation**: Assert main-actor usage for UI code
- **Observable state**: Validate updates propagate to views
- **Actors/Sendable**: Ensure `Sendable` boundaries and no data races

## Navigation & UI

- **Patterns**: Test `NavigationStack` routes and sheet presentations
- **Destinations**: Verify typed destination paths
- **Components**: Snapshot or rendering checks for key components
- **Design System**: Verify token usage where applicable

## Systems Integration

- **Logging**: Optionally assert key log events emitted
- **Sync**: Basic tests around active game presence across devices (where feasible)
- **Haptics**: Not executed in CI; assert call sites

## Error Handling

- **Typed errors**: Verify user-visible messages
- **User surfaces**: Assert error views appear on failures

## Performance Practices

- **Tests**: As above
- **Performance**: Use lazy containers, stable IDs, and avoid heavy work in `body`; pre-aggregate statistics where possible; paginate history; measure critical paths if needed

---

## Fast local testing strategy (CPU-friendly)

- **Principles (MUST)**:

  - Prefer unit and package tests locally; run UI tests only before review or on CI.
  - Disable code coverage for local loops; avoid parallel test scheduling that spins multiple simulators.
  - Pin one simulator destination and reuse the same booted device.

- **Direct commands (copy/paste)**

  - iOS unit tests only (no UI, no coverage):

    ```bash
    xcodebuild -project "Pickleball Score Tracking.xcodeproj" \
      -scheme "Pickleball Score Tracking" \
      -destination "platform=iOS Simulator,name=iPhone 16" \
      -only-testing:Pickleball\ Score\ TrackingTests \
      -enableCodeCoverage NO \
      -parallel-testing-enabled NO \
      test
    ```

  - Skip all UI tests by default (local):

    ```bash
    xcodebuild -project "Pickleball Score Tracking.xcodeproj" \
      -scheme "Pickleball Score Tracking" \
      -destination "platform=iOS Simulator,name=iPhone 16" \
      -skip-testing:"Pickleball Score TrackingUITests" \
      -enableCodeCoverage NO \
      -parallel-testing-enabled NO \
      test
    ```

  - watchOS tests (unit only, skip UI bundle):

    ```bash
    xcodebuild -project "Pickleball Score Tracking.xcodeproj" \
      -scheme "Pickleball Score Tracking Watch App" \
      -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)" \
      -skip-testing:"Pickleball Score Tracking Watch AppUITests" \
      -enableCodeCoverage NO \
      -parallel-testing-enabled NO \
      test
    ```

  - SharedGameCore (package) tests (fast):

    ```bash
    mcp_XcodeBuildMCP_swift_package_test(
      packagePath: "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking/SharedGameCore",
      parallel: false,
      showCodecov: false
    )
    ```

- **When to run UI tests (SHOULD)**:

  - Before pushing for review or release builds.
  - On CI with coverage enabled and default parallelism.

- **Makefile shortcuts (recommended)**:
  - `make test-core-fast` → SharedGameCore tests.
  - `make test-ios-fast` → iOS unit tests only, no coverage, no parallel.
  - `make test-watch-fast` → watchOS unit tests only, no coverage, no parallel.

## Open Questions & Future Work

- **Gaps**: Broader coverage for new services in v0.6/v1.0
- **Planned extensions**: Performance benchmarks for sync and realtime

## References

- **Code**: `SharedGameCore/Tests/*`, app tests directories
- **Related docs**: `docs/architecture/overview.md`

---

## Validation checklist (must meet for acceptance)

- Baseline validation: see `docs/systems/observability/validation-baseline.md`
- **Swift 6.2 strict; iOS 17+ / watchOS 11+ targets** respected; no concurrency warnings
- **UI on `@MainActor`**; shared types are **`Sendable`**; actor boundaries clear
- **Modern SwiftUI**: `NavigationStack`, `@Observable`/`@Bindable`
- **DesignSystem-first**: no hardcoded colors/spacing/typography
- **SwiftData**: single app-level container; proper schema usage
- **Typed errors** with `LocalizedError` where user-visible
- **Tests**: persistence, concurrency, and core UI behaviors covered
