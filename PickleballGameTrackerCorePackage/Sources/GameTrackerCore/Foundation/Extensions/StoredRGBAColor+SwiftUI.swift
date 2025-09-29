import SwiftUI
import CoreGraphics
#if canImport(UIKit)
import UIKit
#endif

public extension StoredRGBAColor {
  init(_ color: Color) {
    #if canImport(UIKit)
    let ui = UIColor(color)
    if let cg = ui.cgColor.converted(to: CGColorSpace(name: CGColorSpace.sRGB)!, intent: .defaultIntent, options: nil),
       let comps = cg.components, comps.count >= 3 {
      let a = comps.count >= 4 ? comps[3] : 1
      self.init(red: Float(comps[0]), green: Float(comps[1]), blue: Float(comps[2]), alpha: Float(a))
      return
    }
    #endif
    self.init(red: 0, green: 0, blue: 0, alpha: 1)
  }

  var swiftUIColor: Color {
    Color(.sRGB, red: Double(red), green: Double(green), blue: Double(blue), opacity: Double(alpha))
  }
}


