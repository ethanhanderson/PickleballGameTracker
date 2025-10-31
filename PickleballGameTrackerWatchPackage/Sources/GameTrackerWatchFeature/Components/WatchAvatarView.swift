import SwiftUI

/// A lightweight avatar view tailored for watchOS.
///
/// This implementation focuses on icon-based avatars for reliability on watchOS
/// and small-screen clarity. Photo avatars can be added later if needed.
struct WatchAvatarView: View {
    struct Configuration: Hashable {
        let symbolName: String
        let tintColor: Color
        let style: Style

        init(symbolName: String = "person.fill", tintColor: Color = .green, style: Style = .card) {
            self.symbolName = symbolName
            self.tintColor = tintColor
            self.style = style
        }
    }

    enum Style: Hashable {
        case card
        case small
        case mini

        var size: CGSize {
            switch self {
            case .card: return CGSize(width: 44, height: 44)
            case .small: return CGSize(width: 34, height: 34)
            case .mini: return CGSize(width: 22, height: 22)
            }
        }

        var symbolSize: CGFloat {
            switch self {
            case .card: return 22
            case .small: return 16
            case .mini: return 12
            }
        }

        var backgroundOpacity: Double {
            switch self {
            case .card: return 0.18
            case .small: return 0.22
            case .mini: return 0.25
            }
        }

        var shadowRadius: CGFloat {
            switch self {
            case .card: return 2
            case .small: return 1.5
            case .mini: return 1
            }
        }
    }

    let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(configuration.tintColor.opacity(configuration.style.backgroundOpacity).gradient)

            Image(systemName: configuration.symbolName)
                .font(.system(size: configuration.style.symbolSize, weight: .semibold))
                .foregroundStyle(configuration.tintColor.gradient)
                .shadow(color: configuration.tintColor.opacity(0.5), radius: configuration.style.shadowRadius)
        }
        .frame(width: configuration.style.size.width, height: configuration.style.size.height)
        .accessibilityHidden(true)
    }
}


