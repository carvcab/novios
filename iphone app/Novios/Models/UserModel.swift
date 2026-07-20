import Foundation
import CoreLocation

public struct UserModel: Identifiable, Codable, Equatable {
    public var id: String
    public var email: String
    public var displayName: String
    public var username: String
    public var avatarUrl: String?
    public var pairCode: String
    public var partnerUid: String?
    public var anniversaryDate: Date?
    public var mood: String
    public var moodMessage: String?
    public var batteryLevel: Double
    public var isCharging: Bool
    public var latitude: Double?
    public var longitude: Double?
    public var lastLocationUpdate: Date?
    public var createdAt: Date
    public var skippedPartner: Bool
    
    public init(
        id: String,
        email: String,
        displayName: String,
        username: String,
        avatarUrl: String? = nil,
        pairCode: String = "",
        partnerUid: String? = nil,
        anniversaryDate: Date? = nil,
        mood: String = "❤️",
        moodMessage: String? = nil,
        batteryLevel: Double = 1.0,
        isCharging: Bool = false,
        latitude: Double? = nil,
        longitude: Double? = nil,
        lastLocationUpdate: Date? = nil,
        createdAt: Date = Date(),
        skippedPartner: Bool = false
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.username = username
        self.avatarUrl = avatarUrl
        self.pairCode = pairCode
        self.partnerUid = partnerUid
        self.anniversaryDate = anniversaryDate
        self.mood = mood
        self.moodMessage = moodMessage
        self.batteryLevel = batteryLevel
        self.isCharging = isCharging
        self.latitude = latitude
        self.longitude = longitude
        self.lastLocationUpdate = lastLocationUpdate
        self.createdAt = createdAt
        self.skippedPartner = skippedPartner
    }

    public var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    public var isPaired: Bool {
        return partnerUid != nil && !(partnerUid?.isEmpty ?? true)
    }

    public func dictionaryRepresentation() -> [String: Any] {
        var dict: [String: Any] = [
            "uid": id,
            "email": email,
            "displayName": displayName,
            "username": username,
            "pairCode": pairCode,
            "mood": mood,
            "batteryLevel": batteryLevel,
            "isCharging": isCharging,
            "skippedPartner": skippedPartner,
            "createdAt": createdAt.timeIntervalSince1970
        ]
        if let avatarUrl = avatarUrl { dict["avatarUrl"] = avatarUrl }
        if let partnerUid = partnerUid { dict["partnerUid"] = partnerUid }
        if let anniversaryDate = anniversaryDate { dict["anniversaryDate"] = anniversaryDate.timeIntervalSince1970 }
        if let moodMessage = moodMessage { dict["moodMessage"] = moodMessage }
        if let latitude = latitude { dict["latitude"] = latitude }
        if let longitude = longitude { dict["longitude"] = longitude }
        if let lastLocationUpdate = lastLocationUpdate { dict["lastLocationUpdate"] = lastLocationUpdate.timeIntervalSince1970 }
        return dict
    }
}
