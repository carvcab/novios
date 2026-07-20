import Foundation

public class FirestoreSyncService {
    public static let shared = FirestoreSyncService()

    private init() {}

    private var coupleId: String? {
        guard let myUid = FirebaseRESTService.shared.localId else { return nil }
        let partnerUid = UserDefaults.standard.string(forKey: "partner_uid") ?? ""
        guard !partnerUid.isEmpty else { return nil }
        return [myUid, partnerUid].sorted().joined(separator: "_")
    }

    // MARK: - Generic CRUD

    public func getCollection(path: String) async throws -> [[String: Any]] {
        guard let docs = try? await FirebaseRESTService.shared.firestoreGet(path: "\(path)?pageSize=100"),
              let documents = docs["documents"] as? [[String: Any]] else { return [] }
        return documents.map { extractFields(from: $0) }
    }

    public func getDocument(path: String) async throws -> [String: Any]? {
        guard let doc = try? await FirebaseRESTService.shared.firestoreGet(path: path) else { return nil }
        return extractFields(from: doc)
    }

    public func saveDocument(path: String, data: [String: Any]) async throws {
        try await FirebaseRESTService.shared.firestoreSet(path: path, fields: data)
    }

    public func createDocument(path: String, data: [String: Any]) async throws -> String? {
        return try await FirebaseRESTService.shared.firestoreCreate(path: path, fields: data)
    }

    public func deleteDocument(path: String) async throws {
        try await FirebaseRESTService.shared.firestoreDelete(path: path)
    }

    // MARK: - Timeline Events (LoveView)

    public func saveTimelineEvent(title: String, description: String, date: Date, emoji: String) async {
        guard let cid = coupleId else { return }
        let data: [String: Any] = [
            "id": UUID().uuidString, "title": title, "description": description,
            "date": date, "emoji": emoji, "createdAt": Date()
        ]
        _ = try? await createDocument(path: "couples/\(cid)/timeline", data: data)
    }

    public func loadTimelineEvents() async -> [[String: Any]] {
        guard let cid = coupleId else { return [] }
        return (try? await getCollection(path: "couples/\(cid)/timeline?orderBy=date")) ?? []
    }

    public func deleteTimelineEvent(id: String) async {
        guard let cid = coupleId else { return }
        try? await deleteDocument(path: "couples/\(cid)/timeline/\(id)")
    }

    // MARK: - Important Dates (ProfileView)

    public func saveImportantDate(title: String, date: Date, icon: String) async {
        guard let myUid = FirebaseRESTService.shared.localId else { return }
        let data: [String: Any] = [
            "id": UUID().uuidString, "title": title, "date": date, "icon": icon, "createdAt": Date()
        ]
        _ = try? await createDocument(path: "users/\(myUid)/importantDates", data: data)
    }

    public func loadImportantDates() async -> [[String: Any]] {
        guard let myUid = FirebaseRESTService.shared.localId else { return [] }
        return (try? await getCollection(path: "users/\(myUid)/importantDates")) ?? []
    }

    public func deleteImportantDate(id: String) async {
        guard let myUid = FirebaseRESTService.shared.localId else { return }
        try? await deleteDocument(path: "users/\(myUid)/importantDates/\(id)")
    }

    // MARK: - Shared Notes

    public func saveNote(title: String, content: String, emoji: String) async {
        guard let cid = coupleId else { return }
        let data: [String: Any] = [
            "id": UUID().uuidString, "title": title, "content": content,
            "emoji": emoji, "createdAt": Date(), "updatedAt": Date()
        ]
        _ = try? await createDocument(path: "couples/\(cid)/notes", data: data)
    }

    public func loadNotes() async -> [[String: Any]] {
        guard let cid = coupleId else { return [] }
        return (try? await getCollection(path: "couples/\(cid)/notes?orderBy=createdAt")) ?? []
    }

    public func deleteNote(id: String) async {
        guard let cid = coupleId else { return }
        try? await deleteDocument(path: "couples/\(cid)/notes/\(id)")
    }

    // MARK: - Dreams

    public func saveDream(title: String, emoji: String, isCompleted: Bool) async {
        guard let cid = coupleId else { return }
        let data: [String: Any] = [
            "id": UUID().uuidString, "title": title, "emoji": emoji,
            "isCompleted": isCompleted, "createdAt": Date()
        ]
        _ = try? await createDocument(path: "couples/\(cid)/dreams", data: data)
    }

    public func loadDreams() async -> [[String: Any]] {
        guard let cid = coupleId else { return [] }
        return (try? await getCollection(path: "couples/\(cid)/dreams")) ?? []
    }

    public func toggleDream(id: String, isCompleted: Bool) async {
        guard let cid = coupleId else { return }
        try? await saveDocument(path: "couples/\(cid)/dreams/\(id)", data: ["isCompleted": isCompleted])
    }

    // MARK: - Wishlist

    public func saveWish(title: String, emoji: String) async {
        guard let cid = coupleId else { return }
        let data: [String: Any] = [
            "id": UUID().uuidString, "title": title, "emoji": emoji,
            "isPurchased": false, "createdAt": Date()
        ]
        _ = try? await createDocument(path: "couples/\(cid)/wishlist", data: data)
    }

    public func loadWishlist() async -> [[String: Any]] {
        guard let cid = coupleId else { return [] }
        return (try? await getCollection(path: "couples/\(cid)/wishlist")) ?? []
    }

    // MARK: - Planner (Date Ideas, Movies, Restaurants)

    public func savePlannerItem(title: String, type: String, emoji: String) async {
        guard let cid = coupleId else { return }
        let data: [String: Any] = [
            "id": UUID().uuidString, "title": title, "type": type,
            "emoji": emoji, "isDone": false, "createdAt": Date()
        ]
        _ = try? await createDocument(path: "couples/\(cid)/planner", data: data)
    }

    public func loadPlannerItems(type: String? = nil) async -> [[String: Any]] {
        guard let cid = coupleId else { return [] }
        return (try? await getCollection(path: "couples/\(cid)/planner")) ?? []
    }

    // MARK: - Music (Shared Playlist)

    public func saveSong(name: String, artist: String) async {
        guard let cid = coupleId else { return }
        let data: [String: Any] = [
            "id": UUID().uuidString, "name": name, "artist": artist,
            "dateAdded": Date(), "isFavorite": false
        ]
        _ = try? await createDocument(path: "couples/\(cid)/songs", data: data)
    }

    public func loadSongs() async -> [[String: Any]] {
        guard let cid = coupleId else { return [] }
        return (try? await getCollection(path: "couples/\(cid)/songs")) ?? []
    }

    // MARK: - Letters

    public func saveLetter(title: String, content: String, emoji: String) async {
        guard let cid = coupleId else { return }
        let data: [String: Any] = [
            "id": UUID().uuidString, "title": title, "content": content,
            "emoji": emoji, "createdAt": Date(), "isRead": false
        ]
        _ = try? await createDocument(path: "couples/\(cid)/letters", data: data)
    }

    // MARK: - Partner Activity (for NotificationsView)

    public func loadPartnerNotifications() async -> [[String: Any]] {
        guard let partnerUid = UserDefaults.standard.string(forKey: "partner_uid"),
              !partnerUid.isEmpty else { return [] }
        return (try? await getCollection(path: "users/\(partnerUid)/activities?orderBy=timestamp")) ?? []
    }

    public func logActivity(type: String, description: String) async {
        guard let myUid = FirebaseRESTService.shared.localId else { return }
        let data: [String: Any] = [
            "id": UUID().uuidString, "type": type, "description": description,
            "timestamp": Date()
        ]
        _ = try? await createDocument(path: "users/\(myUid)/activities", data: data)
    }

    // MARK: - Helper

    private func extractFields(from doc: [String: Any]) -> [String: Any] {
        guard let fields = doc["fields"] as? [String: Any] else {
            if let map = doc["mapValue"] as? [String: Any],
               let f = map["fields"] as? [String: Any] {
                return decodeFields(f)
            }
            return doc
        }
        var result: [String: Any] = [:]
        if let name = doc["name"] as? String,
           let docId = name.split(separator: "/").last {
            result["id"] = String(docId)
        }
        for (key, val) in fields {
            if let map = val as? [String: Any] {
                if let s = map["stringValue"] as? String { result[key] = s }
                else if let b = map["booleanValue"] as? Bool { result[key] = b }
                else if let n = map["integerValue"] as? String { result[key] = Int(n) ?? 0 }
                else if let d = map["doubleValue"] as? Double { result[key] = d }
                else if let ts = map["timestampValue"] as? String {
                    result[key] = ISO8601DateFormatter().date(from: ts) ?? Date()
                }
            }
        }
        return result
    }

    private func decodeFields(_ fields: [String: Any]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, val) in fields {
            if let map = val as? [String: Any] {
                if let s = map["stringValue"] as? String { result[key] = s }
                else if let b = map["booleanValue"] as? Bool { result[key] = b }
            }
        }
        return result
    }
}
