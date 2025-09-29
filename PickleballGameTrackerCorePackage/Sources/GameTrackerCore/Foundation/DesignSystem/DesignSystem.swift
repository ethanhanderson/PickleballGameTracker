import SwiftUI

/// Main Design System enum containing all design tokens and utilities
///
/// This enum follows the Apple-first design system approach by:
/// - Using SwiftUI's built-in tokens for colors, typography, and materials
/// - Providing only scale tokens (spacing, corner radius) using generic names: xs, sm, md, lg, xl, xxl, xxxl
/// - Offering view modifiers that use these tokens for consistent layout patterns
///
/// Scale tokens provide consistent sizing without semantic meaning, allowing flexibility
/// in usage while maintaining visual consistency across the app.
///
/// Usage:
/// ```swift
/// // Use spacing scale tokens
/// VStack(spacing: DesignSystem.Spacing.md) { ... }
/// Text("Hello").padding(DesignSystem.Spacing.sm)
///
/// // Use corner radius scale tokens
/// RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
/// Button { }.cornerRadius(DesignSystem.CornerRadius.sm)
///
/// // Use view modifiers
/// Text("Hello").screenPadding().sectionSpacing()
/// ```
public enum DesignSystem {
    // MARK: - Spacing Tokens
    /// Spacing scale tokens (xs → xxxl)
    /// - xs=4, sm=8, md=16, lg=24, xl=32, xxl=48, xxxl=64
    public enum Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 32
        public static let xxl: CGFloat = 48
        public static let xxxl: CGFloat = 64
    }

    // MARK: - Corner Radius Tokens
    /// Corner radius scale tokens (xs → xxxl)
    /// - xs=4, sm=8, md=12, lg=16, xl=20, xxl=24, xxxl=32
    public enum CornerRadius {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 20
        public static let xxl: CGFloat = 24
        public static let xxxl: CGFloat = 32
    }
}
