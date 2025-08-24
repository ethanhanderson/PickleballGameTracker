# Deep Linking

- **Document name**: Deep Linking
- **Category**: systems
- **Area**: cross-cutting (iOS, watchOS)

## Summary

- **Purpose**: Define link formats, routing, and security for opening in-app destinations from URLs/QR codes (game types, author profiles, completed game shares).
- **Scope**: Universal links and custom scheme; link resolution to typed destinations; expiring share links for completed games.
- **Outcome**: Deterministic navigation and safe sharing that respects privacy and platform conventions.

## Audience & Owners

- **Audience**: engineers, testers
- **Owners**: iOS/watchOS engineering
- **Last updated**: 2025-08-12
- **Status**: draft
- **Version**: v0.3→v0.6 compatible

## Architecture Context

- **Layer**: presentation (navigation) + domain (resolver) + data (share token store)
- **Entry points**: App open URL handler; QR scanner; share sheet
- **Dependencies**: Navigation system, logging, storage, (future) cloud
- **Data flow**: URL → `DeepLinkResolver` parse/validate → map to destination/value types → navigate; for shares: token lookup/validation → navigate or show error

## Responsibilities

- **Core responsibilities**:
  - Define URL formats and parameters for supported destinations
  - Resolve links to typed destinations and inputs (e.g., ids, filters)
  - Support expiring share links for completed games with policy durations
  - Generate and parse QR codes for share and quick access
- **Non-goals**:
  - Web SEO indexing and public listing
  - Analytics tracking (beyond optional logging)

## Structure & Key Types

- **Primary types**: `DeepLink`, `DeepLinkDestination`, `DeepLinkResolver`, `ShareToken`
- **File locations**: Resolver/service in `SharedGameCore/Services/*`; platform URL handlers in app targets
- **Initialization**: Configure resolver at app startup; register with navigation factory

## Link Formats (v0.3 implemented)

- **Universal link**: `https://matchtally.app/<entity>/<id>[?params]`
- **App scheme**: `matchtally://<entity>/<id>[?params]`
- **Entities**:
  - `gametype/{gameTypeId}` → Game Type detail
  - `author/{authorId}` → Author profile
  - `game/{completedGameId}?token=<shareToken>` → Completed Game (requires valid, unexpired token)
  - `stats/game/{gameId}` or `statistics/gametype/{gameType}` → Statistics tab with pre-applied filters (v0.3 placeholder view)
  - `stats?gameId=...&gameType=...` (universal link variant)
- **QR codes**: Encode the universal link; scanner opens the same routes

## Security & Privacy

- **ShareToken**: Signed, time-limited token; durations: 1h, 1d, 7d, 30d, indefinite; scoped to completed game id
- **Validation**: Reject missing/expired/invalid tokens; no PII in links; log reason codes
- **Visibility**: Private data remains user-owned; public game types accessible by id

## Navigation & UI (v0.3)

- **Mapping**: Resolver maps to `GameTypeDetail`, `AuthorProfileView`, `CompletedGameDetailView`, and `Statistics` tab routing (switches tab and presents a placeholder filtered view in v0.3)
- **Failure surfaces**: Friendly error state with retry/dismiss; option to open app home
- **Design System**: Consistent error/empty states

## Systems Integration

- **Logging**: Emit events on resolve success/failure with minimal metadata
- **Storage**: Token issuance/validation via storage layer; background cleanup of expired tokens
- **Sync**: Future cloud token verification on server (v0.6+)

## Error Handling

- **Typed errors**: `invalidLink`, `expiredToken`, `notFound`, `unauthorized` (as `LocalizedError`)
- **User surfaces**: Clear messages; no sensitive detail

## Testing & Performance

- **Tests**: Resolver parsing, token validation, navigation mapping, QR encoding/decoding
- **Performance**: Lightweight parsing; cache recent resolutions; avoid blocking main thread

## Open Questions & Future Work

- **Gaps**: Domain choice for universal links; server validation for tokens
- **Planned extensions**: Invite links and deep links for presets

## References

- **Code**: `SharedGameCore/Services/DeepLinkResolver.swift`, `SharedGameCore/Services/DeepLinkBus.swift`, `Pickleball Score Tracking/Views/Infrastructure/Navigation/AppNavigationView.swift`
- **Related docs**: `docs/systems/ux/navigation.md`, `docs/features/completed-game-view.md`, `docs/features/game-type-creation.md`, `docs/features/author-profiles.md`

## Validation checklist (must meet for acceptance)

- **Swift 6.2 strict; iOS 17+ / watchOS 11+ targets** respected; no concurrency warnings
- **UI on `@MainActor`**; shared types are **`Sendable`**; actor boundaries clear
- **Modern SwiftUI**: `NavigationStack`, `@Observable`/`@Bindable`
- **DesignSystem-first**: no hardcoded colors/spacing/typography
- **SwiftData**: single app-level container; proper schema usage
- **Typed errors** with `LocalizedError` where user-visible
- **Tests**: parsing, mapping, and token flows covered
