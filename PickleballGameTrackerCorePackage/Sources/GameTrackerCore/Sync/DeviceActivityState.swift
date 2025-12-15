import Foundation

enum DeviceActivityRole: Sendable {
  case local
  case peer
}

enum DeviceActivityTier: String, Sendable {
  case inactive
  case passive
  case active
}

enum DeviceMutationSource: Sendable {
  case local
  case remote
  case snapshot
}

struct MutationPrioritySnapshot: Sendable {
  var appliedAt: Date
  var source: DeviceMutationSource
  var localScore: Double
  var peerScore: Double

  static let empty = MutationPrioritySnapshot(
    appliedAt: .distantPast,
    source: .snapshot,
    localScore: 0,
    peerScore: 0
  )
}

struct DeviceActivityState: Sendable {
  let role: DeviceActivityRole

  private(set) var lastUserInteractionAt: Date = .distantPast
  private(set) var lastScoreMutationAt: Date = .distantPast
  private(set) var lastServeMutationAt: Date = .distantPast
  private(set) var lastLifecycleMutationAt: Date = .distantPast
  private(set) var lastTimerPulseAt: Date = .distantPast
  private(set) var lastTimerLeadershipChangeAt: Date = .distantPast
  private(set) var lastForegroundAt: Date = .distantPast
  private(set) var isForegroundLiveView: Bool = false

  init(role: DeviceActivityRole) {
    self.role = role
  }

  mutating func recordUserInteraction(at date: Date = Date()) {
    if date > lastUserInteractionAt {
      lastUserInteractionAt = date
    }
  }

  mutating func recordScoreMutation(at date: Date = Date()) {
    if date > lastScoreMutationAt {
      lastScoreMutationAt = date
    }
    recordUserInteraction(at: date)
  }

  mutating func recordServeMutation(at date: Date = Date()) {
    if date > lastServeMutationAt {
      lastServeMutationAt = date
    }
    recordUserInteraction(at: date)
  }

  mutating func recordLifecycleMutation(at date: Date = Date()) {
    if date > lastLifecycleMutationAt {
      lastLifecycleMutationAt = date
    }
    recordUserInteraction(at: date)
  }

  mutating func recordTimerPulse(at date: Date = Date()) {
    if date > lastTimerPulseAt {
      lastTimerPulseAt = date
    }
  }

  mutating func recordTimerLeadershipChange(at date: Date = Date()) {
    if date > lastTimerLeadershipChangeAt {
      lastTimerLeadershipChangeAt = date
    }
  }

  mutating func setForeground(_ isForeground: Bool, at date: Date = Date()) {
    isForegroundLiveView = isForeground
    if isForeground, date > lastForegroundAt {
      lastForegroundAt = date
    }
  }

  func activityScore(now: Date = Date(), lookbackWindow: TimeInterval = 90) -> Double {
    var score: Double = 0

    func accumulate(for eventTime: Date, weight: Double) {
      guard eventTime > .distantPast else { return }
      let age = now.timeIntervalSince(eventTime)
      guard age <= lookbackWindow else { return }
      let normalized = max(0, lookbackWindow - age) / lookbackWindow
      score += weight * normalized
    }

    accumulate(for: lastUserInteractionAt, weight: 3.0)
    accumulate(for: lastScoreMutationAt, weight: 3.5)
    accumulate(for: lastServeMutationAt, weight: 2.5)
    accumulate(for: lastLifecycleMutationAt, weight: 2.0)
    accumulate(for: lastTimerPulseAt, weight: 1.5)
    accumulate(for: lastTimerLeadershipChangeAt, weight: 1.2)

    if isForegroundLiveView {
      score += 1.5
    } else {
      accumulate(for: lastForegroundAt, weight: 1.0)
    }

    return score
  }

  func activityTier(now: Date = Date(), lookbackWindow: TimeInterval = 90) -> DeviceActivityTier {
    let score = activityScore(now: now, lookbackWindow: lookbackWindow)
    switch score {
    case let value where value >= 3.5:
      return .active
    case let value where value >= 1.0:
      return .passive
    default:
      return .inactive
    }
  }
}

