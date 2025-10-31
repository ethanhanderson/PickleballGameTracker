# File Improvement Task

## Overview

This document outlines the **process and workflow** for improving files while applying existing project rules. All coding standards, patterns, and best practices are defined in the project rule files - this guide focuses on the systematic approach to applying them during file improvement.

## Phase 1: Analysis & Rule Review

**Before making any changes, review relevant rule files:**

1. **Identify applicable rules** based on the file type and changes needed:

   - `swift-ios-project.mdc` - Project overview and architecture patterns
   - `swiftui-patterns.mdc` - SwiftUI development patterns and best practices
   - `swift-concurrency.mdc` - Swift 6 strict concurrency guidelines
   - `swift-testing.mdc` - Modern Swift Testing framework patterns
   - `xcodebuildmcp-tools.mdc` - XcodeBuildMCP tools for building, testing, and deployment

2. **Assess current state**:
   - Document existing test coverage and functionality
   - Identify architectural patterns currently in use
   - Note any performance or accessibility considerations

## Phase 2: Code Quality Improvements

**Apply existing rules while systematically improving code quality:**

1. **Remove outdated elements** (per Agent Development Rules):

   - Eliminate comments that merely describe what code does
   - Remove unused code with certainty (verify no references exist)
   - Clean up temporary or debugging code

2. **Apply modern patterns** (per SwiftUI and Concurrency rules):

   - Update to current Swift 6 APIs and syntax
   - Ensure proper actor isolation for concurrent code
   - Apply @Observable patterns for state management
   - Use structured concurrency with async/await

3. **Ensure architecture compliance** (per project architecture rules):
   - Verify MV pattern adherence in SwiftUI views
   - Confirm proper separation of concerns
   - Validate async operation handling with .task modifier

## Phase 3: Organization & Structure

**Restructure code while maintaining established patterns:**

1. **Apply SwiftUI patterns** (per swiftui-patterns.mdc):

   - Extract reusable components when architecturally beneficial
   - Maintain proper view hierarchy and data flow
   - Keep previews in main view files

2. **Follow testing guidelines** (per swift-testing.mdc):

   - Preserve existing test structure
   - Ensure new components have appropriate test coverage
   - Apply @Test macros and #expect/#require patterns

3. **Maintain documentation governance**:
   - Update wiki pages to reflect code changes
   - Keep documentation scope focused on intent and responsibilities
   - Link changes to relevant architecture/feature documentation

## Phase 4: Validation & Verification

**Ensure compliance with project standards:**

1. **Testing validation**:

   - Run existing test suites to ensure no regressions
   - Apply modern testing patterns for any new code
   - Verify async testing approaches where applicable

2. **Architecture verification**:

   - Confirm changes align with established patterns
   - Validate data flow and state management approaches
   - Ensure proper error handling and telemetry integration

3. **Performance & accessibility check**:
   - Apply accessibility guidelines from SwiftUI patterns
   - Verify performance optimizations are maintained
   - Ensure haptics and UX patterns remain consistent

## Process Guidelines

- **Sequential execution**: Complete each phase before moving to the next
- **Rule-first approach**: Always reference relevant rule files before making decisions
- **Documentation integration**: Update wiki documentation to match code changes
- **Conservative changes**: When uncertain, ask for clarification rather than risk functionality
- **Architecture alignment**: Ensure all changes support established project patterns

## Decision Framework

When evaluating changes, prioritize:

1. **Architecture compliance** over convenience
2. **Test coverage** maintenance over speed
3. **Documentation accuracy** over implementation details
4. **Future maintainability** over current expediency
