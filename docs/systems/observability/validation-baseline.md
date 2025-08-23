# Validation Baseline (Authoritative)

- Purpose: Single source of invariant validation checks to avoid duplication across docs.
- Applies to: iOS 17+, watchOS 11+, Swift 6.2 strict concurrency.

## Baseline checks (inherit in all docs)

- Swift 6.2 strict concurrency; no concurrency warnings
- UI on `@MainActor`; shared types are `Sendable`; clear actor boundaries
- Modern SwiftUI patterns: `NavigationStack`, `@Observable`/`@Bindable`, `@Query` when applicable
- DesignSystem-first: no hardcoded colors/spacing/typography
- SwiftData: single app-level container; proper schema usage
- Typed errors with `LocalizedError` where user-visible
- Tests cover persistence, concurrency/actors, and core UI behaviors

## Usage

- In each doc’s Validation section, include: “Baseline validation: see `docs/systems/observability/validation-baseline.md`”, then add only domain-specific checks.
