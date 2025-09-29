Platform/Haptics

Purpose: Local-only haptic feedback for user actions.
Guidelines:
- Access via `HapticFeedbackService.shared`.
- Respect `isEnabled` and avoid remote/sync-triggered haptics.


