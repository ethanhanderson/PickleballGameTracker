# Game Type Creation

- **Document name**: Game Type Creation
- **Category**: features
- **Area**: cross-cutting (SharedGameCore, iOS authoring; iOS/watchOS consumption)

## Summary

- **Purpose**: Let users define new ways to play by creating configurable, reusable game types (private or public) with optional publishing and author attribution.
- **Scope**: Authoring on iOS (create/edit/clone/privacy toggle); selection on iOS and watchOS; gallery/templates; deep linking/QR.
- **Outcome**: Users can craft rule sets that feel native, share them, and consume them across devices.

## Audience & Owners

- **Audience**: engineers, testers, designers
- **Owners**: iOS/watchOS engineering
- **Last updated**: 2025-08-10
- **Status**: draft
- **Version**: v0.6

## Architecture Context

- **Layer**: presentation (authoring UI) | domain (models, validation) | data (storage/sync-ready)
- **Entry points**: iOS `Game Type Gallery` → `Create/Edit Game Type` → `Preview & Publish`; selection surfaces in Games and watch catalog
- **Dependencies**: `SharedGameCore` models/services, `DesignSystem`, logging, persistence, (future) cloud
- **Data flow**: Form inputs → validation → preview → save (local + cloud when available) → list refresh; deep links/QR resolve to fetch-and-open

## Responsibilities

- **Core responsibilities**:
  - Author game types with required fields for playable games and optional rule toggles
  - Manage privacy (private/public) and post-publish edits with moderate rate limits
  - Attribute creators via author profiles and expose deep links/QR
  - Provide templates, field help, and real-time validation with publish preview
- **Non-goals**:
  - Realtime collaboration in the editor (future)
  - Server-side moderation workflows (future)

## Structure & Key Types

- **Primary types**: `GameType`, `GameVariation` (applied settings), `AuthorProfile`
- **File locations**: `SharedGameCore/Models/*`; iOS authoring views under `Pickleball Score Tracking/Views/...` (new authoring folder)
- **Initialization**: iOS presents gallery and editor; watchOS consumes fetched types only

## Platform Sections (use as needed)

- **SharedGameCore**: Models for `GameType`, `AuthorProfile`; validation rules; typed errors
- **iOS**: Full authoring UI (create/edit/clone/privacy); template gallery; preview; share link/QR; creator header in Game Detail
- **watchOS**: Read-only consumption in catalog; start game from selected type

## Data & Persistence

- **Models**: Required minimal fields for playable game: players/teams schema, scoring target/limits, time options; optional fields: kitchen, side switching, point-on-serve, win-by-2, rotation/serve styles
- **Container**: Standard SwiftData container; forward-compatible for cloud
- **Storage**: Game types stored in database; fetched at app launch/refresh; private/public visibility; link/QR resolves by ID

## State & Concurrency

- **UI isolation**: Authoring views on `@MainActor`
- **Observable state**: Editor state with real-time validation; publish state
- **Actors/Sendable**: Models/DTOs are `Sendable`; network/DB boundaries future-proofed

## Navigation & UI

- **Patterns**: Gallery → Editor → Preview & Publish; clone from existing; Game Detail shows creator header with avatar/name/created-on/plays count; tap author → Author Profile list of types
- **Destinations**: Author Profile, Game Type Detail, Editor
- **Components**: Required/optional field labels, inline help text, validation callouts, live preview card
- **Design System**: Use tokens for form fields, badges (Private/Public), and preview

## Systems Integration

- **Logging**: Events for create/edit/clone/publish/privacy-toggle with context
- **Sync**: Local now; cloud in v0.6+ for distribution across devices
- **Haptics**: Light feedback on validations passing/publish success

## Error Handling

- **Typed errors**: Validation errors, rate-limit exceed, not-authorized for edit of public types; all `LocalizedError`
- **User surfaces**: Inline field errors; blocking sheet on publish failures with retry

## Testing & Performance

- **Tests**: Validation rules; privacy transitions; cloning fidelity; deep-link resolution
- **Performance**: Efficient list fetching with pagination; debounce validation

## Open Questions & Future Work

- **Gaps**: Moderation signals; versioning/migrations for published types
- **Planned extensions**: Import/export; curated featured templates; runtime A/B rule previews

## References

- **Code**: `SharedGameCore/Models/*`, iOS authoring views (to be added)
- **Related docs**: `docs/features/games.md`, `docs/systems/ux/navigation.md`, `docs/systems/data/storage.md`, `docs/features/author-profiles.md`, `docs/systems/ux/deep-linking.md`

## Validation checklist (must meet for acceptance)

- **Swift 6.2 strict; iOS 17+ / watchOS 11+ targets** respected; no concurrency warnings
- **UI on `@MainActor`**; shared types are **`Sendable`**; actor boundaries clear
- **Modern SwiftUI**: `NavigationStack`, `@Observable`/`@Bindable`
- **DesignSystem-first**: no hardcoded colors/spacing/typography
- **SwiftData**: single app-level container; proper schema usage
- **Typed errors** with `LocalizedError` where user-visible
- **Tests**: validation, privacy, cloning, deep-link resolution covered
