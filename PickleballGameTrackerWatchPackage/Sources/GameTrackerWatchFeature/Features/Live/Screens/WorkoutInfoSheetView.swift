import GameTrackerCore
import SwiftUI

@MainActor
struct WorkoutInfoSheetView: View {
    @Environment(WorkoutManager.self) private var workoutManager
    @Environment(LiveGameStateManager.self) private var liveGameStateManager
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    @State private var heartScale: CGFloat = 1.0
    @State private var heartbeatTask: Task<Void, Never>?
    
    private var isPaused: Bool {
        liveGameStateManager.currentGame?.gameState == .paused
    }
    
    private var navigationTitle: String {
        if isPaused {
            return "Paused"
        }
        return liveGameStateManager.currentGameTypeDisplayName ?? 
               liveGameStateManager.currentGame?.gameType.displayName ?? 
               "Workout"
    }

    private var formattedDuration: String {
        let total = workoutManager.elapsed
        let minutes = Int(total) / 60
        let seconds = Int(total) % 60
        let milliseconds = Int((total.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }

    private var durationUpdateInterval: TimeInterval {
        (isPaused || isLuminanceReduced) ? 1.0 : 0.01
    }
    
    private func startHeartbeatAnimation() {
        heartbeatTask?.cancel()
        heartbeatTask = Task { @MainActor in
            while let bpm = workoutManager.currentHeartRateBPM, bpm > 0 {
                guard !Task.isCancelled else { break }
                let interval = 60.0 / Double(bpm)
                
                withAnimation(.easeInOut(duration: 0.15)) {
                    heartScale = 1.2
                }
                
                try? await Task.sleep(nanoseconds: 150_000_000)
                guard !Task.isCancelled else { break }
                
                withAnimation(.easeInOut(duration: 0.15)) {
                    heartScale = 1.0
                }
                
                let remainingTime = max(0.0, interval - 0.3)
                try? await Task.sleep(nanoseconds: UInt64(remainingTime * 1_000_000_000))
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                TimelineView(.periodic(from: Date.now, by: durationUpdateInterval)) { _ in
                    Text(formattedDuration)
                        .font(.system(size: 40, weight: .semibold, design: .rounded))
                        .foregroundStyle(isPaused ? .gray : .yellow)
                        .monospacedDigit()
                }
                .id(durationUpdateInterval)

                HStack(alignment: .center, spacing: 16) {
                    HStack(alignment: .center, spacing: 4) {
                        let activeCals = Int(workoutManager.activeEnergyKCal.rounded())
                        Text("\(activeCals)")
                            .contentTransition(.numericText())
                            .animation(.easeInOut(duration: 0.2), value: activeCals)
                            .font(
                                .system(size: 33.6, weight: .semibold, design: .rounded)
                            )
                        Text("active\ncal")
                            .font(.system(size: 14.4, weight: .regular, design: .default))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    HStack(alignment: .center, spacing: 4) {
                        let totalCals = Int(workoutManager.totalEnergyKCal.rounded())
                        Text("\(totalCals)")
                            .contentTransition(.numericText())
                            .animation(.easeInOut(duration: 0.2), value: totalCals)
                            .font(
                                .system(size: 33.6, weight: .semibold, design: .rounded)
                            )
                        Text("total\ncal")
                            .font(.system(size: 14.4, weight: .regular, design: .default))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(alignment: .center, spacing: 16) {
                    HStack(alignment: .center, spacing: 4) {
                        let currentHR = workoutManager.currentHeartRateBPM ?? 0
                        Text("\(currentHR)")
                            .contentTransition(.numericText())
                            .animation(.easeInOut(duration: 0.2), value: currentHR)
                            .font(
                                .system(
                                    size: 33.6,
                                    weight: .semibold,
                                    design: .rounded
                                )
                            )
                        Image(systemName: "heart.fill")
                            .imageScale(.large)
                            .foregroundStyle(.red)
                            .scaleEffect(isPaused ? 1.0 : heartScale)
                            .onAppear {
                                if !isPaused {
                                    startHeartbeatAnimation()
                                }
                            }
                            .onDisappear {
                                heartbeatTask?.cancel()
                            }
                            .onChange(of: workoutManager.currentHeartRateBPM) {
                                if !isPaused {
                                    startHeartbeatAnimation()
                                }
                            }
                            .onChange(of: isPaused) { _, paused in
                                if paused {
                                    heartbeatTask?.cancel()
                                    withAnimation {
                                        heartScale = 1.0
                                    }
                                } else if workoutManager.currentHeartRateBPM != nil {
                                    startHeartbeatAnimation()
                                }
                            }
                            .onChange(of: isLuminanceReduced) { _, reduced in
                                if reduced {
                                    heartbeatTask?.cancel()
                                    withAnimation {
                                        heartScale = 1.0
                                    }
                                } else if !isPaused, workoutManager.currentHeartRateBPM != nil {
                                    startHeartbeatAnimation()
                                }
                            }
                    }
                    
                    HStack(alignment: .center, spacing: 4) {
                        let avgHR = workoutManager.averageHeartRateBPM ?? 0
                        Text("\(avgHR)")
                            .contentTransition(.numericText())
                            .animation(.easeInOut(duration: 0.2), value: avgHR)
                            .font(
                                .system(
                                    size: 33.6,
                                    weight: .semibold,
                                    design: .rounded
                                )
                            )
                        Text("avg\nHR")
                            .font(
                                .system(
                                    size: 14.4,
                                    weight: .regular,
                                    design: .default
                                )
                            )
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Previews

#Preview {
    let setup = PreviewContainers.standardSetup()
    
    WorkoutInfoSheetView()
        .environment(WorkoutManager.preview())
        .environment(setup.liveGameManager)
        .modelContainer(setup.container)
}
