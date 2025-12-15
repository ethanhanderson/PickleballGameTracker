import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct GroupPlaySessionView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  @Environment(LiveGameStateManager.self) private var liveGameStateManager
  @Environment(PersonalizationEngine.self) private var personalizationEngine
  
  @State private var sessionManager: GroupPlaySessionManager?
  @Bindable var session: GroupPlaySession
  
  @State private var activeGame: Game?
  @State private var showingLive = false
  @State private var showingStandings = false
  @State private var errorMessage = ""
  @State private var showingError = false
  
  init(session: GroupPlaySession) {
    self._session = Bindable(wrappedValue: session)
    // Manager is initialized later in .task with the live modelContext
    self._sessionManager = State(initialValue: nil)
  }
  
  var body: some View {
    NavigationStack {
      List {
        Section("Summary") {
          HStack {
            Label(session.format == .randomPairings ? "Random Pairings" : "Tournament", systemImage: "calendar.badge.clock")
            Spacer()
            Text(session.statusRaw.capitalized)
              .foregroundStyle(.secondary)
          }
          HStack {
            Label(playModeTitle, systemImage: "person.2.fill")
            Spacer()
            Text("\(session.schedule.filter { $0.status == .completed }.count) of \(session.schedule.count) matches")
              .foregroundStyle(.secondary)
          }
        }
        
        Section("Upcoming") {
          if let sm = sessionManager, let match = sm.nextMatch(in: session), match.status == .scheduled {
            matchRow(match)
          } else {
            Text("No upcoming matches")
              .foregroundStyle(.secondary)
          }
        }
        
        Section("All Matches") {
          ForEach(session.schedule, id: \.id) { m in
            matchRow(m)
          }
        }
      }
      .navigationTitle("Group Session")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close") { dismiss() }
        }
        ToolbarItemGroup(placement: .confirmationAction) {
          Button("Standings") { showingStandings = true }
            .buttonStyle(.plain)
          Button(action: startNextMatch) {
            Label("Start Match", systemImage: "play.fill")
          }
          .buttonStyle(.glassProminent)
          .tint(GameType.groupPlay.color)
          .disabled({
            guard let sm = sessionManager else { return true }
            return sm.nextMatch(in: session) == nil
          }())
        }
      }
      .sheet(isPresented: $showingLive) {
        if let game = activeGame {
          NavigationStack {
            LiveView(game: game) { 
              // Called when Game UI dismisses after completion
              handleLiveDismiss(for: game)
            }
          }
          .environment(personalizationEngine)
        }
      }
      .sheet(isPresented: $showingStandings) {
        GroupStandingsSheetView(session: session)
      }
      .alert("Error", isPresented: $showingError) {
        Button("OK", role: .cancel) { showingError = false }
      } message: {
        Text(errorMessage)
      }
      .task {
        // Initialize real manager with current context
        let mgr = GroupPlaySessionManager(modelContext: modelContext)
        mgr.setActiveSession(session)
        sessionManager = mgr
      }
    }
  }
  
  // MARK: - Rows
  
  @ViewBuilder
  private func matchRow(_ match: ScheduledMatch) -> some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text(matchTitle(match))
          .font(.body)
        Text(match.status.rawValue.capitalized)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
      if match.status == .scheduled {
        Image(systemName: "clock")
          .foregroundStyle(.secondary)
      } else if match.status == .inProgress {
        Image(systemName: "play.circle.fill")
          .foregroundStyle(.green)
      } else {
        Image(systemName: "checkmark.circle.fill")
          .foregroundStyle(.green)
      }
    }
  }
  
  private var playModeTitle: String {
    switch session.playMode {
    case .singles: return "Singles"
    case .doubles: return "Doubles"
    case .twoVOne: return "2v1 / 1v2"
    }
  }
  
  private func matchTitle(_ match: ScheduledMatch) -> String {
    switch match.participantMode {
    case .players:
      let a = match.side1PlayerIds.count
      let b = match.side2PlayerIds.count
      return "\(a) vs \(b) (players)"
    case .teams:
      return "Team vs Team"
    }
  }
  
  // MARK: - Actions
  
  private func startNextMatch() {
    guard let sm = sessionManager else { return }
    guard let match = sm.nextMatch(in: session) else { return }
    guard let config = sm.buildStartConfiguration(for: match, rules: nil) else {
      errorMessage = "Unable to build start configuration for the next match."
      showingError = true
      return
    }
    Task { @MainActor in
      do {
        let game = try await liveGameStateManager.startNewGame(with: config)
        activeGame = game
        // Personalization start is now deferred to first meaningful activity or 5-minute threshold
        sm.markMatchInProgress(match, gameId: game.id)
        showingLive = true
      } catch {
        errorMessage = "Failed to start match."
        showingError = true
      }
    }
  }
  
  private func handleLiveDismiss(for game: Game) {
    // If the game completed, record result against the linked match
    if game.isCompleted {
      if let match = session.schedule.first(where: { $0.linkedGameId == game.id }),
         let sm = sessionManager {
        sm.recordResult(from: game, for: match)
      }
    }
    activeGame = nil
  }
}


