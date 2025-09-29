import Foundation
import SwiftData

@MainActor
public protocol Repository {
  associatedtype ModelType: PersistentModel
  func insert(_ model: ModelType) throws
  func delete(_ model: ModelType) throws
  func save() throws
  func fetch(_ descriptor: FetchDescriptor<ModelType>) throws -> [ModelType]
  func first(_ descriptor: FetchDescriptor<ModelType>) throws -> ModelType?
  func count(_ descriptor: FetchDescriptor<ModelType>) throws -> Int
}

@MainActor
public struct SwiftDataRepository<T: PersistentModel>: Repository {
  public typealias ModelType = T
  public let context: ModelContext

  public init(context: ModelContext) {
    self.context = context
  }

  public func insert(_ model: ModelType) throws {
    context.insert(model)
  }

  public func delete(_ model: ModelType) throws {
    context.delete(model)
  }

  public func save() throws {
    try context.save()
  }

  public func fetch(_ descriptor: FetchDescriptor<ModelType>) throws -> [ModelType] {
    try context.fetch(descriptor)
  }

  public func first(_ descriptor: FetchDescriptor<ModelType>) throws -> ModelType? {
    try context.fetch(descriptor).first
  }

  public func count(_ descriptor: FetchDescriptor<ModelType>) throws -> Int {
    try context.fetchCount(descriptor)
  }
}
