import CorePackage
import SwiftUI

@MainActor
struct IconAvatarContent: View {
  @Binding var selectedIconName: String
  @Binding var selectedIconColor: DesignSystem.AppleSystemColor
  let iconOptions: [String]

  var body: some View {
    VStack(alignment: .center, spacing: DesignSystem.Spacing.lg) {
      Group {
        if !selectedIconName.isEmpty {
          Image(systemName: selectedIconName)
            .font(.system(size: 44, weight: .semibold))
            .foregroundStyle(selectedIconColor.color)
            .shadow(color: selectedIconColor.color.opacity(0.6), radius: 3)
            .transition(.opacity)
        } else {
          Image(systemName: "person.fill")
            .font(.system(size: 44, weight: .semibold))
            .foregroundStyle(DesignSystem.Colors.primary.gradient)
            .shadow(color: DesignSystem.Colors.primary.opacity(0.6), radius: 3)
            .transition(.opacity)
        }
      }
      .animation(.easeInOut(duration: 0.15), value: selectedIconName)
      .animation(.easeInOut(duration: 0.15), value: selectedIconColor)
      .frame(width: 96, height: 96)
      .background(
        Circle()
          .fill(
            selectedIconName.isEmpty
              ? DesignSystem.Colors.primary.opacity(0.15).gradient
              : selectedIconColor.color.opacity(0.15).gradient
          )
          .transition(.opacity)
          .animation(.easeInOut(duration: 0.15), value: selectedIconColor)
      )
      .accessibilityLabel("Icon preview")

      VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
        Text("Icon")
          .font(DesignSystem.Typography.body)
          .fontWeight(.semibold)
          .foregroundStyle(DesignSystem.Colors.textPrimary)

        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: DesignSystem.Spacing.md) {
            ForEach(iconOptions, id: \.self) { iconName in
              ZStack {
                Circle()
                  .fill(
                    selectedIconName == iconName
                      ? selectedIconColor.color.opacity(0.2)
                      : DesignSystem.Colors.surfaceSecondary.opacity(0.3)
                  )
                  .frame(width: 46, height: 46)

                Image(systemName: iconName)
                  .resizable()
                  .scaledToFit()
                  .frame(width: 22, height: 22)
                  .foregroundStyle(
                    selectedIconName == iconName
                      ? selectedIconColor.color
                      : DesignSystem.Colors.textSecondary
                  )
              }
              .overlay(
                selectedIconName == iconName
                  ? Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 46, height: 46)
                    .overlay(
                      Image(systemName: "checkmark")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(selectedIconColor.color.opacity(0.8))
                    )
                    .transition(.scale.combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.12), value: selectedIconName)
                  : nil
              )
              .onTapGesture { selectedIconName = iconName }
              .accessibilityLabel("Select \(iconName) icon")
              .accessibilityAddTraits(selectedIconName == iconName ? .isSelected : [])
            }
          }
        }
      }

      VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
        Text("Color")
          .font(DesignSystem.Typography.body)
          .fontWeight(.semibold)
          .foregroundStyle(DesignSystem.Colors.textPrimary)

        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: DesignSystem.Spacing.md) {
            ForEach(DesignSystem.AppleSystemColor.allCases, id: \.self) { color in
              ZStack {
                Circle()
                  .fill(color.color)
                  .frame(width: 46, height: 46)
                  .overlay(
                    selectedIconColor == color
                      ? Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 46, height: 46)
                        .overlay(
                          Image(systemName: "checkmark")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(selectedIconColor.color.opacity(0.8))
                        )
                        .transition(.scale.combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.12), value: selectedIconColor)
                      : nil
                  )
              }
              .onTapGesture { selectedIconColor = color }
              .accessibilityLabel("Select \(color.displayName) color")
              .accessibilityAddTraits(selectedIconColor == color ? .isSelected : [])
            }
          }
        }
      }
    }
  }
}


