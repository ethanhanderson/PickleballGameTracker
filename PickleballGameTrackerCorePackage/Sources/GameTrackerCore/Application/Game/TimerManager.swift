//
//  TimerManager.swift
//  SharedGameCore
//
//  Created by Ethan Anderson on 7/9/25.
//

import Foundation
import SwiftUI

/// Manages game timer functionality independently of game state
@MainActor
public final class TimerManager: Sendable {

  // MARK: - Public Properties

  /// The elapsed time since the timer started
  public private(set) var elapsedTime: TimeInterval = 0

  /// Whether the timer is currently running
  public private(set) var isRunning: Bool = false

  // MARK: - Private Properties

  private var timer: Timer?
  private var startTime: Date?
  private var pausedTime: TimeInterval = 0
  private var lastPauseTime: Date?
  private var updateInterval: TimeInterval = 0.01

  /// Haptic feedback service for timer actions
  private var hapticService: HapticFeedbackService {
    HapticFeedbackService.shared
  }

  /// Whether to trigger haptic feedback (can be disabled for remote updates)
  private var shouldTriggerHaptics: Bool = true

  /// Callback to notify when timer updates
  private var onTimerUpdate: (@Sendable () -> Void)?

  // MARK: - Computed Properties

  /// Formatted elapsed time string (hours:minutes:seconds when hours > 0, otherwise minutes:seconds)
  public var formattedElapsedTime: String {
    let totalSeconds = Int(elapsedTime)
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    let seconds = totalSeconds % 60

    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    } else {
      return String(format: "%02d:%02d", minutes, seconds)
    }
  }

  /// Formatted elapsed time string with centiseconds
  public var formattedElapsedTimeWithCentiseconds: String {
    let totalSeconds = Int(elapsedTime)
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    let seconds = totalSeconds % 60
    let centiseconds = Int((elapsedTime.truncatingRemainder(dividingBy: 1)) * 100)

    if hours > 0 {
      return String(format: "%d:%02d:%02d.%02d", hours, minutes, seconds, centiseconds)
    } else {
      return String(format: "%02d:%02d.%02d", minutes, seconds, centiseconds)
    }
  }

  // MARK: - Initialization

  nonisolated public init() {}

  // MARK: - Timer Control Methods

  /// Start the timer
  public func start() {
    guard !isRunning else { return }

    // Handle pause tracking - if we're resuming from a pause
    if let lastPause = lastPauseTime {
      let pauseDuration = Date().timeIntervalSince(lastPause)
      pausedTime += pauseDuration
      lastPauseTime = nil
    } else if startTime == nil {
      startTime = Date()
    }

    startTimerInternal()

    if shouldTriggerHaptics {
      hapticService.timerToggle()
    }
  }

  /// Stop the timer
  public func stop() {
    stopTimerInternal()
    pausedTime = 0
    lastPauseTime = nil

    if shouldTriggerHaptics {
      hapticService.timerToggle()
    }
  }

  /// Pause the timer (without affecting total paused time tracking)
  public func pause() {
    guard isRunning else { return }

    lastPauseTime = Date()
    stopTimerInternal()
  }

  /// Resume the timer after being paused
  public func resume() {
    guard !isRunning else { return }

    // Add the pause duration to total paused time
    if let pauseStart = lastPauseTime {
      pausedTime += Date().timeIntervalSince(pauseStart)
      lastPauseTime = nil
    }

    // If we never had a start time (e.g., joined mid-game), synthesize one
    // so that elapsed time continues from the current value instead of sticking.
    if startTime == nil {
      startTime = Date().addingTimeInterval(-elapsedTime)
    }

    startTimerInternal()
  }

  /// Toggle timer state
  public func toggle() {
    if isRunning {
      pause()
    } else {
      start()
    }
  }

  /// Reset the timer to zero
  public func reset() {
    stopTimerInternal()
    elapsedTime = 0
    pausedTime = 0
    lastPauseTime = nil
    startTime = nil
  }

  /// Set the timer to a specific elapsed time
  public func setElapsedTime(_ timeInterval: TimeInterval) {
    // Update visible elapsed immediately
    elapsedTime = timeInterval
    // Clear pause bookkeeping since this is an authoritative set
    pausedTime = 0
    lastPauseTime = nil

    if isRunning {
      // Adjust the running baseline so subsequent ticks reflect the new elapsed
      // elapsed = now - start - pausedTime  =>  start = now - (elapsed + pausedTime)
      startTime = Date().addingTimeInterval(-(timeInterval + pausedTime))
      // Ensure a timer is active; if it was somehow invalidated, start it
      if timer == nil {
        startTimerInternal()
      }
    } else {
      // Keep startTime nil so a future resume() synthesizes a baseline from elapsed
      startTime = nil
    }
  }

  /// Change the timer update interval. If the timer is running, it will reschedule.
  public func setUpdateInterval(_ interval: TimeInterval) {
    let clamped = max(0.001, interval)
    guard clamped != updateInterval else { return }
    updateInterval = clamped
    if isRunning {
      // Reschedule with the new interval without changing elapsed/baseline
      startTimerInternal()
    }
  }

  // MARK: - Private Methods

  private func startTimerInternal() {
    // Safety check: Timer should only run when explicitly requested
    guard startTime != nil || lastPauseTime == nil else {
      return
    }

    // Avoid duplicate scheduled timers
    timer?.invalidate()
    timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
      guard let self else { return }
      Task { @MainActor in
        self.updateElapsedTime()
      }
    }
    isRunning = true
  }

  private func stopTimerInternal() {
    timer?.invalidate()
    timer = nil
    isRunning = false
  }

  private func updateElapsedTime() {
    guard let startTime = startTime else { return }

    let totalRealTime = Date().timeIntervalSince(startTime)
    elapsedTime = totalRealTime - pausedTime

    // Notify observers of the update
    onTimerUpdate?()
  }

  // MARK: - Configuration

  /// Disable haptic feedback (useful for remote updates)
  public func disableHaptics() {
    shouldTriggerHaptics = false
  }

  /// Re-enable haptic feedback
  public func enableHaptics() {
    shouldTriggerHaptics = true
  }

  // MARK: - Introspection (Read-Only)

  /// Last time the timer was started (nil if never started)
  public var lastTimerStartTime: Date? { startTime }

  // MARK: - State Validation

  /// Validate that timer state is consistent
  public func validateState() -> Bool {
    // Timer should only be running when we expect it to be
    let timerRunningValid = isRunning == (timer != nil)

    return timerRunningValid
  }

  // MARK: - Observer Management

  /// Set a callback to be called when the timer updates
  public func setTimerUpdateCallback(_ callback: (@Sendable () -> Void)?) {
    onTimerUpdate = callback
  }
}
