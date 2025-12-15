import Foundation

struct TimerDriftResolver {
  let snapThreshold: TimeInterval
  let glideThreshold: TimeInterval
  let glideFactor: Double

  init(
    snapThreshold: TimeInterval = 0.12,
    glideThreshold: TimeInterval = 0.04,
    glideFactor: Double = 0.35
  ) {
    self.snapThreshold = snapThreshold
    self.glideThreshold = glideThreshold
    self.glideFactor = glideFactor
  }

  func resolve(
    currentElapsed: TimeInterval,
    targetElapsed: TimeInterval,
    forceSnap: Bool
  ) -> TimeInterval {
    let delta = targetElapsed - currentElapsed
    let distance = abs(delta)

    if forceSnap || distance >= snapThreshold {
      return targetElapsed
    }

    if distance <= glideThreshold {
      return currentElapsed
    }

    let correction = delta * glideFactor
    return currentElapsed + correction
  }
}


