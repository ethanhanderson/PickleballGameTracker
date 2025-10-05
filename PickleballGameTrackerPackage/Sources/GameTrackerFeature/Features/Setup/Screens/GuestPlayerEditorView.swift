import GameTrackerCore
import SwiftUI

@MainActor
struct GuestPlayerEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PlayerTeamManager.self) private var manager

    @State private var name: String = ""
    @State private var showValidationError: Bool = false
    @FocusState private var nameFocused: Bool

    let gameType: GameType
    let onGuestCreated: ((PlayerProfile) -> Void)?

    init(gameType: GameType, onGuestCreated: ((PlayerProfile) -> Void)? = nil) {
        self.gameType = gameType
        self.onGuestCreated = onGuestCreated
    }

    private var saveDisabled: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .focused($nameFocused)
                    if showValidationError && saveDisabled {
                        Text("Name is required").foregroundStyle(.red)
                    }
                } header: {
                    Text("Guest Player Details")
                } footer: {
                    Text("Guest players are temporary and can be added to your roster after the game.")
                }
            }
            .navigationTitle("New Guest")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: onCancel) {
                        Label("Cancel", systemImage: "xmark")
                    }
                    .accessibilityLabel("Cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: onSave) {
                        Label("Add Guest", systemImage: "checkmark")
                    }
                    .buttonStyle(.glassProminent)
                    .tint(gameType.color)
                    .accessibilityLabel("Add Guest")
                    .disabled(saveDisabled)
                }
            }
            .onAppear {
                nameFocused = true
            }
        }
    }

    func onCancel() {
        Log.event(.actionTapped, level: .info, message: "guest.create.cancel")
        dismiss()
    }

    func onSave() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            showValidationError = true
            return
        }

        do {
            Log.event(
                .saveStarted,
                level: .info,
                message: "guest.create.start"
            )
            let guest = try manager.createGuestPlayer(name: trimmed)
            Log.event(
                .saveSucceeded,
                level: .info,
                message: "guest.create.succeeded",
                metadata: ["guestId": guest.id.uuidString]
            )
            onGuestCreated?(guest)
            dismiss()
        } catch {
            Log.event(
                .saveFailed,
                level: .warn,
                message: "guest.create.failed",
                metadata: ["error": String(describing: error)]
            )
            showValidationError = true
        }
    }
}

#Preview {
    let container = PreviewContainers.minimal()
    let rosterManager = PreviewContainers.rosterManager(for: container)

    NavigationStack {
        GuestPlayerEditorView(gameType: .recreational)
    }
    .modelContainer(container)
    .environment(rosterManager)
}
