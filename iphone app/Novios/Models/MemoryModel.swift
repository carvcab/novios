import Foundation
public struct MemoryModel: Identifiable, Codable {
    public let id: String
    public var title: String
    public var description: String
    public var date: Date
    public var createdBy: String
    public var mediaUrl: String?
    public init(id: String = UUID().uuidString, title: String, description: String = "", date: Date = Date(), createdBy: String = "", mediaUrl: String? = nil) {
        self.id = id; self.title = title; self.description = description; self.date = date; self.createdBy = createdBy; self.mediaUrl = mediaUrl
    }
}
