import Testing
@testable import GameTrackerCore

@Suite("TimerDriftResolver")
struct TimerDriftResolverTests {

  @Test("Snaps when drift exceeds threshold")
  func snapsLargeDrift() {
    let resolver = TimerDriftResolver(snapThreshold: 0.1, glideThreshold: 0.02, glideFactor: 0.5)
    let resolved = resolver.resolve(
      currentElapsed: 10.0,
      targetElapsed: 10.5,
      forceSnap: false
    )
    #expect(resolved == 10.5)
  }

  @Test("Ignores negligible drift")
  func ignoresNegligibleDrift() {
    let resolver = TimerDriftResolver(snapThreshold: 0.1, glideThreshold: 0.02, glideFactor: 0.5)
    let resolved = resolver.resolve(
      currentElapsed: 10.0,
      targetElapsed: 10.01,
      forceSnap: false
    )
    #expect(resolved == 10.0)
  }

  @Test("Glides for moderate drift")
  func glidesModerateDrift() {
    let resolver = TimerDriftResolver(snapThreshold: 0.1, glideThreshold: 0.02, glideFactor: 0.5)
    let resolved = resolver.resolve(
      currentElapsed: 10.0,
      targetElapsed: 10.05,
      forceSnap: false
    )
    #expect(resolved > 10.0)
    #expect(resolved < 10.05)
  }
}


