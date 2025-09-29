import GameTrackerCore
import SwiftData
import SwiftUI

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
    @Environment(\.dismiss) private var dismiss

    // Active-game conflict handling
    @State private var showingActiveGameConfirm: Bool = false
    @State private var pendingVariation: GameVariation? = nil
    @State private var pendingMatchup: MatchupSelection? = nil

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

    private var playerSelectionNumbers: [UUID: Int] {
        selectedPlayerOrder
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

    private var selectedPlayersText: String {
        selectedPlayers.map { $0.name }.joined(separator: ", ")
    }

    private var selectedTeamsText: String {
        let teamNames = [selectedTeam1, selectedTeam2].compactMap { $0?.name }
        return teamNames.joined(separator: ", ")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Current Setup")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        HStack {
                            Text("Game Type:")
                                .foregroundStyle(.secondary)
                            Text(gameType.displayName)
                                .fontWeight(.semibold)
                        }

                        HStack {
                            Text("Team Size:")
                                .foregroundStyle(.secondary)
                            Text("\(selectedTeamSize)")
                                .fontWeight(.semibold)
                        }

                        if !selectedPlayers.isEmpty {
                            HStack {
                                Text("Players:")
                                    .foregroundStyle(.secondary)
                                Text(selectedPlayersText)
                                    .fontWeight(.semibold)
                            }
                        }

                        if selectedTeam1 != nil || selectedTeam2 != nil {
                            HStack {
                                Text("Teams:")
                                    .foregroundStyle(.secondary)
                                Text(selectedTeamsText)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                }

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

                if selectedTeamSize == 1 {
                    Section("Select Players") {
                        ForEach(activePlayers) { player in
                            Button {
                                togglePlayerSelection(player)
                            } label: {
                                HStack {
                                    Text(player.name)
                                    Spacer()
                                    if selectedPlayers.contains(player) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                            }
                            .disabled(selectedPlayers.count >= 2 && !selectedPlayers.contains(player))
                        }
                    }
                } else {
                    Section("Select Teams") {
                        ForEach(activeTeams) { team in
                            Button {
                                toggleTeamSelection(team)
                            } label: {
                                HStack {
                                    Text(team.name)
                                    Spacer()
                                    if selectedTeams.contains(team) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                            }
                            .disabled(selectedTeams.count >= 2 && !selectedTeams.contains(team))
                        }
                    }
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
                                .tint(.accentColor)
                        } else {
                            Label("Start Game", systemImage: "play")
                        }
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.accentColor)
                    .disabled(!canStartGame || isCreatingGame)
                    .confirmationDialog(
                        "An active game is in progress",
                        isPresented: $showingActiveGameConfirm,
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

                        Button("Keep current game (Resume)") {
                            dismiss()
                            pendingVariation = nil
                            pendingMatchup = nil
                        }

                        Button("Cancel", role: .cancel) {
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
            return selectedTeam1 != nil && selectedTeam2 != nil
        }
    }

    private func togglePlayerSelection(_ player: PlayerProfile) {
        if selectedPlayerOrder[player.id] != nil {
            selectedPlayerOrder[player.id] = nil
        } else if selectedPlayerOrder.count < 2 {
            let available =
                [1, 2].first { slot in
                    !selectedPlayerOrder.values.contains(slot)
                } ?? 1
            selectedPlayerOrder[player.id] = available
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
                // If there is an active game, confirm with the user before starting
                if activeGameStateManager.hasActiveGame {
                    pendingVariation = variation
                    pendingMatchup = matchup
                    showingActiveGameConfirm = true
                } else {
                    onStartGame(variation, matchup)
                    // Request the Live Game sheet to open
                    NotificationCenter.default.post(
                        name: Notification.Name("OpenLiveGameRequested"),
                        object: nil
                    )
                }
            } catch let error as GameVariationError {
                errorMessage = [
                    error.localizedDescription,
                    error.recoverySuggestion,
                ]
                .compactMap { $0 }
                .joined(separator: "\n\n")
                showingError = true
            } catch {
                errorMessage =
                    "An unexpected error occurred: \(error.localizedDescription)"
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

            let variation = try GameVariation.createValidated(
                name: "\(player1.name) vs \(player2.name)",
                gameType: gameType,
                teamSize: 1,
                winningScore: gameType.defaultWinningScore,
                winByTwo: gameType.defaultWinByTwo,
                kitchenRule: gameType.defaultKitchenRule,
                doubleBounceRule: gameType.defaultDoubleBounceRule,
                servingRotation: .standard,
                sideSwitchingRule: gameType.defaultSideSwitchingRule,
                isCustom: true
            )
            let matchup = MatchupSelection(
                teamSize: 1,
                mode: .players(
                    sideA: [player1.id],
                    sideB: [player2.id]
                )
            )
            return (variation, matchup)
        } else {
            guard let team1 = selectedTeam1, let team2 = selectedTeam2 else {
                throw GameVariationError.invalidConfiguration(
                    "Please select both teams"
                )
            }

            let variation = try GameVariation.createValidated(
                name: "\(team1.name) vs \(team2.name)",
                gameType: gameType,
                teamSize: selectedTeamSize,
                winningScore: gameType.defaultWinningScore,
                winByTwo: gameType.defaultWinByTwo,
                kitchenRule: gameType.defaultKitchenRule,
                doubleBounceRule: gameType.defaultDoubleBounceRule,
                servingRotation: .standard,
                sideSwitchingRule: gameType.defaultSideSwitchingRule,
                isCustom: true
            )
            let matchup = MatchupSelection(
                teamSize: selectedTeamSize,
                mode: .teams(team1Id: team1.id, team2Id: team2.id)
            )
            return (variation, matchup)
        }
    }
}

#Preview {
    let randomType = GameType.allTypes.randomElement() ?? .recreational
    let setup = PreviewEnvironmentSetup.createMinimal(container: PreviewEnvironment.roster().container)
    SetupView(gameType: randomType) { _, _ in }
        .minimalPreview(environment: setup.environment)
}
