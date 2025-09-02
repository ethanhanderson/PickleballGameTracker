import CorePackage
import SwiftUI

@MainActor
struct AvatarView: View {
  enum Style {
    case card
    case detail
    case navigation

    var size: CGSize {
      switch self {
      case .card: return CGSize(width: 58, height: 58)
      case .detail: return CGSize(width: 60, height: 60)
      case .navigation: return CGSize(width: 38, height: 38)
      }
    }

    var contentSize: CGSize {
      switch self {
      case .card: return CGSize(width: 48, height: 48)
      case .detail: return CGSize(width: 40, height: 40)
      case .navigation: return CGSize(width: 16, height: 16)
      }
    }

    var symbolSize: CGFloat {
      switch self {
      case .card: return 28
      case .detail: return 28
      case .navigation: return 18
      }
    }

    var backgroundOpacity: Double {
      switch self {
      case .card: return 0.15
      case .detail: return 0.15
      case .navigation: return 0.25
      }
    }

    var shadowRadius: CGFloat {
      switch self {
      case .card: return 3
      case .detail: return 4
      case .navigation: return 2
      }
    }
  }

  let avatarImageData: Data?
  let iconSymbolName: String?
  let iconTintColor: DesignSystem.AppleSystemColor?
  let style: Style
  let isArchived: Bool

  init(
    avatarImageData: Data?,
    iconSymbolName: String?,
    iconTintColor: DesignSystem.AppleSystemColor?,
    style: Style = .card,
    isArchived: Bool = false
  ) {
    self.avatarImageData = avatarImageData
    self.iconSymbolName = iconSymbolName
    self.iconTintColor = iconTintColor
    self.style = style
    self.isArchived = isArchived
  }

  var body: some View {
    ZStack {
      // Background circle with gradient based on tint color
      Circle()
        .fill(
          backgroundColor.opacity(style.backgroundOpacity).gradient
        )
        .frame(width: style.size.width, height: style.size.height)

      // Avatar content
      Group {
        if let imageData = avatarImageData,
          let uiImage = UIImage(data: imageData)
        {
          Image(uiImage: uiImage)
            .resizable()
            .scaledToFill()
            .grayscale(isArchived ? 1.0 : 0.0)
            .clipShape(Circle())
            .overlay(
              Circle()
                .strokeBorder(
                  backgroundColor.opacity(0.3),
                  lineWidth: 2
                )
            )
        } else {
          let symbolName = iconSymbolName ?? "person.fill"
          let tintColor: DesignSystem.AppleSystemColor =
            isArchived ? .gray : (iconTintColor ?? .green)

          Image(systemName: symbolName)
            .font(.system(size: style.symbolSize, weight: .semibold))
            .foregroundStyle(tintColor.color.gradient)
            .shadow(
              color: tintColor.color.opacity(0.6),
              radius: style.shadowRadius
            )
        }
      }
      .frame(width: style.contentSize.width, height: style.contentSize.height)
    }
    .accessibilityHidden(true)
  }

  // Computed property to determine the background color
  private var backgroundColor: Color {
    if let imageData = avatarImageData, UIImage(data: imageData) != nil {
      // For photo avatars, use a neutral background
      return isArchived ? DesignSystem.Colors.paused : DesignSystem.Colors.primary
    } else {
      // For icon avatars, use the tint color
      let tintColor = isArchived ? DesignSystem.AppleSystemColor.gray : (iconTintColor ?? .green)
      return tintColor.color
    }
  }
}

// Convenience initializers for PlayerProfile and TeamProfile
extension AvatarView {
  init(player: PlayerProfile, style: Style = .card, isArchived: Bool = false) {
    self.init(
      avatarImageData: player.avatarImageData,
      iconSymbolName: player.iconSymbolName,
      iconTintColor: player.iconTintColor,
      style: style,
      isArchived: isArchived
    )
  }

  init(team: TeamProfile, style: Style = .card, isArchived: Bool = false) {
    self.init(
      avatarImageData: team.avatarImageData,
      iconSymbolName: team.iconSymbolName,
      iconTintColor: team.iconTintColor,
      style: style,
      isArchived: isArchived
    )
  }
}

#Preview("Card Style - Photo Avatar") {
  let sampleData = UIImage(systemName: "person.fill")?.pngData()
  return AvatarView(
    avatarImageData: sampleData,
    iconSymbolName: "person.fill",
    iconTintColor: .green,
    style: .card
  )
  .padding()
}

#Preview("Card Style - Icon Avatar") {
  AvatarView(
    avatarImageData: nil,
    iconSymbolName: "tennis.racket",
    iconTintColor: .blue,
    style: .card
  )
  .padding()
}

#Preview("Detail Style") {
  AvatarView(
    avatarImageData: nil,
    iconSymbolName: "figure.tennis",
    iconTintColor: .green,
    style: .detail
  )
  .padding()
}

#Preview("Navigation Style") {
  AvatarView(
    avatarImageData: nil,
    iconSymbolName: "medal.fill",
    iconTintColor: .purple,
    style: .navigation
  )
  .padding()
}

#Preview("Color Variations") {
  VStack(spacing: 20) {
    HStack(spacing: 20) {
      AvatarView(
        avatarImageData: nil,
        iconSymbolName: "star.fill",
        iconTintColor: .red,
        style: .card
      )
      AvatarView(
        avatarImageData: nil,
        iconSymbolName: "heart.fill",
        iconTintColor: .pink,
        style: .card
      )
    }
    HStack(spacing: 20) {
      AvatarView(
        avatarImageData: nil,
        iconSymbolName: "bolt.fill",
        iconTintColor: .orange,
        style: .card
      )
      AvatarView(
        avatarImageData: nil,
        iconSymbolName: "flame.fill",
        iconTintColor: .red,
        style: .card
      )
    }
  }
  .padding()
}
