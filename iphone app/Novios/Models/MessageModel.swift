import Foundation

public enum MessageType: String, Codable {
    case text
    case image
    case audio
    case doodle
    case kiss
    case hug
    case touch
}

public struct MessageModel: Identifiable, Codable, Equatable {
    public var id: String
    public var senderId: String
    public var receiverId: String
    public var text: String?
    public var mediaUrl: String?
    public var type: MessageType
    public var timestamp: Date
    public var reactions: [String: String]? // [userId: emoji]
    public var isRead: Bool

    public init(
        id: String = UUID().uuidString,
        senderId: String,
        receiverId: String,
        text: String? = nil,
        mediaUrl: String? = nil,
        type: MessageType = .text,
        timestamp: Date = Date(),
        reactions: [String: String]? = nil,
        isRead: Bool = false
    ) {
        self.id = id
        self.senderId = senderId
        self.receiverId = receiverId
        self.text = text
        self.mediaUrl = mediaUrl
        self.type = type
        self.timestamp = timestamp
        self.reactions = reactions
        self.isRead = isRead
    }

    public func dictionaryRepresentation() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "senderId": senderId,
            "receiverId": receiverId,
            "type": type.rawValue,
            "timestamp": timestamp.timeIntervalSince1970,
            "isRead": isRead
        ]
        if let text = text { dict["text"] = text }
        if let mediaUrl = mediaUrl { dict["mediaUrl"] = mediaUrl }
        if let reactions = reactions { dict["reactions"] = reactions }
        return dict
    }
}
