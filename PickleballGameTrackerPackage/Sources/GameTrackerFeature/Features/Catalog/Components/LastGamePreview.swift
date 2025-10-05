//
//  LastGamePreview.swift
//

import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct LastGamePreview: View {
  let game: Game
  let gameType: GameType
  let onStartGame: () -> Void
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  
  private func participantName(at index: Int) -> String {
    let names = game.teamsWithLabels(context: modelContext).map { $0.teamName }
    if names.count > index, names[index] != "Team \(index + 1)" {
      return names[index]
    }
    return index == 0 ? game.effectivePlayerLabel1 : game.effectivePlayerLabel2
  }
  
  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Button("Cancel") {
          dismiss()
        }
        
        Spacer()
        
        Text("Last Game")
          .font(.headline)
        
        Spacer()
        
        Button(action: {
          dismiss()
          onStartGame()
        }) {
          Text("Start Game")
            .fontWeight(.semibold)
        }
        .buttonStyle(.borderedProminent)
        .tint(gameType.color)
      }
      .padding()
      .background(Color(uiColor: .systemBackground))
      
      Divider()
      
      ScrollView {
        VStack(spacing: DesignSystem.Spacing.lg) {
          VStack(spacing: DesignSystem.Spacing.md) {
            ParticipantRow(
              name: participantName(at: 0),
              teamSize: game.effectiveTeamSize,
              gameType: gameType
            )
            
            Divider()
              .overlay(
                Text("vs")
                  .font(.caption)
                  .fontWeight(.semibold)
                  .foregroundStyle(.secondary)
                  .padding(.horizontal, DesignSystem.Spacing.sm)
                  .background(Color(uiColor: .systemGroupedBackground))
              )
              .padding(.vertical, DesignSystem.Spacing.xs)
            
            ParticipantRow(
              name: participantName(at: 1),
              teamSize: game.effectiveTeamSize,
              gameType: gameType
            )
          }
          .padding(DesignSystem.Spacing.md)
          .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
              .fill(Color(uiColor: .systemGroupedBackground))
          )
        }
      }
      .contentMargins(.horizontal, DesignSystem.Spacing.lg, for: .scrollContent)
      .contentMargins(.top, DesignSystem.Spacing.lg, for: .scrollContent)
    }
  }
}

@MainActor
private struct ParticipantRow: View {
  let name: String
  let teamSize: Int
  let gameType: GameType
  
  private var teamSizeIcon: String {
    teamSize == 1 ? "person.fill" : "person.2.fill"
  }
  
  private var teamSizeText: String {
    teamSize == 1 ? "Singles" : "Doubles"
  }
  
  var body: some View {
    HStack(spacing: DesignSystem.Spacing.md) {
      ZStack {
        Circle()
          .fill(gameType.color.opacity(0.2).gradient)
          .frame(width: 44, height: 44)
        
        Image(systemName: teamSizeIcon)
          .font(.system(size: 20, weight: .semibold))
          .foregroundStyle(gameType.color)
      }
      
      VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
        Text(name)
          .font(.title3)
          .fontWeight(.regular)
          .foregroundStyle(.primary)
        
        Text(teamSizeText)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      
      Spacer()
    }
    .padding(.vertical, DesignSystem.Spacing.xs)
  }
}

#Preview("With Players") {
  let container = SwiftDataContainer.createPreviewContainer { context in
    SwiftDataSeeding.seedSampleRoster(into: context)
    
    let generated = CompletedGameFactory(context: context)
      .withPlayers()
      .gameType(.recreational)
      .scores(winner: 11, loser: 9)
      .timestamp(daysAgo: 2)
      .duration(minutes: 20, seconds: 45)
      .rallies(42)
      .generateWithDate()
    
    context.insert(generated.game)
    generated.game.isCompleted = true
    generated.game.completedDate = generated.completionDate
  }
  
  let context = container.mainContext
  let games = try? context.fetch(FetchDescriptor<Game>())
  let game = games?.first ?? Game(gameType: .recreational)
  
  LastGamePreview(
    game: game,
    gameType: .recreational,
    onStartGame: {
      print("Start game tapped")
    }
  )
  .modelContainer(container)
}

#Preview("With Teams") {
  let container = SwiftDataContainer.createPreviewContainer { context in
    SwiftDataSeeding.seedSampleRoster(into: context)
    
    let generated = CompletedGameFactory(context: context)
      .withTeams()
      .gameType(.recreational)
      .scores(winner: 11, loser: 9)
      .timestamp(daysAgo: 2)
      .duration(minutes: 20, seconds: 45)
      .rallies(42)
      .generateWithDate()
    
    context.insert(generated.game)
    generated.game.isCompleted = true
    generated.game.completedDate = generated.completionDate
  }
  
  let context = container.mainContext
  let games = try? context.fetch(FetchDescriptor<Game>())
  let game = games?.first ?? Game(gameType: .recreational)
  
  LastGamePreview(
    game: game,
    gameType: .recreational,
    onStartGame: {
      print("Start game tapped")
    }
  )
  .modelContainer(container)
}

