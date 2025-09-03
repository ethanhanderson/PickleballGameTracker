import SwiftUI
import UIKit

@MainActor
struct CameraPicker: UIViewControllerRepresentable {
  @Binding var selectedImageData: Data?
  @Environment(\.dismiss) private var dismiss

  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.sourceType = .camera
    picker.cameraCaptureMode = .photo
    picker.cameraDevice = .rear
    picker.showsCameraControls = true
    picker.delegate = context.coordinator
    return picker
  }

  func updateUIViewController(
    _ uiViewController: UIImagePickerController,
    context: Context
  ) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, UIImagePickerControllerDelegate,
    UINavigationControllerDelegate
  {
    let parent: CameraPicker

    init(_ parent: CameraPicker) {
      self.parent = parent
    }

    func imagePickerController(
      _ picker: UIImagePickerController,
      didFinishPickingMediaWithInfo info: [UIImagePickerController
        .InfoKey: Any]
    ) {
      if let image = info[.originalImage] as? UIImage,
        let imageData = image.jpegData(compressionQuality: 0.8)
      {
        parent.selectedImageData = imageData
      }
      parent.dismiss()
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      parent.dismiss()
    }
  }
}


