import SwiftUI

extension DesignSystem {
  /// Apple system colors available for user customization
  public enum AppleSystemColor: String, Codable, CaseIterable, Sendable {
    case green = "green"
    case blue = "blue"
    case orange = "orange"
    case red = "red"
    case purple = "purple"
    case pink = "pink"
    case teal = "teal"
    case indigo = "indigo"
    case brown = "brown"
    case gray = "gray"

    /// Human-readable name for the color
    public var displayName: String {
      switch self {
      case .blue: "Blue"
      case .green: "Green"
      case .orange: "Orange"
      case .red: "Red"
      case .purple: "Purple"
      case .pink: "Pink"
      case .teal: "Teal"
      case .indigo: "Indigo"
      case .brown: "Brown"
      case .gray: "Gray"
      }
    }

    /// SwiftUI Color representation
    public var color: Color {
      switch self {
      case .blue: return .blue
      case .green: return .green
      case .orange: return .orange
      case .red: return .red
      case .purple: return .purple
      case .pink: return .pink
      case .teal: return .teal
      case .indigo: return .indigo
      case .brown: return .brown
      case .gray: return .gray
      }
    }

    /// Legacy hex representation for migration purposes
    public var legacyHex: String {
      switch self {
      case .blue: "#007AFF"
      case .green: "#34C759"
      case .orange: "#FF9500"
      case .red: "#FF3B30"
      case .purple: "#AF52DE"
      case .pink: "#FF2D55"
      case .teal: "#5AC8FA"
      case .indigo: "#5856D6"
      case .brown: "#A2845E"
      case .gray: "#8E8E93"
      }
    }

    /// Create from legacy hex string (for migration)
    public init?(fromHex hex: String) {
      let normalizedHex = hex.uppercased()
      for color in Self.allCases {
        if color.legacyHex.uppercased() == normalizedHex {
          self = color
          return
        }
      }
      return nil
    }
  }

  public enum Colors {
    // Primary Brand Colors
    #if os(iOS)
      public static let primary = Color(.accent)

      // Secondary Colors
      public static let secondary = Color(.systemBlue)
      public static let secondaryLight = Color(.systemBlue).opacity(0.1)

      // Tertiary/Special Action Colors
      public static let tertiary = Color(.systemCyan)

      // Score Colors
      public static let scorePlayer1 = Color(.systemBlue)
      public static let scorePlayer2 = Color(.systemOrange)

      // Semantic Colors
      public static let success = Color(.systemGreen)
      public static let warning = Color(.systemYellow)
      public static let error = Color(.systemRed)
      public static let info = Color(.systemBlue)

      // Surface Colors
      public static let surface = Color(.systemBackground)
      public static let surfaceSecondary = Color(
        .secondarySystemBackground
      )
      public static let surfaceTertiary = Color(.tertiarySystemBackground)

      // Neutral Colors for Cards and Containers
      public static let neutralSurface = Color(.systemGray6)
      public static let neutralBorder = Color(.systemGray4)

      // Gradient Colors for Cards
      public static let cardGradientTop = Color(.tertiarySystemBackground)
        .opacity(0.8)
      public static let cardGradientBottom = Color(
        .secondarySystemBackground
      ).opacity(0.6)
      public static let cardGradientHighlightTop = Color(.systemBlue)
        .opacity(0.15)
      public static let cardGradientHighlightBottom = Color(.systemBlue)
        .opacity(0.05)

      // Text Colors
      public static let textPrimary = Color(.label)
      public static let textSecondary = Color(.secondaryLabel)
      public static let textTertiary = Color(.tertiaryLabel)

      // Button Colors
      public static let buttonPrimary = Color(.systemBlue)
    #else
      // watchOS Compatible Colors
      public static let primary: Color = .accentColor

      // Secondary Colors
      public static let secondary = Color.blue
      public static let secondaryLight = Color.blue.opacity(0.1)

      // Tertiary/Special Action Colors
      public static let tertiary = Color.cyan

      // Score Colors
      public static let scorePlayer1 = Color.blue
      public static let scorePlayer2 = Color.orange

      // Semantic Colors
      public static let success = Color.green
      public static let warning = Color.yellow
      public static let error = Color.red
      public static let info = Color.blue

      // Surface Colors
      public static let surface = Color.black
      public static let surfaceSecondary = Color.gray.opacity(0.1)
      public static let surfaceTertiary = Color.gray.opacity(0.05)

      // Neutral Colors for Cards and Containers
      public static let neutralSurface = Color.gray.opacity(0.08)
      public static let neutralBorder = Color.gray.opacity(0.2)

      // Gradient Colors for Cards
      public static let cardGradientTop = Color.gray.opacity(0.2)
      public static let cardGradientBottom = Color.gray.opacity(0.1)
      public static let cardGradientHighlightTop = Color.blue.opacity(
        0.15
      )
      public static let cardGradientHighlightBottom = Color.blue.opacity(
        0.05
      )

      // Text Colors
      public static let textPrimary = Color.white
      public static let textSecondary = Color.gray
      public static let textTertiary = Color.gray.opacity(0.6)

      // Button Colors
      public static let buttonPrimary = Color.blue
    #endif

    // Navigation Colors
    public static let navigationTintColor = primary

    // Utility Colors
    public static let clear = Color.clear

    // MARK: - Additional Semantic Tokens
    // Paused/Disabled
    #if os(iOS)
      public static let paused = Color(.systemGray)
    #else
      public static let paused = Color.gray
    #endif

    // Container fills
    #if os(iOS)
      public static let containerFillSecondary = Color(
        .secondarySystemBackground
      )
    #else
      public static let containerFillSecondary = Color.gray.opacity(0.12)
    #endif

    // Rule UI helpers
    public static let rulePositive = success
    public static let ruleCaution = warning
    public static let ruleNegative = error
    public static let ruleInfo = info

    // Text on colored backgrounds
    #if os(iOS)
      public static let textOnColor = Color.white
      public static let textOnColorMuted = Color.white.opacity(0.8)
    #else
      public static let textOnColor = Color.white
      public static let textOnColorMuted = Color.white.opacity(0.8)
    #endif

    // MARK: - Feature Utilities
    /// Accent color for a given game type using semantic tokens
    public static func gameType(_ type: GameType) -> Color {
      switch type {
      case .recreational:
        return success
      case .tournament:
        return warning
      case .training:
        return info
      case .social:
        return tertiary
      case .custom:
        return secondary
      }
    }

    // MARK: - Gradient Utilities

    /// Standard card gradient from lighter top-left to darker bottom-right
    public static var cardGradient: LinearGradient {
      LinearGradient(
        gradient: Gradient(colors: [
          cardGradientTop, cardGradientBottom,
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    }

    /// Highlighted card gradient for selected or important states
    public static var cardGradientHighlight: LinearGradient {
      LinearGradient(
        gradient: Gradient(colors: [
          cardGradientHighlightTop, cardGradientHighlightBottom,
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    }

    /// Custom gradient with any colors
    public static func customGradient(
      from topColor: Color,
      to bottomColor: Color,
      startPoint: UnitPoint = .topLeading,
      endPoint: UnitPoint = .bottomTrailing
    ) -> LinearGradient {
      LinearGradient(
        gradient: Gradient(colors: [topColor, bottomColor]),
        startPoint: startPoint,
        endPoint: endPoint
      )
    }

    /// Generic navigation background gradient with a color in the top third fading to transparent
    public static func navigationGradient(
      color: Color? = nil, topOpacity: Double = 0.4, cutoff: CGFloat = 0.33
    ) -> LinearGradient {
      let base = color ?? primary
      return LinearGradient(
        gradient: Gradient(stops: [
          .init(color: base.opacity(topOpacity), location: 0.0),
          .init(color: .clear, location: cutoff),
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
    }

    /// Navigation background gradient using the brand accent color
    public static var navigationBrandGradient: LinearGradient {
      navigationGradient(color: primary)
    }

    /// Game card background with material, gradient, and stroke
    public static func gameCardBackground(
      color: Color,
      cornerRadius: CGFloat = DesignSystem.CornerRadius.cardRounded
    ) -> some View {
      RoundedRectangle(cornerRadius: cornerRadius)
        .fill(.thinMaterial)
        .overlay(
          RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
              LinearGradient(
                gradient: Gradient(colors: [
                  color.opacity(0.4), color,
                ]),
                startPoint: .bottom,
                endPoint: .top
              )
            )
        )
        .overlay(
          RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(.thinMaterial, lineWidth: 1)
        )
    }
  }
}
