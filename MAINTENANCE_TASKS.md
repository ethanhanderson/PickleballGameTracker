### Code Maintenance and Refactor Tasks

- **Task**: Unify HapticFeedbackService into core and remove duplicate

  - **Context**: There are two implementations of `HapticFeedbackService`:
    - `PickleballGameTrackerCorePackage/Sources/Core/Platform/Haptics/HapticFeedbackService.swift`
    - `PickleballGameTrackerPackage/Sources/GameTrackerFeature/Core/Services/HapticFeedbackService.swift`
      The feature-level one duplicates functionality. Consolidate to the core version to avoid divergence.
  - **What to do (for me, the LLM agent)**: Migrate all references in the app and watch feature to use the core package service. Delete the duplicate file in the feature package. Ensure imports and access control are correct across iOS/watchOS.
  - **Steps**:
    - [ ] Replace imports/usages in feature package to reference the core `HapticFeedbackService`.
    - [ ] Remove `PickleballGameTrackerPackage/Sources/GameTrackerFeature/Core/Services/HapticFeedbackService.swift`.
    - [ ] Build packages and app targets; fix any visibility or import issues.
    - [ ] Run unit tests touching haptics; verify behavior parity.
    - [ ] Update wiki: `systems/ux/haptics.md` to reflect the single-source service.

- **Task**: Replace GCD delays with Swift Concurrency (Task.sleep) in watch view

  - **Context**: `PickleballGameTrackerWatchPackage/Sources/GameTrackerWatchFeature/Features/ActiveGame/Screens/WatchActiveGameView.swift` uses `DispatchQueue.main.asyncAfter` in several places (e.g., score success feedback, toggle animations). Per concurrency guidelines, prefer structured concurrency.
  - **What to do (for me, the LLM agent)**: Swap `DispatchQueue.main.asyncAfter` calls with `try? await Task.sleep` inside `Task { @MainActor in ... }` blocks, keeping identical UX timing and main-actor state updates.
  - **Steps**:
    - [ ] Identify all `DispatchQueue.main.asyncAfter` usages in `WatchActiveGameView.swift`.
    - [ ] Replace with `Task { @MainActor in try? await Task.sleep(for: .milliseconds(N)); /* then toggle triggers */ }`.
    - [ ] Ensure any state mutation occurs on `@MainActor`.
    - [ ] Build and run watch target; validate haptic/animation timing.
    - [ ] Update wiki: `development/swift-concurrency` examples to include one of these replacements.

- **Task**: Annotate SwiftUI Views with @MainActor where missing

  - **Context**: Many SwiftUI view structs are not explicitly isolated. Our standard requires UI code on the main actor. Example with annotation present: `GameTrackerFeature/Features/ActiveGame/Components/TeamScoreCard.swift`. Apply this across feature and watch packages.
  - **What to do (for me, the LLM agent)**: Add `@MainActor` to SwiftUI `struct ... : View` declarations missing it in `PickleballGameTrackerPackage/Sources/GameTrackerFeature/**` and `PickleballGameTrackerWatchPackage/Sources/**`.
  - **Steps**:
    - [ ] Grep for `struct .*: View` and review files; skip those already annotated.
    - [ ] Add `@MainActor` above declarations lacking it.
    - [ ] Build; address any actor-isolation diagnostics by adjusting call sites or moving side-effects to `.task`.
    - [ ] Smoke test navigation and interactions.
    - [ ] Update wiki: `systems/ux/view-architecture.md` noting enforcement.

- **Task**: Migrate Core package tests from XCTest to Swift Testing

  - **Context**: Tests in `PickleballGameTrackerCorePackage/Tests/...` import XCTest. The project standard is the Swift Testing framework with `@Test` and `#expect`.
  - **What to do (for me, the LLM agent)**: Convert unit tests in the core package to use `import Testing`, replace XCTest assertions with `#expect/#require`, and adopt `@Test`/`@Suite`. Leave UI tests (UITests) on XCTest.
  - **Steps**:
    - [ ] For each core test file importing XCTest, switch to `import Testing`.
    - [ ] Replace `XCTAssert*` with `#expect/#require` equivalents.
    - [ ] Wrap related tests in `@Suite` where appropriate; convert test functions to `@Test`.
    - [ ] Update test target settings if needed to link Swift Testing.
    - [ ] Run tests for the package and fix failures.
    - [ ] Update wiki: `systems/observability/testing-and-performance.md` with migration note.

- **Task**: Replace ad-hoc Task{} sleeps in UI with utility helpers (readability)
  - **Context**: UI files like `TeamScoreCard.triggerScoreAnimation()` and watch view use inline `Task { @MainActor in try? await Task.sleep(...) }` for brief delays. Extract a tiny helper to improve readability and consistency.
  - **What to do (for me, the LLM agent)**: Create a small main-actor sleep helper in the core UI utilities and use it at call sites.
  - **Steps**:
    - [ ] Add a `@MainActor public func sleepMs(_ ms: Int) async` in a shared UI utilities file (core package).
    - [ ] Replace inline `Task.sleep` blocks in UI with `await sleepMs(N)` within main-actor async contexts.
    - [ ] Build and ensure identical UX timing.
    - [ ] Document helper in `systems/ux/design-system.md` (Utilities section).
