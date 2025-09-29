import GameTrackerCore
import SwiftUI

@MainActor
struct MaintenanceView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var gameManager = SwiftDataGameManager()
  @State private var exportStatus: String = ""
  @State private var maintenanceStatus: String = ""

  var body: some View {
    List {
      Section("Backup & Restore") {
        Button("Export Backup") {
          Task {
            do {
              let data = try await gameManager.storage.exportBackup()
              exportStatus = "Exported (\(data.count) bytes)"
            } catch {
              exportStatus = "Export failed: \(error.localizedDescription)"
            }
          }
        }
        if !exportStatus.isEmpty {
          Text(exportStatus).font(.footnote).foregroundStyle(.secondary)
        }

        Button("Import Backup (Merge)") {
          Task {
            do {
              // In a real app, present a document picker. Here we re-import last export as smoke.
              let data = try await gameManager.storage.exportBackup()
              try await gameManager.storage.importBackup(data, mode: .merge)
              exportStatus = "Imported (merge)"
            } catch {
              exportStatus = "Import failed: \(error.localizedDescription)"
            }
          }
        }

        Button("Import Backup (Replace)", role: .destructive) {
          Task {
            do {
              let data = try await gameManager.storage.exportBackup()
              try await gameManager.storage.importBackup(data, mode: .replace)
              exportStatus = "Imported (replace)"
            } catch {
              exportStatus = "Import failed: \(error.localizedDescription)"
            }
          }
        }
      }

      Section("Maintenance") {
        Button("Integrity Sweep") {
          Task {
            do {
              let report = try await gameManager.storage.integritySweep()
              maintenanceStatus =
                "Orphans: \(report.orphanSummariesRemoved), Repaired: \(report.repairedRelationships)"
            } catch {
              maintenanceStatus = "Integrity failed: \(error.localizedDescription)"
            }
          }
        }

        Button("Compact Store") {
          Task {
            do {
              try await gameManager.storage.compactStore()
              maintenanceStatus = "Compaction requested"
            } catch {
              maintenanceStatus = "Compaction failed: \(error.localizedDescription)"
            }
          }
        }

        Button("Purge Archived > 30 days", role: .destructive) {
          Task {
            do {
              let result = try await gameManager.storage.purge(
                PurgeOptions(purgeAllGames: false, purgeArchivedOnly: true, olderThanDays: 30))
              maintenanceStatus = "Purged games: \(result.removedGames)"
            } catch {
              maintenanceStatus = "Purge failed: \(error.localizedDescription)"
            }
          }
        }
        if !maintenanceStatus.isEmpty {
          Text(maintenanceStatus).font(.footnote).foregroundStyle(.secondary)
        }
      }
    }
    .navigationTitle("Maintenance")
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          dismiss()
        } label: {
          Image(systemName: "xmark")
        }
        .accessibilityIdentifier("maintenance.dismiss")
      }
    }
  }
}
