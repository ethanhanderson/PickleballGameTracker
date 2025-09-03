## Roadmap: Maintenance & Refactoring Tasks (Batchable)

These tasks are maintenance/refactor oriented and can be executed in the same iteration. Each item references its Roadmap ID and the linked repository issue for alignment.

### 1.12 — Polish platform and performance ([#19](https://github.com/ethanhanderson/PickleballGameTracker/issues/19))
- **Roadmap ID**: 1.12
- **Project Item ID**: PVTI_lAHOASThjM4BBPKszgd8h1Q
- **Type**: Maintenance/Performance
- **Docs**: `PickleballGameTracker.wiki/systems/observability/testing-and-performance.md`

Concise description:
- Audit and optimize runtime hot paths across iOS/watchOS. Reduce main-thread work, fix unnecessary SwiftUI view re-renders, optimize state propagation, and tighten logging/profiling so regressions are detectable.

Steps to complete:
- Define perf targets and acceptance checks in `PickleballGameTracker.wiki/systems/observability/testing-and-performance.md`.
- Profile cold and warm startup; move expensive work off the main thread using Swift 6 structured concurrency with `@MainActor` isolation boundaries.
- Minimize SwiftUI invalidations: extract stable view models, add `@Observable` best practices, and memoize computed UI state where appropriate.
- Reduce allocations and copies in core models; audit `Sendable` conformance and remove needless `@MainActor` from non-UI types.
- Add lightweight performance logs and metrics around navigation, list rendering, and statistics aggregation.
- Create repeatable benchmarks (simple UI test timings + targeted unit perf tests) and document results in the wiki.

### 1.23 — Roster UX polish: duplicate merge, archive/restore, preset hook ([#9](https://github.com/ethanhanderson/PickleballGameTracker/issues/9))
- **Roadmap ID**: 1.23
- **Project Item ID**: PVTI_lAHOASThjM4BBPKszgd8hxY
- **Type**: Maintenance/UX polish
- **Docs**: `PickleballGameTracker.wiki/features/player-team-management.md`

Concise description:
- Improve roster management by enabling safe duplicate detection/merge, archive/restore flows, and a hook to start games from presets directly from roster items.

Steps to complete:
- Add duplicate detection utilities (normalized name + members) and a merge flow with confirmation.
- Implement archive/restore with clear affordances and state indicators; ensure queries exclude archived by default.
- Add a preset start hook from roster list/detail, wiring to existing game preset start flow.
- Update previews and accessibility labels; add UI tests for merge and archive flows.
- Document UX guidelines and edge cases in the wiki page.

### 3.6 — Improve UX and accessibility ([#33](https://github.com/ethanhanderson/PickleballGameTracker/issues/33))
- **Roadmap ID**: 3.6
- **Project Item ID**: PVTI_lAHOASThjM4BBPKszgd8h_8
- **Type**: Maintenance/Accessibility
- **Docs**: `PickleballGameTracker.wiki/systems/observability/testing-and-performance.md`, `PickleballGameTracker.wiki/systems/ux/design-system.md`

Concise description:
- Systematically raise baseline accessibility: VoiceOver, Dynamic Type, contrast, focus order, hit targets, haptics semantics, and motion reduction compliance.

Steps to complete:
- Run an accessibility audit across primary flows (Roster, Active Game, History, Statistics) and log findings.
- Add `.accessibilityLabel`, `.accessibilityHint`, and `accessibilitySortPriority` where navigation/focus is ambiguous.
- Ensure Dynamic Type scales; replace fixed sizes with tokenized styles; verify minimum hit targets.
- Fix contrast using design tokens; add reduced motion alternatives for animations.
- Add targeted UI tests for VoiceOver traversal on critical screens.
- Document the baseline rules and exemptions in the wiki.

---

Batch plan notes:
- 1.12, 1.23, and 3.6 can be delivered in a single polishing/refactor milestone with separate PRs but shared profiling and accessibility checks.
