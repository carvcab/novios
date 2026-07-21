import Foundation
public struct LetterModel: Identifiable, Codable {
    public let id: String
    public var title: String
    public var content: String
    public var createdAt: Date
    public var createdBy: String
    public init(id: String = UUID().uuidString, title: String, content: String, createdAt: Date = Date(), createdBy: String = "") {
        self.id = id; self.title = title; self.content = content; self.createdAt = createdAt; self.createdBy = createdBy
    }
}
