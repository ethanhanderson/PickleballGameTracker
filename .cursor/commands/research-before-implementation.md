# Research Before Implementation

## Purpose

Complete a systematic research phase before implementing features to discover existing patterns, utilities, and architectural decisions that inform the implementation approach. This reduces duplication, maintains consistency, and ensures alignment with established project patterns.

## When to Use

Apply this checklist when:

- Starting a new feature or component
- Adding functionality to an existing feature
- Creating preview or test data
- Implementing UI patterns or workflows
- Refactoring existing code

## Research Checklist

### 1. Search for Existing Patterns and Utilities

**Before writing any new code, search for existing implementations:**

#### Preview Data and Test Utilities

- [ ] **Search `GameTrackerCore/Support/Preview/`** for factory utilities:

  - List directory contents using `list_dir` tool:
    ```
    list_dir(target_directory: "Pickleball Game Tracker/PickleballGameTrackerCorePackage/Sources/GameTrackerCore/Support/Preview")
    ```
  - Read factory files to understand available patterns:
    - `CompletedGameFactory` - Completed games with realistic data
    - `ActiveGameFactory` - In-progress games at various stages
    - `GameEventFactory` - Game events and history
    - `PreviewEnvironment` - Full environment setup with managers
    - `PreviewData` - Common game scenarios (earlyGame, midGame, etc.)
    - `PreviewDataSeeder` - Container setup with seeded data

- [ ] **Check for similar preview patterns** in existing files:
  - Use `grep` tool to find preview implementations:
    ```
    grep(pattern: "#Preview", path: "<feature-directory>", type: "swift")
    ```

#### Feature Patterns and Components

- [ ] **Search for similar features** that might share patterns:

  - Use `codebase_search` tool with questions like:
    ```
    codebase_search(
      query: "How does <similar-feature> work?",
      target_directories: ["Pickleball Game Tracker/PickleballGameTrackerPackage/Sources/GameTrackerFeature/Features"],
      explanation: "Finding similar feature implementations to reuse patterns"
    )
    ```
  - Look for existing components that could be reused
  - Identify established UI patterns for similar workflows

- [ ] **Check Shared UI components** in `GameTrackerFeature/Shared/`:
  - Use `list_dir` tool to explore shared components:
    ```
    list_dir(target_directory: "Pickleball Game Tracker/PickleballGameTrackerPackage/Sources/GameTrackerFeature/Shared")
    ```
  - Look for:
    - Design system primitives and tokens
    - Common view components and modifiers
    - Reusable form controls and layouts

#### Data Models and Services

- [ ] **Review existing models** in `GameTrackerCore/Domain/Models/`:

  - Use `list_dir` to explore available models:
    ```
    list_dir(target_directory: "Pickleball Game Tracker/PickleballGameTrackerCorePackage/Sources/GameTrackerCore/Domain/Models")
    ```
  - Check if model already exists or can be extended
  - Look for related models that inform the design
  - Review model factories for test data creation

- [ ] **Check for services and managers** in `GameTrackerCore/Application/`:
  - Use `list_dir` to explore services:
    ```
    list_dir(target_directory: "Pickleball Game Tracker/PickleballGameTrackerCorePackage/Sources/GameTrackerCore/Application")
    ```
  - Identify services that handle similar operations
  - Review manager patterns for state coordination
  - Look for existing repository or store patterns

### 2. Review Documentation

**Understand architectural context before implementing:**

#### Project Rules

- [ ] **Read applicable rule files** using `fetch_rules`:
  - `swift-ios-project` - Project overview and architecture
  - `swiftui-patterns` - SwiftUI development patterns
  - `swift-concurrency` - Concurrency guidelines
  - `swift-testing` - Testing framework patterns
  - `xcodebuildmcp-tools` - Build and deployment tools

#### Wiki Documentation

- [ ] **Review relevant wiki pages**:

  - [Architecture.md](mdc:PickleballGameTracker.wiki/Architecture.md) - Architecture overview
  - [Features.md](mdc:PickleballGameTracker.wiki/Features.md) - Feature index
  - [Systems.md](mdc:PickleballGameTracker.wiki/Systems.md) - Systems index

- [ ] **Find specific documentation** for the feature area:
  - Search wiki for related feature pages
  - Review system documentation for affected systems
  - Check model definitions for data contracts

### 3. Analyze Similar Implementations

**Learn from existing code before creating new patterns:**

- [ ] **Find and read similar features**:

  - Use `codebase_search` tool with specific questions:

    ```
    codebase_search(
      query: "How is game setup implemented?",
      target_directories: [],
      explanation: "Understanding existing game setup patterns"
    )

    codebase_search(
      query: "Where are player selection flows handled?",
      target_directories: [],
      explanation: "Finding player selection implementations"
    )

    codebase_search(
      query: "How do sheets with medium detents work?",
      target_directories: [],
      explanation: "Learning sheet presentation patterns"
    )
    ```

- [ ] **Identify patterns to follow**:

  - State management approach (@Observable, @State, @Binding)
  - Navigation patterns (sheets, navigation stack, tabs)
  - Error handling and validation
  - Async operation handling with .task modifier
  - Accessibility implementation

- [ ] **Note architectural decisions**:
  - Why was a particular pattern chosen?
  - What constraints shaped the implementation?
  - What alternatives were considered?

### 4. Check for Existing Utilities and Helpers

**Avoid recreating what already exists:**

#### Extensions and Utilities

- [ ] **Search for extensions** on types you'll work with:

  - Use `grep` tool to find extensions:
    ```
    grep(pattern: "extension Game", type: "swift")
    grep(pattern: "extension GameVariation", type: "swift")
    grep(pattern: "extension PlayerProfile", type: "swift")
    ```

- [ ] **Check for formatting utilities**:
  - Use `codebase_search` to find formatters:
    ```
    codebase_search(
      query: "Where are date and duration formatting utilities?",
      target_directories: [],
      explanation: "Finding existing formatting helpers"
    )
    ```
  - Look for:
    - Date formatting helpers
    - Duration formatting
    - Score formatting
    - String utilities

#### Preview and Test Helpers

- [ ] **Review preview helper files**:

  - Use `glob_file_search` to find preview helpers:
    ```
    glob_file_search(glob_pattern: "**/PreviewHelpers.swift")
    glob_file_search(glob_pattern: "**/PreviewEnvironment*.swift")
    ```
  - Read files to understand:
    - `PreviewHelpers.swift` - Standard preview utilities
    - `PreviewEnvironmentSetup.swift` - Environment configuration
    - Check for preview-specific modifiers and extensions

- [ ] **Check test utilities** if writing tests:
  - Use `glob_file_search` to find test utilities:
    ```
    glob_file_search(glob_pattern: "**/*TestHelpers.swift")
    glob_file_search(glob_pattern: "**/*Factory.swift", target_directory: "Tests")
    ```
  - Look for:
    - Test data builders and fixtures
    - Mock objects and stubs
    - Test helper functions

### 5. Validate Architectural Fit

**Ensure the approach aligns with project architecture:**

- [ ] **Confirm architectural layer**:

  - Where does this code belong? (Model, Service, ViewModel, View)
  - What dependencies will it have?
  - How does it integrate with existing systems?

- [ ] **Review data flow**:

  - How will data move through the system?
  - What state management is appropriate?
  - Where should business logic live?

- [ ] **Consider testability**:
  - Can this be easily tested?
  - Does it need to be extracted for testing?
  - What test coverage is appropriate?

## Implementation Decision Framework

After completing research, document decisions:

### Use Existing vs. Create New

**Use existing patterns when:**

- Functionality already exists in factories/utilities
- Similar features have established patterns
- Existing components can be composed or extended
- Documentation prescribes a specific approach

**Create new patterns when:**

- No existing pattern fits the use case
- Existing patterns have documented limitations
- New requirements necessitate different approach
- Creating would reduce duplication across codebase

**Document reasoning:**

```markdown
## Implementation Approach

**Decision**: Using `CompletedGameFactory` for preview data

**Rationale**:

- Factory already provides realistic game data with proper relationships
- Maintains consistency with other preview implementations
- Avoids duplicating data setup logic
- Factory's fluent API makes preview code more readable

**Alternatives Considered**:

- Manual game setup: Rejected because it duplicates factory logic
- PreviewData static properties: Rejected because factory offers more flexibility
```

### Architectural Considerations

Document how the implementation fits into architecture:

```markdown
## Architectural Fit

**Layer**: Feature View Layer
**Dependencies**:

- GameTrackerCore.Game (model)
- GameTrackerCore.CompletedGameFactory (preview)
- DesignSystem tokens (styling)

**State Management**: Local @State for sheet presentation
**Navigation**: Sheet with medium detent presentation
**Data Flow**: One-way from parent view via closure callback

**Compliance**:

- ✅ Follows MV pattern (no ViewModel needed for simple sheet)
- ✅ Uses existing factories for preview data
- ✅ Proper @MainActor isolation
- ✅ DesignSystem token usage
```

## Research Output Template

After completing research, document findings:

```markdown
# Feature: [Feature Name]

## Research Summary

### Existing Patterns Found

- Pattern 1: [Description and location]
- Pattern 2: [Description and location]

### Relevant Utilities

- Utility 1: [Purpose and usage]
- Utility 2: [Purpose and usage]

### Architectural Context

- Related features: [List]
- Affected systems: [List]
- Documentation references: [List]

### Implementation Approach

- Strategy: [High-level approach]
- Reused components: [List]
- New components needed: [List with justification]
- Risks and considerations: [List]

### Documentation Updates Required

- Wiki pages to update: [List]
- New documentation needed: [List]
```

## Checklist Completion

Before proceeding to implementation:

- [ ] All relevant searches completed
- [ ] Documentation reviewed and understood
- [ ] Similar implementations analyzed
- [ ] Existing utilities identified and evaluated
- [ ] Architectural fit validated
- [ ] Implementation approach documented
- [ ] Potential reuse opportunities identified
- [ ] Documentation requirements noted

## Anti-Patterns to Avoid

❌ **Don't:**

- Skip searches because you "know" how to implement it
- Recreate functionality that exists in factories/utilities
- Ignore established patterns without documented reasoning
- Create preview data manually when factories exist
- Start coding before understanding architectural context

✅ **Do:**

- Search thoroughly before implementing
- Document why you chose existing patterns or created new ones
- Ask questions when patterns are unclear
- Propose improvements to existing patterns when beneficial
- Update documentation as you learn

## Success Criteria

Research is complete when you can answer:

1. **Does this functionality already exist?** If yes, where and how can I use it?
2. **What patterns should I follow?** Based on similar features and architecture
3. **What utilities can I reuse?** Factories, helpers, extensions, components
4. **How does this fit architecturally?** Layer, dependencies, data flow
5. **What documentation needs updating?** To reflect this implementation

## Time Investment

Expected research time by task complexity:

- **Simple component/view**: 15-30 minutes
- **Feature addition**: 30-60 minutes
- **New feature**: 1-2 hours
- **Architectural change**: 2-4 hours

Time spent on research reduces implementation time and rework significantly.
