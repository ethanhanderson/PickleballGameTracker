//
//  HapticFeedbackService.swift
//  SharedGameCore
//
//  Haptic feedback service for local user actions
//  Ensures only local actions trigger haptics, remote sync updates remain silent
//

import Foundation
import SwiftUI

#if os(iOS)
  /// Service responsible for providing haptic feedback for user actions on iOS
  /// Uses SwiftUI's sensoryFeedback API (iOS 17+) via published triggers
  /// Only triggers haptics for local actions, not remote sync updates
  @MainActor
  @available(iOS 17.0, *)
  public final class HapticFeedbackService: ObservableObject, Sendable {

    // MARK: - Singleton

    public static let shared = HapticFeedbackService()

    // MARK: - Settings

    @Published public var isEnabled: Bool = true
    
    // MARK: - SwiftUI State Triggers
    
    @Published public var scoreHapticTrigger: Int = 0
    @Published public var serveChangeHapticTrigger: Int = 0
    @Published public var gameStateChangeHapticTrigger: Int = 0
    @Published public var timerToggleHapticTrigger: Int = 0
    @Published public var gameCompleteHapticTrigger: Int = 0
    @Published public var gameStartHapticTrigger: Int = 0
    @Published public var buttonSelectionHapticTrigger: Int = 0
    @Published public var errorHapticTrigger: Int = 0
    @Published public var warningHapticTrigger: Int = 0

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Trigger haptic feedback for scoring actions
    /// - Parameter isGamePlaying: If false, haptic will not be triggered. Only triggers when game is actively playing.
    public func scoreAction(isGamePlaying: Bool = true) {
      guard isGamePlaying && isEnabled else { return }
      scoreHapticTrigger += 1
    }

    /// Trigger haptic feedback for serve changes
    /// - Parameter isGamePlaying: If false, haptic will not be triggered. Only triggers when game is actively playing.
    public func serveChange(isGamePlaying: Bool = true) {
      guard isGamePlaying && isEnabled else { return }
      serveChangeHapticTrigger += 1
    }

    /// Trigger haptic feedback for game state changes (timeout, rally, etc.)
    /// - Parameter isGamePlaying: If false, haptic will not be triggered. Only triggers when game is actively playing.
    public func gameStateChange(isGamePlaying: Bool = true) {
      guard isGamePlaying && isEnabled else { return }
      gameStateChangeHapticTrigger += 1
    }

    /// Trigger haptic feedback for timer start/stop
    public func timerToggle() {
      guard isEnabled else { return }
      timerToggleHapticTrigger += 1
    }

    /// Trigger haptic feedback for game completion
    public func gameComplete() {
      guard isEnabled else { return }
      gameCompleteHapticTrigger += 1
    }

    /// Trigger haptic feedback for new game start
    public func gameStart() {
      guard isEnabled else { return }
      gameStartHapticTrigger += 1
    }

    /// Trigger haptic feedback for button selections
    public func buttonSelection() {
      guard isEnabled else { return }
      buttonSelectionHapticTrigger += 1
    }

    /// Trigger haptic feedback for errors
    public func error() {
      guard isEnabled else { return }
      errorHapticTrigger += 1
    }

    /// Trigger haptic feedback for warnings
    public func warning() {
      guard isEnabled else { return }
      warningHapticTrigger += 1
    }

    /// Prepare all generators for responsive feedback (no-op on iOS, uses SwiftUI sensoryFeedback)
    public func prepareGenerators() {
      // No preparation needed - SwiftUI handles haptic engine preparation automatically
    }
  }

#elseif os(watchOS)
  import WatchKit

  /// Service responsible for providing haptic feedback for user actions on watchOS
  /// Only triggers haptics for local actions, not remote sync updates
  @MainActor
  public final class HapticFeedbackService: ObservableObject, Sendable {

    // MARK: - Singleton

    public static let shared = HapticFeedbackService()

    // MARK: - Settings

    @Published public var isEnabled: Bool = true

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Trigger haptic feedback for scoring actions
    /// - Parameter isGamePlaying: If false, haptic will not be triggered. Only triggers when game is actively playing.
    public func scoreAction(isGamePlaying: Bool = true) {
      guard isEnabled && isGamePlaying else { return }
      WKInterfaceDevice.current().play(.click)
    }

    /// Trigger haptic feedback for serve changes
    /// - Parameter isGamePlaying: If false, haptic will not be triggered. Only triggers when game is actively playing.
    public func serveChange(isGamePlaying: Bool = true) {
      guard isEnabled && isGamePlaying else { return }
      WKInterfaceDevice.current().play(.click)
    }

    /// Trigger haptic feedback for game state changes (timeout, rally, etc.)
    /// - Parameter isGamePlaying: If false, haptic will not be triggered. Only triggers when game is actively playing.
    public func gameStateChange(isGamePlaying: Bool = true) {
      guard isEnabled && isGamePlaying else { return }
      WKInterfaceDevice.current().play(.click)
    }

    /// Trigger haptic feedback for timer start/stop
    public func timerToggle() {
      guard isEnabled else { return }
      WKInterfaceDevice.current().play(.start)
    }

    /// Trigger haptic feedback for game completion
    public func gameComplete() {
      guard isEnabled else { return }
      WKInterfaceDevice.current().play(.success)
    }

    /// Trigger haptic feedback for new game start
    public func gameStart() {
      guard isEnabled else { return }
      WKInterfaceDevice.current().play(.start)
    }

    /// Trigger haptic feedback for button selections
    public func buttonSelection() {
      guard isEnabled else { return }
      WKInterfaceDevice.current().play(.click)
    }

    /// Trigger haptic feedback for errors
    public func error() {
      guard isEnabled else { return }
      WKInterfaceDevice.current().play(.failure)
    }

    /// Trigger haptic feedback for warnings
    public func warning() {
      guard isEnabled else { return }
      WKInterfaceDevice.current().play(.retry)
    }

    /// Prepare all generators for responsive feedback (no-op on watchOS)
    public func prepareGenerators() {
      // No preparation needed on watchOS
    }
  }

#else

  // MARK: - Stub Implementation for Other Platforms

  @MainActor
  public final class HapticFeedbackService: ObservableObject, Sendable {

    public static let shared = HapticFeedbackService()

    @Published public var isEnabled: Bool = true

    private init() {}

    public func scoreAction(isGamePlaying: Bool = true) {}
    public func serveChange(isGamePlaying: Bool = true) {}
    public func gameStateChange(isGamePlaying: Bool = true) {}
    public func timerToggle() {}
    public func gameComplete() {}
    public func gameStart() {}
    public func buttonSelection() {}
    public func error() {}
    public func warning() {}
    public func prepareGenerators() {}
  }

#endif

// MARK: - Convenience Extensions

extension HapticFeedbackService {

  /// Trigger appropriate haptic for different game actions
  /// - Parameters:
  ///   - action: The game action type
  ///   - isGamePlaying: If false, haptic will not be triggered for scoring/serve/state change actions. Only triggers when game is actively playing.
  public func gameAction(_ action: GameAction, isGamePlaying: Bool = true) {
    switch action {
    case .scoreTeam1, .scoreTeam2:
      scoreAction(isGamePlaying: isGamePlaying)
    case .serveChange:
      serveChange(isGamePlaying: isGamePlaying)
    case .gameStateChange:
      gameStateChange(isGamePlaying: isGamePlaying)
    case .timerStart, .timerStop:
      timerToggle()
    case .gameComplete:
      gameComplete()
    case .gameStart:
      gameStart()
    case .buttonPress:
      buttonSelection()
    case .error:
      error()
    case .warning:
      warning()
    }
  }
}

// MARK: - Game Action Types

public enum GameAction {
  case scoreTeam1
  case scoreTeam2
  case serveChange
  case gameStateChange
  case timerStart
  case timerStop
  case gameComplete
  case gameStart
  case buttonPress
  case error
  case warning
}

// MARK: - SwiftUI Integration

extension View {

  /// Add haptic feedback to button press
  /// - Parameters:
  ///   - action: The game action type
  ///   - isEnabled: Whether haptics are enabled
  ///   - isGamePlaying: If false, haptic will not be triggered for scoring/serve/state change actions. Only triggers when game is actively playing.
  public func hapticFeedback(
    _ action: GameAction,
    isEnabled: Bool = true,
    isGamePlaying: Bool = true
  ) -> some View {
    self.onTapGesture {
      if isEnabled {
        HapticFeedbackService.shared.gameAction(action, isGamePlaying: isGamePlaying)
      }
    }
  }

  /// Add haptic feedback with custom trigger
  /// - Parameters:
  ///   - trigger: The value that triggers the haptic when it changes
  ///   - action: The game action type
  ///   - isGamePlaying: If false, haptic will not be triggered for scoring/serve/state change actions. Only triggers when game is actively playing.
  public func hapticFeedback(
    trigger: some Equatable,
    action: GameAction,
    isGamePlaying: Bool = true
  ) -> some View {
    self.onChange(of: trigger) { _, _ in
      HapticFeedbackService.shared.gameAction(action, isGamePlaying: isGamePlaying)
    }
  }
}

// MARK: - SwiftUI Sensory Feedback Integration

@available(iOS 17.0, watchOS 10.0, *)
extension View {
  
  /// Add modern SwiftUI sensory feedback for scoring actions
  /// Uses SwiftUI's native `sensoryFeedback` modifier with game state checking
  /// - Parameters:
  ///   - trigger: The value that triggers the haptic when it changes
  ///   - isGamePlaying: If false, haptic will not be triggered. Only triggers when game is actively playing.
  ///   - intensity: The intensity of the haptic feedback (0.0 to 1.0, default: 1.0)
  public func sensoryFeedbackScore(
    trigger: some Equatable,
    isGamePlaying: Bool = true,
    intensity: Double = 1.0
  ) -> some View {
    self.sensoryFeedback(
      .impact(weight: .medium, intensity: intensity),
      trigger: trigger,
      condition: { _, _ in isGamePlaying && HapticFeedbackService.shared.isEnabled }
    )
  }
  
  /// Add modern SwiftUI sensory feedback for serve changes
  /// Uses SwiftUI's native `sensoryFeedback` modifier with game state checking
  /// - Parameters:
  ///   - trigger: The value that triggers the haptic when it changes
  ///   - isGamePlaying: If false, haptic will not be triggered. Only triggers when game is actively playing.
  ///   - intensity: The intensity of the haptic feedback (0.0 to 1.0, default: 1.0)
  public func sensoryFeedbackServeChange(
    trigger: some Equatable,
    isGamePlaying: Bool = true,
    intensity: Double = 1.0
  ) -> some View {
    self.sensoryFeedback(
      .impact(weight: .light, intensity: intensity),
      trigger: trigger,
      condition: { _, _ in isGamePlaying && HapticFeedbackService.shared.isEnabled }
    )
  }
  
  /// Add modern SwiftUI sensory feedback for game completion
  /// Uses SwiftUI's native `sensoryFeedback` modifier
  /// - Parameters:
  ///   - trigger: The value that triggers the haptic when it changes
  public func sensoryFeedbackGameComplete(
    trigger: some Equatable
  ) -> some View {
    self.sensoryFeedback(
      .success,
      trigger: trigger,
      condition: { _, _ in HapticFeedbackService.shared.isEnabled }
    )
  }
  
  /// Add modern SwiftUI sensory feedback for game start
  /// Uses SwiftUI's native `sensoryFeedback` modifier
  /// - Parameters:
  ///   - trigger: The value that triggers the haptic when it changes
  ///   - intensity: The intensity of the haptic feedback (0.0 to 1.0, default: 1.0)
  public func sensoryFeedbackGameStart(
    trigger: some Equatable,
    intensity: Double = 1.0
  ) -> some View {
    self.sensoryFeedback(
      .impact(weight: .heavy, intensity: intensity),
      trigger: trigger,
      condition: { _, _ in HapticFeedbackService.shared.isEnabled }
    )
  }
  
  /// Add modern SwiftUI sensory feedback for errors
  /// Uses SwiftUI's native `sensoryFeedback` modifier
  /// - Parameters:
  ///   - trigger: The value that triggers the haptic when it changes
  public func sensoryFeedbackError(
    trigger: some Equatable
  ) -> some View {
    self.sensoryFeedback(
      .error,
      trigger: trigger,
      condition: { _, _ in HapticFeedbackService.shared.isEnabled }
    )
  }
  
  /// Add modern SwiftUI sensory feedback for warnings
  /// Uses SwiftUI's native `sensoryFeedback` modifier
  /// - Parameters:
  ///   - trigger: The value that triggers the haptic when it changes
  public func sensoryFeedbackWarning(
    trigger: some Equatable
  ) -> some View {
    self.sensoryFeedback(
      .warning,
      trigger: trigger,
      condition: { _, _ in HapticFeedbackService.shared.isEnabled }
    )
  }
  
  /// Add modern SwiftUI sensory feedback with dynamic game state checking
  /// Uses SwiftUI's native `sensoryFeedback` modifier with a closure that checks game state
  /// - Parameters:
  ///   - trigger: The value that triggers the haptic when it changes
  ///   - feedback: A closure that returns the appropriate SensoryFeedback based on current state
  ///   - isGamePlaying: A closure that returns whether the game is currently playing
  public func sensoryFeedbackGameAction(
    trigger: some Equatable,
    feedback: @escaping () -> SensoryFeedback?,
    isGamePlaying: @escaping () -> Bool
  ) -> some View {
    self.sensoryFeedback(trigger: trigger) {
      guard HapticFeedbackService.shared.isEnabled else { return nil }
      guard isGamePlaying() else { return nil }
      return feedback()
    }
  }
  
  /// Observe haptic triggers from HapticFeedbackService and play appropriate feedback
  /// This allows programmatic haptic calls to trigger SwiftUI sensory feedback in views
  @available(iOS 17.0, watchOS 10.0, *)
  public func observeHapticServiceTriggers() -> some View {
    #if os(iOS)
    self
      .sensoryFeedbackScore(
        trigger: HapticFeedbackService.shared.scoreHapticTrigger,
        isGamePlaying: true
      )
      .sensoryFeedbackServeChange(
        trigger: HapticFeedbackService.shared.serveChangeHapticTrigger,
        isGamePlaying: true
      )
      .sensoryFeedback(
        .impact(weight: .light, intensity: 1.0),
        trigger: HapticFeedbackService.shared.gameStateChangeHapticTrigger,
        condition: { _, _ in HapticFeedbackService.shared.isEnabled }
      )
      .sensoryFeedback(
        .impact(weight: .medium, intensity: 1.0),
        trigger: HapticFeedbackService.shared.timerToggleHapticTrigger,
        condition: { _, _ in HapticFeedbackService.shared.isEnabled }
      )
      .sensoryFeedbackGameComplete(
        trigger: HapticFeedbackService.shared.gameCompleteHapticTrigger
      )
      .sensoryFeedbackGameStart(
        trigger: HapticFeedbackService.shared.gameStartHapticTrigger
      )
      .sensoryFeedback(
        .selection,
        trigger: HapticFeedbackService.shared.buttonSelectionHapticTrigger,
        condition: { _, _ in HapticFeedbackService.shared.isEnabled }
      )
      .sensoryFeedbackError(
        trigger: HapticFeedbackService.shared.errorHapticTrigger
      )
      .sensoryFeedbackWarning(
        trigger: HapticFeedbackService.shared.warningHapticTrigger
      )
    #else
    self
    #endif
  }
}
