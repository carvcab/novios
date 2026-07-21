import Foundation
public struct SongModel: Identifiable, Codable {
    public let id: String
    public var title: String
    public var artist: String
    public var addedBy: String
    public init(id: String = UUID().uuidString, title: String, artist: String = "", addedBy: String = "") {
        self.id = id; self.title = title; self.artist = artist; self.addedBy = addedBy
    }
}
