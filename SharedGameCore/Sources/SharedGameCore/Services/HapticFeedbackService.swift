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
  import UIKit

  /// Service responsible for providing haptic feedback for user actions
  /// Only triggers haptics for local actions, not remote sync updates
  @MainActor
  public final class HapticFeedbackService: ObservableObject, Sendable {

    // MARK: - Singleton

    public static let shared = HapticFeedbackService()

    // MARK: - Private Properties

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()

    // MARK: - Settings

    @Published public var isEnabled: Bool = true

    // MARK: - Initialization

    private init() {
      // Prepare generators for better responsiveness
      prepareGenerators()
    }

    // MARK: - Public Methods

    /// Trigger haptic feedback for scoring actions
    public func scoreAction() {
      guard isEnabled else { return }
      impactMedium.impactOccurred()
    }

    /// Trigger haptic feedback for serve changes
    public func serveChange() {
      guard isEnabled else { return }
      impactLight.impactOccurred()
    }

    /// Trigger haptic feedback for game state changes (timeout, rally, etc.)
    public func gameStateChange() {
      guard isEnabled else { return }
      impactLight.impactOccurred()
    }

    /// Trigger haptic feedback for timer start/stop
    public func timerToggle() {
      guard isEnabled else { return }
      impactMedium.impactOccurred()
    }

    /// Trigger haptic feedback for game completion
    public func gameComplete() {
      guard isEnabled else { return }
      notificationGenerator.notificationOccurred(.success)
    }

    /// Trigger haptic feedback for new game start
    public func gameStart() {
      guard isEnabled else { return }
      impactHeavy.impactOccurred()
    }

    /// Trigger haptic feedback for button selections
    public func buttonSelection() {
      guard isEnabled else { return }
      selectionGenerator.selectionChanged()
    }

    /// Trigger haptic feedback for errors
    public func error() {
      guard isEnabled else { return }
      notificationGenerator.notificationOccurred(.error)
    }

    /// Trigger haptic feedback for warnings
    public func warning() {
      guard isEnabled else { return }
      notificationGenerator.notificationOccurred(.warning)
    }

    /// Prepare all generators for responsive feedback
    public func prepareGenerators() {
      impactLight.prepare()
      impactMedium.prepare()
      impactHeavy.prepare()
      notificationGenerator.prepare()
      selectionGenerator.prepare()
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
    public func scoreAction() {
      guard isEnabled else { return }
      WKInterfaceDevice.current().play(.click)
    }

    /// Trigger haptic feedback for serve changes
    public func serveChange() {
      guard isEnabled else { return }
      WKInterfaceDevice.current().play(.click)
    }

    /// Trigger haptic feedback for game state changes (timeout, rally, etc.)
    public func gameStateChange() {
      guard isEnabled else { return }
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

    public func scoreAction() {}
    public func serveChange() {}
    public func gameStateChange() {}
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
  public func gameAction(_ action: GameAction) {
    switch action {
    case .scoreTeam1, .scoreTeam2:
      scoreAction()
    case .serveChange:
      serveChange()
    case .gameStateChange:
      gameStateChange()
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
  public func hapticFeedback(
    _ action: GameAction,
    isEnabled: Bool = true
  ) -> some View {
    self.onTapGesture {
      if isEnabled {
        HapticFeedbackService.shared.gameAction(action)
      }
    }
  }

  /// Add haptic feedback with custom trigger
  public func hapticFeedback(
    trigger: some Equatable,
    action: GameAction
  ) -> some View {
    self.onChange(of: trigger) { _, _ in
      HapticFeedbackService.shared.gameAction(action)
    }
  }
}
