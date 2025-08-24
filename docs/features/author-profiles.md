# Author Profiles

- **Document name**: Author Profiles
- **Category**: systems
- **Area**: cross-cutting (iOS authoring; iOS/watchOS attribution)

## Summary

- **Purpose**: Provide creator attribution for user-published game types with a consistent identity surface (name, avatar/icon) and profile view.
- **Scope**: Profile creation on first publish (iOS), display in Game Type detail headers, profile screen with authored types and stats; read-only on watchOS.
- **Outcome**: Users see who created a game type and can explore that author’s other types safely and privately.

## Audience & Owners

- **Audience**: engineers, testers, designers
- **Owners**: iOS/watchOS engineering
- **Last updated**: 2025-08-10
- **Status**: draft
- **Version**: v0.6 (forward-compatible from v0.3)

## Architecture Context

- **Layer**: cross-cutting (presentation + domain + data touchpoints)
- **Entry points**: Tap author header in Game Type detail → `AuthorProfileView`; first publish flow creates profile
- **Dependencies**: `SharedGameCore` models/services, `DesignSystem`, logging, deep linking, persistence, (future) cloud
- **Data flow**: Publish flow ensures or creates profile → associate `GameType.authorId` → headers fetch author summary → profile view lists authored types + stats

## Responsibilities

- **Core responsibilities**:
  - Maintain author identity (display name, avatar/icon/emoji, optional bio)
  - Attribute `GameType` with creator and show created-on and plays count
  - Expose profile view with list of authored public types and summary stats
  - Support deep links/QR to an author profile
- **Non-goals**:
  - Social graphs (followers/likes) and moderation workflows (future)
  - Cross-user messaging or comments

## Structure & Key Types

- **Primary types**: `AuthorProfile` (id, displayName, avatarKind, createdAt, stats), `AuthorService`
- **File locations**: Core types under `SharedGameCore/Sources/SharedGameCore/Models` and `.../Services`; app views under platform `Views/...`
- **Initialization**: Created lazily on first publish; otherwise fetched and cached

## Platform Sections (use as needed)

- **iOS**: Author creation/edit limited to publish flow; profile view lists authored game types and basic stats
- **watchOS**: Read-only attribution surfaces; optional compact profile view

## Data & Persistence

- **Models**: `AuthorProfile` with stats (counts: authored types, total plays)
- **Container**: Stored in SwiftData locally; mirrored to cloud in v0.6
- **Storage**: Fetch by `authorId`; denormalized plays count updated by storage-side aggregations

## State & Concurrency

- **UI isolation**: Profile UI on `@MainActor`
- **Observable state**: Profile loader state; list of authored `GameType`
- **Actors/Sendable**: DTOs `Sendable`; service isolates background updates

## Navigation & UI

- **Patterns**: Game Type detail header with avatar/name/date/plays → tap to profile
- **Destinations**: `AuthorProfileView`
- **Components**: Avatar/icon renderer; authored-type card list using `DesignSystem`
- **Design System**: Use tokens for typography, color, and spacing

## Systems Integration

- **Logging**: View impressions and navigation; publish and edit events
- **Sync**: Cloud mirrored in v0.6; local cache otherwise
- **Deep Linking**: `deeplink://author/{authorId}` and universal link route to profile

## Error Handling

- **Typed errors**: Not found, permission, network/storage; `LocalizedError`
- **User surfaces**: Content unavailable states; retry affordances

## Testing & Performance

- **Tests**: Profile creation on publish; attribution rendering; plays count aggregation
- **Performance**: Cache profile summaries; paginate list of authored types

## Open Questions & Future Work

- **Gaps**: Verification badges; profile moderation
- **Planned extensions**: Rich bios and links; featured authors

## References

- **Code**: `SharedGameCore/Models/*`, `SharedGameCore/Services/*`
- **Related docs**: `docs/features/game-type-creation.md`, `docs/features/games.md`, `docs/systems/ux/deep-linking.md`

## Validation checklist (must meet for acceptance)

- **Swift 6.2 strict; iOS 17+ / watchOS 11+ targets** respected; no concurrency warnings
- **UI on `@MainActor`**; shared types are **`Sendable`**; actor boundaries clear
- **Modern SwiftUI**: `NavigationStack`, `@Observable`/`@Bindable`
- **DesignSystem-first**: no hardcoded colors/spacing/typography
- **SwiftData**: single app-level container; proper schema usage
- **Typed errors** with `LocalizedError` where user-visible
- **Tests**: creation, attribution rendering, aggregation covered
