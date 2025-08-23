# Statistics

- **Document name**: Statistics
- **Category**: features
- **Area**: cross-cutting (iOS/watchOS)

## Summary

- **Purpose**: Provide insightful, privacy‑respecting analytics for players, teams, and games.
- **Scope**: Dedicated Statistics tab with an Overview screen composed of grouped stat cards, and per‑stat Detail screens. Overview replaces History embedded cards.
- **Outcome**: Users see an overall picture of their performance via grouped stat cards. Tapping a card opens a Detail view with expanded context (charts/tables). Deep links from Completed Game open the corresponding Detail with filters applied.

## Audience & Owners

- **Audience**: engineers, testers, designers
- **Owners**: iOS/watchOS engineering
- **Last updated**: 2025-08-10
- **Status**: draft
- **Version**: v0.3

## Architecture Context

- **Layer**: presentation (Overview and Detail views) | domain (aggregation logic) | data (derived from games/players/teams)
- **Entry points**: `Statistics` tab (Overview) → tap stat card → per‑stat Detail; deep links from Completed Game open a specific Detail with pre‑applied filters
- **Dependencies**: `SwiftCharts`, `SharedGameCore` storage/managers, `DesignSystem`, logging
- **Data flow**: Persist per‑game summaries during play → aggregate per user/player/team → Overview renders grouped stat cards → tap card → Detail renders charts/tables with filters. Completed Game deep link applies filters (e.g., `gameId`, `gameTypeId`, date range, participants) directly to a Detail.

## Responsibilities

- **Core responsibilities**:
  - Capture minimal per-game metrics during tracking (serve outcomes, rally lengths, point sources, errors proxy like kitchen/out)
  - Present KPIs (win rate, point differential, serve-win %, streaks, trend lines) with appropriate chart types
  - Provide logical filters (date range, game type/variation, partner/opponent, players/teams)
  - Ensure data is private to the user’s account/device
- **Non-goals**:
  - Elo/TrueSkill ranking (post-1.0)

## Structure & Key Types

- **Primary types**:
  - Domain: `StatisticsAggregator`, `StatisticsFilters`
  - iOS views: `StatisticsHomeView` (Overview), per‑stat `StatDetailView` types (e.g., Win Rate Detail, Serve Win % Detail, Streaks Detail)
- **File locations**: Aggregation in `SharedGameCore/Services/*`; iOS views in `Pickleball Score Tracking/Features/Statistics/Screens/*` (Overview/Detail) and shared UI components under platform `UI/`
- **Initialization**: Aggregator consumes stored games; Overview binds to summaries; Detail binds to filters and data series.

## Overview and Detail model

- **Overview (main tab view)**: A grid/list of stat cards grouped by category (e.g., Results, Serving, Trends, Streaks). Card content shows a concise KPI and small sparkline/mini chart when helpful.
- **Detail (drill‑in)**: Tapping any card opens its corresponding Detail with expanded charts/tables, controls for filters, and contextual explanations. Detail is the target of deep links from Completed Game.

## Initial stats (v0.3)

- **Results**

  - Win rate (overall; supports date and game type filters)
  - Point differential per game (avg, median; distribution)
  - Games played (count; by period)
  - Average game duration

- **Serving**

  - Serve win % (points won on own serve) — implemented with a v0.3 approximation using summaries/games until rally‑level outcomes are persisted
  - Side‑out rate (opponent winning return games) — computed from summaries/games in v0.3 with approximations
  - Average rally length on serve — derived from `totalRallies` and time per game; refined rally‑level accuracy deferred

- **Trends**

  - 7‑day and 30‑day win rate trend (sparkline)
  - Rolling point differential trend

- **Streaks**
  - Current win streak
  - Longest win streak (with date range)

Each stat has a dedicated Detail view (e.g., `WinRateDetailView`, `ServeWinDetailView`, `PointDifferentialDetailView`, `StreaksDetailView`, `TrendLinesDetailView`).

## Grouping and ordering policy (v0.3)

- **Groups are hard‑coded**: Results, Serving, Trends, Streaks.
- **Dynamic ordering within groups**: Cards inside a group are ordered by a relevance score computed from recent activity (recency‑weighted), variance (interestingness), and user interactions (view taps). When no signal, default to the canonical order above.
- **Group block reordering**: Allowed when relevance score difference between adjacent groups exceeds a threshold to avoid jitter. Default order is Results → Serving → Trends → Streaks.
- **User affordances (future)**: Pin favorites and persist order (post‑v0.3).

## Deep‑link target mapping (Completed Game → Statistics Detail)

- Completed Game actions deep‑link to the Statistics tab and open the default Results detail: `WinRateDetailView` with filters pre‑applied for the game’s participants, game type, and date range focused on the game day.
- Users can switch to other stat details in‑place; filters remain applied across details within the Statistics tab session.

## Platform Sections (use as needed)

- **iOS**: Rich charts (lines, bars, distributions), tables, and highlight cards; deep links from history/completed game
- **watchOS**: Compact charts and key KPIs; fewer controls with sensible defaults

## Data & Persistence

- **Models**: Derived metrics keyed by game/player/team
- **Container**: Stored alongside games; small footprint; retained as long as referenced entities exist
- **Storage**: Local-first; mirrored to cloud in v0.6; access limited to the owner. Statistics prefer `GameSummary` rows (persisted on save/update) and fall back to full `Game` scans when summaries are unavailable.

## State & Concurrency

- **UI isolation**: `@MainActor` views
- **Observable state**: Filters observable; charts update reactively
- **Actors/Sendable**: Aggregation work split into safe chunks; sendable results

## Navigation & UI

- **Patterns**: Statistics tab Overview → grouped stat cards → tap card → per‑stat Detail; deep links open a specific Detail with filters applied.
- **Destinations**: Drill‑in views for each metric; filter editor within Detail views.
- **Components**: Stat cards, KPI highlights, grouped sections, filter pills, empty/zero‑state, SwiftCharts visualizations.
- **Design System**: Rich but cohesive color mapping by metric category; no hardcoded colors/spacing/typography.

## Systems Integration

- **Logging**: Track heavy computation durations and filter usage
- **Sync**: Future mirroring to cloud; filters remain local preferences
- **Haptics**: Subtle feedback on filter changes

## Error Handling

- **Typed errors**: Data unavailable, computation failed; `LocalizedError`
- **User surfaces**: Friendly empty states; retry options

## Testing & Performance

- **Tests**: Aggregation correctness; filter application; deep-link pre-filters; chart data integrity
- **Performance**: Precompute summaries on save; incremental updates; paginate history queries

## Open Questions & Future Work

- **Gaps**: Advanced correlation analyses; custom dashboards; dynamic group re‑ordering by relevance.
- **Planned extensions**: Post‑1.0 ratings (Elo/TrueSkill), shareable snapshots.
- **Decisions (tasks)**: Finalize the initial stats set and their grouping taxonomy for the Overview. Decide which groups are hard‑coded vs. dynamically re‑ordered based on user data and recency.

## References

- **Code**: Aggregator/services and views (to be added)
- **Related docs**: `docs/features/history.md`, `docs/systems/observability/testing-and-performance.md`

## Code path anchors

- `SharedGameCore/Sources/SharedGameCore/Services/SwiftDataStorage.swift` (stats summaries on save)
- `Pickleball Score Tracking/Features/Statistics/Screens/StatisticsHomeView.swift`
- Per‑stat `StatDetailView` files under `Pickleball Score Tracking/Features/Statistics/Screens/`

## Starter queries

- Where are per-game metrics persisted for later aggregation?
- How are deep-link filters applied when entering Statistics?

## Validation checklist (must meet for acceptance)

- **Swift 6.2 strict; iOS 17+ / watchOS 11+ targets** respected; no concurrency warnings
- **UI on `@MainActor`**; shared types are **`Sendable`**; actor boundaries clear
- **Modern SwiftUI**: `NavigationStack`, `@Observable`/`@Bindable`
- **DesignSystem-first**: no hardcoded colors/spacing/typography
- **SwiftData**: single app-level container; proper schema usage
- **Deep links**: Completed Game deep links open the correct Statistics Detail with filters applied.
- **Serving metrics**: Serve win % available (v0.3 approximation); side‑out and rally length approximations documented.
- **Typed errors** with `LocalizedError` where user-visible
- **Tests**: aggregation, filters, Overview → Detail navigation, and deep links covered
