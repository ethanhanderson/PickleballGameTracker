# Pickleball Game Tracker - iOS App

A modern iOS application using a **workspace + SPM package** architecture for clean separation between app shell and feature code.

## Getting Started

- Open the workspace:

```
PickleballGameTracker/
├── PickleballGameTracker.xcworkspace/           # Open this file in Xcode
├── PickleballGameTracker.xcodeproj/             # App shell project
├── PickleballGameTracker/                       # App target (minimal)
│   ├── Assets.xcassets/                         # App-level assets (icons, colors)
│   ├── PickleballGameTrackerApp.swift           # App entry point
│   └── PickleballGameTracker.xctestplan         # Test configuration
├── PickleballGameTrackerPackage/                # 🚀 Primary development area
│   ├── Package.swift                            # Package configuration
│   ├── Sources/GameTrackerFeature/              # Your feature code
│   └── Tests/GameTrackerFeatureTests/           # Unit tests
└── PickleballGameTrackerUITests/                # UI automation tests
```

### Workspace + SPM Structure

- **App Shell**: `PickleballGameTracker/` contains minimal app lifecycle code
- **Feature Code**: `PickleballGameTrackerPackage/Sources/GameTrackerFeature/` is where most development happens
- **Separation**: Business logic lives in the SPM package, app target just imports and displays it

### Build & Run

- Select the `TestApp` scheme
- Choose an iOS Simulator (e.g. iPhone 16 Pro)
- Run (⌘R)

### Code Organization

Most development happens in `PickleballGameTrackerPackage/Sources/GameTrackerFeature/` - organize your code as you prefer.

### Public API Requirements

- Keep public surface area minimal and intentional
- Add documentation to public types and functions

### Adding Dependencies

Edit `PickleballGameTrackerPackage/Package.swift` to add SPM dependencies:

```swift
dependencies: [
    // .package(url: "https://github.com/owner/repo", from: "1.0.0")
]

targets: [
    .target(
        name: "GameTrackerFeature",
        dependencies: ["SomePackage"]
    ),
]
```

### Test Structure

- **Unit Tests**: `PickleballGameTrackerPackage/Tests/GameTrackerFeatureTests/` (Swift Testing framework)
- **UI Tests**: `PickleballGameTrackerUITests/` (XCUITest framework)
- **Test Plan**: `PickleballGameTracker.xctestplan` coordinates all tests

## Configuration

### Entitlements Management

App capabilities are managed through a **declarative entitlements file**:

- `Config/TestApp.entitlements` - All app entitlements and capabilities
- AI agents can safely edit this XML file to add HealthKit, CloudKit, Push Notifications, etc.
- No need to modify complex Xcode project files

### Asset Management

- **App-Level Assets**: `PickleballGameTracker/Assets.xcassets/` (app icon, accent color)
- **Feature Assets**: Add `Resources/` folder to SPM package if needed

### Resources in SPM

```swift
.target(
    name: "GameTrackerFeature",
    name: "GameTrackerFeature",
    dependencies: [],
    resources: [.process("Resources")]
)
```
