import Foundation

public struct MessageModel: Identifiable, Codable, Equatable {
    public let id: String
    public var senderId: String
    public var text: String?
    public var timestamp: Date
    public var type: MessageType
    public var isDisappearing: Bool
    public var disappearDurationSeconds: Int
    public var readTimestamp: Date?
    public var scheduledTime: Date?
    public var letterTitle: String?
    public var voiceNotePath: String?
    public var videoMessagePath: String?
    public var mediaUrl: String?
    public var giftId: String?
    public var replyToId: String?
    public var replyToText: String?
    public var replyToSenderId: String?
    public var reactions: [String: String]?

    public init(id: String, senderId: String, text: String?, timestamp: Date, type: MessageType = .text,
                isDisappearing: Bool = false, disappearDurationSeconds: Int = 0,
                readTimestamp: Date? = nil, scheduledTime: Date? = nil,
                letterTitle: String? = nil, voiceNotePath: String? = nil,
                videoMessagePath: String? = nil, mediaUrl: String? = nil,
                giftId: String? = nil, replyToId: String? = nil,
                replyToText: String? = nil, replyToSenderId: String? = nil,
                reactions: [String: String]? = nil) {
        self.id = id; self.senderId = senderId; self.text = text; self.timestamp = timestamp
        self.type = type; self.isDisappearing = isDisappearing
        self.disappearDurationSeconds = disappearDurationSeconds; self.readTimestamp = readTimestamp
        self.scheduledTime = scheduledTime; self.letterTitle = letterTitle
        self.voiceNotePath = voiceNotePath; self.videoMessagePath = videoMessagePath
        self.mediaUrl = mediaUrl; self.giftId = giftId; self.replyToId = replyToId
        self.replyToText = replyToText; self.replyToSenderId = replyToSenderId
        self.reactions = reactions
    }

    public var isVisible: Bool {
        if !isDisappearing { return true }
        guard let read = readTimestamp else { return true }
        return Date().timeIntervalSince(read) < Double(disappearDurationSeconds)
    }
}

public enum MessageType: String, Codable {
    case text, image, voice, video, gift, letter, kiss, hug, touch, disappearing
}
