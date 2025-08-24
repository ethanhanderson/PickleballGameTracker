# Roadmap Governance & Agent Workflow

- **Document name**: Roadmap Governance & Agent Workflow
- **Category**: systems
- **Area**: cross-cutting (iOS, watchOS, SharedGameCore)

## Summary

- **Purpose**: Define how the Kanban roadmap (`docs/implementation-roadmap.md`) is maintained and how agents/developers interface with it to keep planning accurate as features evolve.
- **Scope**: Board ownership, card lifecycle, version lanes, acceptance rules, and links to authoritative docs.
- **Outcome**: A predictable process that keeps planning, docs, and code in sync.

## Audience & Owners

- **Audience**: engineers, testers
- **Owners**: iOS/watchOS engineering
- **Last updated**: 2025-08-10
- **Status**: draft
- **Version**: v0.3 baseline

## Architecture Context

- **Layer**: cross-cutting process over presentation/domain/data
- **Entry points**: `docs/implementation-roadmap.md` (Kanban board)
- **Dependencies**: `docs/architecture/*`, `docs/features/*`, `docs/systems/*`
- **Data flow**: Card intent → linked docs updated (source of truth) → code changes → board status updated → acceptance verified

## Responsibilities

- **Core responsibilities**:
  - Maintain a single planning source of truth at `docs/implementation-roadmap.md`
  - Ensure each card links to authoritative docs and relevant code paths
  - Enforce WIP limits and version lane discipline (v0.3, v0.6, v1.0)
  - Require acceptance criteria per card aligned to linked doc checklists
- **Non-goals**:
  - Store design or implementation details in the board (keep in linked docs)

## Structure & Key Types

- **Primary types**: Roadmap board (cards), version lanes, tags
- **File locations**: `docs/implementation-roadmap.md`
- **Initialization**: Pre-populated lanes, card schema, and tags provided in the board

## Platform Sections (use as needed)

- **SharedGameCore**: Cards cover domain/data services and tests; link to package paths
- **iOS**: Cards cover features, navigation, and UI; link to iOS view/state files
- **watchOS**: Cards cover watch UI and parity tasks; link to watch views

## Data & Persistence

- **Models**: N/A
- **Container**: N/A
- **Storage**: Board lives in git; changes reviewed via PR

## State & Concurrency

- **UI isolation**: N/A
- **Observable state**: N/A
- **Actors/Sendable**: Cards are declarative YAML-like blocks embedded in markdown; values must be copy-paste safe

## Navigation & UI

- **Patterns**: Version lanes → columns → cards with clear status
- **Destinations**: Linked docs provide full behavior; board only points and tracks
- **Components**: Card schema in the board; tags for discovery
- **Design System**: N/A

## Systems Integration

- **Logging**: Record significant process changes in PR descriptions
- **Sync**: Keep board and docs synced atomically in the same change whenever behavior changes
- **Haptics**: N/A

## Error Handling

- **Typed errors**: N/A
- **User surfaces**: N/A

## Testing & Performance

- **Tests**: Process checks via CI markdown lints on changed docs
- **Performance**: Keep board concise; avoid duplicate content with linked docs

## Definition of Ready (DoR)

- **Before moving a card to In Progress, all must be true**:
  - `links.docs` and `links.code` contain concrete, existing paths
  - `links.commands` includes deterministic build/test commands for iOS and watchOS with explicit destinations
  - `validation.refs` lists doc checklist anchors that acceptance will be validated against
  - `tests.touchpoints` enumerates suites/files to modify or confirms a new test will be added
  - Dependencies are acknowledged and unblocking steps (if any) are noted

## Local quick checks

- Run a lightweight link and anchors check locally before committing:
  - Script: `docs/systems/devx/roadmap-quick-check.sh`
  - Usage: `bash docs/systems/devx/roadmap-quick-check.sh`
  - What it does: verifies that for all In Progress cards, linked doc/code files exist, `validation.refs` anchors resolve, and `tests.touchpoints` paths exist (when applicable). Also runs fast tests by default.

## Priority governance (authoritative)

- Non-negotiables (MUST)

  - MUST NOT change `priority` on cards in In Review or Done. Preserve history for accurate metrics and retrospectives.
  - When a card moves to In Progress, treat its `priority` as the baseline for planning analytics.
  - If a mis-prioritization is discovered after completion, add a one-line note under `notes` explaining the learning; do not edit `priority`.

- Allowed changes (SHOULD/MAY)

  - Backlog and In Progress cards MAY have `priority` adjusted when objectives change. Record a brief rationale in `notes` and keep ordering coherent.
  - For broad shifts (e.g., re-scoping v0.3), create a single “Reprioritize [lane]” card that documents the rationale and links to updated cards.

- Agent instructions (MUST/SHOULD)
  - MUST NOT change `priority` on any Done card.
  - SHOULD rebaseline `priority` on Backlog and In Progress cards when asked to reprioritize a lane; add rationale to each affected card’s `notes`.
  - SHOULD avoid bulk changes that rewrite history; prefer targeted reprioritization of open work.

## Automatic task selection policy (authoritative)

- Trigger: When the user says "start a new task" without specifying a card.
- Active lane: Use the currently active version lane (default: v0.3) unless the user specifies a different lane.
- Selection rule:
  - Order by `priority` (P0 → P1 → P2), then by `size` (S → M → L → XL), then by number of `dependencies` (fewest first), then by lowest `id`.
  - Consider only cards with `status: Backlog` whose dependencies are all `Done`.
- WIP guard: If In Progress WIP ≥ limit, propose to finish or park an existing card before starting a new one.
- Transparency: Announce the chosen card ID/title and the reason (e.g., priority/size). If no eligible card exists, surface the nearest‑ready candidate and list the blocking dependency card IDs.

## Open Questions & Future Work

- **Gaps**: Automation to validate card links and required fields
- **Planned extensions**: CI checks for card schema and cross-link existence

## References

- **Code**: N/A
- **Related docs**: `docs/implementation-roadmap.md`, `docs/architecture/overview.md`, `docs/systems/observability/testing-and-performance.md`

---

## Validation checklist (must meet for acceptance)

- **Board is single source of planning truth** at `docs/implementation-roadmap.md`
- **Every active card links to authoritative docs** under `docs/*`
- **Docs updated first** when behavior changes; board updated in same PR
- **Swift 6.2 strict; iOS 17+ / watchOS 11+ targets** respected; no concurrency warnings
- **Tests and builds green** before moving cards to Done
- **Fast local tests executed** (`make test-all-fast`) before moving cards to In Review
