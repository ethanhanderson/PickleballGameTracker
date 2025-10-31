import Foundation

public struct StoredRGBAColor: Codable, Sendable, Equatable {
  public var red: Float
  public var green: Float
  public var blue: Float
  public var alpha: Float

  public init(red: Float, green: Float, blue: Float, alpha: Float = 1) {
    self.red = red
    self.green = green
    self.blue = blue
    self.alpha = alpha
  }

  public static func fromSeed(_ seed: UUID) -> StoredRGBAColor {
    let scalars = seed.uuidString.unicodeScalars.map { UInt32($0.value) }
    let rBase = scalars.enumerated().reduce(UInt32(0)) { acc, item in acc &+ (item.element &* UInt32(31 &+ item.offset)) }
    let gBase = scalars.enumerated().reduce(UInt32(17)) { acc, item in acc &+ (item.element &* UInt32(19 &+ item.offset)) }
    let bBase = scalars.enumerated().reduce(UInt32(23)) { acc, item in acc &+ (item.element &* UInt32(13 &+ item.offset)) }
    let r = Float((rBase % 200) + 30) / 255.0
    let g = Float((gBase % 200) + 30) / 255.0
    let b = Float((bBase % 200) + 30) / 255.0
    return StoredRGBAColor(red: r, green: g, blue: b, alpha: 1)
  }
}


