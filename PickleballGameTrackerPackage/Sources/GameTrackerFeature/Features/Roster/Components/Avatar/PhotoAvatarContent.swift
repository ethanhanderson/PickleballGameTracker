import CorePackage
import PhotosUI
import SwiftUI
import UIKit

@MainActor
struct PhotoAvatarContent: View {
  @Binding var selectedPhotoData: Data?
  @Binding var selectedPhotoItem: PhotosPickerItem?
  @Binding var showingCamera: Bool

  var body: some View {
    HStack {
      Spacer()
      Group {
        if let photoData = selectedPhotoData, let uiImage = UIImage(data: photoData) {
          Image(uiImage: uiImage)
            .resizable()
            .scaledToFill()
            .frame(width: 96, height: 96)
            .clipShape(Circle())
            .overlay(
              Circle().stroke(DesignSystem.Colors.surfaceSecondary.opacity(0.3), lineWidth: 2)
            )
            .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 4)
            .transition(.opacity)
        } else {
          Circle()
            .fill(DesignSystem.Colors.surfaceSecondary.opacity(0.3))
            .frame(width: 96, height: 96)
            .overlay(
              Image(systemName: "photo.fill")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(DesignSystem.Colors.textSecondary.opacity(0.6))
            )
            .transition(.opacity)
        }
      }
      .animation(.easeInOut(duration: 0.15), value: selectedPhotoData)
      .accessibilityLabel("Photo preview")
      Spacer()
    }

    if selectedPhotoData != nil {
      Button(action: {
        selectedPhotoData = nil
        selectedPhotoItem = nil
      }) {
        HStack {
          Image(systemName: "trash.fill")
            .foregroundStyle(.red)
          Text("Remove Photo")
            .foregroundStyle(.red)
          Spacer()
        }
      }
      .accessibilityLabel("Remove selected photo")
    }

    let buttonTitle = (selectedPhotoData != nil) ? "Change Photo" : "Choose Photo"
    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
      HStack {
        Image(systemName: "photo.badge.plus.fill")
        Text(buttonTitle)
        Spacer()
        Image(systemName: "chevron.right")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(DesignSystem.Colors.textSecondary)
      }
      .foregroundStyle(DesignSystem.Colors.textPrimary)
    }
    .accessibilityLabel("Select photo for avatar")
    .onChange(of: selectedPhotoItem, initial: false) { _, newItem in
      if let newItem = newItem {
        Task {
          if let data = try? await newItem.loadTransferable(type: Data.self),
             let image = UIImage(data: data),
             let resizedData = image.jpegData(compressionQuality: 0.8) {
            await MainActor.run { selectedPhotoData = resizedData }
          }
        }
      } else {
        selectedPhotoData = nil
      }
    }

    Button(action: { showingCamera = true }) {
      HStack {
        Image(systemName: "camera.viewfinder")
        Text("Take Photo")
        Spacer()
        Image(systemName: "chevron.right")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(DesignSystem.Colors.textSecondary)
      }
      .foregroundStyle(DesignSystem.Colors.textPrimary)
    }
    .accessibilityLabel("Take photo with camera")
  }
}


