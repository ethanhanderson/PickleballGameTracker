# Document Recent Work

## Purpose

Document recently completed work in the repository wiki to maintain accurate, up-to-date project documentation that helps future developers understand the codebase.

## Process

When documenting recent changes:

1. **Scan the completed work**: Review all code changes, features, and architectural decisions made
2. **Identify documentation targets**: Determine which wiki pages need updates and whether new pages should be created
3. **Review documentation governance**: Read the project and wiki rules for maintenance and addition guidelines (see workspace rules)
4. **Apply documentation principles**: Follow the principles below to create clear, useful documentation

## Documentation Principles

When documenting code changes, follow these principles to create useful, clear documentation:

### Focus on Understanding and Rationale

- **Document how things work and why**: Explain the implementation approach and the reasoning behind design decisions
- **Provide context for future development**: Help future developers understand the intent and constraints that shaped the current implementation
- **Explain trade-offs**: When a design makes a specific choice, document what alternatives were considered and why this approach was selected

### Voice and Tone

- **Use instructive and neutral voice**: Write as if teaching someone how the system works
- **Avoid negative or prescriptive language**: Don't write "don't do X" or "we shouldn't do X this way"
  - Instead, document what the system does and explain why it's designed that way
  - Example: Replace "Don't use empty arrays" with "The system uses empty arrays to support quick-start flows where participants are configured during gameplay"
- **Be solution-oriented**: Focus on how the code achieves its goals rather than what to avoid

### Content Scope

- **Document intent, responsibilities, and boundaries**: Define what each component does and where its responsibilities end
- **Include design decisions with rationale**: Explain why the code is structured a particular way
- **Focus on organization and architecture**: Document what the code should be and how to organize it
- **Avoid step-by-step coding instructions**: Don't write tutorials on how to write the code; instead explain the patterns and structure

### Practical Guidelines

- Keep docs concise and skimmable
- Use "Design Decision" sections to explicitly call out architectural choices
- Include code snippets when they clarify structure or contracts
- Cross-reference related documentation pages
- Update Version Differences tables to track evolution
- Link to actual implementation files for the source of truth
