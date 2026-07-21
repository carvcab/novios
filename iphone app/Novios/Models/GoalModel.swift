import Foundation
public struct GoalModel: Identifiable, Codable {
    public let id: String
    public var title: String
    public var isCompleted: Bool
    public var createdBy: String
    public init(id: String = UUID().uuidString, title: String, isCompleted: Bool = false, createdBy: String = "") {
        self.id = id; self.title = title; self.isCompleted = isCompleted; self.createdBy = createdBy
    }
}
