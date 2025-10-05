//
//  CompletedGameDetailView.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 8/10/25.
//

import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct CompletedGameDetailView: View {
  @Bindable var game: Game
  @Environment(SwiftDataGameManager.self) private var gameManager
  @Environment(\.modelContext) private var modelContext
  @State private var showNavigationTitle = false
  @State private var showDeleteConfirm = false
  @State private var showConversionSheet = false
  @State private var selectedGuestPlayer: PlayerProfile?

  private var themeColor: Color { 
    game.isArchived ? Color(UIColor.systemGray) : game.gameType.color 
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
        GeometryReader { geometry in
          header
            .onChange(of: geometry.frame(in: .named("scroll")).maxY) { _, newValue in
              withAnimation(.easeInOut(duration: 0.2)) {
                showNavigationTitle = newValue <= -35
              }
            }
        }
        .frame(height: 80)

        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
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
    .contentMargins(.horizontal, DesignSystem.Spacing.lg, for: .scrollContent)
    .contentMargins(.top, DesignSystem.Spacing.lg, for: .scrollContent)
    .contentMargins(.bottom, DesignSystem.Spacing.lg, for: .scrollContent)
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
          item: URL(string: "https://example.com/g/\(game.id.uuidString)?t=local-stub")!
        ) {
          Image(systemName: "square.and.arrow.up")
        }
        .tint(themeColor)
      }

      ToolbarItem(placement: .topBarTrailing) {
        // Menu button with stats, archive, delete
        Menu {
          Button {
            Log.event(
              .actionTapped, level: .info, message: "completed → stats",
              context: .current(gameId: game.id))
            DeepLinkBus.post(
              .statistics(gameId: game.id.uuidString, gameTypeId: game.gameType.rawValue))
          } label: {
            Label("View Statistics", systemImage: "chart.bar")
          }

          Button {
            Log.event(
              .actionTapped, level: .info, message: game.isArchived ? "restore" : "archive",
              context: .current(gameId: game.id))
            Task { await toggleArchive() }
          } label: {
            Label(
              game.isArchived ? "Restore" : "Archive",
              systemImage: game.isArchived ? "arrow.uturn.left" : "archivebox"
            )
          }

          Button(role: .destructive) {
            Log.event(
              .actionTapped, level: .warn, message: "delete", context: .current(gameId: game.id))
            Task { await confirmDelete() }
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
    .task { Log.event(.viewAppear, level: .info, context: .current(gameId: game.id)) }
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

  private func toggleArchive() async {
    do {
      if game.isArchived {
        try await gameManager.restoreGame(game)
      } else {
        try await gameManager.archiveGame(game)
      }
    } catch {
      Log.error(
        error, event: .saveFailed, context: .current(gameId: game.id),
        metadata: ["phase": "toggleArchive"]
      )
    }
  }

  private func confirmDelete() async {
    do {
      try await gameManager.deleteGame(game)
    } catch {
      Log.error(
        error, event: .saveFailed, context: .current(gameId: game.id), metadata: ["phase": "delete"]
      )
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
    HStack(spacing: DesignSystem.Spacing.lg) {
      CompletedGameScoreDisplay(
        score: game.score1,
        label: game.teamsWithLabels(context: modelContext)[0].teamName,
        color: .blue,
        size: .large,
        isWinner: (game.score1 > game.score2)
      )
      CompletedGameScoreDisplay(
        score: game.score2,
        label: game.teamsWithLabels(context: modelContext)[1].teamName,
        color: .green,
        size: .large,
        isWinner: (game.score2 > game.score1)
      )
    }
    .frame(height: 120)
  }

  private var participantsSection: some View {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
      Text("Participants")
        .font(.title3)
        .fontWeight(.semibold)
        .foregroundStyle(.primary)

      VStack(spacing: DesignSystem.Spacing.md) {
        switch game.participantMode {
        case .players:
          if let side1Players = game.resolveSide1Players(context: modelContext),
             let side2Players = game.resolveSide2Players(context: modelContext) {
            ForEach(side1Players) { player in
              if player.isGuest {
                Button {
                  selectedGuestPlayer = player
                  showConversionSheet = true
                } label: {
                  HStack(spacing: DesignSystem.Spacing.sm) {
                    IdentityCard(identity: .player(player, teamCount: nil))
                    
                    Image(systemName: "person.crop.circle.badge.plus")
                      .font(.system(size: 24, weight: .medium))
                      .foregroundStyle(themeColor)
                      .padding(.trailing, DesignSystem.Spacing.sm)
                  }
                  .padding(DesignSystem.Spacing.md)
                  .glassEffect(
                    .regular.tint(
                      Color(UIColor.secondarySystemFill).opacity(0.5)
                    ),
                    in: RoundedRectangle(
                      cornerRadius: DesignSystem.CornerRadius.xl
                    )
                  )
                }
                .buttonStyle(.plain)
              } else {
                NavigationLink {
                  IdentityDetailView(identity: .player(player, teamCount: nil))
                } label: {
                  IdentityCard(identity: .player(player, teamCount: nil))
                    .padding(DesignSystem.Spacing.md)
                    .glassEffect(
                      .regular.tint(
                        Color(UIColor.secondarySystemFill).opacity(0.5)
                      ),
                      in: RoundedRectangle(
                        cornerRadius: DesignSystem.CornerRadius.xl
                      )
                    )
                }
                .buttonStyle(.plain)
              }
            }
            ForEach(side2Players) { player in
              if player.isGuest {
                Button {
                  selectedGuestPlayer = player
                  showConversionSheet = true
                } label: {
                  HStack(spacing: DesignSystem.Spacing.sm) {
                    IdentityCard(identity: .player(player, teamCount: nil))
                    
                    Image(systemName: "person.crop.circle.badge.plus")
                      .font(.system(size: 24, weight: .medium))
                      .foregroundStyle(themeColor)
                      .padding(.trailing, DesignSystem.Spacing.sm)
                  }
                  .padding(DesignSystem.Spacing.md)
                  .glassEffect(
                    .regular.tint(
                      Color(UIColor.secondarySystemFill).opacity(0.5)
                    ),
                    in: RoundedRectangle(
                      cornerRadius: DesignSystem.CornerRadius.xl
                    )
                  )
                }
                .buttonStyle(.plain)
              } else {
                NavigationLink {
                  IdentityDetailView(identity: .player(player, teamCount: nil))
                } label: {
                  IdentityCard(identity: .player(player, teamCount: nil))
                    .padding(DesignSystem.Spacing.md)
                    .glassEffect(
                      .regular.tint(
                        Color(UIColor.secondarySystemFill).opacity(0.5)
                      ),
                      in: RoundedRectangle(
                        cornerRadius: DesignSystem.CornerRadius.xl
                      )
                    )
                }
                .buttonStyle(.plain)
              }
            }
          }
        case .teams:
          if let team1 = game.resolveSide1Team(context: modelContext),
             let team2 = game.resolveSide2Team(context: modelContext) {
            NavigationLink {
              IdentityDetailView(identity: .team(team1))
            } label: {
              IdentityCard(identity: .team(team1))
                .padding(DesignSystem.Spacing.md)
                .glassEffect(
                  .regular.tint(
                    Color(UIColor.secondarySystemFill).opacity(0.5)
                  ),
                  in: RoundedRectangle(
                    cornerRadius: DesignSystem.CornerRadius.xl
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
                    Color(UIColor.secondarySystemFill).opacity(0.5)
                  ),
                  in: RoundedRectangle(
                    cornerRadius: DesignSystem.CornerRadius.xl
                  )
                )
            }
            .buttonStyle(.plain)
          }
        case .anonymous:
          // Fallback to simple display for anonymous games
          ForEach(game.teamsWithLabels(context: modelContext)) { teamConfig in
            GameParticipantCard(
              displayName: teamConfig.teamName,
              teamNumber: teamConfig.teamNumber,
              color: teamConfig.teamNumber == 1 ? .blue : .green
            )
            .padding(DesignSystem.Spacing.md)
            .glassEffect(
              .regular.tint(
                Color(UIColor.secondarySystemFill).opacity(0.5)
              ),
              in: RoundedRectangle(
                cornerRadius: DesignSystem.CornerRadius.xl
              )
            )
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
            value: "\(game.winningScore)\(game.winByTwo ? " +2" : "")",
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
      HStack {
        Text("Logged Events")
          .font(.title3)
          .fontWeight(.semibold)
          .foregroundStyle(.primary)
        Spacer()
        Text("\(game.events.count)")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      VStack(spacing: DesignSystem.Spacing.sm) {
        ForEach(game.eventsByTimestamp.prefix(3), id: \.id) { event in
          CompactEventRow(event: event)
        }
        
        if game.events.count > 3 {
          Text("+ \(game.events.count - 3) more events")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.top, DesignSystem.Spacing.xs)
        }
      }
    }
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
        Button {
          Log.event(
            .actionTapped, level: .info, message: "completed → stats",
            context: .current(gameId: game.id))
          DeepLinkBus.post(
            .statistics(gameId: game.id.uuidString, gameTypeId: game.gameType.rawValue))
        } label: {
          Label("View Statistics", systemImage: "chart.bar")
            .frame(maxWidth: .infinity)
        }
        .controlSize(.large)
        .buttonStyle(.borderedProminent)
        .tint(themeColor)

        HStack(spacing: DesignSystem.Spacing.sm) {
          ShareLink(
            item: URL(string: "https://example.com/g/\(game.id.uuidString)?t=local-stub")!
          ) {
            Label("Share", systemImage: "square.and.arrow.up")
              .frame(maxWidth: .infinity)
          }
          .controlSize(.large)
          .buttonStyle(.bordered)

          Button {
            Log.event(
              .actionTapped, level: .info, message: game.isArchived ? "restore" : "archive",
              context: .current(gameId: game.id))
            Task { await toggleArchive() }
          } label: {
            Label(
              game.isArchived ? "Restore" : "Archive",
              systemImage: game.isArchived ? "arrow.uturn.left" : "archivebox"
            )
            .frame(maxWidth: .infinity)
          }
          .controlSize(.large)
          .buttonStyle(.bordered)
        }

        Button(role: .destructive) {
          Log.event(
            .actionTapped, level: .warn, message: "delete", context: .current(gameId: game.id))
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

@MainActor
private struct CompactEventRow: View {
  let event: GameEvent

  var body: some View {
    HStack(spacing: DesignSystem.Spacing.sm) {
      Image(systemName: event.eventType.iconName)
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(.secondary)
        .frame(width: 24, height: 24)

      VStack(alignment: .leading, spacing: 2) {
        Text(event.eventType.displayName)
          .font(.subheadline)
          .fontWeight(.medium)
          .foregroundStyle(.primary)
        
        Text(event.formattedTimestamp)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()
    }
    .padding(DesignSystem.Spacing.sm)
    .background(Color.gray.opacity(0.08))
    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
  }
}

struct CompletedGameScoreDisplay: View {
  let score: Int
  let label: String
  let color: Color
  let size: Size
  let isWinner: Bool

  enum Size {
    case small, medium, large
  }

  init(score: Int, label: String, color: Color, size: Size = .medium, isWinner: Bool = false) {
    self.score = score
    self.label = label
    self.color = color
    self.size = size
    self.isWinner = isWinner
  }

  private var scoreFontSize: Font {
    let effectiveSize = isWinner ? size : smallerSize
    return effectiveSize == .small ? .title2 : effectiveSize == .medium ? .title : .largeTitle
  }

  private var smallerSize: Size {
    switch size {
    case .large: return .medium
    case .medium: return .small
    case .small: return .small
    }
  }

  var body: some View {
    VStack(spacing: DesignSystem.Spacing.xs) {
      Text(label)
        .font(.headline)
        .foregroundStyle(.secondary)
        .opacity(isWinner ? 1.0 : 0.6)

      Text("\(score)")
        .font(scoreFontSize)
        .fontWeight(isWinner ? .bold : .medium)
        .fontDesign(.rounded)
        .foregroundStyle(color)
        .opacity(isWinner ? 1.0 : 0.6)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(size == .small ? DesignSystem.Spacing.sm : DesignSystem.Spacing.md)
    .glassEffect(.regular.tint(color.opacity(0.08)), in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xxl))
  }
}

#Preview {
  let container = PreviewContainers.history()
  let games = try! container.mainContext.fetch(FetchDescriptor<Game>())
  guard let completedGame = games.first(where: { $0.isCompleted }) ?? games.first else {
    return AnyView(
      EmptyStateView(
        icon: "exclamationmark.triangle",
        title: "No Games",
        description: "Preview data unavailable"
      )
      .modelContainer(container)
    )
  }
  
  let (gameManager, _) = PreviewContainers.managers(for: container)

  return AnyView(
    NavigationStack {
      CompletedGameDetailView(game: completedGame)
    }
    .modelContainer(container)
    .environment(gameManager)
  )
}
