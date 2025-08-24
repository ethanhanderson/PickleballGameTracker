//
//  DesignSystem.swift
//  SharedGameCore
//
//  Created by Ethan Anderson on 7/9/25.
//

import SwiftUI

// MARK: - Design System

public enum DesignSystem {}

// MARK: - Reusable Components

// MARK: - View Extensions (moved to Foundation/DesignSystem/ViewExtensions.swift)

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

  public init(
    score: Int,
    label: String,
    color: Color,
    size: ScoreSize,
    isWinner: Bool = false
  ) {
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
        Animation.linear(duration: 1.0).repeatForever(
          autoreverses: false
        ),
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
        Animation.easeInOut(duration: duration).repeatForever(
          autoreverses: true
        ),
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
        withAnimation(
          SwiftUI.Animation.easeInOut(duration: 0.3).delay(delay)
        ) {
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

// MARK: - Accessibility moved to Foundation/DesignSystem/Accessibility.swift

// MARK: - Modern Layout Containers

/// Adaptive grid layout for game type selection
public struct GameTypeGridLayout: Layout {
  let spacing: CGFloat
  let minItemWidth: CGFloat

  public init(spacing: CGFloat = 16, minItemWidth: CGFloat = 140) {
    self.spacing = spacing
    self.minItemWidth = minItemWidth
  }

  public func sizeThatFits(
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  )
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
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) {
    let columns = max(1, Int(bounds.width / minItemWidth))
    let itemWidth =
      (bounds.width - CGFloat(columns - 1) * spacing) / CGFloat(columns)
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
          RoundedRectangle(
            cornerRadius: DesignSystem.CornerRadius.card
          )
          .fill(
            LinearGradient(
              gradient: Gradient(colors: [
                DesignSystem.Colors.gameType(gameType).opacity(
                  0.15
                ),
                DesignSystem.Colors.gameType(gameType).opacity(
                  0.05
                ),
              ]),
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .overlay(
            RoundedRectangle(
              cornerRadius: DesignSystem.CornerRadius.card
            )
            .strokeBorder(.thinMaterial, lineWidth: 1)
          )
        } else {
          // Default card style
          RoundedRectangle(
            cornerRadius: DesignSystem.CornerRadius.card
          )
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

// MARK: - Layout Extensions moved to Foundation/DesignSystem/ViewExtensions.swift
