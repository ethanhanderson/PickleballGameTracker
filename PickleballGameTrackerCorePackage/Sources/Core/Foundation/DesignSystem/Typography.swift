import SwiftUI

public extension DesignSystem {
    enum Typography {
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
        public static let scoreDisplay = Font.system(
            size: 72,
            weight: .bold,
            design: .rounded
        )
        public static let scoreLarge = Font.system(
            size: 48,
            weight: .bold,
            design: .rounded
        )
        public static let scoreMedium = Font.system(
            size: 36,
            weight: .bold,
            design: .rounded
        )
        public static let scoreSmall = Font.system(
            size: 24,
            weight: .bold,
            design: .rounded
        )

        // Buttons
        public static let buttonPrimary = Font.headline.weight(.semibold)
        public static let buttonSecondary = Font.subheadline.weight(.medium)
        public static let buttonLarge = Font.title2.weight(.semibold)
    }
}


