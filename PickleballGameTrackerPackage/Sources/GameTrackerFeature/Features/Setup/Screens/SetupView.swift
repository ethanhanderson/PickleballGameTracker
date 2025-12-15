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
        if isGuest {
            return "Guest player"
        }
        return skillLevel.displayName != "Unknown"
            ? skillLevel.displayName : nil
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
    let showRemoveButton: Bool
    let onRemove: (() -> Void)?

    init(
        entity: any GameEntity,
        isSelected: Bool,
        isDisabled: Bool,
        selectionIndex: Int?,
        selectionColor: Color,
        showRemoveButton: Bool = false,
        onRemove: (() -> Void)? = nil
    ) {
        self.entity = entity
        self.isSelected = isSelected
        self.isDisabled = isDisabled
        self.selectionIndex = selectionIndex
        self.selectionColor = selectionColor
        self.showRemoveButton = showRemoveButton
        self.onRemove = onRemove
    }

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
                    .fontWeight(.regular)
                    .foregroundStyle(
                        isDisabled
                            ? .gray
                            : .primary
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

            if showRemoveButton {
                Button(action: { onRemove?() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.gray)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(entity.displayName)")
            } else {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(selectionColor)
                            .frame(width: 26, height: 26)
                        if let selectionIndex {
                            Text("\(selectionIndex)")
                                .font(
                                    .system(
                                        size: 20,
                                        weight: .bold,
                                        design: .rounded
                                    )
                                )
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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
        .opacity(isDisabled ? 0.5 : 1.0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(entity.displayName)\(selectionIndex != nil && isSelected ? ", selected number \(selectionIndex!)" : "")"
        )
        .accessibilityIdentifier("entity.selection.\(entity.id.uuidString)")
    }
}

@MainActor
struct EntitySelectionSection: View {
    let title: String
    let entities: [any GameEntity]
    let selectedEntityIds: Set<UUID>
    let isEntityDisabled: (any GameEntity) -> Bool
    let onToggleSelection: (any GameEntity) -> Void
    let selectionNumbers: [UUID: Int]?
    let selectionColor: Color
    let createButtonLabel: String?
    let createButtonIcon: String?
    let onCreateNew: (() -> Void)?
    let hideEmptyState: Bool

    init(
        title: String,
        entities: [any GameEntity],
        selectedEntityIds: Set<UUID>,
        isEntityDisabled: @escaping (any GameEntity) -> Bool,
        onToggleSelection: @escaping (any GameEntity) -> Void,
        selectionNumbers: [UUID: Int]?,
        selectionColor: Color,
        createButtonLabel: String?,
        createButtonIcon: String?,
        onCreateNew: (() -> Void)?,
        hideEmptyState: Bool = false
    ) {
        self.title = title
        self.entities = entities
        self.selectedEntityIds = selectedEntityIds
        self.isEntityDisabled = isEntityDisabled
        self.onToggleSelection = onToggleSelection
        self.selectionNumbers = selectionNumbers
        self.selectionColor = selectionColor
        self.createButtonLabel = createButtonLabel
        self.createButtonIcon = createButtonIcon
        self.onCreateNew = onCreateNew
        self.hideEmptyState = hideEmptyState
    }

    private var availableEntities: [any GameEntity] {
        entities.filter { !selectedEntityIds.contains($0.id) }
    }

    var body: some View {
        Section(title) {
            if availableEntities.isEmpty && !hideEmptyState {
                Text("No \(title.lowercased()) available")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(availableEntities, id: \.id) { entity in
                    let isDisabled = isEntityDisabled(entity)
                    EntitySelectionRow(
                        entity: entity,
                        isSelected: false,
                        isDisabled: isDisabled,
                        selectionIndex: nil,
                        selectionColor: selectionColor
                    )
                    .contentShape(.rect)
                    .onTapGesture {
                        if !isDisabled {
                            onToggleSelection(entity)
                        }
                    }
                }
            }

            if let createButtonLabel, let createButtonIcon, let onCreateNew {
                Button(action: onCreateNew) {
                    HStack(spacing: DesignSystem.Spacing.md) {
                        Image(systemName: createButtonIcon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(selectionColor)
                            .frame(width: 38, height: 38)

                        Text(createButtonLabel)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(selectionColor)

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(
                    "setup.\(createButtonLabel.replacingOccurrences(of: " ", with: "").lowercased())"
                )
            }
        }
    }
}

@MainActor
struct MatchupEntityRow: View {
    let entity: any GameEntity
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            if let player = entity as? PlayerProfile {
                AvatarView(player: player, style: .small)
            } else if let team = entity as? TeamProfile {
                AvatarView(team: team, style: .small)
            }

            Text(entity.displayName)
                .font(.title3)
                .fontWeight(.regular)
                .foregroundStyle(.primary)

            Spacer()

            Button(action: onRemove) {
                Image(systemName: "xmark")
            }
            .buttonBorderShape(.circle)
            .buttonStyle(.glassProminent)
            .tint(.red)
            .fontWeight(.semibold)
            .accessibilityLabel("Remove \(entity.displayName)")
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(entity.displayName)
        .accessibilityIdentifier("matchup.entity.\(entity.id.uuidString)")
    }
}

@MainActor
struct CurrentMatchupSection: View {
    let teamSize: Int
    let sideAEntities: [any GameEntity]
    let sideBEntities: [any GameEntity]
    let sideAHasTeam: Bool
    let sideBHasTeam: Bool
    let sideATeam: TeamProfile?
    let sideBTeam: TeamProfile?
    let onRemove: (any GameEntity) -> Void

    private var maxPlayersPerSide: Int {
        teamSize == 1 ? 1 : 2
    }

    private var hasSelections: Bool {
        !sideAEntities.isEmpty || !sideBEntities.isEmpty
    }

    private var allEntities: [any GameEntity] {
        sideAEntities + sideBEntities
    }

    var body: some View {
        if hasSelections {
            Section {
                VStack(spacing: DesignSystem.Spacing.md) {
                    if !sideAEntities.isEmpty {
                        HStack {
                            Text("South")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, DesignSystem.Spacing.sm)
                                .padding(.vertical, DesignSystem.Spacing.xs)
                                .glassEffect(
                                    .regular.tint(Color.gray.opacity(0.15).opacity(0.2))
                                )
                            Spacer()
                            if let team = sideATeam {
                                HStack(spacing: DesignSystem.Spacing.sm) {
                                    Circle()
                                        .fill(team.accentColorStored.swiftUIColor.gradient)
                                        .frame(width: 16, height: 16)
                                    Text(team.name)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, DesignSystem.Spacing.sm)
                                .padding(.vertical, DesignSystem.Spacing.xs)
                                .glassEffect(
                                    .regular.tint(team.accentColorStored.swiftUIColor.opacity(0.08))
                                )
                            }
                        }
                        ForEach(sideAEntities, id: \.id) { entity in
                            MatchupEntityRow(
                                entity: entity,
                                onRemove: { onRemove(entity) }
                            )
                        }
                    }

                    if !sideAEntities.isEmpty && !sideBEntities.isEmpty {
                        ZStack(alignment: .center) {
                            Text("vs")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .padding(
                                    .horizontal,
                                    DesignSystem.Spacing.sm
                                )
                                .padding(.vertical, DesignSystem.Spacing.xs)

                            ZStack(alignment: .center) {
                                Capsule()
                                    .fill(.primary)
                                    .frame(
                                        width: 40,
                                        height: 25
                                    )

                                Capsule()
                                    .fill(.primary)
                                    .frame(height: 2)
                            }
                            .compositingGroup()
                            .opacity(0.03)
                        }
                    }

                    if !sideBEntities.isEmpty {
                        HStack {
                            Text("North")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, DesignSystem.Spacing.sm)
                                .padding(.vertical, DesignSystem.Spacing.xs)
                                .glassEffect(
                                    .regular.tint(Color.gray.opacity(0.15).opacity(0.2))
                                )
                            Spacer()
                            if let team = sideBTeam {
                                HStack(spacing: DesignSystem.Spacing.sm) {
                                    Circle()
                                        .fill(team.accentColorStored.swiftUIColor.gradient)
                                        .frame(width: 16, height: 16)
                                    Text(team.name)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, DesignSystem.Spacing.sm)
                                .padding(.vertical, DesignSystem.Spacing.xs)
                                .glassEffect(
                                    .regular.tint(team.accentColorStored.swiftUIColor.opacity(0.08))
                                )
                            }
                        }
                        ForEach(sideBEntities, id: \.id) { entity in
                            MatchupEntityRow(
                                entity: entity,
                                onRemove: { onRemove(entity) }
                            )
                        }
                    }
                }
                .padding(.vertical, DesignSystem.Spacing.sm)
            } header: {
                Text("Current Matchup")
            }
        }
    }
}

@MainActor
struct GameFormatOptionsView: View {
    let gameType: GameType
    @Binding var selectedTeamSize: Int
    @Binding var selectedTeamSizeA: Int
    @Binding var selectedTeamSizeB: Int
    @Binding var cutthroatPlayerCount: Int
    @Binding var isCutthroatPickerExpanded: Bool
    let teamSizeOptions: [TeamSizeOption]

    var body: some View {
        Group {
            if gameType == .custom {
                Section("Team Format") {
                    Picker("South Size", selection: $selectedTeamSizeA) {
                        ForEach(teamSizeOptions, id: \.size) { option in
                            Text(option.displayName).tag(option.size)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(gameType.color)

                    Picker("North Size", selection: $selectedTeamSizeB) {
                        ForEach(teamSizeOptions, id: \.size) { option in
                            Text(option.displayName).tag(option.size)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(gameType.color)
                }
            } else if gameType == .cutthroat {
                Section("Number of Players") {
                    HStack {
                        Text("Players")
                            .font(.title3)
                            .foregroundStyle(.primary)

                        Spacer()

                        Button(action: {
                            withAnimation {
                                isCutthroatPickerExpanded.toggle()
                            }
                        }) {
                            Text("\(cutthroatPlayerCount)")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, DesignSystem.Spacing.md)
                                .frame(height: 32)
                                .background(
                                    Capsule().fill(.gray.opacity(0.1))
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    if isCutthroatPickerExpanded {
                        Picker("Players", selection: $cutthroatPlayerCount) {
                            ForEach(gameType.minPlayersTotal...gameType.maxPlayersTotal, id: \.self) { n in
                                Text("\(n)").tag(n)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .tint(gameType.color)
                    }
                }
            } else {
                TeamFormatSection(
                    gameType: gameType,
                    selectedTeamSize: $selectedTeamSize,
                    teamSizeOptions: teamSizeOptions
                )
            }
        }
    }
}

@MainActor
struct TeamPickerSectionView: View {
    let teams: [TeamProfile]
    let selectedTeamIds: Set<UUID>
    let isEntityDisabled: (any GameEntity) -> Bool
    let selectionColor: Color
    let onCreateNew: () -> Void
    let onToggleTeam: (TeamProfile) -> Void

    var body: some View {
        EntitySelectionSection(
            title: "Select Teams",
            entities: teams,
            selectedEntityIds: selectedTeamIds,
            isEntityDisabled: isEntityDisabled,
            onToggleSelection: { entity in
                if let team = entity as? TeamProfile {
                    onToggleTeam(team)
                }
            },
            selectionNumbers: nil,
            selectionColor: selectionColor,
            createButtonLabel: "New Team",
            createButtonIcon: "person.2.badge.plus.fill",
            onCreateNew: onCreateNew
        )
    }
}

@MainActor
struct PlayerPickerSectionView: View {
    let players: [PlayerProfile]
    let selectedPlayerIds: Set<UUID>
    let selectionNumbers: [UUID: Int]
    let selectionColor: Color
    let isEntityDisabled: (any GameEntity) -> Bool
    let onCreateNew: () -> Void
    let onTogglePlayer: (PlayerProfile) -> Void

    var body: some View {
        EntitySelectionSection(
            title: "Select Players",
            entities: players,
            selectedEntityIds: selectedPlayerIds,
            isEntityDisabled: isEntityDisabled,
            onToggleSelection: { entity in
                if let player = entity as? PlayerProfile {
                    onTogglePlayer(player)
                }
            },
            selectionNumbers: selectionNumbers,
            selectionColor: selectionColor,
            createButtonLabel: "New Player",
            createButtonIcon: "person.fill.badge.plus",
            onCreateNew: onCreateNew
        )
    }
}

@MainActor
struct CutthroatMatchupSection: View {
    let entities: [any GameEntity]
    let onRemove: (any GameEntity) -> Void

    var body: some View {
        if !entities.isEmpty {
            Section {
                VStack(spacing: DesignSystem.Spacing.md) {
                    ForEach(entities, id: \.id) { entity in
                        MatchupEntityRow(
                            entity: entity,
                            onRemove: { onRemove(entity) }
                        )
                    }
                }
                .padding(.vertical, DesignSystem.Spacing.sm)
            } header: {
                Text("Players")
            }
        }
    }
}

@MainActor
struct FillRemainingSlotsButton: View {
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Section {
            Button(action: action) {
                Text("Fill remaining slots with guests")
            }
            .foregroundStyle(accentColor)
            .accessibilityIdentifier("setup.fillGuests")
        }
    }
}

@MainActor
struct SetupView: View {
    let gameType: GameType
    let onStartGame: (GameType, GameRules?, MatchupSelection) -> Void

    @Query(filter: #Predicate<PlayerProfile> { !$0.isArchived && !$0.isGuest })
    private var allPlayers: [PlayerProfile]
    @Query private var allTeams: [TeamProfile]
    @Query(filter: #Predicate<PlayerProfile> { $0.isGuest })
    private var allGuestPlayers: [PlayerProfile]
    @Environment(LiveGameStateManager.self) private var activeGameStateManager
    @Environment(LiveSyncCoordinator.self) private var syncCoordinator
    @Environment(PlayerTeamManager.self) private var rosterManager

    @State private var selectedTeamSize: Int = 1
    @State private var selectedTeamSizeA: Int = 1
    @State private var selectedTeamSizeB: Int = 1
    @State private var cutthroatPlayerCount: Int = 3
    @State private var selectedPlayerOrder: [UUID: Int] = [:]
    @State private var selectedPlayers: [PlayerProfile] = []
    @State private var selectedTeam1: TeamProfile?
    @State private var selectedTeam2: TeamProfile?

    @State private var isCreatingGame = false
    @State private var showingError = false
    @State private var errorMessage = ""

    @State private var showingLiveGameConfirm = false
    @State private var pendingRules: GameRules?
    @State private var pendingMatchup: MatchupSelection?

    @State private var showPlayerSheet = false
    @State private var showTeamSheet = false
    @State private var globalNav = GlobalNavigationState.shared
    @State private var isCutthroatPickerExpanded = false
    @State private var isCutthroatScorePickerExpanded = false
    @State private var cutthroatTargetScore: Int = 11
    @State private var cutthroatNoLimit: Bool = false

    @Environment(\.dismiss) private var dismiss

    private var activePlayers: [PlayerProfile] {
        allPlayers
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
        Set(selectedPlayers.map { $0.id })
    }

    private var slotsPerSide: Int { selectedTeamSize }
    private var slotsPerSideA: Int { gameType == .custom ? selectedTeamSizeA : selectedTeamSize }
    private var slotsPerSideB: Int { gameType == .custom ? selectedTeamSizeB : selectedTeamSize }

    private var totalSlots: Int {
        if gameType == .cutthroat {
            return cutthroatPlayerCount
        }
        return slotsPerSideA + slotsPerSideB
    }

    private var totalSlotsFilled: Int {
        var count = 0

        if gameType == .cutthroat {
            count = selectedPlayers.count
        } else {
            if selectedTeam1 != nil {
                count += slotsPerSideA
            } else {
                count += min(sideAPlayers.count, slotsPerSideA)
            }

            if selectedTeam2 != nil {
                count += slotsPerSideB
            } else {
                count += min(sideBPlayers.count, slotsPerSideB)
            }
        }

        return count
    }

    private var slotsRemaining: Int { max(0, totalSlots - totalSlotsFilled) }

    private var sideASlotsFilled: Int {
        if gameType == .cutthroat { return min(selectedPlayers.count, max(1, cutthroatPlayerCount / 2 + (cutthroatPlayerCount % 2))) }
        if selectedTeam1 != nil { return slotsPerSideA }
        return min(selectedPlayers.count, slotsPerSideA)
    }

    private var sideBSlotsFilled: Int {
        if gameType == .cutthroat { return max(0, selectedPlayers.count - sideASlotsFilled) }
        if selectedTeam2 != nil { return slotsPerSideB }
        let playersForSideB = max(0, selectedPlayers.count - sideASlotsFilled)
        return min(playersForSideB, slotsPerSideB)
    }

    private var sideAPlayers: [PlayerProfile] {
        if selectedTeam1 != nil { return [] }
        if gameType == .cutthroat {
            // Alternate assignment: even indices to side A
            return selectedPlayers.enumerated().compactMap { idx, p in idx % 2 == 0 ? p : nil }
        }
        return Array(selectedPlayers.prefix(min(selectedPlayers.count, slotsPerSideA)))
    }

    private var sideBPlayers: [PlayerProfile] {
        if selectedTeam2 != nil { return [] }
        if gameType == .cutthroat {
            // Alternate assignment: odd indices to side B
            return selectedPlayers.enumerated().compactMap { idx, p in idx % 2 == 1 ? p : nil }
        }
        let offset = selectedTeam1 != nil ? 0 : sideAPlayers.count
        return Array(selectedPlayers.dropFirst(offset).prefix(slotsPerSideB))
    }

    private var sideAEntities: [any GameEntity] {
        if let team = selectedTeam1 {
            return team.players.map { $0 as any GameEntity }
        }
        return sideAPlayers.map { $0 as any GameEntity }
    }

    private var sideBEntities: [any GameEntity] {
        if let team = selectedTeam2 {
            return team.players.map { $0 as any GameEntity }
        }
        return sideBPlayers.map { $0 as any GameEntity }
    }

    private func isEntityDisabled(_ entity: any GameEntity) -> Bool {
        if selectedEntityIds.contains(entity.id) {
            return false
        }

        if gameType == .cutthroat {
            // Disable when we've reached the selected total count
            return slotsRemaining < 1
        }

        if entity is TeamProfile {
            return slotsRemaining < 1 || (slotsPerSideA - sideASlotsFilled < selectedTeamSize && slotsPerSideB - sideBSlotsFilled < selectedTeamSize)
        } else {
            return slotsRemaining < 1
        }
    }

    private var selectedEntityIds: Set<UUID> {
        var ids = selectedPlayerIds
        if let team1 = selectedTeam1 {
            ids.insert(team1.id)
        }
        if let team2 = selectedTeam2 {
            ids.insert(team2.id)
        }
        return ids
    }

    init(
        gameType: GameType,
        onStartGame: @escaping (GameType, GameRules?, MatchupSelection) -> Void
    ) {
        self.gameType = gameType
        self.onStartGame = onStartGame
        self._selectedTeamSize = State(initialValue: gameType.defaultTeamSize)
        self._selectedTeamSizeA = State(initialValue: gameType.defaultTeamSize)
        self._selectedTeamSizeB = State(initialValue: gameType.defaultTeamSize)
        self._cutthroatPlayerCount = State(initialValue: 3)
    }

    var body: some View {
        NavigationStack {
            Form {
                gameTypeContent
            }
            .navigationTitle("Set Up Game")
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
                            guard let rules = pendingRules,
                                  let matchup = pendingMatchup
                            else { return }
                            Task { @MainActor in
                                do {
                                    try await activeGameStateManager.completeCurrentGame()
                                } catch {
                                    Log.error(
                                        error,
                                        event: .saveFailed,
                                        metadata: [
                                            "phase": "completeBeforeStart"
                                        ]
                                    )
                                }
                                onStartGame(gameType, rules, matchup)
                                pendingRules = nil
                                pendingMatchup = nil
                            }
                        }

                        Button("Keep current game") {
                            dismiss()
                            pendingRules = nil
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
        .sheet(isPresented: $showPlayerSheet) {
            IdentityEditorView(identity: .player(nil))
        }
        .onChange(of: showPlayerSheet) { _, isPresented in
            if isPresented {
                globalNav.registerSheet("setupPlayer")
            } else {
                globalNav.unregisterSheet("setupPlayer")
            }
        }
        .sheet(isPresented: $showTeamSheet) {
            IdentityEditorView(identity: .team(nil))
        }
        .onChange(of: showTeamSheet) { _, isPresented in
            if isPresented {
                globalNav.registerSheet("setupTeam")
            } else {
                globalNav.unregisterSheet("setupTeam")
            }
        }

    }

    @ViewBuilder
    private var gameTypeContent: some View {
        if gameType == .custom {
            Group {
                GameFormatOptionsView(
                    gameType: gameType,
                    selectedTeamSize: $selectedTeamSize,
                    selectedTeamSizeA: $selectedTeamSizeA,
                    selectedTeamSizeB: $selectedTeamSizeB,
                    cutthroatPlayerCount: $cutthroatPlayerCount,
                    isCutthroatPickerExpanded: $isCutthroatPickerExpanded,
                    teamSizeOptions: teamSizeOptions
                )
                .onChange(of: selectedTeamSizeA) { _, _ in
                    selectedPlayerOrder = [:]
                    selectedPlayers = []
                    selectedTeam1 = nil
                    selectedTeam2 = nil
                }
                .onChange(of: selectedTeamSizeB) { _, _ in
                    selectedPlayerOrder = [:]
                    selectedPlayers = []
                    selectedTeam1 = nil
                    selectedTeam2 = nil
                }

                CurrentMatchupSection(
                    teamSize: max(selectedTeamSizeA, selectedTeamSizeB),
                    sideAEntities: sideAEntities,
                    sideBEntities: sideBEntities,
                    sideAHasTeam: selectedTeam1 != nil,
                    sideBHasTeam: selectedTeam2 != nil,
                    sideATeam: selectedTeam1,
                    sideBTeam: selectedTeam2,
                    onRemove: removeEntity
                )

                if slotsRemaining > 0 && (!sideAEntities.isEmpty || !sideBEntities.isEmpty) {
                    FillRemainingSlotsButton(
                        accentColor: gameType.color,
                        action: fillRemainingWithGuests
                    )
                }

                if max(selectedTeamSizeA, selectedTeamSizeB) > 1 {
                    TeamPickerSectionView(
                        teams: activeTeams,
                        selectedTeamIds: selectedTeamIds,
                        isEntityDisabled: isEntityDisabled,
                        selectionColor: gameType.color,
                        onCreateNew: { showTeamSheet = true },
                        onToggleTeam: { team in
                            toggleTeamSelection(team)
                        }
                    )
                }

                PlayerPickerSectionView(
                    players: activePlayers,
                    selectedPlayerIds: selectedPlayerIds,
                    selectionNumbers: playerSelectionNumbers,
                    selectionColor: gameType.color,
                    isEntityDisabled: isEntityDisabled,
                    onCreateNew: { showPlayerSheet = true },
                    onTogglePlayer: { player in
                        togglePlayerSelection(player)
                    }
                )
            }
        } else if gameType == .cutthroat {
            Group {
                Section("Target Score") {
                    HStack {
                        Text("Play to")
                            .font(.title3)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                isCutthroatScorePickerExpanded.toggle()
                            }
                        }) {
                            Text(cutthroatNoLimit ? "No limit" : "\(cutthroatTargetScore)")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, DesignSystem.Spacing.md)
                                .frame(height: 32)
                                .background(
                                    Capsule().fill(.gray.opacity(0.1))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if isCutthroatScorePickerExpanded {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            Picker("Target Score", selection: $cutthroatTargetScore) {
                                ForEach(1...50, id: \.self) { n in
                                    Text("\(n)").tag(n)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .tint(gameType.color)
                            .disabled(cutthroatNoLimit)
                            .opacity(cutthroatNoLimit ? 0.3 : 1.0)
                            
                            Toggle(isOn: $cutthroatNoLimit) {
                                Text("No limit")
                            }
                            .tint(gameType.color)
                        }
                    }
                }

                GameFormatOptionsView(
                    gameType: gameType,
                    selectedTeamSize: $selectedTeamSize,
                    selectedTeamSizeA: $selectedTeamSizeA,
                    selectedTeamSizeB: $selectedTeamSizeB,
                    cutthroatPlayerCount: $cutthroatPlayerCount,
                    isCutthroatPickerExpanded: $isCutthroatPickerExpanded,
                    teamSizeOptions: teamSizeOptions
                )
                .onChange(of: cutthroatPlayerCount) { _, _ in
                    if selectedPlayers.count > cutthroatPlayerCount {
                        selectedPlayers = Array(selectedPlayers.prefix(cutthroatPlayerCount))
                        updatePlayerOrder()
                    }
                }

                CutthroatMatchupSection(
                    entities: selectedPlayers.map { $0 as any GameEntity },
                    onRemove: removeEntity
                )

                if slotsRemaining > 0 && !selectedPlayers.isEmpty {
                    FillRemainingSlotsButton(
                        accentColor: gameType.color,
                        action: fillRemainingWithGuests
                    )
                }

                PlayerPickerSectionView(
                    players: activePlayers,
                    selectedPlayerIds: selectedPlayerIds,
                    selectionNumbers: playerSelectionNumbers,
                    selectionColor: gameType.color,
                    isEntityDisabled: { entity in
                        if selectedEntityIds.contains(entity.id) { return false }
                        return selectedPlayers.count >= cutthroatPlayerCount
                    },
                    onCreateNew: { showPlayerSheet = true },
                    onTogglePlayer: { player in
                        togglePlayerSelection(player)
                    }
                )
            }
        } else {
            Group {
                GameFormatOptionsView(
                    gameType: gameType,
                    selectedTeamSize: $selectedTeamSize,
                    selectedTeamSizeA: $selectedTeamSizeA,
                    selectedTeamSizeB: $selectedTeamSizeB,
                    cutthroatPlayerCount: $cutthroatPlayerCount,
                    isCutthroatPickerExpanded: $isCutthroatPickerExpanded,
                    teamSizeOptions: teamSizeOptions
                )
                .onChange(of: selectedTeamSize) { _, _ in
                    selectedPlayerOrder = [:]
                    selectedPlayers = []
                    selectedTeam1 = nil
                    selectedTeam2 = nil
                }

                CurrentMatchupSection(
                    teamSize: selectedTeamSize,
                    sideAEntities: sideAEntities,
                    sideBEntities: sideBEntities,
                    sideAHasTeam: selectedTeam1 != nil,
                    sideBHasTeam: selectedTeam2 != nil,
                    sideATeam: selectedTeam1,
                    sideBTeam: selectedTeam2,
                    onRemove: removeEntity
                )

                if slotsRemaining > 0 && (!sideAEntities.isEmpty || !sideBEntities.isEmpty) {
                    FillRemainingSlotsButton(
                        accentColor: gameType.color,
                        action: fillRemainingWithGuests
                    )
                }

                if selectedTeamSize > 1 {
                    TeamPickerSectionView(
                        teams: activeTeams,
                        selectedTeamIds: selectedTeamIds,
                        isEntityDisabled: isEntityDisabled,
                        selectionColor: gameType.color,
                        onCreateNew: { showTeamSheet = true },
                        onToggleTeam: { team in
                            toggleTeamSelection(team)
                        }
                    )
                }

                PlayerPickerSectionView(
                    players: activePlayers,
                    selectedPlayerIds: selectedPlayerIds,
                    selectionNumbers: playerSelectionNumbers,
                    selectionColor: gameType.color,
                    isEntityDisabled: isEntityDisabled,
                    onCreateNew: { showPlayerSheet = true },
                    onTogglePlayer: { player in
                        togglePlayerSelection(player)
                    }
                )
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
        if gameType == .cutthroat {
            return selectedPlayers.count >= gameType.minPlayersTotal && selectedPlayers.count == cutthroatPlayerCount
        }
        if gameType == .custom {
            let sideAFilled = sideASlotsFilled == slotsPerSideA
            let sideBFilled = sideBSlotsFilled == slotsPerSideB
            return sideAFilled && sideBFilled
        }
        let sideAFilled = sideASlotsFilled == slotsPerSide
        let sideBFilled = sideBSlotsFilled == slotsPerSide
        return sideAFilled && sideBFilled
    }

    private func togglePlayerSelection(_ player: PlayerProfile) {
        if let index = selectedPlayers.firstIndex(where: { $0.id == player.id })
        {
            selectedPlayers.remove(at: index)
            updatePlayerOrder()
        } else {
            if slotsRemaining >= 1 {
                selectedPlayers.append(player)
                updatePlayerOrder()
            }
        }
    }

    private func updatePlayerOrder() {
        selectedPlayerOrder = [:]
        for (index, player) in selectedPlayers.enumerated() {
            selectedPlayerOrder[player.id] = index + 1
        }
    }

    private func toggleTeamSelection(_ team: TeamProfile) {
        if selectedTeam1?.id == team.id {
            selectedTeam1 = nil
        } else if selectedTeam2?.id == team.id {
            selectedTeam2 = nil
        } else {
            if gameType == .cutthroat { return }
            if slotsRemaining >= 1 {
                let sideAAvailable = slotsPerSideA - sideASlotsFilled
                let sideBAvailable = slotsPerSideB - sideBSlotsFilled

                if sideAAvailable >= selectedTeamSize {
                    selectedTeam1 = team
                } else if sideBAvailable >= selectedTeamSize {
                    selectedTeam2 = team
                }
            }
        }
    }

    private func removeEntity(_ entity: any GameEntity) {
        if let player = entity as? PlayerProfile {
            if let team1 = selectedTeam1,
                team1.players.contains(where: { $0.id == player.id })
            {
                let remainingPlayers = team1.players.filter {
                    $0.id != player.id
                }
                selectedTeam1 = nil

                let insertIndex = 0
                for remainingPlayer in remainingPlayers.reversed() {
                    if !selectedPlayers.contains(where: {
                        $0.id == remainingPlayer.id
                    }) {
                        selectedPlayers.insert(remainingPlayer, at: insertIndex)
                    }
                }
                updatePlayerOrder()
            } else if let team2 = selectedTeam2,
                team2.players.contains(where: { $0.id == player.id })
            {
                let remainingPlayers = team2.players.filter {
                    $0.id != player.id
                }
                selectedTeam2 = nil

                let insertIndex = sideAPlayers.count
                for (offset, remainingPlayer) in remainingPlayers.enumerated() {
                    if !selectedPlayers.contains(where: {
                        $0.id == remainingPlayer.id
                    }) {
                        selectedPlayers.insert(
                            remainingPlayer,
                            at: insertIndex + offset
                        )
                    }
                }
                updatePlayerOrder()
            } else {
                if let index = selectedPlayers.firstIndex(where: {
                    $0.id == player.id
                }) {
                    selectedPlayers.remove(at: index)
                    updatePlayerOrder()
                }
            }
        } else if let team = entity as? TeamProfile {
            if selectedTeam1?.id == team.id {
                selectedTeam1 = nil
            } else if selectedTeam2?.id == team.id {
                selectedTeam2 = nil
            }
        }
    }

    private func startGame() {
        isCreatingGame = true

        Task { @MainActor in
            defer { isCreatingGame = false }
            do {
                let (rules, matchup) =
                    try await createGameRulesAndMatchup()
                
                if activeGameStateManager.hasLiveGame {
                    pendingRules = rules
                    pendingMatchup = matchup
                    showingLiveGameConfirm = true
                } else {
                    onStartGame(gameType, rules, matchup)
                }
            } catch let error as GameRulesError {
                if let suggestion = error.recoverySuggestion {
                    errorMessage =
                        "\(error.localizedDescription)\n\n\(suggestion)"
                } else {
                    errorMessage = error.localizedDescription
                }
                showingError = true
            } catch {
                errorMessage =
                    "An unexpected error occurred: \(error.localizedDescription)"
                showingError = true
            }
        }
    }

    private func fillRemainingWithGuests() {
        let remaining = slotsRemaining
        guard remaining > 0 else { return }

        func extractGuestNumber(from name: String) -> Int? {
            let parts = name.split(separator: " ")
            guard parts.count == 2, parts[0].lowercased() == "guest",
                let num = Int(parts[1])
            else { return nil }
            return num
        }

        let existingGuestNumbers: [Int] =
            (allGuestPlayers + selectedPlayers.filter { $0.isGuest })
            .compactMap { extractGuestNumber(from: $0.name) }
        let startNumber = (existingGuestNumbers.max() ?? 0) + 1

        for i in 0..<remaining {
            do {
                let guestName = "Guest \(startNumber + i)"
                let guest = try rosterManager.createGuestPlayer(name: guestName)
                selectedPlayers.append(guest)
            } catch {
                Log.error(
                    error,
                    event: .saveFailed,
                    metadata: [
                        "phase": "fillGuests"
                    ]
                )
                break
            }
        }
        updatePlayerOrder()
    }

    private func createGameRulesAndMatchup()
        async throws(GameRulesError)
        -> (GameRules?, MatchupSelection)
    {
        if gameType == .cutthroat {
            guard selectedPlayers.count >= 2 else {
                throw GameRulesError.invalidConfiguration("Please select at least 2 players")
            }
            let rules = gameType.defaultRules
            let sideAIds = sideAPlayers.map { $0.id }
            let sideBIds = sideBPlayers.map { $0.id }
            let matchup = MatchupSelection(teamSize: 1, mode: .players(sideA: sideAIds, sideB: sideBIds))
            return (rules, matchup)
        }

        guard sideASlotsFilled == slotsPerSideA && sideBSlotsFilled == slotsPerSideB else {
            throw GameRulesError.invalidConfiguration("Please fill all slots for both sides")
        }

        let rules = gameType.defaultRules

        if (gameType == .custom ? max(selectedTeamSizeA, selectedTeamSizeB) : selectedTeamSize) == 1 {
            guard sideAPlayers.count == 1 && sideBPlayers.count == 1 else {
                throw GameRulesError.invalidConfiguration(
                    "Please select exactly 1 player per side"
                )
            }

            let player1 = sideAPlayers[0]
            let player2 = sideBPlayers[0]

            let matchup = MatchupSelection(
                teamSize: 1,
                mode: .players(
                    sideA: [player1.id],
                    sideB: [player2.id]
                )
            )
            return (rules, matchup)
        } else {
            if let team1 = selectedTeam1, let team2 = selectedTeam2 {
                let matchup = MatchupSelection(
                    teamSize: gameType == .custom ? max(selectedTeamSizeA, selectedTeamSizeB) : selectedTeamSize,
                    mode: .teams(team1Id: team1.id, team2Id: team2.id)
                )
                return (rules, matchup)
            } else {
                let sideAPlayerIds: [UUID]
                let sideBPlayerIds: [UUID]

                if let team1 = selectedTeam1 {
                    sideAPlayerIds = team1.players.map { $0.id }
                } else {
                    guard sideAPlayers.count == (gameType == .custom ? selectedTeamSizeA : 2) else {
                        throw GameRulesError.invalidConfiguration(
                            gameType == .custom ? "Please select \(selectedTeamSizeA) players for the South side" : "Please select 2 players for the first side"
                        )
                    }
                    sideAPlayerIds = sideAPlayers.map { $0.id }
                }

                if let team2 = selectedTeam2 {
                    sideBPlayerIds = team2.players.map { $0.id }
                } else {
                    guard sideBPlayers.count == (gameType == .custom ? selectedTeamSizeB : 2) else {
                        throw GameRulesError.invalidConfiguration(
                            gameType == .custom ? "Please select \(selectedTeamSizeB) players for the North side" : "Please select 2 players for the second side"
                        )
                    }
                    sideBPlayerIds = sideBPlayers.map { $0.id }
                }

                let matchup = MatchupSelection(
                    teamSize: gameType == .custom ? max(selectedTeamSizeA, selectedTeamSizeB) : 2,
                    mode: .players(
                        sideA: sideAPlayerIds,
                        sideB: sideBPlayerIds
                    )
                )
                return (rules, matchup)
            }
        }
    }
}

#Preview {
    let randomType = GameType.allTypes.randomElement() ?? .recreational
    let container = PreviewContainers.roster()
    let (_, liveGameManager) = PreviewContainers.managers(for: container)
    let rosterManager = PreviewContainers.rosterManager(for: container)
    let syncCoordinator = LiveSyncCoordinator(service: NoopSyncService())

    SetupView(gameType: randomType) { _, _, _ in }
        .modelContainer(container)
        .environment(liveGameManager)
        .environment(rosterManager)
        .environment(syncCoordinator)
}

#Preview("Custom Game Type") {
    let container = PreviewContainers.roster()
    let (_, liveGameManager) = PreviewContainers.managers(for: container)
    let rosterManager = PreviewContainers.rosterManager(for: container)
    let syncCoordinator = LiveSyncCoordinator(service: NoopSyncService())

    SetupView(gameType: .custom) { _, _, _ in }
        .modelContainer(container)
        .environment(liveGameManager)
        .environment(rosterManager)
        .environment(syncCoordinator)
}

#Preview("Cutthroat Game Type") {
    let container = PreviewContainers.roster()
    let (_, liveGameManager) = PreviewContainers.managers(for: container)
    let rosterManager = PreviewContainers.rosterManager(for: container)
    let syncCoordinator = LiveSyncCoordinator(service: NoopSyncService())

    SetupView(gameType: .cutthroat) { _, _, _ in }
        .modelContainer(container)
        .environment(liveGameManager)
        .environment(rosterManager)
        .environment(syncCoordinator)
}
