# Sync Codebase with Docs

## Purpose

Review git changes on the current branch and update wiki documentation to stay synchronized with the codebase, ensuring docs reflect both current implementation and intended direction.

## Process

When syncing documentation with code changes:

1. **Review git changes**: Get the current branch's changes and examine modified files
2. **Identify affected documentation**: Map code changes to their corresponding wiki pages:
   - Feature code → `features/` pages
   - Architecture/system code → `architecture/` or `systems/` pages
   - Data models → `systems/data/` model pages
   - Cross-cutting concerns → relevant system pages
3. **Read existing documentation**: Review the current content of affected wiki pages
4. **Analyze impact level**: Determine the scope of documentation updates needed:
   - **Minor**: Implementation details changed but contracts/behavior stayed the same
   - **Moderate**: New capabilities added or behavior modified
   - **Major**: Architecture changed, new systems introduced, or contracts redefined
5. **Update documentation**: Modify wiki pages to reflect changes while maintaining forward-looking guidance
6. **Update Version Differences**: Add entries to version tables tracking what changed and why
7. **Verify governance compliance**: Ensure updates maintain template structure, metadata accuracy, and cross-references

## Documentation Sync Principles

### Balance Current State with Direction

- **Document both "what is" and "what should be"**: Update to reflect current implementation while preserving guidance about intended patterns and future direction
- **Keep docs prescriptive**: Don't just describe what the code does; explain what patterns should be followed and why
- **Preserve architectural intent**: When code changes, ensure docs still communicate the underlying design principles and goals

### Update Strategy by Impact Level

**Minor changes** (implementation details):

- Update code references and file paths if they changed
- Refine examples or clarifications without structural changes
- May not require Version Differences entry

**Moderate changes** (new capabilities or behavior):

- Add new sections or subsections for new functionality
- Update Data Model & Contracts, State Management, or Error States sections
- Add Version Differences entry noting what was added and why
- Update acceptance criteria to cover new behaviors

**Major changes** (architecture or system redesign):

- Restructure affected sections to reflect new organization
- Update diagrams and high-level descriptions
- Create new wiki pages if new systems were introduced
- Add detailed Version Differences entry with migration guidance
- Review cross-references and update related pages

### Version Differences Guidance

When adding Version Differences entries:

- **Focus on behavioral changes**: What changed from a developer's perspective
- **Explain rationale**: Why the change was made (performance, maintainability, new requirements)
- **Provide migration guidance**: How to adapt existing code or patterns
- **Update acceptance criteria**: What new behaviors need to be validated

Example:

```markdown
### v1.1 Details

- Changes:
  - Replaced direct SwiftData queries with `GameRepository` abstraction
  - Added caching layer for frequently accessed game summaries
- Migration:
  - Update query code to use `repository.fetchGames()` instead of `@Query`
  - Remove manual predicate construction; use repository methods
- Acceptance criteria:
  - Repository methods return correct data with <50ms latency
  - Cache invalidation works when games are updated
```
