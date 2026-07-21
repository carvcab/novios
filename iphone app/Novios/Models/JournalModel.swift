import Foundation
public struct JournalModel: Identifiable, Codable {
    public let id: String
    public var content: String
    public var date: Date
    public var createdBy: String
    public init(id: String = UUID().uuidString, content: String, date: Date = Date(), createdBy: String = "") {
        self.id = id; self.content = content; self.date = date; self.createdBy = createdBy
    }
}
