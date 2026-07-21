import Foundation
public struct TodoItemModel: Identifiable, Codable {
    public let id: String
    public var title: String
    public var isDone: Bool
    public var createdBy: String
    public init(id: String = UUID().uuidString, title: String, isDone: Bool = false, createdBy: String = "") {
        self.id = id; self.title = title; self.isDone = isDone; self.createdBy = createdBy
    }
}
