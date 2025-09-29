import SwiftUI

public extension View {
    /// Apply standard horizontal padding for screens
    func screenPadding(_ size: CGFloat = DesignSystem.Spacing.xl) -> some View {
        self.padding(.horizontal, size)
    }

    /// Apply vertical spacing between major sections
    func sectionSpacing(_ size: CGFloat = DesignSystem.Spacing.lg) -> some View {
        self.padding(.vertical, size)
    }

    /// Apply consistent header spacing
    func headerSpacing(_ size: CGFloat = DesignSystem.Spacing.xl) -> some View {
        self.padding(.top, size)
    }

    /// Apply consistent footer spacing
    func footerSpacing(_ size: CGFloat = DesignSystem.Spacing.xl) -> some View {
        self.padding(.bottom, size)
    }

    /// Apply semantic spacing between major sections
    func majorSectionSpacing(_ size: CGFloat = DesignSystem.Spacing.lg) -> some View {
        self.padding(.vertical, size)
    }

    /// Apply card gradient style
    func cardGradientStyle() -> some View {
        self.background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }

    /// Apply primary button style
    func primaryButton() -> some View {
        self.buttonStyle(.borderedProminent)
    }

    /// Apply secondary button style
    func secondaryButton() -> some View {
        self.buttonStyle(.bordered)
    }

    /// Apply brand navigation container background
    func viewContainerBackground(color: Color = Color.accentColor) -> some View {
        self.containerBackground(
            LinearGradient(
                stops: [
                    .init(color: color.opacity(0.65), location: 0.0),
                    .init(color: .clear, location: 0.23)
                ],
                startPoint: .top,
                endPoint: .bottom
            ),
            for: .navigation
        )
    }
}


