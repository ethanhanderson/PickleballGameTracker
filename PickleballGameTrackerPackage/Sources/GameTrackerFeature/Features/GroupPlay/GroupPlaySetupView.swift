import GameTrackerCore
import SwiftData
import SwiftUI

@MainActor
struct GroupPlaySetupView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  @Environment(PlayerTeamManager.self) private var rosterManager
  
  // Output
  let onCreate: (GroupPlaySession) -> Void
  
  // Queries
  @Query(filter: #Predicate<PlayerProfile> { !$0.isArchived && !$0.isGuest })
  private var allPlayers: [PlayerProfile]
  @Query private var allTeams: [TeamProfile]
  
  // Selections
  @State private var format: GroupPlayFormat = .randomPairings
  @State private var playMode: GroupPlayPlayMode = .doubles
  @State private var partnerRotation: Bool = true
  @State private var teamRoundRobin: Bool = false
  @State private var isSeeded: Bool = false
  
  @State private var selectedPlayers: Set<UUID> = []
  @State private var selectedTeams: Set<UUID> = []
  
  @State private var isCreating = false
  @State private var showPlayerSheet = false
  @State private var showTeamSheet = false
  @State private var errorMessage = ""
  @State private var showingError = false
  
  private var selectionColor: Color { GameType.groupPlay.color }
  
  private var activePlayers: [PlayerProfile] {
    allPlayers.sorted { $0.name < $1.name }
  }
  
  private var activeTeams: [TeamProfile] {
    allTeams.sorted { $0.name < $1.name }
  }
  
  private var canCreate: Bool {
    switch format {
    case .randomPairings:
      return selectedPlayers.count >= 2 || selectedTeams.count >= 2
    case .tournamentBracket:
      return selectedPlayers.count >= 2 || selectedTeams.count >= 2
    }
  }
  
  var body: some View {
    NavigationStack {
      Form {
        Section("Format") {
          Picker("Match Format", selection: $format) {
            Text("Random Pairings").tag(GroupPlayFormat.randomPairings)
            Text("Tournament").tag(GroupPlayFormat.tournamentBracket)
          }
          .pickerStyle(.segmented)
          .tint(selectionColor)
          
          Picker("Play Mode", selection: $playMode) {
            Text("Singles").tag(GroupPlayPlayMode.singles)
            Text("Doubles").tag(GroupPlayPlayMode.doubles)
            Text("2v1 / 1v2").tag(GroupPlayPlayMode.twoVOne)
          }
          .pickerStyle(.segmented)
          .tint(selectionColor)
          
          if format == .randomPairings {
            Toggle("Partner Rotation", isOn: $partnerRotation)
              .tint(selectionColor)
            Toggle("Team Round Robin", isOn: $teamRoundRobin)
              .tint(selectionColor)
          } else {
            Toggle("Seeded Bracket", isOn: $isSeeded)
              .tint(selectionColor)
          }
        }
        
        if playMode == .doubles, teamRoundRobin {
          TeamPickerSectionView(
            teams: activeTeams,
            selectedTeamIds: selectedTeams,
            isEntityDisabled: { _ in false },
            selectionColor: selectionColor,
            onCreateNew: { showTeamSheet = true },
            onToggleTeam: { team in
              if selectedTeams.contains(team.id) {
                selectedTeams.remove(team.id)
              } else {
                selectedTeams.insert(team.id)
              }
            }
          )
        }
        
        PlayerPickerSectionView(
          players: activePlayers,
          selectedPlayerIds: selectedPlayers,
          selectionNumbers: [:],
          selectionColor: selectionColor,
          isEntityDisabled: { _ in false },
          onCreateNew: { showPlayerSheet = true },
          onTogglePlayer: { player in
            if selectedPlayers.contains(player.id) {
              selectedPlayers.remove(player.id)
            } else {
              selectedPlayers.insert(player.id)
            }
          }
        )
      }
      .navigationTitle("Group Session Setup")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button(action: createSession) {
            if isCreating {
              ProgressView().tint(selectionColor)
            } else {
              Label("Create Session", systemImage: "play")
            }
          }
          .buttonStyle(.glassProminent)
          .tint(selectionColor)
          .disabled(!canCreate || isCreating)
        }
      }
      .alert("Unable to Create Session", isPresented: $showingError) {
        Button("OK", role: .cancel) { showingError = false }
      } message: {
        Text(errorMessage)
      }
    }
  }
  
  private func createSession() {
    isCreating = true
    defer { isCreating = false }
    
    let roster = Array(selectedPlayers)
    let fixedTeamIds = Array(selectedTeams)
    
    // Basic validation
    if roster.count < 2 && fixedTeamIds.count < 2 {
      errorMessage = "Select at least two participants."
      showingError = true
      return
    }
    
    let manager = GroupPlaySessionManager(modelContext: modelContext)
    let teamsForRoundRobin = teamRoundRobin ? fixedTeamIds : []
    let session = manager.createSession(
      rosterPlayerIds: roster,
      format: format,
      playMode: playMode,
      isPartnerRotation: partnerRotation,
      isTeamRoundRobin: teamRoundRobin,
      isSeeded: isSeeded,
      fixedTeamIds: fixedTeamIds,
      teamsForRoundRobin: teamsForRoundRobin
    )
    onCreate(session)
    dismiss()
  }
}


