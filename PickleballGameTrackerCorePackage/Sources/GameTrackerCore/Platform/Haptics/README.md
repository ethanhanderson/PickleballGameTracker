Platform/Haptics

Purpose: Local-only haptic feedback for user actions.

## iOS Implementation (iOS 17+)

- Uses SwiftUI's `sensoryFeedback` API exclusively
- Service publishes trigger values that views observe
- Views use `.observeHapticServiceTriggers()` to respond to programmatic haptic calls
- Direct state observation uses helper methods like `.sensoryFeedbackScore()`

## watchOS Implementation

- Uses WatchKit's `WKInterfaceDevice.play()` API
- Direct haptic feedback for all actions

## Guidelines

- Access via `HapticFeedbackService.shared`
- Respect `isEnabled` and avoid remote/sync-triggered haptics
- Only trigger haptics when game is in `.playing` state (enforced in service methods)
- Use `.observeHapticServiceTriggers()` in SwiftUI views to observe programmatic haptic calls
