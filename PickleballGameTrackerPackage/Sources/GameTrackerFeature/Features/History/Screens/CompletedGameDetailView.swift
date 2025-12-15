import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct CompletedGameDetailView: View {
    @Bindable var game: Game
    @Environment(SwiftDataGameManager.self) private var gameManager
    @Environment(PlayerTeamManager.self) private var rosterManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showNavigationTitle = false
    @State private var showDeleteConfirm = false
    @State private var selectedGuestPlayer: PlayerProfile?
    @State private var isDeleted = false

    private var themeColor: Color {
        game.isArchived ? Color(UIColor.systemGray) : game.gameType.color
    }

    var body: some View {
        Group {
            if isDeleted || game.isDetachedFromContext {
                Color.clear
                    .task { dismiss() }
            } else {
                ScrollView {
                    VStack(
                        alignment: .leading,
                        spacing: DesignSystem.Spacing.lg
                    ) {
                        GeometryReader { geometry in
                            header
                                .onChange(
                                    of: geometry.frame(in: .named("scroll"))
                                        .maxY
                                ) { _, newValue in
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showNavigationTitle = newValue <= -35
                                    }
                                }
                        }
                        .frame(height: 80)

                        VStack(
                            alignment: .leading,
                            spacing: DesignSystem.Spacing.lg
                        ) {
                            scoreSection
                            participantsSection
                            detailsSection
                            if !game.events.isEmpty {
                                eventsSection
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentMargins(
                    .horizontal,
                    DesignSystem.Spacing.lg,
                    for: .scrollContent
                )
                .contentMargins(
                    .top,
                    DesignSystem.Spacing.lg,
                    for: .scrollContent
                )
                .contentMargins(
                    .bottom,
                    DesignSystem.Spacing.lg,
                    for: .scrollContent
                )
                .coordinateSpace(name: "scroll")
                .navigationBarTitleDisplayMode(.inline)
                .viewContainerBackground(color: themeColor)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        NavigationTitleWithIcon(
                            systemImageName: game.gameType.iconName,
                            title: game.gameType.displayName,
                            gradient: themeColor.gradient,
                            show: showNavigationTitle
                        )
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        // Share button
                        ShareLink(
                            item: URL(
                                string:
                                    "https://example.com/g/\(game.id.uuidString)?t=local-stub"
                            )!
                        ) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .tint(themeColor)
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        // Menu button with archive, delete
                        Menu {
                            Button {
                                Log.event(
                                    .actionTapped,
                                    level: .info,
                                    message: game.isArchived
                                        ? "restore" : "archive",
                                    context: .current(gameId: game.id)
                                )
                                Task { await toggleArchive() }
                            } label: {
                                Label(
                                    game.isArchived ? "Restore" : "Archive",
                                    systemImage: game.isArchived
                                        ? "arrow.uturn.left" : "archivebox"
                                )
                            }

                            Button(role: .destructive) {
                                Log.event(
                                    .actionTapped,
                                    level: .warn,
                                    message: "delete",
                                    context: .current(gameId: game.id)
                                )
                                showDeleteConfirm = true
                            } label: {
                                Label("Delete Game", systemImage: "trash")
                            }
                            .tint(.red)
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        .tint(themeColor)
                    }
                }
                .task {
                    Log.event(
                        .viewAppear,
                        level: .info,
                        context: .current(gameId: game.id)
                    )
                }
                .alert("Delete game?", isPresented: $showDeleteConfirm) {
                    Button("Delete", role: .destructive) {
                        Task { await confirmDelete() }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This action cannot be undone.")
                }
                .sheet(item: $selectedGuestPlayer) { guestPlayer in
                    IdentityEditorView(identity: .player(guestPlayer))
                }
            }
        }
        .onChange(of: game.isDetachedFromContext) { _, detached in
            if detached {
                isDeleted = true
            }
        }
    }

    private func toggleArchive() async {
        do {
            if game.isArchived {
                try await gameManager.restoreGame(game)
            } else {
                try await gameManager.archiveGame(game)
            }
        } catch {
            Log.error(
                error,
                event: .saveFailed,
                context: .current(gameId: game.id),
                metadata: ["phase": "toggleArchive"]
            )
        }
    }

    private func confirmDelete() async {
        // Defer actual deletion to HistoryView to avoid fallback flashes during navigation pop.
        await MainActor.run {
            HistoryDeletionRequestBus.requestDelete(gameId: game.id)
            isDeleted = true
        }
    }

    private var header: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: game.gameType.iconName)
                .font(.system(size: 40, weight: .medium))
                .foregroundStyle(themeColor.gradient)
                .shadow(color: themeColor.opacity(0.3), radius: 6, x: 0, y: 3)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(game.gameType.displayName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text(game.formattedDate)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var scoreSection: some View {
        Group {
            if game.layoutStyle == .players {
                if game.gameType == .cutthroat {
                    let participantRows = game.participantRows(context: modelContext)
                    if participantRows.count <= 2 {
                        HStack(spacing: DesignSystem.Spacing.md) {
                            ForEach(participantRows, id: \.id) { row in
                                let player = row.player
                                CompletedGameScoreDisplay(
                                    score: game.playerScore(for: player),
                                    label: player.name,
                                    color: player.accentColor,
                                    size: .medium,
                                    isWinner: false
                                )
                            }
                        }
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHGrid(
                                rows: [
                                    GridItem(
                                        .flexible(),
                                        spacing: DesignSystem.Spacing.md
                                    ),
                                    GridItem(
                                        .flexible(),
                                        spacing: DesignSystem.Spacing.md
                                    ),
                                ],
                                alignment: .top,
                                spacing: DesignSystem.Spacing.md
                            ) {
                                ForEach(participantRows, id: \.id) { row in
                                    let player = row.player
                                    CompletedGameScoreDisplay(
                                        score: game.playerScore(for: player),
                                        label: player.name,
                                        color: player.accentColor,
                                        size: .medium,
                                        isWinner: false
                                    )
                                    .containerRelativeFrame(.horizontal) {
                                        length,
                                        _ in
                                        let spacing = participantRows.count > 4 
                                            ? DesignSystem.Spacing.xl 
                                            : DesignSystem.Spacing.md
                                        return (length - spacing) / 2
                                    }
                                }
                            }
                            .scrollTargetLayout()
                        }
                        .scrollTargetBehavior(.viewAligned)
                        .scrollClipDisabled()
                    }
                } else {
                    VStack(
                        alignment: .leading,
                        spacing: DesignSystem.Spacing.md
                    ) {
                        ForEach(
                            game.participantRows(context: modelContext),
                            id: \.id
                        ) { row in
                            let player = row.player
                            CompletedGameScoreDisplay(
                                score: game.playerScore(for: player),
                                label: player.name,
                                color: player.accentColor,
                                size: .medium,
                                isWinner: false
                            )
                        }
                    }
                }
            } else {
                HStack(spacing: DesignSystem.Spacing.lg) {
                    CompletedGameScoreDisplay(
                        score: game.score1,
                        label: game.teamsWithLabels(context: modelContext)[0]
                            .teamName,
                        color: game.teamTintColor(
                            for: 1,
                            context: modelContext
                        ),
                        size: .large,
                        isWinner: (game.score1 > game.score2)
                    )
                    CompletedGameScoreDisplay(
                        score: game.score2,
                        label: game.teamsWithLabels(context: modelContext)[1]
                            .teamName,
                        color: game.teamTintColor(
                            for: 2,
                            context: modelContext
                        ),
                        size: .large,
                        isWinner: (game.score2 > game.score1)
                    )
                }
            }
        }
    }

    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Participants")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            VStack(spacing: DesignSystem.Spacing.md) {
                if game.layoutStyle == .players {
                    if game.gameType == .cutthroat {
                        let participantRows = game.participantRows(context: modelContext)
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHGrid(
                                rows: [
                                    GridItem(
                                        .flexible(),
                                        spacing: DesignSystem.Spacing.md
                                    ),
                                    GridItem(
                                        .flexible(),
                                        spacing: DesignSystem.Spacing.md
                                    ),
                                ],
                                alignment: .top,
                                spacing: DesignSystem.Spacing.md
                            ) {
                                ForEach(participantRows, id: \.id) { row in
                                    let player = row.player
                                    Group {
                                        if player.isGuest {
                                            Button {
                                                do {
                                                    try rosterManager
                                                        .convertGuestToPlayer(
                                                            player
                                                        )
                                                    selectedGuestPlayer = player
                                                } catch {
                                                    Log.error(
                                                        error,
                                                        event: .saveFailed,
                                                        context: .current(
                                                            gameId: game.id
                                                        ),
                                                        metadata: [
                                                            "phase":
                                                                "convertGuest.playersList"
                                                        ]
                                                    )
                                                }
                                            } label: {
                                                HStack(
                                                    spacing: DesignSystem
                                                        .Spacing.sm
                                                ) {
                                                    IdentityCard(
                                                        identity: .player(
                                                            player,
                                                            teamCount: nil
                                                        )
                                                    )
                                                    Image(
                                                        systemName:
                                                            "person.crop.circle.badge.plus"
                                                    )
                                                    .font(
                                                        .system(
                                                            size: 24,
                                                            weight: .medium
                                                        )
                                                    )
                                                    .foregroundStyle(themeColor)
                                                    .padding(
                                                        .trailing,
                                                        DesignSystem.Spacing.sm
                                                    )
                                                }
                                                .padding(
                                                    DesignSystem.Spacing.md
                                                )
                                                .glassEffect(
                                                    .regular.tint(
                                                        Color(
                                                            UIColor
                                                                .secondarySystemFill
                                                        ).opacity(0.5)
                                                    ),
                                                    in: RoundedRectangle(
                                                        cornerRadius:
                                                            DesignSystem
                                                            .CornerRadius.xl
                                                    )
                                                )
                                            }
                                            .buttonStyle(.plain)
                                        } else {
                                            NavigationLink {
                                                IdentityDetailView(
                                                    identity: .player(
                                                        player,
                                                        teamCount: nil
                                                    )
                                                )
                                            } label: {
                                                IdentityCard(
                                                    identity: .player(
                                                        player,
                                                        teamCount: nil
                                                    )
                                                )
                                                .padding(
                                                    DesignSystem.Spacing.md
                                                )
                                                .glassEffect(
                                                    .regular.tint(
                                                        Color(
                                                            UIColor
                                                                .secondarySystemFill
                                                        ).opacity(0.5)
                                                    ),
                                                    in: RoundedRectangle(
                                                        cornerRadius:
                                                            DesignSystem
                                                            .CornerRadius.xl
                                                    )
                                                )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .containerRelativeFrame(.horizontal) {
                                        length,
                                        _ in
                                        let spacing = participantRows.count > 2 
                                            ? DesignSystem.Spacing.xl 
                                            : 0
                                        return length - spacing
                                    }
                                }
                            }
                            .scrollTargetLayout()
                        }
                        .scrollTargetBehavior(.viewAligned)
                        .scrollClipDisabled()
                    } else {
                        ForEach(
                            game.participantRows(context: modelContext),
                            id: \.id
                        ) { row in
                            let player = row.player
                            if player.isGuest {
                                Button {
                                    do {
                                        try rosterManager.convertGuestToPlayer(
                                            player
                                        )
                                        selectedGuestPlayer = player
                                    } catch {
                                        Log.error(
                                            error,
                                            event: .saveFailed,
                                            context: .current(gameId: game.id),
                                            metadata: [
                                                "phase":
                                                    "convertGuest.playersList"
                                            ]
                                        )
                                    }
                                } label: {
                                    HStack(spacing: DesignSystem.Spacing.sm) {
                                        IdentityCard(
                                            identity: .player(
                                                player,
                                                teamCount: nil
                                            )
                                        )
                                        Image(
                                            systemName:
                                                "person.crop.circle.badge.plus"
                                        )
                                        .font(
                                            .system(size: 24, weight: .medium)
                                        )
                                        .foregroundStyle(themeColor)
                                        .padding(
                                            .trailing,
                                            DesignSystem.Spacing.sm
                                        )
                                    }
                                    .padding(DesignSystem.Spacing.md)
                                    .glassEffect(
                                        .regular.tint(
                                            Color(UIColor.secondarySystemFill)
                                                .opacity(0.5)
                                        ),
                                        in: RoundedRectangle(
                                            cornerRadius: DesignSystem
                                                .CornerRadius.xl
                                        )
                                    )
                                }
                                .buttonStyle(.plain)
                            } else {
                                NavigationLink {
                                    IdentityDetailView(
                                        identity: .player(
                                            player,
                                            teamCount: nil
                                        )
                                    )
                                } label: {
                                    IdentityCard(
                                        identity: .player(
                                            player,
                                            teamCount: nil
                                        )
                                    )
                                    .padding(DesignSystem.Spacing.md)
                                    .glassEffect(
                                        .regular.tint(
                                            Color(UIColor.secondarySystemFill)
                                                .opacity(0.5)
                                        ),
                                        in: RoundedRectangle(
                                            cornerRadius: DesignSystem
                                                .CornerRadius.xl
                                        )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                } else {
                    switch game.participantMode {
                    case .players:
                        if let side1Players = game.resolveSide1Players(
                            context: modelContext
                        ),
                            let side2Players = game.resolveSide2Players(
                                context: modelContext
                            )
                        {
                            ForEach(side1Players) { player in
                                if player.isGuest {
                                    Button {
                                        do {
                                            try rosterManager
                                                .convertGuestToPlayer(player)
                                            selectedGuestPlayer = player
                                        } catch {
                                            Log.error(
                                                error,
                                                event: .saveFailed,
                                                context: .current(
                                                    gameId: game.id
                                                ),
                                                metadata: [
                                                    "phase":
                                                        "convertGuest.side1"
                                                ]
                                            )
                                        }
                                    } label: {
                                        HStack(spacing: DesignSystem.Spacing.sm)
                                        {
                                            IdentityCard(
                                                identity: .player(
                                                    player,
                                                    teamCount: nil
                                                )
                                            )
                                            Image(
                                                systemName:
                                                    "person.crop.circle.badge.plus"
                                            )
                                            .font(
                                                .system(
                                                    size: 24,
                                                    weight: .medium
                                                )
                                            )
                                            .foregroundStyle(themeColor)
                                            .padding(
                                                .trailing,
                                                DesignSystem.Spacing.sm
                                            )
                                        }
                                        .padding(DesignSystem.Spacing.md)
                                        .glassEffect(
                                            .regular.tint(
                                                Color(
                                                    UIColor.secondarySystemFill
                                                ).opacity(0.5)
                                            ),
                                            in: RoundedRectangle(
                                                cornerRadius: DesignSystem
                                                    .CornerRadius.xl
                                            )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    NavigationLink {
                                        IdentityDetailView(
                                            identity: .player(
                                                player,
                                                teamCount: nil
                                            )
                                        )
                                    } label: {
                                        IdentityCard(
                                            identity: .player(
                                                player,
                                                teamCount: nil
                                            )
                                        )
                                        .padding(DesignSystem.Spacing.md)
                                        .glassEffect(
                                            .regular.tint(
                                                Color(
                                                    UIColor.secondarySystemFill
                                                ).opacity(0.5)
                                            ),
                                            in: RoundedRectangle(
                                                cornerRadius: DesignSystem
                                                    .CornerRadius.xl
                                            )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            ForEach(side2Players) { player in
                                if player.isGuest {
                                    Button {
                                        do {
                                            try rosterManager
                                                .convertGuestToPlayer(player)
                                            selectedGuestPlayer = player
                                        } catch {
                                            Log.error(
                                                error,
                                                event: .saveFailed,
                                                context: .current(
                                                    gameId: game.id
                                                ),
                                                metadata: [
                                                    "phase":
                                                        "convertGuest.side2"
                                                ]
                                            )
                                        }
                                    } label: {
                                        HStack(spacing: DesignSystem.Spacing.sm)
                                        {
                                            IdentityCard(
                                                identity: .player(
                                                    player,
                                                    teamCount: nil
                                                )
                                            )
                                            Image(
                                                systemName:
                                                    "person.crop.circle.badge.plus"
                                            )
                                            .font(
                                                .system(
                                                    size: 24,
                                                    weight: .medium
                                                )
                                            )
                                            .foregroundStyle(themeColor)
                                            .padding(
                                                .trailing,
                                                DesignSystem.Spacing.sm
                                            )
                                        }
                                        .padding(DesignSystem.Spacing.md)
                                        .glassEffect(
                                            .regular.tint(
                                                Color(
                                                    UIColor.secondarySystemFill
                                                ).opacity(0.5)
                                            ),
                                            in: RoundedRectangle(
                                                cornerRadius: DesignSystem
                                                    .CornerRadius.xl
                                            )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    NavigationLink {
                                        IdentityDetailView(
                                            identity: .player(
                                                player,
                                                teamCount: nil
                                            )
                                        )
                                    } label: {
                                        IdentityCard(
                                            identity: .player(
                                                player,
                                                teamCount: nil
                                            )
                                        )
                                        .padding(DesignSystem.Spacing.md)
                                        .glassEffect(
                                            .regular.tint(
                                                Color(
                                                    UIColor.secondarySystemFill
                                                ).opacity(0.5)
                                            ),
                                            in: RoundedRectangle(
                                                cornerRadius: DesignSystem
                                                    .CornerRadius.xl
                                            )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    case .teams:
                        if let team1 = game.resolveSide1Team(
                            context: modelContext
                        ),
                            let team2 = game.resolveSide2Team(
                                context: modelContext
                            )
                        {
                            NavigationLink {
                                IdentityDetailView(identity: .team(team1))
                            } label: {
                                IdentityCard(identity: .team(team1))
                                    .padding(DesignSystem.Spacing.md)
                                    .glassEffect(
                                        .regular.tint(
                                            Color(UIColor.secondarySystemFill)
                                                .opacity(0.5)
                                        ),
                                        in: RoundedRectangle(
                                            cornerRadius: DesignSystem
                                                .CornerRadius.xl
                                        )
                                    )
                            }
                            .buttonStyle(.plain)

                            NavigationLink {
                                IdentityDetailView(identity: .team(team2))
                            } label: {
                                IdentityCard(identity: .team(team2))
                                    .padding(DesignSystem.Spacing.md)
                                    .glassEffect(
                                        .regular.tint(
                                            Color(UIColor.secondarySystemFill)
                                                .opacity(0.5)
                                        ),
                                        in: RoundedRectangle(
                                            cornerRadius: DesignSystem
                                                .CornerRadius.xl
                                        )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Game Details")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            VStack(spacing: DesignSystem.Spacing.md) {
                HStack(spacing: DesignSystem.Spacing.md) {
                    StatCard(
                        symbolName: "clock",
                        title: "Duration",
                        value: game.formattedDuration ?? "—",
                        themeColor: themeColor
                    )
                    StatCard(
                        symbolName: "arrow.triangle.2.circlepath",
                        title: "Total Rallies",
                        value: "\(game.totalRallies)",
                        themeColor: themeColor
                    )
                }

                HStack(spacing: DesignSystem.Spacing.md) {
                    StatCard(
                        symbolName: "flag",
                        title: "Playing To",
                        value:
                            "\(game.winningScore)\(game.winByTwo ? " +2" : "")",
                        themeColor: themeColor
                    )
                    StatCard(
                        symbolName: "figure.pickleball",
                        title: "Final Server",
                        value: game.currentServingPlayerShortLabel,
                        themeColor: themeColor
                    )
                }

                HStack(spacing: DesignSystem.Spacing.md) {
                    StatCard(
                        symbolName: "arrow.left.arrow.right",
                        title: "Final Side",
                        value: game.sideOfCourt.displayName,
                        themeColor: themeColor
                    )
                    StatCard(
                        symbolName: "checkerboard.rectangle",
                        title: "Rules",
                        value: rulesDescription,
                        themeColor: themeColor
                    )
                }
            }
        }
    }

    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Top Events")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

            if topEvents.isEmpty {
                Text("No events logged")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, DesignSystem.Spacing.sm)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: DesignSystem.Spacing.md),
                        GridItem(.flexible(), spacing: DesignSystem.Spacing.md),
                    ],
                    alignment: .leading,
                    spacing: DesignSystem.Spacing.md
                ) {
                    ForEach(topEvents, id: \.type) { eventInfo in
                        StatCard(
                            symbolName: eventInfo.type.iconName,
                            title: eventInfo.type.displayName,
                            value: "\(eventInfo.count)",
                            themeColor: themeColor
                        )
                }
                }
            }
        }
    }

    private struct EventCount: Identifiable {
        let type: GameEventType
        let count: Int

        var id: GameEventType { type }
    }

    private var topEvents: [EventCount] {
        let impactfulTypes: [GameEventType] = [
            .playerScored,
            .serviceFault,
            .ballOutOfBounds,
            .ballHitNet,
            .kitchenViolation,
            .doubleBounce,
            .ballInKitchenOnServe,
        ]

        let eventCounts = impactfulTypes.compactMap {
            eventType -> EventCount? in
            let count = game.eventsOfType(eventType).count
            guard count > 0 else { return nil }
            return EventCount(type: eventType, count: count)
        }

        return
            eventCounts
            .sorted { $0.count > $1.count }
            .prefix(4)
            .map { $0 }
    }

    private var rulesDescription: String {
        var rules: [String] = []
        if game.kitchenRule { rules.append("K") }
        if game.doubleBounceRule { rules.append("DB") }
        return rules.isEmpty ? "Standard" : rules.joined(separator: ", ")
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Actions")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            VStack(spacing: DesignSystem.Spacing.sm) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ShareLink(
                        item: URL(
                            string:
                                "https://example.com/g/\(game.id.uuidString)?t=local-stub"
                        )!
                    ) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .controlSize(.large)
                    .buttonStyle(.bordered)

                    Button {
                        Log.event(
                            .actionTapped,
                            level: .info,
                            message: game.isArchived ? "restore" : "archive",
                            context: .current(gameId: game.id)
                        )
                        Task { await toggleArchive() }
                    } label: {
                        Label(
                            game.isArchived ? "Restore" : "Archive",
                            systemImage: game.isArchived
                                ? "arrow.uturn.left" : "archivebox"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .controlSize(.large)
                    .buttonStyle(.bordered)
                }

                Button(role: .destructive) {
                    Log.event(
                        .actionTapped,
                        level: .warn,
                        message: "delete",
                        context: .current(gameId: game.id)
                    )
                    showDeleteConfirm = true
                } label: {
                    Label("Delete Game", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .buttonStyle(.bordered)
            }
        }
    }

}

// MARK: - Local Components

struct CompletedGameScoreDisplay: View {
    let score: Int
    let label: String
    let color: Color
    let size: Size
    let isWinner: Bool

    enum Size {
        case small, medium, large
    }

    init(
        score: Int,
        label: String,
        color: Color,
        size: Size = .medium,
        isWinner: Bool = false
    ) {
        self.score = score
        self.label = label
        self.color = color
        self.size = size
        self.isWinner = isWinner
    }

    private var scoreFontSize: Font {
        switch size {
        case .small: return .title
        case .medium: return .largeTitle
        case .large: return .system(size: 48, weight: .bold, design: .rounded)
        }
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Text(label)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text("\(score)")
                .font(scoreFontSize)
                .fontWeight(.bold)
                .fontDesign(.rounded)
                .foregroundStyle(color)
                .opacity(isWinner ? 1.0 : 0.6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(
            size == .small ? DesignSystem.Spacing.sm : DesignSystem.Spacing.md
        )
        .glassEffect(
            .regular.tint(color.opacity(0.08)),
            in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xxl)
        )
    }
}

#Preview {
    let container = PreviewContainers.history()
    let (gameManager, _) = PreviewContainers.managers(for: container)
    let rosterManager = PreviewContainers.rosterManager(for: container)
    let game = PreviewContainers.exampleGame(
        in: container,
        desiredState: .completed
    )

    GameEventFactory.populateGameWithEvents(game, eventCount: 5)

    return NavigationStack {
        CompletedGameDetailView(game: game)
    }
    .modelContainer(container)
    .environment(gameManager)
    .environment(rosterManager)
}

#Preview("Cutthroat Game") {
    let container = PreviewContainers.history()
    let (gameManager, _) = PreviewContainers.managers(for: container)
    let rosterManager = PreviewContainers.rosterManager(for: container)
    let game = PreviewContainers.exampleGame(
        in: container,
        type: .cutthroat,
        desiredState: .completed
    )

    GameEventFactory.populateGameWithEvents(game, eventCount: 5)

    return NavigationStack {
        CompletedGameDetailView(game: game)
    }
    .modelContainer(container)
    .environment(gameManager)
    .environment(rosterManager)
}
