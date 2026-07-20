import Foundation

public struct EventModel: Identifiable, Codable, Equatable {
    public var id: String
    public var title: String
    public var notes: String?
    public var eventDate: Date
    public var location: String?
    public var createdBy: String
    public var category: String

    public init(
        id: String = UUID().uuidString,
        title: String,
        notes: String? = nil,
        eventDate: Date,
        location: String? = nil,
        createdBy: String,
        category: String = "Cita"
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.eventDate = eventDate
        self.location = location
        self.createdBy = createdBy
        self.category = category
    }
}

public struct CapsuleModel: Identifiable, Codable, Equatable {
    public var id: String
    public var title: String
    public var message: String
    public var imageUrl: String?
    public var createdDate: Date
    public var unlockDate: Date
    public var authorId: String

    public init(
        id: String = UUID().uuidString,
        title: String,
        message: String,
        imageUrl: String? = nil,
        createdDate: Date = Date(),
        unlockDate: Date,
        authorId: String
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.imageUrl = imageUrl
        self.createdDate = createdDate
        self.unlockDate = unlockDate
        self.authorId = authorId
    }

    public var isUnlocked: Bool {
        return Date() >= unlockDate
    }
}

public struct GoalModel: Identifiable, Codable, Equatable {
    public var id: String
    public var title: String
    public var description: String?
    public var isCompleted: Bool
    public var targetDate: Date?
    public var createdBy: String

    public init(
        id: String = UUID().uuidString,
        title: String,
        description: String? = nil,
        isCompleted: Bool = false,
        targetDate: Date? = nil,
        createdBy: String
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.isCompleted = isCompleted
        self.targetDate = targetDate
        self.createdBy = createdBy
    }
}
