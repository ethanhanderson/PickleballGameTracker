# Document Recent Work

## Purpose

Document recently completed work in the repository wiki to maintain accurate, up-to-date project documentation that helps future developers understand the codebase.

## Process

When documenting recent changes:

1. **Scan the completed work**: Review all code changes, features, and architectural decisions made
2. **Identify documentation targets**: Determine which wiki pages need updates and whether new pages should be created
3. **Review documentation governance**: Read the project and wiki rules (see workspace rules) for:
   - Template requirements (all pages must use canonical templates from `templates/`)
   - Metadata block structure (document name, category, area, audience, date, status, version)
   - Version Differences requirements (v0.3, v0.6, v1.0 minimum)
   - Index linking requirements (`Architecture.md`, `Features.md`, `Systems.md`)
   - Acceptance checklist items
4. **Create or update pages following the templates**: Copy the appropriate template and fill in all required sections
5. **Apply voice and tone principles**: Follow the writing style guidance below

## Writing Style Guidance

When writing documentation, apply these principles to create clear, instructive content:

### Voice and Tone

- **Use instructive and neutral voice**: Write as if teaching someone how the system works
- **Avoid negative or prescriptive language**: Don't write "don't do X" or "we shouldn't do X this way"
  - Instead, document what the system does and explain why it's designed that way
  - Example: Replace "Don't use empty arrays" with "The system uses empty arrays to support quick-start flows where participants are configured during gameplay"
- **Be solution-oriented**: Focus on how the code achieves its goals rather than what to avoid
- **Explain trade-offs**: When a design makes a specific choice, document what alternatives were considered and why this approach was selected

### Design Decisions

Use inline "Design Decision" callouts to explicitly explain architectural choices with rationale:

```markdown
**Design Decision**: The Last Game flow intentionally starts with empty participant lists because:

1. **Flexibility**: Players may vary between sessions even when rules stay consistent
2. **Speed**: Skips participant selection for users who want to configure participants during gameplay
3. **Convenience**: Preserves rule configurations without forcing roster reuse
```

These callouts help future developers understand why the code is structured a particular way and what constraints shaped the implementation.
