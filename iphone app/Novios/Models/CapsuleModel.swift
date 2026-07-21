import Foundation
public struct CapsuleModel: Identifiable, Codable {
    public let id: String
    public var title: String
    public var content: String
    public var openDate: Date
    public var createdBy: String
    public init(id: String = UUID().uuidString, title: String, content: String = "", openDate: Date = Date(), createdBy: String = "") {
        self.id = id; self.title = title; self.content = content; self.openDate = openDate; self.createdBy = createdBy
    }
}
