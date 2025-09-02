import SwiftUI

public extension View {
    /// Apply card gradient background with rounded corners
    func cardGradientBackground(
        cornerRadius: CGFloat = DesignSystem.CornerRadius.cardRounded,
        highlighted: Bool = false
    ) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    highlighted
                        ? DesignSystem.Colors.cardGradientHighlight
                        : DesignSystem.Colors.cardGradient
                )
        )
    }

    /// Apply card gradient style with padding and background
    func cardGradientStyle(
        padding: CGFloat = DesignSystem.Spacing.cardPadding,
        cornerRadius: CGFloat = DesignSystem.CornerRadius.cardRounded,
        highlighted: Bool = false
    ) -> some View {
        self
            .padding(padding)
            .cardGradientBackground(
                cornerRadius: cornerRadius,
                highlighted: highlighted
            )
    }

    func primaryButton(isDisabled: Bool = false) -> some View {
        self.buttonStyle(.borderedProminent)
            .disabled(isDisabled)
            .controlSize(.large)
    }

    func secondaryButton(color: Color = DesignSystem.Colors.secondary)
        -> some View
    {
        self.buttonStyle(.bordered)
            .tint(color)
            .controlSize(.large)
    }

    func actionButton(
        color: Color = DesignSystem.Colors.primary,
        size: CGFloat = 44
    )
        -> some View
    {
        self.buttonStyle(.borderedProminent)
            .buttonBorderShape(.circle)
            .tint(color)
            .controlSize(size > 50 ? .large : .regular)
    }

    func cardButton(
        color: Color = DesignSystem.Colors.primary,
        isSelected: Bool = false
    )
        -> some View
    {
        self.buttonStyle(.plain)
            .tint(color)
            .controlSize(.large)
            .background(color.opacity(0.1))
            .cornerRadius(DesignSystem.CornerRadius.lg)
    }

    func compactButton(
        color: Color = DesignSystem.Colors.primary,
        prominent: Bool = false
    ) -> some View {
        self.buttonStyle(.plain)
            .tint(color)
            .controlSize(.small)
            .background(color.opacity(0.1))
            .cornerRadius(DesignSystem.CornerRadius.sm)
    }

    func sectionSpacing() -> some View {
        self.padding(.vertical, DesignSystem.Spacing.sectionSpacing)
    }

    func screenPadding() -> some View {
        self.padding(.horizontal, DesignSystem.Spacing.screenPadding)
    }

    /// Apply semantic section layout
    func sectionLayout(
        title: String? = nil,
        subtitle: String? = nil,
        icon: String? = nil
    ) -> some View {
        SectionContainer(title: title, subtitle: subtitle, icon: icon) {
            self
        }
    }

    /// Apply info card styling
    func infoCard(
        title: String? = nil,
        icon: String? = nil,
        style: InfoCard<Self>.InfoCardStyle = .info
    ) -> some View {
        InfoCard(title: title, icon: icon, style: style) {
            self
        }
    }

    /// Apply consistent header spacing
    func headerSpacing() -> some View {
        self.padding(.top, DesignSystem.Spacing.xl)
    }

    /// Apply consistent footer spacing
    func footerSpacing() -> some View {
        self.padding(.bottom, DesignSystem.Spacing.xl)
    }

    /// Apply semantic spacing between major sections
    func majorSectionSpacing() -> some View {
        self.padding(.vertical, DesignSystem.Spacing.lg)
    }

    /// Apply global navigation tint color for back buttons and navigation elements
    func navigationTint() -> some View {
        self.tint(DesignSystem.Colors.navigationTintColor)
    }
}


