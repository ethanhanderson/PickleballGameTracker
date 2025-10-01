import GameTrackerCore
import SwiftData
import SwiftUI

struct TeamSizeOption: Identifiable {
  let id: Int
  let size: Int
  let displayName: String
  let description: String

  init(size: Int, displayName: String, description: String) {
    self.id = size
    self.size = size
    self.displayName = displayName
    self.description = description
  }
}

protocol GameEntity: Identifiable, Hashable {
  var id: UUID { get }
  var name: String { get }
  var displayName: String { get }
  var skillLevelDisplay: String? { get }
}

extension PlayerProfile: GameEntity {
  var displayName: String { name }
  var skillLevelDisplay: String? {
    skillLevel.displayName != "Unknown" ? skillLevel.displayName : nil
  }
}

extension TeamProfile: GameEntity {
  var displayName: String { name }
  var skillLevelDisplay: String? { nil }
}

@MainActor
struct TeamFormatSection: View {
  let gameType: GameType
  @Binding var selectedTeamSize: Int
  let teamSizeOptions: [TeamSizeOption]

  var body: some View {
    Section("Team Format") {
      Picker("Team Size", selection: $selectedTeamSize) {
        ForEach(teamSizeOptions, id: \.size) { option in
          Text(option.displayName).tag(option.size)
        }
      }
      .pickerStyle(.menu)
      .tint(gameType.color)
    }
  }
}

@MainActor
struct EntitySelectionRow: View {
  let entity: any GameEntity
  let isSelected: Bool
  let isDisabled: Bool
  let selectionIndex: Int?
  let selectionColor: Color

  var body: some View {
    HStack(spacing: DesignSystem.Spacing.md) {
      if let player = entity as? PlayerProfile {
        AvatarView(player: player, style: .small)
      } else if let team = entity as? TeamProfile {
        AvatarView(team: team, style: .small)
      }

      VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
        Text(entity.displayName)
          .font(.title3)
          .fontWeight(isSelected ? .semibold : .regular)
          .foregroundStyle(
            isSelected
              ? .black
              : (isDisabled
                ? .gray
                : .primary)
          )

        if let skillLevelDisplay = entity.skillLevelDisplay {
          Text(skillLevelDisplay)
            .font(.subheadline)
            .foregroundStyle(
              isDisabled
                ? .gray
                : .secondary
            )
        }

        if let team = entity as? TeamProfile, !team.players.isEmpty {
          Text(team.players.map { $0.name }.joined(separator: ", "))
            .font(.subheadline)
            .foregroundStyle(
              isDisabled
                ? .gray
                : .secondary
            )
            .lineLimit(1)
            .truncationMode(.tail)
        }
      }

      Spacer()

      ZStack {
        if isSelected {
          Circle()
            .fill(selectionColor)
            .frame(width: 26, height: 26)
          if let selectionIndex {
            Text("\(selectionIndex)")
              .font(.system(size: 20, weight: .bold, design: .rounded))
              .foregroundStyle(.white)
          }
        } else {
          Circle()
            .strokeBorder(
              isDisabled ? .gray.opacity(0.5) : .gray,
              lineWidth: 2
            )
            .frame(width: 26, height: 26)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .contentShape(.rect)
    .opacity(isDisabled ? 0.5 : 1.0)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(entity.displayName)\(selectionIndex != nil && isSelected ? ", selected number \(selectionIndex!)" : "")")
    .accessibilityIdentifier("entity.selection.\(entity.id.uuidString)")
  }
}

@MainActor
struct EntitySelectionSection: View {
  let title: String
  let entities: [any GameEntity]
  let selectedEntityIds: Set<UUID>
  let maxSelections: Int
  let onToggleSelection: (any GameEntity) -> Void
  let selectionNumbers: [UUID: Int]?
  let selectionColor: Color

  private var canSelectMore: Bool { selectedEntityIds.count < maxSelections }

  var body: some View {
    Section(title) {
      if entities.isEmpty {
        Text("No \(title.lowercased()) available")
          .foregroundStyle(.secondary)
      } else {
        ForEach(entities, id: \.id) { entity in
          let isSelected = selectedEntityIds.contains(entity.id)
          let index = selectionNumbers?[entity.id]
          EntitySelectionRow(
            entity: entity,
            isSelected: isSelected,
            isDisabled: !isSelected && !canSelectMore,
            selectionIndex: index,
            selectionColor: selectionColor
          )
          .contentShape(.rect)
          .onTapGesture {
            if isSelected || canSelectMore {
              onToggleSelection(entity)
            }
          }
        }
      }
    }
  }
}

@MainActor
struct SetupView: View {
    let gameType: GameType
    let onStartGame: (GameVariation, MatchupSelection) -> Void

    @Query private var allPlayers: [PlayerProfile]
    @Query private var allTeams: [TeamProfile]
    @Environment(LiveGameStateManager.self) private var activeGameStateManager

    @State private var selectedTeamSize: Int = 1
    @State private var selectedPlayerOrder: [UUID: Int] = [:]
    @State private var selectedTeam1: TeamProfile?
    @State private var selectedTeam2: TeamProfile?
    
    @State private var isCreatingGame = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    @State private var showingLiveGameConfirm = false
    @State private var pendingVariation: GameVariation?
    @State private var pendingMatchup: MatchupSelection?
    
    @Environment(\.dismiss) private var dismiss

    private var activePlayers: [PlayerProfile] {
        allPlayers.filter { !$0.isArchived }
    }

    private var activeTeams: [TeamProfile] {
        allTeams.filter { !$0.isArchived }
    }

    private var selectedTeams: [TeamProfile] {
        var teams: [TeamProfile] = []
        if let t1 = selectedTeam1 { teams.append(t1) }
        if let t2 = selectedTeam2 { teams.append(t2) }
        return teams
    }
    
    private var selectedTeamIds: Set<UUID> {
        var ids = Set<UUID>()
        if let t1 = selectedTeam1 { ids.insert(t1.id) }
        if let t2 = selectedTeam2 { ids.insert(t2.id) }
        return ids
    }

    private var playerSelectionNumbers: [UUID: Int] {
        selectedPlayerOrder
    }
    
    private var selectedPlayerIds: Set<UUID> {
        Set(selectedPlayerOrder.keys)
    }

    private var selectedPlayers: [PlayerProfile] {
        let orderedPairs = selectedPlayerOrder.sorted { lhs, rhs in
            lhs.value < rhs.value
        }
        return orderedPairs.compactMap { pair in
            allPlayers.first(where: { $0.id == pair.key })
        }
    }

    init(
        gameType: GameType,
        onStartGame: @escaping (GameVariation, MatchupSelection) -> Void
    ) {
        self.gameType = gameType
        self.onStartGame = onStartGame
        self._selectedTeamSize = State(initialValue: gameType.defaultTeamSize)
    }


    var body: some View {
        NavigationStack {
            Form {
                TeamFormatSection(
                    gameType: gameType,
                    selectedTeamSize: $selectedTeamSize,
                    teamSizeOptions: teamSizeOptions
                )
                .onChange(of: selectedTeamSize) { _, _ in
                    selectedPlayerOrder = [:]
                    selectedTeam1 = nil
                    selectedTeam2 = nil
                }

                EntitySelectionSection(
                    title: "Select Players",
                    entities: activePlayers,
                    selectedEntityIds: selectedPlayerIds,
                    maxSelections: selectedTeamSize == 1 ? 2 : 4,
                    onToggleSelection: { entity in
                        if let player = entity as? PlayerProfile {
                            togglePlayerSelection(player)
                        }
                    },
                    selectionNumbers: playerSelectionNumbers,
                    selectionColor: gameType.color
                )

                if selectedTeamSize > 1 {
                    EntitySelectionSection(
                        title: "Select Teams",
                        entities: activeTeams,
                        selectedEntityIds: selectedTeamIds,
                        maxSelections: 2,
                        onToggleSelection: { entity in
                            if let team = entity as? TeamProfile {
                                toggleTeamSelection(team)
                            }
                        },
                        selectionNumbers: nil,
                        selectionColor: gameType.color
                    )
                }
            }
            .navigationTitle("Set Up Game")
            .navigationBarTitleDisplayMode(.large)
            .scrollClipDisabled()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: startGame) {
                        if isCreatingGame {
                            ProgressView()
                                .tint(gameType.color)
                        } else {
                            Label("Start Game", systemImage: "play")
                        }
                    }
                    .buttonStyle(.glassProminent)
                    .tint(gameType.color)
                    .disabled(!canStartGame || isCreatingGame)
                    .confirmationDialog(
                        "An active game is in progress",
                        isPresented: $showingLiveGameConfirm,
                        titleVisibility: .visible
                    ) {
                        Button(
                            "End current game and start new",
                            role: .destructive
                        ) {
                            guard let variation = pendingVariation,
                                let matchup = pendingMatchup
                            else { return }
                            Task { @MainActor in
                                do {
                                    try await activeGameStateManager
                                        .completeCurrentGame()
                                } catch {
                                    Log.error(
                                        error,
                                        event: .saveFailed,
                                        metadata: [
                                            "phase": "completeBeforeStart"
                                        ]
                                    )
                                }
                                onStartGame(variation, matchup)
                                pendingVariation = nil
                                pendingMatchup = nil
                            }
                        }

                        Button("Keep current game") {
                            dismiss()
                            pendingVariation = nil
                            pendingMatchup = nil
                        }
                    } message: {
                        Text(
                            "You already have a game running. What would you like to do?"
                        )
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .tint(.secondary)
                    .accessibilityLabel("Close")
                    .accessibilityIdentifier("setup.close")
                }
            }
            .alert("Error Creating Game", isPresented: $showingError) {
                Button("OK", role: .confirm) {
                    errorMessage = ""
                }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var teamSizeOptions: [TeamSizeOption] {
        let minSize = gameType.minTeamSize
        let maxSize = gameType.maxTeamSize

        return (minSize...maxSize).map { size in
            TeamSizeOption(
                size: size,
                displayName: size == 1 ? "Singles" : "Doubles",
                description: size == 1
                    ? "1 player per team" : "\(size) players per team"
            )
        }
    }

    private var canStartGame: Bool {
        if selectedTeamSize == 1 {
            return selectedPlayers.count == 2
        } else {
            let hasEnoughPlayers = selectedPlayers.count == 4
            let hasEnoughTeams = selectedTeam1 != nil && selectedTeam2 != nil
            return hasEnoughPlayers || hasEnoughTeams
        }
    }

    private func togglePlayerSelection(_ player: PlayerProfile) {
        if selectedPlayerOrder[player.id] != nil {
            selectedPlayerOrder[player.id] = nil
        } else {
            let maxPlayers = selectedTeamSize == 1 ? 2 : 4
            if selectedPlayerOrder.count < maxPlayers {
                let availableSlots = selectedTeamSize == 1 ? [1, 2] : [1, 2, 3, 4]
                let available =
                    availableSlots.first { slot in
                        !selectedPlayerOrder.values.contains(slot)
                    } ?? 1
                selectedPlayerOrder[player.id] = available
            }
        }
    }

    private func toggleTeamSelection(_ team: TeamProfile) {
        if selectedTeam1?.id == team.id {
            selectedTeam1 = nil
        } else if selectedTeam2?.id == team.id {
            selectedTeam2 = nil
        } else if selectedTeam1 == nil {
            selectedTeam1 = team
        } else if selectedTeam2 == nil {
            selectedTeam2 = team
        }
    }

    private func startGame() {
        isCreatingGame = true

        Task { @MainActor in
            defer { isCreatingGame = false }
            do {
                let (variation, matchup) =
                    try await createGameVariationAndMatchup()
                // If there is a live game, confirm with the user before starting
                if activeGameStateManager.hasActiveGame {
                    pendingVariation = variation
                    pendingMatchup = matchup
                    showingLiveGameConfirm = true
                } else {
                    onStartGame(variation, matchup)
                }
            } catch let error as GameVariationError {
                if let suggestion = error.recoverySuggestion {
                    errorMessage = "\(error.localizedDescription)\n\n\(suggestion)"
                } else {
                    errorMessage = error.localizedDescription
                }
                showingError = true
            } catch {
                errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                showingError = true
            }
        }
    }

    private func createGameVariationAndMatchup()
        async throws(GameVariationError)
        -> (GameVariation, MatchupSelection)
    {
        if selectedTeamSize == 1 {
            let p1 = allPlayers.first { selectedPlayerOrder[$0.id] == 1 }
            let p2 = allPlayers.first { selectedPlayerOrder[$0.id] == 2 }
            guard let player1 = p1, let player2 = p2 else {
                throw GameVariationError.invalidConfiguration(
                    "Please select exactly 2 players"
                )
            }

            let variation = try createGameVariation(
                name: "\(player1.name) vs \(player2.name)",
                teamSize: 1
            )
            let matchup = MatchupSelection(
                teamSize: 1,
                mode: .players(
                    sideA: [player1.id],
                    sideB: [player2.id]
                )
            )
            return (variation, matchup)
        } else if selectedPlayers.count == 4 {
            let team1Player1 = allPlayers.first { selectedPlayerOrder[$0.id] == 1 }
            let team1Player2 = allPlayers.first { selectedPlayerOrder[$0.id] == 2 }
            let team2Player1 = allPlayers.first { selectedPlayerOrder[$0.id] == 3 }
            let team2Player2 = allPlayers.first { selectedPlayerOrder[$0.id] == 4 }

            guard let p1 = team1Player1, let p2 = team1Player2, let p3 = team2Player1, let p4 = team2Player2 else {
                throw GameVariationError.invalidConfiguration(
                    "Please select exactly 4 players (2 per team)"
                )
            }

            let variation = try createGameVariation(
                name: "\(p1.name) & \(p2.name) vs \(p3.name) & \(p4.name)",
                teamSize: 2
            )
            let matchup = MatchupSelection(
                teamSize: 2,
                mode: .players(
                    sideA: [p1.id, p2.id],
                    sideB: [p3.id, p4.id]
                )
            )
            return (variation, matchup)
        } else {
            guard let team1 = selectedTeam1, let team2 = selectedTeam2 else {
                throw GameVariationError.invalidConfiguration(
                    "Please select both teams"
                )
            }

            let variation = try createGameVariation(
                name: "\(team1.name) vs \(team2.name)",
                teamSize: selectedTeamSize
            )
            let matchup = MatchupSelection(
                teamSize: selectedTeamSize,
                mode: .teams(team1Id: team1.id, team2Id: team2.id)
            )
            return (variation, matchup)
        }
    }
    
    private func createGameVariation(name: String, teamSize: Int) throws(GameVariationError) -> GameVariation {
        try GameVariation.createValidated(
            name: name,
            gameType: gameType,
            teamSize: teamSize,
            winningScore: gameType.defaultWinningScore,
            winByTwo: gameType.defaultWinByTwo,
            kitchenRule: gameType.defaultKitchenRule,
            doubleBounceRule: gameType.defaultDoubleBounceRule,
            servingRotation: .standard,
            sideSwitchingRule: gameType.defaultSideSwitchingRule,
            isCustom: true
        )
    }
}

#Preview {
    let randomType = GameType.allTypes.randomElement() ?? .recreational
    let setup = PreviewEnvironmentSetup.createMinimal(container: PreviewEnvironment.roster().container)
    SetupView(gameType: randomType) { _, _ in }
        .minimalPreview(environment: setup.environment)
}
