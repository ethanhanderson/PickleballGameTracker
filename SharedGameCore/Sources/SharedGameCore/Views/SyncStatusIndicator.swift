//
//  SyncStatusIndicator.swift
//  SharedGameCore
//
//  UI component for displaying cross-device synchronization status
//

import SwiftUI

/// View component that displays the current synchronization status
/// Shows connection state, error conditions, and sync activity
public struct SyncStatusIndicator: View {

  // MARK: - Properties

  private let syncState: ActiveGameSyncService.SyncState
  private let lastError: (any Error)?
  private let isCompact: Bool

  // MARK: - Initialization

  public init(
    syncState: ActiveGameSyncService.SyncState,
    lastError: (any Error)? = nil,
    isCompact: Bool = false
  ) {
    self.syncState = syncState
    self.lastError = lastError
    self.isCompact = isCompact
  }

  // MARK: - Body

  public var body: some View {
    HStack(spacing: DesignSystem.Spacing.sm) {
      // Status icon
      Image(systemName: syncState.iconName)
        .foregroundColor(statusColor)
        .font(.system(size: isCompact ? 12 : 14, weight: .medium))

      if !isCompact {
        // Status text
        Text(syncState.displayName)
          .font(DesignSystem.Typography.caption)
          .foregroundColor(DesignSystem.Colors.textSecondary)
      }
    }
    .padding(.horizontal, isCompact ? DesignSystem.Spacing.xs : DesignSystem.Spacing.sm)
    .padding(.vertical, isCompact ? 2 : 4)
    .background(
      RoundedRectangle(cornerRadius: isCompact ? 4 : 6)
        .fill(statusColor.opacity(0.1))
    )
    .overlay(
      RoundedRectangle(cornerRadius: isCompact ? 4 : 6)
        .stroke(statusColor.opacity(0.3), lineWidth: 1)
    )
    .help(toolTipText)
  }

  // MARK: - Computed Properties

  private var statusColor: Color {
    switch syncState {
    case .connected:
      return DesignSystem.Colors.success
    case .connecting:
      return DesignSystem.Colors.warning
    case .disconnected:
      return DesignSystem.Colors.textSecondary
    case .error:
      return DesignSystem.Colors.error
    }
  }

  private var toolTipText: String {
    if let error = lastError {
      return "Sync Error: \(error.localizedDescription)"
    }

    switch syncState {
    case .connected:
      return "Connected to paired device"
    case .connecting:
      return "Connecting to paired device..."
    case .disconnected:
      return "Not connected to paired device"
    case .error:
      return "Sync error occurred"
    }
  }
}

// MARK: - Computed Properties (using existing DesignSystem colors)

// MARK: - Convenience Initializers

extension SyncStatusIndicator {

  /// Create a compact sync status indicator for toolbars
  public static func compact(
    syncState: ActiveGameSyncService.SyncState,
    lastError: (any Error)? = nil
  ) -> SyncStatusIndicator {
    SyncStatusIndicator(
      syncState: syncState,
      lastError: lastError,
      isCompact: true
    )
  }

  /// Create a full sync status indicator for settings or detailed views
  public static func full(
    syncState: ActiveGameSyncService.SyncState,
    lastError: (any Error)? = nil
  ) -> SyncStatusIndicator {
    SyncStatusIndicator(
      syncState: syncState,
      lastError: lastError,
      isCompact: false
    )
  }
}

// MARK: - Observable Sync Status

/// ObservableObject wrapper for easy SwiftUI integration
@MainActor
public final class SyncStatusViewModel: ObservableObject {

  // MARK: - Published Properties

  @Published public var syncState: ActiveGameSyncService.SyncState = .disconnected
  @Published public var lastError: (any Error)? = nil

  // MARK: - Private Properties

  private let syncService: ActiveGameSyncService

  // MARK: - Initialization

  public init(syncService: ActiveGameSyncService = ActiveGameSyncService.shared) {
    self.syncService = syncService
    startObserving()
  }

  // MARK: - Private Methods

  private func startObserving() {
    // Observe sync service changes
    Task {
      while !Task.isCancelled {
        syncState = syncService.syncState
        lastError = syncService.lastError

        try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds
      }
    }
  }
}

// MARK: - SwiftUI View Extension

extension View {

  /// Add a sync status indicator to the view
  public func syncStatusIndicator(
    placement: SyncStatusPlacement = .topTrailing,
    style: SyncStatusStyle = .compact
  ) -> some View {
    self.modifier(
      SyncStatusModifier(
        placement: placement,
        style: style
      )
    )
  }
}

public enum SyncStatusPlacement {
  case topLeading
  case topTrailing
  case bottomLeading
  case bottomTrailing
}

public enum SyncStatusStyle {
  case compact
  case full
}

private struct SyncStatusModifier: ViewModifier {
  let placement: SyncStatusPlacement
  let style: SyncStatusStyle

  @StateObject private var viewModel = SyncStatusViewModel()

  func body(content: Content) -> some View {
    content
      .overlay(alignment: alignment) {
        Group {
          switch style {
          case .compact:
            SyncStatusIndicator.compact(
              syncState: viewModel.syncState,
              lastError: viewModel.lastError
            )
          case .full:
            SyncStatusIndicator.full(
              syncState: viewModel.syncState,
              lastError: viewModel.lastError
            )
          }
        }
        .padding(DesignSystem.Spacing.sm)
      }
  }

  private var alignment: Alignment {
    switch placement {
    case .topLeading: return .topLeading
    case .topTrailing: return .topTrailing
    case .bottomLeading: return .bottomLeading
    case .bottomTrailing: return .bottomTrailing
    }
  }
}

#if DEBUG

  // MARK: - Preview Support

  struct SyncStatusIndicator_Previews: PreviewProvider {
    static var previews: some View {
      VStack(spacing: DesignSystem.Spacing.lg) {
        // Compact variants
        HStack(spacing: DesignSystem.Spacing.md) {
          SyncStatusIndicator.compact(syncState: .connected)
          SyncStatusIndicator.compact(syncState: .connecting)
          SyncStatusIndicator.compact(syncState: .disconnected)
          SyncStatusIndicator.compact(syncState: .error)
        }

        // Full variants
        VStack(spacing: DesignSystem.Spacing.sm) {
          SyncStatusIndicator.full(syncState: .connected)
          SyncStatusIndicator.full(syncState: .connecting)
          SyncStatusIndicator.full(syncState: .disconnected)
          SyncStatusIndicator.full(syncState: .error)
        }
      }
      .padding()
      .previewDisplayName("Sync Status Indicators")
    }
  }

#endif
