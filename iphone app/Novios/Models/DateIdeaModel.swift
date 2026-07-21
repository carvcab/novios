import Foundation
public struct DateIdeaModel: Identifiable, Codable {
    public let id: String
    public var title: String
    public var description: String
    public var createdBy: String
    public init(id: String = UUID().uuidString, title: String, description: String = "", createdBy: String = "") {
        self.id = id; self.title = title; self.description = description; self.createdBy = createdBy
    }
}
