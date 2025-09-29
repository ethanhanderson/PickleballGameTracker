# Build iOS target

Run this command:

```bash
xcodebuild -workspace "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Game Tracker/PickleballGameTracker.xcworkspace" -scheme "PickleballGameTrackerWatch" -configuration Debug -destination 'platform=watchOS Simulator,name=Apple Watch Ultra 3 (49mm)' build
```

## Debugging Process

1. Read the errors from the tool call output, categorize them, and pick a file to target changes for (if possible).
2. Get a comprehensive understanding of what the file needs to do by scanning the file, the related code, and the docs.
3. Find any relevent plan files that may give additional content as to what the code may be a part of.
4. Once you see what the file is supposed to be doing, update the code to fix the errors so the file can function properly.
