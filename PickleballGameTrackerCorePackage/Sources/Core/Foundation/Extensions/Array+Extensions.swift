//
//  Array+Extensions.swift
//  SharedGameCore
//
//  Created by Ethan Anderson on 7/9/25.
//

import Foundation

extension Array {
  /// Splits the array into chunks of the specified size
  /// Used for batch operations in Core Data performance optimizations
  public func chunked(into size: Int) -> [[Element]] {
    return stride(from: 0, to: count, by: size).map {
      Array(self[$0..<Swift.min($0 + size, count)])
    }
  }
}

extension Collection {
  /// Returns the element at the specified index if it is within bounds, otherwise nil
  public subscript(safe index: Index) -> Element? {
    return indices.contains(index) ? self[index] : nil
  }
}
