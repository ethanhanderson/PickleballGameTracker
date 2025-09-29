import GameTrackerCore
import SwiftUI

@MainActor
struct GameDetailInfoCard<Content: View>: View {
  let title: String
  let gradient: AnyGradient
  @ViewBuilder var content: () -> Content
  let size: Size
  let accessibilityIdentifier: String?
  let iconSystemName: String?
  let iconVariableValue: Double?
  let style: Display

  var body: some View {
    VStack(spacing: DesignSystem.Spacing.xs) {
      if let iconSystemName {
        if let iconVariableValue {
          Image(systemName: iconSystemName, variableValue: iconVariableValue)
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(gradient)
            .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
        } else {
          Image(systemName: iconSystemName)
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(gradient)
            .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
        }
      }

      if style != .iconOnly {
        Text(title)
          .font(.caption)
          .fontWeight(.medium)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)

        content()
          .font(size.contentFont)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(size.padding)
    .glassEffect(
      .regular.tint(
        Color.gray.opacity(0.15).opacity(0.2)
      ),
      in: RoundedRectangle(
        cornerRadius: DesignSystem.CornerRadius.xl
      )
    )
    .accessibilityIdentifier(accessibilityIdentifier ?? "")
  }
}

extension GameDetailInfoCard {
  init(
    title: String,
    gradient: AnyGradient,
    size: Size = .regular,
    iconSystemName: String? = nil,
    iconVariableValue: Double? = nil,
    style: Display = .iconLabelValue,
    accessibilityIdentifier: String? = nil,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.title = title
    self.gradient = gradient
    self.size = size
    self.accessibilityIdentifier = accessibilityIdentifier
    self.iconSystemName = iconSystemName
    self.iconVariableValue = iconVariableValue
    self.style = style
    self.content = content
  }
}

extension GameDetailInfoCard {
  enum Size {
    case compact
    case regular

    var padding: CGFloat {
      switch self {
      case .compact: return DesignSystem.Spacing.sm
      case .regular: return DesignSystem.Spacing.md
      }
    }

    var contentFont: Font {
      switch self {
      case .compact:
        return .system(size: 16, weight: .semibold)
      case .regular:
        return .system(size: 18, weight: .semibold)
      }
    }
  }
}

extension GameDetailInfoCard where Content == _GameDetailInfoCardValueContent {
  init(
    title: String,
    value: String,
    gradient: AnyGradient,
    size: Size = .regular,
    iconSystemName: String? = nil,
    iconVariableValue: Double? = nil,
    style: Display = .iconLabelValue,
    accessibilityIdentifier: String? = nil
  ) {
    self.title = title
    self.gradient = gradient
    self.size = size
    self.accessibilityIdentifier = accessibilityIdentifier
    self.iconSystemName = iconSystemName
    self.iconVariableValue = iconVariableValue
    self.style = style
    self.content = {
      _GameDetailInfoCardValueContent(
        value: value
      )
    }
  }
}

struct _GameDetailInfoCardValueContent: View {
  let value: String

  var body: some View {
    Text(value)
      .foregroundStyle(.primary)
  }
}

extension GameDetailInfoCard {
  enum Display {
    case iconLabelValue
    case iconOnly
  }
}


