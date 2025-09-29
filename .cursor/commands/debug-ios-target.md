# Build iOS target

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

1. Read the errors from the tool call output, categorize them, and pick a file to target changes for (if possible).
2. Get a comprehensive understanding of what the file needs to do by scanning the file, the related code, and the docs.
3. Find any relevent plan files that may give additional content as to what the code may be a part of.
4. Once you see what the file is supposed to be doing, update the code to fix the errors so the file can function properly.
