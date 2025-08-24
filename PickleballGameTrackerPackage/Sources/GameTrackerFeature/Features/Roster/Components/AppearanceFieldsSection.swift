import PickleballGameTrackerCorePackage
import SwiftUI

@MainActor
struct AppearanceFieldsSection: View {
  @Binding var iconSymbolName: String
  @Binding var iconTintHex: String
  let symbolPlaceholder: String

  var body: some View {
    Section("Appearance (optional)") {
      TextField(symbolPlaceholder, text: $iconSymbolName)
      TextField("Icon tint hex (e.g., #34C759)", text: $iconTintHex)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
    }
  }
}
