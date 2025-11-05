import GameTrackerCore
import SwiftUI

@MainActor
public struct PersistenceResetPromptView: View {
  @Environment(LiveGameStateManager.self) private var activeGameStateManager
  @Environment(\.dismiss) private var dismiss

  @State private var isResetting: Bool = false
  @State private var errorMessage: String? = nil
  @State private var didCompleteReset: Bool = false

  public init() {}

  public var body: some View {
    VStack(spacing: 16) {
      Image(systemName: didCompleteReset ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
        .font(.system(size: 48, weight: .medium))
        .foregroundStyle(didCompleteReset ? .green : .red)
        .symbolRenderingMode(.hierarchical)

      VStack(spacing: 8) {
        Text(didCompleteReset ? "Data Reset Complete" : "Storage Issue Detected")
          .font(.headline)
          .fontWeight(.semibold)
          .foregroundStyle(.primary)

        Text(descriptionText)
          .font(.body)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
      }

      if let message = errorMessage {
        Text(message)
          .font(.footnote)
          .foregroundStyle(.red)
          .multilineTextAlignment(.center)
      }

      HStack(spacing: 12) {
        Button(action: { dismiss() }) {
          Text(didCompleteReset ? "OK" : "Not Now")
            .font(.callout)
            .fontWeight(.semibold)
            .frame(minHeight: 44)
        }
        .buttonSizing(.flexible)
        .buttonStyle(.bordered)
        .disabled(isResetting)

        Button(action: resetAction) {
          HStack(spacing: 8) {
            if isResetting { ProgressView() }
            Text(didCompleteReset ? "Dismiss" : "Reset Data Now")
              .font(.callout)
              .fontWeight(.semibold)
          }
          .frame(minHeight: 44)
        }
        .buttonSizing(.flexible)
        .buttonStyle(.borderedProminent)
        .tint(.blue)
        .disabled(isResetting)
      }
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 32)
    .presentationDetents([.medium])
    .onAppear {
      Task { await logPromptShown() }
    }
  }

  private var descriptionText: String {
    if didCompleteReset {
      return
        "The app will recreate its data store on next launch. Please relaunch the app to continue."
    } else {
      return
        "We couldn't open your local data store. You can continue in a temporary session, or reset the local data."
    }
  }

  private func resetAction() {
    if didCompleteReset {
      dismiss()
      return
    }
    isResetting = true
    errorMessage = nil

    Task {
      do {
        await MainActor.run {
          activeGameStateManager.clearCurrentGame()
        }
        try SwiftDataContainer.shared.resetStoreFiles()
        await LoggingService.shared.log(
          level: .info,
          event: .saveSucceeded,
          message: "User-initiated persistence reset completed",
          metadata: [:]
        )
        didCompleteReset = true
      } catch {
        await LoggingService.shared.log(
          level: .error,
          event: .saveFailed,
          message: "Persistence reset failed",
          metadata: ["error": String(describing: error)]
        )
        errorMessage =
          (error as? LocalizedError)?.localizedDescription
          ?? "Unable to remove store files."
      }
      isResetting = false
    }
  }

  private func logPromptShown() async {
    await LoggingService.shared.log(
      level: .warn,
      event: .loadFailed,
      message: "Using in-memory fallback container; showing reset prompt",
      metadata: [:]
    )
  }
}
