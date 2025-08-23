# Build & CI — Deterministic Commands and Triage

- Purpose: Centralize build/test commands and quick triage steps for iOS, watchOS, and the `SharedGameCore` package.
- Applies to: Local dev and future CI steps. Always pin destinations for reproducibility.

## iOS app — build/test

```bash
cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking"
xcodebuild -project "Pickleball Score Tracking.xcodeproj" \
  -scheme "Pickleball Score Tracking" \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  build

# Tests
xcodebuild -project "Pickleball Score Tracking.xcodeproj" \
  -scheme "Pickleball Score Tracking" \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  test

# Fast local (unit only, CPU-friendly)
xcodebuild -project "Pickleball Score Tracking.xcodeproj" \
  -scheme "Pickleball Score Tracking" \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  -only-testing:Pickleball\ Score\ TrackingTests \
  -enableCodeCoverage NO \
  -parallel-testing-enabled NO \
  test
```

## watchOS app — build/test

```bash
cd "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking"
xcodebuild -project "Pickleball Score Tracking.xcodeproj" \
  -scheme "Pickleball Score Tracking Watch App" \
  -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)" \
  build

# Tests
xcodebuild -project "Pickleball Score Tracking.xcodeproj" \
  -scheme "Pickleball Score Tracking Watch App" \
  -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)" \
  test

# Fast local (skip UI tests)
xcodebuild -project "Pickleball Score Tracking.xcodeproj" \
  -scheme "Pickleball Score Tracking Watch App" \
  -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)" \
  -skip-testing:"Pickleball Score Tracking Watch AppUITests" \
  -enableCodeCoverage NO \
  -parallel-testing-enabled NO \
  test
```

## SharedGameCore (Swift Package) — build/test

```bash
# Build
mcp_XcodeBuildMCP_swift_package_build(
  packagePath: "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking/SharedGameCore"
)

# Test
mcp_XcodeBuildMCP_swift_package_test(
  packagePath: "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Score Tracking/SharedGameCore"
)
```

## Quick triage: failing tests vs compile-only

- If unit/UI tests fail but compile is green:
  - Run package tests to isolate core vs app surface: SharedGameCore first, then iOS/watchOS targets.
  - Open the related feature/system doc and validate against its checklist.
- If compile fails:
  - Build package, then iOS, then watchOS to narrow scope.
  - Prefer addressing type/concurrency errors first to keep validation clean.

## Notes

- Prefer symmetric runs for iOS and watchOS changes.
- Keep commands in card `links.commands` so new chats can reproduce quickly.
