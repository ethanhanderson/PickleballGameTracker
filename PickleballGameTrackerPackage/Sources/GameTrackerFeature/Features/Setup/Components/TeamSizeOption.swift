import Foundation

struct TeamSizeOption: Identifiable {
  let id: Int
  let size: Int
  let displayName: String
  let description: String

  init(size: Int, displayName: String, description: String) {
    self.id = size
    self.size = size
    self.displayName = displayName
    self.description = description
  }
}


