# Debug iOS target

Call the tool `mcp_xcodebuildmcp_build_sim` with the following parameters:

```json
{
  "workspacePath": "/Users/ethanhanderson/Documents/Development/eha dev/MatchTally Explorations/Pickleball Game Tracker/PickleballGameTracker.xcworkspace",
  "scheme": "PickleballGameTracker",
  "simulatorName": "iPhone 17 Pro",
  "configuration": "Debug",
  "preferXcodebuild": true
}
```

## Debugging Process

1. Read the errors and warnings from the tool call output, categorize them, and pick a file to target changes for (if possible).
2. Get a comprehensive understanding of what the file needs to do by scanning the file, and the related code.
3. Once you see what the file is supposed to be doing, update the code to fix the errors and warnings so the file can function properly.
