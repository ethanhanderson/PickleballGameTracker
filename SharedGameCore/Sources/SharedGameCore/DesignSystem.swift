//
//  DesignSystem.swift
//  SharedGameCore
//
//  Created by Ethan Anderson on 7/9/25.
//

import SwiftUI

// MARK: - Design System

public enum DesignSystem {

  // MARK: - Colors
  public enum Colors {
    // Primary Brand Colors
    #if os(iOS)
      public static let primary: Color = .accentColor
      public static let primaryLight: Color = .accentColor.opacity(0.1)
      public static let primaryDark: Color = .accentColor.opacity(0.8)

      // Secondary Colors
      public static let secondary = Color(.systemBlue)
      public static let secondaryLight = Color(.systemBlue).opacity(0.1)
      public static let secondaryDark = Color(.systemBlue).opacity(0.8)

      // Tertiary/Special Action Colors
      public static let tertiary = Color(.systemCyan)
      public static let tertiaryLight = Color(.systemCyan).opacity(0.1)
      public static let tertiaryDark = Color(.systemCyan).opacity(0.8)

      // Score Colors
      public static let scorePlayer1 = Color(.systemBlue)
      public static let scorePlayer2 = Color(.systemOrange)
      public static let scoreWinner = primary

      // Semantic Colors
      public static let success = primary
      public static let warning = Color(.systemYellow)
      public static let error = Color(.systemRed)
      public static let info = Color(.systemBlue)

      // Surface Colors
      public static let surface = Color(.systemBackground)
      public static let surfaceSecondary = Color(.secondarySystemBackground)
      public static let surfaceTertiary = Color(.tertiarySystemBackground)

      // Neutral Colors for Cards and Containers
      public static let neutralSurface = Color(.systemGray6)
      public static let neutralBorder = Color(.systemGray4)

      // Gradient Colors for Cards
      public static let cardGradientTop = Color(.tertiarySystemBackground).opacity(0.8)
      public static let cardGradientBottom = Color(.secondarySystemBackground).opacity(0.6)
      public static let cardGradientHighlightTop = Color(.systemBlue).opacity(0.15)
      public static let cardGradientHighlightBottom = Color(.systemBlue).opacity(0.05)

      // Text Colors
      public static let textPrimary = Color(.label)
      public static let textSecondary = Color(.secondaryLabel)
      public static let textTertiary = Color(.tertiaryLabel)

      // Button Colors
      public static let buttonPrimary = Color(.systemBlue)
      public static let buttonSecondary = Color(.systemGray6)
      public static let buttonDestructive = Color(.systemRed)
    #else
      // watchOS Compatible Colors
      public static let primary: Color = .accentColor
      public static let primaryLight: Color = .accentColor.opacity(0.1)
      public static let primaryDark: Color = .accentColor.opacity(0.8)

      // Secondary Colors
      public static let secondary = Color.blue
      public static let secondaryLight = Color.blue.opacity(0.1)
      public static let secondaryDark = Color.blue.opacity(0.8)

      // Tertiary/Special Action Colors
      public static let tertiary = Color.cyan
      public static let tertiaryLight = Color.cyan.opacity(0.1)
      public static let tertiaryDark = Color.cyan.opacity(0.8)

      // Score Colors
      public static let scorePlayer1 = Color.blue
      public static let scorePlayer2 = Color.orange
      public static let scoreWinner = primary

      // Semantic Colors
      public static let success = primary
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
      public static let cardGradientHighlightTop = Color.blue.opacity(0.15)
      public static let cardGradientHighlightBottom = Color.blue.opacity(0.05)

      // Text Colors
      public static let textPrimary = Color.white
      public static let textSecondary = Color.gray
      public static let textTertiary = Color.gray.opacity(0.6)

      // Button Colors
      public static let buttonPrimary = Color.blue
      public static let buttonSecondary = Color.gray
      public static let buttonDestructive = Color.red
    #endif

    // Overlay Colors
    public static let overlay = Color.black.opacity(0.3)
    public static let overlayLight = Color.white.opacity(0.1)

    // Utility Colors
    public static let clear = Color.clear
    public static let transparent = Color.clear

    // MARK: - Additional Semantic Tokens
    // Paused/Disabled
    #if os(iOS)
      public static let paused = Color(.systemGray)
    #else
      public static let paused = Color.gray
    #endif

    // Container fills
    #if os(iOS)
      public static let containerFillSecondary = Color(.secondarySystemBackground)
      public static let containerFillTertiary = Color(.tertiarySystemFill)
    #else
      public static let containerFillSecondary = Color.gray.opacity(0.12)
      public static let containerFillTertiary = Color.gray.opacity(0.16)
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
        gradient: Gradient(colors: [cardGradientTop, cardGradientBottom]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    }

    /// Highlighted card gradient for selected or important states
    public static var cardGradientHighlight: LinearGradient {
      LinearGradient(
        gradient: Gradient(colors: [cardGradientHighlightTop, cardGradientHighlightBottom]),
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

    /// Navigation background gradient with brand color in the top third fading to transparent
    public static var navigationBrandGradient: LinearGradient {
      LinearGradient(
        gradient: Gradient(stops: [
          .init(color: primary.opacity(0.4), location: 0.0),
          .init(color: .clear, location: 0.33),
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
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
                gradient: Gradient(colors: [color.opacity(0.4), color]),
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

  // MARK: - Typography
  public enum Typography {
    // Headlines
    public static let largeTitle = Font.largeTitle.weight(.bold)
    public static let title1 = Font.title.weight(.bold)
    public static let title2 = Font.title2.weight(.semibold)
    public static let title3 = Font.title3.weight(.semibold)

    // Body Text
    public static let body = Font.body
    public static let bodyEmphasized = Font.body.weight(.medium)
    public static let bodyLarge = Font.title3

    // UI Elements
    public static let headline = Font.headline.weight(.semibold)
    public static let subheadline = Font.subheadline
    public static let caption = Font.caption
    public static let caption2 = Font.caption2

    // Specialized
    public static let scoreDisplay = Font.system(size: 72, weight: .bold, design: .rounded)
    public static let scoreLarge = Font.system(size: 48, weight: .bold, design: .rounded)
    public static let scoreMedium = Font.system(size: 36, weight: .bold, design: .rounded)
    public static let scoreSmall = Font.system(size: 24, weight: .bold, design: .rounded)

    // Buttons
    public static let buttonPrimary = Font.headline.weight(.semibold)
    public static let buttonSecondary = Font.subheadline.weight(.medium)
    public static let buttonLarge = Font.title2.weight(.semibold)
  }

  // MARK: - Spacing
  public enum Spacing {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 24
    public static let xl: CGFloat = 32
    public static let xxl: CGFloat = 48
    public static let xxxl: CGFloat = 64

    // Semantic Spacing
    public static let cardPadding: CGFloat = 16
    public static let sectionSpacing: CGFloat = 24
    public static let buttonPadding: CGFloat = 16
    public static let screenPadding: CGFloat = 20
  }

  // MARK: - Corner Radius
  public enum CornerRadius {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 20
    public static let xxl: CGFloat = 24
    public static let xxxl: CGFloat = 32

    // Semantic Radius
    public static let button: CGFloat = 12
    public static let card: CGFloat = 16
    public static let cardRounded: CGFloat = 22
    public static let sheet: CGFloat = 20
  }

  // MARK: - Shadows
  public enum Shadow {
    public static let sm = (
      color: Color.black.opacity(0.1), radius: CGFloat(2), x: CGFloat(0), y: CGFloat(1)
    )
    public static let md = (
      color: Color.black.opacity(0.15), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2)
    )
    public static let lg = (
      color: Color.black.opacity(0.2), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4)
    )
    public static let xl = (
      color: Color.black.opacity(0.25), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(8)
    )
  }

  // MARK: - Animation
  public enum Animation {
    public static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
    public static let smooth = SwiftUI.Animation.easeInOut(duration: 0.3)
    public static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
    public static let bouncy = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.8)
  }
}

// MARK: - Reusable Components

// MARK: - Button Styles

/// Legacy button styles - now using system styles for liquid glass design
/// These are kept for backward compatibility but internally use system styles
public struct PrimaryButtonStyle: ButtonStyle {
  let isDisabled: Bool

  public init(isDisabled: Bool = false) {
    self.isDisabled = isDisabled
  }

  public func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(DesignSystem.Typography.buttonPrimary)
      .frame(maxWidth: .infinity)
      .frame(minHeight: 50)
  }
}

public struct SecondaryButtonStyle: ButtonStyle {
  let color: Color

  public init(color: Color = DesignSystem.Colors.secondary) {
    self.color = color
  }

  public func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(DesignSystem.Typography.buttonSecondary)
      .frame(maxWidth: .infinity)
      .frame(minHeight: 50)
  }
}

public struct ActionButtonStyle: ButtonStyle {
  let color: Color
  let size: CGFloat

  public init(color: Color = DesignSystem.Colors.primary, size: CGFloat = 44) {
    self.color = color
    self.size = size
  }

  public func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: size * 0.4, weight: .bold))
      .frame(width: size, height: size)
  }
}

/// Liquid glass card button style for prominent UI elements
public struct CardButtonStyle: ButtonStyle {
  let color: Color
  let isSelected: Bool

  public init(color: Color = DesignSystem.Colors.primary, isSelected: Bool = false) {
    self.color = color
    self.isSelected = isSelected
  }

  public func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .frame(maxWidth: .infinity)
      .frame(minHeight: 120)
  }
}

/// Compact button style for smaller UI elements
public struct CompactButtonStyle: ButtonStyle {
  let color: Color

  public init(color: Color = DesignSystem.Colors.primary) {
    self.color = color
  }

  public func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(DesignSystem.Typography.caption)
      .frame(minHeight: 32)
  }
}

// MARK: - Card Styles
public struct CardStyle: ViewModifier {
  let backgroundColor: Color
  let padding: CGFloat

  public init(
    backgroundColor: Color = DesignSystem.Colors.surface,
    padding: CGFloat = DesignSystem.Spacing.cardPadding
  ) {
    self.backgroundColor = backgroundColor
    self.padding = padding
  }

  public func body(content: Content) -> some View {
    content
      .padding(padding)
      .background(
        .regularMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
  }
}

// MARK: - View Extensions
extension View {
  public func cardStyle(
    backgroundColor: Color = DesignSystem.Colors.surface,
    padding: CGFloat = DesignSystem.Spacing.cardPadding
  ) -> some View {
    self.modifier(CardStyle(backgroundColor: backgroundColor, padding: padding))
  }

  /// Apply card gradient background with rounded corners
  public func cardGradientBackground(
    cornerRadius: CGFloat = DesignSystem.CornerRadius.cardRounded,
    highlighted: Bool = false
  ) -> some View {
    self.background(
      RoundedRectangle(cornerRadius: cornerRadius)
        .fill(
          highlighted ? DesignSystem.Colors.cardGradientHighlight : DesignSystem.Colors.cardGradient
        )
    )
  }

  /// Apply card gradient style with padding and background
  public func cardGradientStyle(
    padding: CGFloat = DesignSystem.Spacing.cardPadding,
    cornerRadius: CGFloat = DesignSystem.CornerRadius.cardRounded,
    highlighted: Bool = false
  ) -> some View {
    self
      .padding(padding)
      .cardGradientBackground(cornerRadius: cornerRadius, highlighted: highlighted)
  }

  public func primaryButton(isDisabled: Bool = false) -> some View {
    self.buttonStyle(.borderedProminent)
      .disabled(isDisabled)
      .controlSize(.large)
  }

  public func secondaryButton(color: Color = DesignSystem.Colors.secondary) -> some View {
    self.buttonStyle(.bordered)
      .tint(color)
      .controlSize(.large)
  }

  public func actionButton(color: Color = DesignSystem.Colors.primary, size: CGFloat = 44)
    -> some View
  {
    self.buttonStyle(.borderedProminent)
      .buttonBorderShape(.circle)
      .tint(color)
      .controlSize(size > 50 ? .large : .regular)
  }

  public func cardButton(color: Color = DesignSystem.Colors.primary, isSelected: Bool = false)
    -> some View
  {
    self.buttonStyle(.plain)
      .tint(color)
      .controlSize(.large)
      .background(color.opacity(0.1))
      .cornerRadius(DesignSystem.CornerRadius.lg)
  }

  public func compactButton(
    color: Color = DesignSystem.Colors.primary,
    prominent: Bool = false
  ) -> some View {
    self.buttonStyle(.plain)
      .tint(color)
      .controlSize(.small)
      .background(color.opacity(0.1))
      .cornerRadius(DesignSystem.CornerRadius.sm)
  }

  public func sectionSpacing() -> some View {
    self.padding(.vertical, DesignSystem.Spacing.sectionSpacing)
  }

  public func screenPadding() -> some View {
    self.padding(.horizontal, DesignSystem.Spacing.screenPadding)
  }
}

// MARK: - Specialized Components

public struct ScoreDisplayView: View {
  let score: Int
  let label: String
  let color: Color
  let size: ScoreSize
  let isWinner: Bool

  public enum ScoreSize {
    case large, medium, small

    var font: Font {
      switch self {
      case .large: return DesignSystem.Typography.scoreDisplay
      case .medium: return DesignSystem.Typography.scoreMedium
      case .small: return DesignSystem.Typography.scoreSmall
      }
    }
  }

  public init(score: Int, label: String, color: Color, size: ScoreSize, isWinner: Bool = false) {
    self.score = score
    self.label = label
    self.color = color
    self.size = size
    self.isWinner = isWinner
  }

  public var body: some View {
    VStack(spacing: DesignSystem.Spacing.sm) {
      Text(label)
        .font(DesignSystem.Typography.caption)
        .foregroundColor(DesignSystem.Colors.textSecondary)
        .fontWeight(.medium)
        .accessibilityHidden(true)

      Text("\(score)")
        .font(size.font)
        .foregroundColor(color)
        .monospacedDigit()
        .accessibilityHidden(true)
    }
    .scoreAccessibility(
      score: score,
      playerLabel: label,
      isWinner: isWinner
    )
  }
}

public struct GameTypeCard: View {
  let gameType: GameType
  let isSelected: Bool
  let action: () -> Void

  public init(gameType: GameType, isSelected: Bool, action: @escaping () -> Void) {
    self.gameType = gameType
    self.isSelected = isSelected
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      VStack(spacing: DesignSystem.Spacing.md) {
        Image(systemName: gameType.iconName)
          .font(.system(size: 32, weight: .medium))
          .accessibilityHidden(true)

        VStack(spacing: DesignSystem.Spacing.xs) {
          Text(gameType.displayName)
            .font(DesignSystem.Typography.headline)
            .accessibilityHidden(true)

          Text(gameType.description)
            .font(DesignSystem.Typography.caption)
            .accessibilityHidden(true)
        }
      }
      .frame(maxWidth: .infinity)
      .frame(height: 120)
    }
    .cardButton(color: DesignSystem.Colors.gameType(gameType), isSelected: isSelected)
    .gameTypeSelectionAccessibility(
      gameType: gameType,
      isSelected: isSelected
    )
  }
}

// MARK: - Loading Animation
public struct LoadingSpinner: View {
  let size: CGFloat
  let color: Color

  @State private var isAnimating = false

  public init(size: CGFloat = 20, color: Color = DesignSystem.Colors.primary) {
    self.size = size
    self.color = color
  }

  public var body: some View {
    Circle()
      .trim(from: 0.0, to: 0.7)
      .stroke(color, lineWidth: 2)
      .frame(width: size, height: size)
      .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
      .animation(
        Animation.linear(duration: 1.0).repeatForever(autoreverses: false),
        value: isAnimating
      )
      .onAppear {
        isAnimating = true
      }
  }
}

// MARK: - Pulse Animation
public struct PulseEffect: ViewModifier {
  let duration: Double

  @State private var isPulsing = false

  public init(duration: Double = 1.0) {
    self.duration = duration
  }

  public func body(content: Content) -> some View {
    content
      .scaleEffect(isPulsing ? 1.05 : 1.0)
      .opacity(isPulsing ? 0.8 : 1.0)
      .animation(
        Animation.easeInOut(duration: duration).repeatForever(autoreverses: true),
        value: isPulsing
      )
      .onAppear {
        isPulsing = true
      }
  }
}

// MARK: - Slide In Animation
public struct SlideInEffect: ViewModifier {
  let delay: Double

  @State private var offset: CGFloat = 50
  @State private var opacity: Double = 0

  public init(delay: Double = 0.0) {
    self.delay = delay
  }

  public func body(content: Content) -> some View {
    content
      .offset(y: offset)
      .opacity(opacity)
      .onAppear {
        withAnimation(DesignSystem.Animation.smooth.delay(delay)) {
          offset = 0
          opacity = 1
        }
      }
  }
}

// MARK: - Animation Extensions
extension View {
  public func pulse(duration: Double = 1.0) -> some View {
    self.modifier(PulseEffect(duration: duration))
  }

  public func slideIn(delay: Double = 0.0) -> some View {
    self.modifier(SlideInEffect(delay: delay))
  }
}

// MARK: - Accessibility
public enum Accessibility {
  // MARK: - VoiceOver Labels
  public enum Labels {
    public static let scorePlayer1 = "Player 1 Score"
    public static let scorePlayer2 = "Player 2 Score"
    public static let incrementScore = "Increment Score"
    public static let decrementScore = "Decrement Score"
    public static let undoLastPoint = "Undo Last Point"
    public static let finishGame = "Finish Game"
    public static let saveAndReturn = "Save and Return to Menu"
    public static let backToMenu = "Back to Menu"
    public static let newGame = "Start New Game"
    public static let gameHistory = "View Game History"
    public static let resumeGame = "Resume Current Game"
    public static let selectGameType = "Select Game Type"
    public static let gameComplete = "Game Complete"
    public static let winner = "Winner"
    public static let duration = "Game Duration"
    public static let rallies = "Total Rallies"
    public static let currentRally = "Current Rally"
    public static let playingTo = "Playing to"
    public static let winBy = "Win by"
    public static let gameTypeIcon = "Game Type Icon"
    public static let filterGames = "Filter Games"
    public static let resetFilters = "Reset Filters"
  }

  // MARK: - VoiceOver Hints
  public enum Hints {
    public static let scoreButton = "Double tap to add a point"
    public static let undoButton = "Double tap to undo the last point"
    public static let gameTypeButton = "Double tap to select this game type"
    public static let navigationButton = "Double tap to navigate"
    public static let filterButton = "Double tap to filter by this option"
    public static let gameRow = "Double tap to view game details"
  }
}

// MARK: - Accessibility View Extensions
extension View {
  // MARK: - Score Display Accessibility
  public func scoreAccessibility(
    score: Int,
    playerLabel: String,
    isWinner: Bool = false
  ) -> some View {
    self
      .accessibilityLabel("\(playerLabel): \(score) points")
      .accessibilityValue(isWinner ? "Winner" : "")
  }

  // MARK: - Action Button Accessibility
  public func actionButtonAccessibility(
    label: String,
    hint: String? = nil,
    isEnabled: Bool = true
  ) -> some View {
    self
      .accessibilityLabel(label)
      .accessibilityHint(hint ?? "")
  }

  // MARK: - Navigation Button Accessibility
  public func navigationButtonAccessibility(
    label: String,
    hint: String? = nil
  ) -> some View {
    self
      .accessibilityLabel(label)
      .accessibilityHint(hint ?? Accessibility.Hints.navigationButton)
  }

  // MARK: - Game Type Selection Accessibility
  public func gameTypeSelectionAccessibility(
    gameType: GameType,
    isSelected: Bool
  ) -> some View {
    self
      .accessibilityLabel("\(gameType.displayName) - \(gameType.description)")
      .accessibilityHint(Accessibility.Hints.gameTypeButton)
  }

  // MARK: - Game Status Accessibility
  public func gameStatusAccessibility(
    status: String,
    additionalInfo: String? = nil
  ) -> some View {
    self
      .accessibilityLabel(status)
      .accessibilityValue(additionalInfo ?? "")
  }

  // MARK: - Filter Accessibility
  public func filterAccessibility(
    title: String,
    isSelected: Bool
  ) -> some View {
    self
      .accessibilityLabel(title)
      .accessibilityHint(Accessibility.Hints.filterButton)
  }

  // MARK: - Game History Row Accessibility
  public func gameHistoryRowAccessibility(
    game: Game,
    rank: Int? = nil
  ) -> some View {
    let rankText = rank != nil ? "Rank \(rank!). " : ""
    let statusText = game.isCompleted ? "Completed" : "In Progress"
    let scoreText =
      "\(game.gameType.playerLabel1) \(game.score1), \(game.gameType.playerLabel2) \(game.score2)"
    let winnerText = game.winner != nil ? ". Winner: \(game.winner!)" : ""
    let durationText = game.formattedDuration != nil ? ". Duration: \(game.formattedDuration!)" : ""

    return
      self
      .accessibilityLabel(
        "\(rankText)\(game.gameType.displayName) game. \(statusText). \(scoreText)\(winnerText). \(game.formattedDate)\(durationText)"
      )
      .accessibilityHint(Accessibility.Hints.gameRow)
  }

  // MARK: - Header Accessibility
  public func headerAccessibility(title: String) -> some View {
    self
      .accessibilityLabel(title)
  }
}

// MARK: - Modern Layout Containers

/// Adaptive grid layout for game type selection
public struct GameTypeGridLayout: Layout {
  let spacing: CGFloat
  let minItemWidth: CGFloat

  public init(spacing: CGFloat = 16, minItemWidth: CGFloat = 140) {
    self.spacing = spacing
    self.minItemWidth = minItemWidth
  }

  public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ())
    -> CGSize
  {
    let width = proposal.width ?? 300
    let columns = max(1, Int(width / minItemWidth))
    let _ = (width - CGFloat(columns - 1) * spacing) / CGFloat(columns)
    let rows = Int(ceil(Double(subviews.count) / Double(columns)))
    let height = CGFloat(rows) * 120 + CGFloat(max(0, rows - 1)) * spacing

    return CGSize(width: width, height: height)
  }

  public func placeSubviews(
    in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
  ) {
    let columns = max(1, Int(bounds.width / minItemWidth))
    let itemWidth = (bounds.width - CGFloat(columns - 1) * spacing) / CGFloat(columns)
    let itemHeight: CGFloat = 120

    for (index, subview) in subviews.enumerated() {
      let row = index / columns
      let col = index % columns

      let x = bounds.minX + CGFloat(col) * (itemWidth + spacing)
      let y = bounds.minY + CGFloat(row) * (itemHeight + spacing)

      subview.place(
        at: CGPoint(x: x, y: y),
        proposal: ProposedViewSize(width: itemWidth, height: itemHeight)
      )
    }
  }
}

/// Semantic section container for consistent grouping
public struct SectionContainer<Content: View>: View {
  let title: String?
  let subtitle: String?
  let icon: String?
  let content: Content

  public init(
    title: String? = nil,
    subtitle: String? = nil,
    icon: String? = nil,
    @ViewBuilder content: () -> Content
  ) {
    self.title = title
    self.subtitle = subtitle
    self.icon = icon
    self.content = content()
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
      if let title = title {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
          HStack(spacing: DesignSystem.Spacing.sm) {
            if let icon = icon {
              Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(DesignSystem.Colors.primary)
            }

            Text(title)
              .font(DesignSystem.Typography.headline)
              .foregroundColor(DesignSystem.Colors.textPrimary)
          }

          if let subtitle = subtitle {
            Text(subtitle)
              .font(DesignSystem.Typography.caption)
              .foregroundColor(DesignSystem.Colors.textSecondary)
          }
        }
      }

      content
    }
  }
}

/// Adaptive score control grid
public struct ScoreControlsGrid<Content: View>: View {
  let content: Content
  let spacing: CGFloat

  public init(spacing: CGFloat = 16, @ViewBuilder content: () -> Content) {
    self.spacing = spacing
    self.content = content()
  }

  public var body: some View {
    ViewThatFits(in: .horizontal) {
      // Wide layout - horizontal arrangement
      HStack(spacing: spacing * 2) {
        content
      }

      // Narrow layout - vertical stack
      VStack(spacing: spacing) {
        content
      }
    }
  }
}

/// Responsive card grid
public struct CardGrid<Content: View>: View {
  let content: Content
  let minItemWidth: CGFloat
  let spacing: CGFloat

  public init(
    minItemWidth: CGFloat = 280,
    spacing: CGFloat = 16,
    @ViewBuilder content: () -> Content
  ) {
    self.minItemWidth = minItemWidth
    self.spacing = spacing
    self.content = content()
  }

  public var body: some View {
    LazyVGrid(
      columns: [
        GridItem(.adaptive(minimum: minItemWidth), spacing: spacing)
      ],
      spacing: spacing
    ) {
      content
    }
  }
}

/// Semantic info card with consistent styling
public struct InfoCard<Content: View>: View {
  let title: String?
  let icon: String?
  let style: InfoCardStyle
  let gameType: GameType?
  let content: Content

  public enum InfoCardStyle {
    case info, success, warning, error

    var color: Color {
      switch self {
      case .info: return DesignSystem.Colors.info
      case .success: return DesignSystem.Colors.success
      case .warning: return DesignSystem.Colors.warning
      case .error: return DesignSystem.Colors.error
      }
    }
  }

  public init(
    title: String? = nil,
    icon: String? = nil,
    style: InfoCardStyle = .info,
    gameType: GameType? = nil,
    @ViewBuilder content: () -> Content
  ) {
    self.title = title
    self.icon = icon
    self.style = style
    self.gameType = gameType
    self.content = content()
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
      if let title = title {
        HStack(spacing: DesignSystem.Spacing.sm) {
          if let icon = icon {
            Image(systemName: icon)
              .font(.system(size: 16, weight: .medium))
              .foregroundColor(iconColor)
          }

          Text(title)
            .font(DesignSystem.Typography.headline)
            .foregroundColor(DesignSystem.Colors.textPrimary)
        }
      }

      content
    }
    .padding(DesignSystem.Spacing.cardPadding)
    .background(
      Group {
        if let gameType = gameType {
          // Game-themed card with gradient background and stroke
          RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
            .fill(
              LinearGradient(
                gradient: Gradient(colors: [
                  DesignSystem.Colors.gameType(gameType).opacity(0.15),
                  DesignSystem.Colors.gameType(gameType).opacity(0.05),
                ]),
                startPoint: .top,
                endPoint: .bottom
              )
            )
            .overlay(
              RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .strokeBorder(.thinMaterial, lineWidth: 1)
            )
        } else {
          // Default card style
          RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
            .fill(.regularMaterial)
        }
      }
    )
  }

  private var iconColor: Color {
    if let gameType = gameType {
      return DesignSystem.Colors.gameType(gameType).opacity(0.8)  // Darker shade of game color
    } else {
      return style.color
    }
  }
}

/// Adaptive action bar layout
public struct ActionBarLayout<Content: View>: View {
  let content: Content
  let maxWidth: CGFloat

  public init(maxWidth: CGFloat = 600, @ViewBuilder content: () -> Content) {
    self.content = content()
    self.maxWidth = maxWidth
  }

  public var body: some View {
    ViewThatFits(in: .horizontal) {
      // Wide layout - horizontal buttons
      HStack(spacing: DesignSystem.Spacing.md) {
        content
      }
      .frame(maxWidth: maxWidth)

      // Narrow layout - vertical stack
      VStack(spacing: DesignSystem.Spacing.md) {
        content
      }
    }
  }
}

// MARK: - Layout Extensions

extension View {
  /// Apply semantic section layout
  public func sectionLayout(
    title: String? = nil,
    subtitle: String? = nil,
    icon: String? = nil
  ) -> some View {
    SectionContainer(title: title, subtitle: subtitle, icon: icon) {
      self
    }
  }

  /// Apply info card styling
  public func infoCard(
    title: String? = nil,
    icon: String? = nil,
    style: InfoCard<Self>.InfoCardStyle = .info
  ) -> some View {
    InfoCard(title: title, icon: icon, style: style) {
      self
    }
  }

  /// Apply adaptive layout that fits content
  public func adaptiveLayout() -> some View {
    ViewThatFits {
      self
    }
  }

  /// Apply consistent header spacing
  public func headerSpacing() -> some View {
    self.padding(.top, DesignSystem.Spacing.xl)
  }

  /// Apply consistent footer spacing
  public func footerSpacing() -> some View {
    self.padding(.bottom, DesignSystem.Spacing.xl)
  }

  /// Apply semantic spacing between major sections
  public func majorSectionSpacing() -> some View {
    self.padding(.vertical, DesignSystem.Spacing.lg)
  }

  /// Apply responsive padding that adapts to screen size
  public func responsivePadding() -> some View {
    self.modifier(ResponsivePaddingModifier())
  }
}

/// Responsive padding modifier that adapts to screen size
struct ResponsivePaddingModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .padding(.horizontal, DesignSystem.Spacing.lg)
  }
}
