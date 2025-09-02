//
//  ErrorView.swift
//  Pickleball Score Tracking
//
//  Created by Ethan Anderson on 7/9/25.
//

import SwiftUI
import CorePackage

public struct ErrorView: View {
  let error: Error
  let retry: (() -> Void)?

  public var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 48, weight: .medium))
        .foregroundColor(DesignSystem.Colors.error)
        .symbolRenderingMode(.hierarchical)

      VStack(spacing: 8) {
        Text("Something went wrong")
          .font(.headline)
          .fontWeight(.semibold)
          .foregroundColor(.primary)

        Text(errorMessage)
          .font(.body)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
      }

      if let retry = retry {
        Button(action: retry) {
          HStack(spacing: 8) {
            Image(systemName: "arrow.clockwise")
              .font(.system(size: 16, weight: .semibold))
            Text("Try Again")
              .font(.callout)
              .fontWeight(.semibold)
          }
          .foregroundColor(.white)
          .frame(height: 44)
          .frame(maxWidth: .infinity)
          .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.cardRounded)
              .fill(DesignSystem.Colors.buttonPrimary)
          )
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 32)
  }

  private var errorMessage: String {
    if let localizedError = error as? LocalizedError {
      return localizedError.localizedDescription
    } else {
      return "An unexpected error occurred. Please try again."
    }
  }
}

// MARK: - Custom Error Types
enum AppError: LocalizedError {
  case coreDataError(String)
  case syncError(String)
  case gameError(String)
  case networkError(String)

  nonisolated var errorDescription: String? {
    switch self {
    case .coreDataError(let message):
      return "Data Error: \(message)"
    case .syncError(let message):
      return "Sync Error: \(message)"
    case .gameError(let message):
      return "Game Error: \(message)"
    case .networkError(let message):
      return "Network Error: \(message)"
    }
  }

  nonisolated var recoverySuggestion: String? {
    switch self {
    case .coreDataError:
      return "Try restarting the app or contact support if the problem persists."
    case .syncError:
      return "Check your internet connection and try again."
    case .gameError:
      return "Try starting a new game or restart the app."
    case .networkError:
      return "Check your internet connection and try again."
    }
  }
}
