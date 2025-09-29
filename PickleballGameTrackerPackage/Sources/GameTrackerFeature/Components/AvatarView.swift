import GameTrackerCore
import SwiftUI

/// A flexible avatar view that displays either a photo or icon with customizable styling and accessibility.
///
/// AvatarView supports two display modes:
/// - **Photo avatars**: Display user-uploaded images without background circles for a clean, direct appearance
/// - **Icon avatars**: Display SF Symbols with colored background circles and shadows
///
/// ## Usage Examples
///
/// ### Basic Configuration
/// ```swift
/// // Icon avatar
/// AvatarView(configuration: .init(symbolName: "person.fill", tintColor: .blue, style: .card))
///
/// // Photo avatar
/// AvatarView(configuration: .init(imageData: photoData, style: .card))
/// ```
///
/// ### Using Convenience Initializers
/// ```swift
/// // From PlayerProfile
/// AvatarView(player: playerProfile, style: .small)
///
/// // From TeamProfile
/// AvatarView(team: teamProfile, style: .detail)
///
/// // Legacy style (still supported)
/// AvatarView(avatarImageData: data, iconSymbolName: "star.fill", iconTintColor: .blue, style: .card)
/// ```
@MainActor
struct AvatarView: View {
  /// The configuration defining how this avatar should be displayed.
  let configuration: Configuration

  /// Creates an avatar view with the specified configuration.
  /// - Parameter configuration: The display configuration for this avatar.
  init(configuration: Configuration) {
    self.configuration = configuration
  }

  var body: some View {
    Group {
      if let imageData = configuration.imageData {
        PhotoAvatar(imageData: imageData, configuration: configuration)
      } else {
        IconAvatar(configuration: configuration)
      }
    }
    .accessibilityLabel(accessibilityLabel)
    .accessibilityHidden(configuration.isDecorative)
  }

  private var accessibilityLabel: String {
    if configuration.isDecorative { return "" }
    return configuration.imageData != nil ? "Profile photo" : "Profile icon"
  }
}

// MARK: - Configuration

extension AvatarView {
  /// Configuration options for customizing avatar appearance and behavior.
  ///
  /// The configuration supports both photo and icon display modes. When `imageData` is provided,
  /// the avatar displays as a photo without background. When `imageData` is `nil`, it displays
  /// as an icon with a colored background circle.
  struct Configuration {
    /// Image data for photo avatars. When provided, displays as a photo without background circle.
    let imageData: Data?

    /// SF Symbol name for icon avatars. Defaults to "person.fill" when nil.
    let symbolName: String?

    /// Tint color for icon avatars. Affects both icon color and background circle color.
    let tintColor: Color?

    /// Visual style determining size and appearance.
    let style: Style

    /// Whether this avatar represents archived content, affecting grayscale and color treatment.
    let isArchived: Bool

    /// Whether this avatar is purely decorative and should be hidden from accessibility.
    let isDecorative: Bool

    /// Creates a new avatar configuration.
    ///
    /// - Parameters:
    ///   - imageData: Image data for photo display. When provided, overrides icon display.
    ///   - symbolName: SF Symbol name for icon display. Ignored when `imageData` is provided.
    ///   - tintColor: Color for icon and background. Defaults to `.green` when nil.
    ///   - style: Size and visual style. Defaults to `.card`.
    ///   - isArchived: Whether content is archived. Defaults to `false`.
    ///   - isDecorative: Whether avatar is decorative for accessibility. Defaults to `true`.
    init(
      imageData: Data? = nil,
      symbolName: String? = nil,
      tintColor: Color? = nil,
      style: Style = .card,
      isArchived: Bool = false,
      isDecorative: Bool = true
    ) {
      self.imageData = imageData
      self.symbolName = symbolName
      self.tintColor = tintColor
      self.style = style
      self.isArchived = isArchived
      self.isDecorative = isDecorative
    }
  }
}

// MARK: - Style

extension AvatarView {
  /// Available visual styles for avatar sizing and appearance.
  ///
  /// Each style defines specific dimensions, symbol sizes, and visual effects
  /// that work well in different UI contexts.
  enum Style: Hashable {
    /// Standard card style (58x58pt) - used in profile cards and lists.
    case card

    /// Detailed view style (60x60pt) - used in detailed profile views.
    case detail

    /// Compact style (38x38pt) - used in navigation bars and compact layouts.
    case small

    /// The total size of the avatar circle.
    var size: CGSize {
      switch self {
      case .card: CGSize(width: 58, height: 58)
      case .detail: CGSize(width: 60, height: 60)
      case .small: CGSize(width: 38, height: 38)
      }
    }

    /// Size of the content area for icon avatars (smaller than total size to accommodate background).
    var contentSize: CGSize {
      switch self {
      case .card: CGSize(width: 48, height: 48)
      case .detail: CGSize(width: 40, height: 40)
      case .small: CGSize(width: 16, height: 16)
      }
    }

    /// Font size for SF Symbols in icon avatars.
    var symbolSize: CGFloat {
      switch self {
      case .card, .detail: 28
      case .small: 18
      }
    }

    /// Opacity for background circles in icon avatars.
    var backgroundOpacity: Double {
      switch self {
      case .card, .detail: 0.15
      case .small: 0.25
      }
    }

    /// Shadow radius for icon avatars.
    var shadowRadius: CGFloat {
      switch self {
      case .card: 3
      case .detail: 4
      case .small: 2
      }
    }
  }
}

// MARK: - Photo Avatar

/// Private view for rendering photo avatars without background circles.
private struct PhotoAvatar: View {
  let imageData: Data
  let configuration: AvatarView.Configuration

  var body: some View {
    if let uiImage = UIImage(data: imageData) {
      Image(uiImage: uiImage)
        .resizable()
        .scaledToFill()
        .grayscale(configuration.isArchived ? 1.0 : 0.0)
        .frame(width: configuration.style.size.width, height: configuration.style.size.height)
        .clipShape(.circle)
    } else {
      // Fallback to icon if image data is invalid
      IconAvatar(configuration: configuration)
    }
  }
}

// MARK: - Icon Avatar

/// Private view for rendering icon avatars with colored background circles.
private struct IconAvatar: View {
  let configuration: AvatarView.Configuration

  var body: some View {
    ZStack {
      Circle()
        .fill(backgroundColor.opacity(configuration.style.backgroundOpacity).gradient)

      Image(systemName: symbolName)
        .font(.system(size: configuration.style.symbolSize, weight: .semibold))
        .foregroundStyle(tintColor.gradient)
        .shadow(color: tintColor.opacity(0.6), radius: configuration.style.shadowRadius)
    }
    .frame(width: configuration.style.size.width, height: configuration.style.size.height)
  }

  private var symbolName: String {
    configuration.symbolName ?? "person.fill"
  }

  private var tintColor: Color {
    if configuration.isArchived {
      .gray
    } else {
      configuration.tintColor ?? .green
    }
  }

  private var backgroundColor: Color {
    tintColor
  }
}

// MARK: - Convenience Initializers

extension AvatarView {
  /// Creates an avatar view with individual parameters (legacy style, still supported).
  ///
  /// This initializer is provided for backwards compatibility and ease of use in simple cases.
  /// For more complex configurations, use `AvatarView(configuration:)` instead.
  ///
  /// - Parameters:
  ///   - avatarImageData: Image data for photo display. When provided, overrides icon display.
  ///   - iconSymbolName: SF Symbol name for icon display.
  ///   - iconTintColor: Color for icon and background.
  ///   - style: Visual style. Defaults to `.card`.
  ///   - isArchived: Whether content is archived. Defaults to `false`.
  ///   - isDecorative: Whether avatar is decorative for accessibility. Defaults to `true`.
  init(
    avatarImageData: Data?,
    iconSymbolName: String?,
    iconTintColor: Color?,
    style: Style = .card,
    isArchived: Bool = false,
    isDecorative: Bool = true
  ) {
    let configuration = Configuration(
      imageData: avatarImageData,
      symbolName: iconSymbolName,
      tintColor: iconTintColor,
      style: style,
      isArchived: isArchived,
      isDecorative: isDecorative
    )
    self.init(configuration: configuration)
  }

  /// Creates an avatar view from a PlayerProfile.
  ///
  /// Automatically uses the player's avatar image, icon, and color settings.
  /// The archived state is determined by combining the parameter and profile's archived state.
  ///
  /// - Parameters:
  ///   - player: The player profile to display.
  ///   - style: Visual style override. Defaults to `.card`.
  ///   - isArchived: Additional archived state (combined with profile's state).
  init(player: PlayerProfile, style: Style = .card, isArchived: Bool = false) {
    self.init(
      avatarImageData: player.avatarImageData,
      iconSymbolName: player.iconSymbolName,
      iconTintColor: player.iconTintColorValue,
      style: style,
      isArchived: isArchived || player.isArchived
    )
  }

  /// Creates an avatar view from a TeamProfile.
  ///
  /// Automatically uses the team's avatar image, icon, and color settings.
  /// The archived state is determined by combining the parameter and profile's archived state.
  ///
  /// - Parameters:
  ///   - team: The team profile to display.
  ///   - style: Visual style override. Defaults to `.card`.
  ///   - isArchived: Additional archived state (combined with profile's state).
  init(team: TeamProfile, style: Style = .card, isArchived: Bool = false) {
    self.init(
      avatarImageData: team.avatarImageData,
      iconSymbolName: team.iconSymbolName,
      iconTintColor: team.iconTintColorValue,
      style: style,
      isArchived: isArchived || team.isArchived
    )
  }
}

#Preview("Icon Avatars") {
  VStack(spacing: 20) {
    HStack(spacing: 20) {
      AvatarView(configuration: .init(symbolName: "star.fill", tintColor: .blue, style: .small))
      AvatarView(configuration: .init(symbolName: "person.fill", tintColor: .green, style: .card))
      AvatarView(configuration: .init(symbolName: "trophy.fill", tintColor: .orange, style: .detail))
    }
    .padding()

    Text("Archived Icon Avatars")
      .font(.headline)

    HStack(spacing: 20) {
      AvatarView(configuration: .init(symbolName: "star.fill", tintColor: .blue, style: .small, isArchived: true))
      AvatarView(configuration: .init(symbolName: "person.fill", tintColor: .green, style: .card, isArchived: true))
      AvatarView(configuration: .init(symbolName: "trophy.fill", tintColor: .orange, style: .detail, isArchived: true))
    }
    .padding()
  }
}

#Preview("Photo Avatars") {
  VStack(spacing: 20) {
    HStack(spacing: 20) {
      AvatarView(configuration: .init(imageData: sampleImageData(), tintColor: .blue, style: .small))
      AvatarView(configuration: .init(imageData: sampleImageData(), tintColor: .green, style: .card))
      AvatarView(configuration: .init(imageData: sampleImageData(), tintColor: .orange, style: .detail))
    }
    .padding()

    Text("Archived Photo Avatars")
      .font(.headline)

    HStack(spacing: 20) {
      AvatarView(configuration: .init(imageData: sampleImageData(), tintColor: .blue, style: .small, isArchived: true))
      AvatarView(configuration: .init(imageData: sampleImageData(), tintColor: .green, style: .card, isArchived: true))
      AvatarView(configuration: .init(imageData: sampleImageData(), tintColor: .orange, style: .detail, isArchived: true))
    }
    .padding()
  }
}

#Preview("All Styles Comparison") {
  VStack(spacing: 16) {
    ForEach([AvatarView.Style.small, .card, .detail], id: \.self) { style in
      HStack(spacing: 16) {
        AvatarView(configuration: .init(symbolName: "person.fill", tintColor: .blue, style: style))
        AvatarView(configuration: .init(imageData: sampleImageData(), tintColor: .green, style: style))

        Text(styleDescription(for: style))
          .font(.caption)
          .frame(width: 60, alignment: .leading)
      }
    }
  }
  .padding()
}

#Preview("Convenience Initializers") {
  VStack(spacing: 16) {
    HStack(spacing: 16) {
      // Using legacy convenience initializer (still works)
      AvatarView(
        avatarImageData: nil,
        iconSymbolName: "person.fill",
        iconTintColor: .blue,
        style: .card
      )

      // Using new configuration initializer
      AvatarView(configuration: .init(symbolName: "star.fill", tintColor: .orange, style: .card))
    }

    Text("Dynamic Configuration")
      .font(.headline)

    HStack(spacing: 16) {
      // Non-decorative avatar with accessibility
      AvatarView(configuration: .init(symbolName: "person.fill", tintColor: .green, style: .card, isDecorative: false))

      // With custom configuration
      AvatarView(configuration: .init(
        imageData: sampleImageData(),
        symbolName: "star.fill",
        tintColor: .purple,
        style: .detail,
        isArchived: false,
        isDecorative: true
      ))
    }
  }
  .padding()
}

/// Creates sample image data for preview purposes.
private func sampleImageData() -> Data? {
  let size = CGSize(width: 100, height: 100)
  UIGraphicsBeginImageContextWithOptions(size, false, 0)
  defer { UIGraphicsEndImageContext() }

  guard let context = UIGraphicsGetCurrentContext() else { return nil }

  let colors = [
    UIColor.systemBlue.cgColor,
    UIColor.systemGreen.cgColor
  ] as CFArray

  let colorSpace = CGColorSpaceCreateDeviceRGB()
  let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1])!

  context.drawLinearGradient(
    gradient,
    start: CGPoint(x: 0, y: 0),
    end: CGPoint(x: size.width, y: size.height),
    options: []
  )

  UIColor.white.setStroke()
  context.setLineWidth(3)
  context.strokeEllipse(in: CGRect(x: 20, y: 20, width: 60, height: 60))

  guard let image = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
  return image.pngData()
}

/// Returns a human-readable description of an avatar style for preview labels.
private func styleDescription(for style: AvatarView.Style) -> String {
  switch style {
  case .small: "Small"
  case .card: "Card"
  case .detail: "Detail"
  }
}
