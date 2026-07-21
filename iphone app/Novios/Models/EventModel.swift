import Foundation
public struct EventModel: Identifiable, Codable {
    public let id: String
    public var title: String
    public var date: Date
    public var createdBy: String
    public init(id: String = UUID().uuidString, title: String, date: Date = Date(), createdBy: String = "") {
        self.id = id; self.title = title; self.date = date; self.createdBy = createdBy
    }
}
