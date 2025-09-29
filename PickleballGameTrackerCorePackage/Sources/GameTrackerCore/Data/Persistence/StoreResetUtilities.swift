import Foundation
import SwiftData

@MainActor
public enum StoreResetUtilities {
  public static func resetStoreFiles() throws {
    try SwiftDataContainer.shared.resetStoreFiles()
  }

  public static func storeFilesExist() -> Bool {
    SwiftDataContainer.shared.storeFilesExist()
  }

  public static func storeFileURL() throws -> URL {
    try SwiftDataContainer.shared.getStoreFileURL()
  }

  public static func storeFileSize() -> Int64 {
    SwiftDataContainer.shared.getStoreFileSize()
  }

  public static func performHealthCheck() async -> Bool {
    await SwiftDataContainer.shared.performHealthCheck()
  }

  public static func validateAndRecoverStore() async throws -> Bool {
    try await SwiftDataContainer.shared.validateAndRecoverStore()
  }
}


