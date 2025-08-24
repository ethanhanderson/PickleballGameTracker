# Chat Kickoff — New Conversation Playbook

- Goal: Start fast, stay focused, and ship safely using the board and docs.

## Steps

1. Pick a card

   - Open `docs/implementation-roadmap.md` and pick a Backlog card (respect WIP ≤ 3..
   - Ensure it meets the Definition of Ready (see `docs/systems/devx/roadmap-governance.md#definition-of-ready-dor`..

   Automatic selection (when you say "start a new task")

   - Active lane: Use the current version lane in focus (default: v0.3) unless you explicitly say otherwise.
   - Selection rule: choose the most logical card by priority then size: P0 → P1 → P2, with tie‑breakers S → M → L → XL, then lowest dependency count, then lowest card ID.
   - Preconditions: skip cards whose dependencies are not Done; if none qualify, surface the nearest‑ready candidate and the blocking dependency.
   - WIP guard: if WIP is at the limit, propose finishing/parking an In Progress card before starting a new one.

2. Open context

   - Open all paths in `links.docs` and `links.code` from the card.
   - Skim the doc’s Summary, Structure & Key Types, and Validation sections.

3. Run deterministic commands

   - Execute build/test commands in `links.commands`:
     - iOS and watchOS must pin destinations.
   - If missing, add them to the card before proceeding.
   - Fast local loop (MUST): run CPU-friendly tests first
     - `make test-all-fast` (package → iOS unit → watch unit)
     - For a single failing test: `make test-ios-one TEST=Pickleball\ Score\ TrackingTests/SomeTestCase`

4. Update docs first

   - If behavior/architecture changes, update the linked docs first.
   - Use `docs/DOC_TEMPLATE.md` sections: Deterministic Commands, Test touchpoints, Change impact.

5. Implement and test

   - Make the code edits.
   - Update/add tests per `tests.touchpoints`.
   - Local loop (MUST): use fast tests → `make test-ios-fast` and `make test-watch-fast`.
   - Before In Review (SHOULD): run full app test commands in `links.commands` (include UI tests if applicable).

6. Validate & close the loop
   - Validate against `validation.refs` anchors.
   - Run the quick check: `bash docs/systems/devx/roadmap-quick-check.sh` (runs fast tests by default; set `RUN_FAST_TESTS=0` to skip).
   - Move the card to In Review → Done with a one-line completion note.

## Tips

- Keep one focus; avoid starting multiple cards.
- Log via `LoggingService`; no `print`.
- Prefer small PRs that keep docs and board in sync.
