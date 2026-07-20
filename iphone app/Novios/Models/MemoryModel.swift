import Foundation

public struct MemoryModel: Identifiable, Codable, Equatable {
    public var id: String
    public var title: String
    public var description: String?
    public var imageUrl: String
    public var date: Date
    public var category: String
    public var isFavorite: Bool
    public var createdBy: String

    public init(
        id: String = UUID().uuidString,
        title: String,
        description: String? = nil,
        imageUrl: String,
        date: Date = Date(),
        category: String = "Especial",
        isFavorite: Bool = false,
        createdBy: String
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.imageUrl = imageUrl
        self.date = date
        self.category = category
        self.isFavorite = isFavorite
        self.createdBy = createdBy
    }
}

public struct JournalModel: Identifiable, Codable, Equatable {
    public var id: String
    public var authorId: String
    public var content: String
    public var moodEmoji: String
    public var date: Date
    public var isShared: Bool

    public init(
        id: String = UUID().uuidString,
        authorId: String,
        content: String,
        moodEmoji: String = "❤️",
        date: Date = Date(),
        isShared: Bool = true
    ) {
        self.id = id
        self.authorId = authorId
        self.content = content
        self.moodEmoji = moodEmoji
        self.date = date
        self.isShared = isShared
    }
}
