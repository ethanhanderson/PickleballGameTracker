//
//  ServeBezel.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 7/9/25.
//

import CorePackage
import SwiftUI

@MainActor
struct ServeBezel: View {
  @Bindable var game: Game
  let currentServeNumber: Int
  @State private var sideSwitchPulse: Bool = false

  var body: some View {
    HStack(spacing: DesignSystem.Spacing.sm) {
      Image(systemName: "figure.pickleball")
        .font(.system(size: 20, weight: .semibold))
        .foregroundStyle(DesignSystem.Colors.gameType(game.gameType).gradient)
        .symbolEffect(.bounce, value: sideSwitchPulse)

      Text("Serve")
        .font(DesignSystem.Typography.headline)
        .fontWeight(.semibold)
        .foregroundStyle(.primary)

      Spacer()

      // Current side label with subtle animation on change
      Text(game.sideOfCourt.displayName.uppercased())
        .font(.system(size: 12, weight: .heavy))
        .padding(.horizontal, DesignSystem.Spacing.xs)
        .padding(.vertical, 4)
        .glassEffect(
          .regular.tint(DesignSystem.Colors.gameType(game.gameType).opacity(0.25)), in: Capsule()
        )
        .foregroundStyle(.primary)
        .transition(.scale.combined(with: .opacity))
        .id(game.sideOfCourt)  // ensure transition triggers on change

      Text("\(currentServeNumber)")
        .font(.system(size: 28, weight: .bold, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(.primary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, DesignSystem.Spacing.sm)
    .padding(.horizontal, DesignSystem.Spacing.lg)
    .glassEffect(
      .regular.tint(DesignSystem.Colors.gameType(game.gameType).opacity(0.4)), in: Capsule()
    )
    .onChange(of: game.sideOfCourt) { _, _ in
      // Trigger a short pulse whenever side switches
      sideSwitchPulse.toggle()
      Task { @MainActor in
        try? await Task.sleep(for: .milliseconds(250))
        sideSwitchPulse.toggle()
      }
    }
  }
}

#Preview {
  VStack(spacing: DesignSystem.Spacing.lg) {
    ServeBezel(
      game: PreviewGameData.midGame,
      currentServeNumber: 1
    )
    ServeBezel(
      game: PreviewGameData.trainingGame,
      currentServeNumber: 5
    )
    ServeBezel(
      game: PreviewGameData.highScoreGame,
      currentServeNumber: 12
    )
  }
  .padding()
}
