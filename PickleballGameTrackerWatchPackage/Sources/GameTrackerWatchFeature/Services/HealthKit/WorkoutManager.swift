import GameTrackerCore
import Foundation
import HealthKit
import Observation
import SwiftUI

@MainActor
@Observable
public final class WorkoutManager: NSObject {
  public override init() {
    super.init()
  }
  // MARK: - Public State
  private(set) var isAuthorized: Bool = false
  private(set) var isPrepared: Bool = false
  private(set) var isActive: Bool = false
  private(set) var sessionState: HKWorkoutSessionState = .notStarted

  private(set) var elapsed: TimeInterval = 0
  private(set) var currentHeartRateBPM: Int?
  private(set) var averageHeartRateBPM: Int?
  private(set) var activeEnergyKCal: Double = 0
  private(set) var totalEnergyKCal: Double = 0

  // MARK: - HealthKit
  private let healthStore = HKHealthStore()
  private var session: HKWorkoutSession?
  private var builder: HKLiveWorkoutBuilder?
  private var dataSource: HKLiveWorkoutDataSource?

  private var metricsUpdateTimer: Timer?
  private var startDate: Date?

  // MARK: - Lifecycle Helpers
  private func startMetricsTimerIfNeeded() {
    guard metricsUpdateTimer == nil || metricsUpdateTimer?.isValid == false else { return }
    metricsUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      Task { @MainActor in
        guard let self, let start = self.startDate, self.sessionState == .running else { return }
        self.elapsed = Date().timeIntervalSince(start)
      }
    }
  }

  private func stopMetricsTimer() {
    metricsUpdateTimer?.invalidate()
    metricsUpdateTimer = nil
  }

  private func resetSessionResources(nextState: HKWorkoutSessionState = .notStarted) {
    session?.delegate = nil
    builder?.delegate = nil
    dataSource = nil
    session = nil
    builder = nil
    startDate = nil
    stopMetricsTimer()
    isPrepared = false
    isActive = false
    sessionState = nextState
  }

  // MARK: - Preview Detection
  private var isPreviewEnvironment: Bool {
    ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
  }

  // MARK: - Authorization
  func requestAuthorizationIfNeeded() async {
    guard HKHealthStore.isHealthDataAvailable() else {
      isAuthorized = false
      return
    }

    // Skip authorization in preview environments where Info.plist isn't available
    if isPreviewEnvironment {
      isAuthorized = false
      return
    }

    let readTypes: Set<HKObjectType> = [
      HKObjectType.quantityType(forIdentifier: .heartRate)!,
      HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
      HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
    ]
    let shareTypes: Set<HKSampleType> = [
      HKObjectType.workoutType(),
      HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
    ]

    do {
      try await healthStore.requestAuthorization(toShare: shareTypes, read: readTypes)
      isAuthorized = true
      Log.event(.permissionGranted, level: .info, message: "HealthKit authorized on watch")
    } catch {
      isAuthorized = false
      Log.error(error, event: .permissionDenied, metadata: ["component": "WorkoutManager"])
    }
  }

  // MARK: - Prepare
  func prepare(for gameType: GameType) async {
    // Skip in preview environments
    if isPreviewEnvironment {
      return
    }
    guard isAuthorized else { return }
    guard session == nil, builder == nil else {
      // Already prepared
      isPrepared = true
      return
    }

    let config = HKWorkoutConfiguration()
    if #available(watchOS 11.0, *), Self.supportsPickleball {
      config.activityType = .pickleball
    } else if Self.supportsTableTennis {
      config.activityType = .tableTennis
    } else {
      config.activityType = .play
    }
    config.locationType = .indoor

    do {
      let session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
      session.delegate = self
      let builder = session.associatedWorkoutBuilder()
      let dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)
      builder.dataSource = dataSource
      builder.delegate = self
      self.session = session
      self.builder = builder
      self.dataSource = dataSource
      self.isPrepared = true
      self.sessionState = .notStarted
      Log.event(.createSucceeded, level: .info, message: "Workout session prepared")
    } catch {
      Log.error(error, event: .createFailed, metadata: ["component": "WorkoutManager", "phase": "prepare"])
      resetSessionResources()
    }
  }

  // MARK: - Controls
  func start() async {
    if isPreviewEnvironment { return }
    guard isAuthorized else { return }
    guard let session, let builder, isPrepared else { return }

    if sessionState == .paused {
      resume()
      return
    }

    guard sessionState == .notStarted else { return }
    startDate = Date()

    // Start activity (use sync API to avoid cross-SDK async mismatch warnings)
    session.startActivity(with: startDate!)

    // Begin collection (bridge to completion API to avoid noasync warnings across SDKs)
    await MainActor.run {
      beginCollectionLegacy(builder, startDate: startDate!)
    }

    applyStateChange(.running, timestamp: startDate)
    Log.event(.start, level: .info, message: "Workout started")
  }

  // Using the completion-based API for compatibility across SDKs
  private func beginCollectionLegacy(_ builder: HKLiveWorkoutBuilder, startDate: Date) {
    builder.beginCollection(withStart: startDate) { _, _ in }
  }

  func pause() {
    if isPreviewEnvironment { return }
    guard let session, sessionState == .running else { return }
    session.pause()
    applyStateChange(.paused)
    Log.event(.pause, level: .info, message: "Workout paused")
  }

  func resume() {
    if isPreviewEnvironment { return }
    guard let session, sessionState == .paused else { return }
    session.resume()
    applyStateChange(.running)
    Log.event(.resume, level: .info, message: "Workout resumed")
  }

  func endAndSave() async {
    if isPreviewEnvironment { return }
    guard let session, let builder else { return }
    session.end()
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      builder.endCollection(withEnd: Date()) { _, _ in
        builder.finishWorkout { _, _ in
          continuation.resume()
        }
      }
    }
    isPrepared = false
    applyStateChange(.ended)
    resetSessionResources(nextState: .ended)
    Log.event(.end, level: .info, message: "Workout ended and saved")
  }

  private func applyStateChange(_ newState: HKWorkoutSessionState, timestamp: Date? = nil) {
    sessionState = newState
    switch newState {
    case .running:
      isActive = true
      if let timestamp, startDate == nil {
        startDate = timestamp
      }
      startMetricsTimerIfNeeded()
    case .paused, .notStarted:
      isActive = false
      stopMetricsTimer()
    case .ended, .stopped:
      isActive = false
      isPrepared = false
      stopMetricsTimer()
    default:
      break
    }
  }

  // MARK: - Preview Factory
  static func preview(
    isActive: Bool = true,
    elapsed: TimeInterval = 1250,
    currentHeartRateBPM: Int? = 145,
    averageHeartRateBPM: Int? = 138,
    activeEnergyKCal: Double = 127.5,
    totalEnergyKCal: Double = 180.0
  ) -> WorkoutManager {
    let manager = WorkoutManager()
    manager.isActive = isActive
    manager.elapsed = elapsed
    manager.currentHeartRateBPM = currentHeartRateBPM
    manager.averageHeartRateBPM = averageHeartRateBPM
    manager.activeEnergyKCal = activeEnergyKCal
    manager.totalEnergyKCal = totalEnergyKCal
    return manager
  }

  // MARK: - Helpers
  private static var supportsPickleball: Bool {
    if #available(watchOS 11.0, *) {
      return true
    }
    return false
  }

  private static var supportsTableTennis: Bool {
    // Always available
    true
  }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
  public nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
    // No-op
  }

  public nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
    // Compute metrics on background, then hop to main actor for UI updates
    Task { @MainActor in
      // Active Energy (kcal)
      var activeEnergy: Double = 0
      if let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
         let energyStats = workoutBuilder.statistics(for: energyType),
         let sum = energyStats.sumQuantity() {
        activeEnergy = sum.doubleValue(for: .kilocalorie())
        activeEnergyKCal = activeEnergy
      }
      
      // Basal Energy (kcal)
      var basalEnergy: Double = 0
      if let basalType = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned),
         let basalStats = workoutBuilder.statistics(for: basalType),
         let sum = basalStats.sumQuantity() {
        basalEnergy = sum.doubleValue(for: .kilocalorie())
      }
      
      // Total Energy (active + basal)
      totalEnergyKCal = activeEnergy + basalEnergy

      // Heart Rate (current and average)
      if let hrType = HKObjectType.quantityType(forIdentifier: .heartRate),
         let hrStats = workoutBuilder.statistics(for: hrType) {
        let bpmUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
        if let recent = hrStats.mostRecentQuantity() {
          currentHeartRateBPM = Int(recent.doubleValue(for: bpmUnit).rounded())
        }
        if let avg = hrStats.averageQuantity() {
          averageHeartRateBPM = Int(avg.doubleValue(for: bpmUnit).rounded())
        }
      }

      // Elapsed (prefer builder’s elapsedTime when available)
      if let start = startDate {
        elapsed = workoutBuilder.elapsedTime + max(0, Date().timeIntervalSince(start) - workoutBuilder.elapsedTime)
      } else {
        elapsed = workoutBuilder.elapsedTime
      }
    }
  }
}

// MARK: - HKWorkoutSessionDelegate
extension WorkoutManager: HKWorkoutSessionDelegate {
  public nonisolated func workoutSession(
    _ workoutSession: HKWorkoutSession,
    didChangeTo toState: HKWorkoutSessionState,
    from _: HKWorkoutSessionState,
    date: Date
  ) {
    Task { @MainActor [weak self] in
      guard let self else { return }
      self.applyStateChange(toState, timestamp: date)
    }
  }

  public nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
    Task { @MainActor [weak self] in
      guard let self else { return }
      Log.error(
        error,
        event: .startFailed,
        metadata: ["component": "WorkoutManager", "phase": "sessionDelegate"]
      )
      self.applyStateChange(.ended)
      self.resetSessionResources(nextState: .ended)
    }
  }
}


