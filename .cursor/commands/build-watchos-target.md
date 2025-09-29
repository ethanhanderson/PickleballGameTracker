# Build watchOS target

1. Run this command:

```bash
xcodebuild -workspace "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Game Tracker/PickleballGameTracker.xcworkspace" -scheme "PickleballGameTrackerWatch" -configuration Debug -destination 'platform=watchOS Simulator,name=Apple Watch Ultra 3 (49mm)' build
```
