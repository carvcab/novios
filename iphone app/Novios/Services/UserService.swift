import Foundation
import Combine

public enum AddPartnerResult {
    case success
    case alreadyHasPartner
    case targetHasPartner
    case notFound
    case error(String)
}

public class UserService: ObservableObject {
    public static let shared = UserService()
    
    @Published public var partnerUser: UserModel?
    @Published public var isSearching: Bool = false
    
    private var partnerObserverCancellable: AnyCancellable?
    
    private init() {
        loadMockPartnerIfNeeded()
    }
    
    public func searchUser(query: String) async -> [String: Any]? {
        await MainActor.run { self.isSearching = true }
        defer { Task { await MainActor.run { self.isSearching = false } } }

        let cleaned = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanUsername = cleaned.hasPrefix("@") ? String(cleaned.dropFirst()) : cleaned
        if cleanUsername.isEmpty { return nil }

        // 1. Try direct read from usernames/{username} (no index needed)
        if let doc = try? await FirebaseRESTService.shared.firestoreGet(path: "usernames/\(cleanUsername)"),
           let fields = doc["fields"] as? [String: Any],
           let uid = (fields["uid"] as? [String: Any])?["stringValue"] as? String {
            if let uDoc = try? await FirebaseRESTService.shared.firestoreGet(path: "users/\(uid)"),
               let uf = uDoc["fields"] as? [String: Any] {
                let displayName = (uf["displayName"] as? [String: Any])?["stringValue"] as? String ?? cleanUsername
                let uname = (uf["username"] as? [String: Any])?["stringValue"] as? String ?? cleanUsername
                let email = (uf["email"] as? [String: Any])?["stringValue"] as? String ?? ""
                let partnerUid = (uf["partnerUid"] as? [String: Any])?["stringValue"] as? String ?? ""
                return ["uid": uid, "displayName": displayName, "username": uname, "email": email, "hasPartner": !partnerUid.isEmpty]
            }
            return ["uid": uid, "displayName": cleanUsername, "username": cleanUsername, "email": ""]
        }

        // 2. Try as email (if contains @)
        if cleaned.contains("@") {
            // Try to find the user by checking if their email exists in the system
            // We can't search Firestore by email without an index, but we can try a direct document read
            // by checking if there's a usernames document with this email
            if let allDocs = try? await FirebaseRESTService.shared.firestoreGet(path: "usernames?pageSize=200"),
               let docs = allDocs["documents"] as? [[String: Any]] {
                for doc in docs {
                    if let f = doc["fields"] as? [String: Any],
                       let emailVal = (f["email"] as? [String: Any])?["stringValue"]?.lowercased(),
                       emailVal == cleaned {
                        let uid = (f["uid"] as? [String: Any])?["stringValue"] as? String ?? ""
                        if !uid.isEmpty {
                            if let uDoc = try? await FirebaseRESTService.shared.firestoreGet(path: "users/\(uid)"),
                               let uf = uDoc["fields"] as? [String: Any] {
                                let displayName = (uf["displayName"] as? [String: Any])?["stringValue"] as? String ?? cleaned
                                let uname = (uf["username"] as? [String: Any])?["stringValue"] as? String ?? cleanUsername
                                return ["uid": uid, "displayName": displayName, "username": uname, "email": emailVal]
                            }
                        }
                    }
                }
            }
        }

        // 3. Fallback: list all users and filter locally
        if let usersList = try? await FirebaseRESTService.shared.firestoreGet(path: "users?pageSize=200"),
           let docs = usersList["documents"] as? [[String: Any]] {
            for doc in docs {
                guard let f = doc["fields"] as? [String: Any],
                      let name = doc["name"] as? String else { continue }
                let uid = name.split(separator: "/").last.map(String.init) ?? ""
                let username = ((f["username"] as? [String: Any])?["stringValue"] as? String ?? "").lowercased()
                let displayName = (f["displayName"] as? [String: Any])?["stringValue"] as? String ?? (f["name"] as? [String: Any])?["stringValue"] as? String ?? username
                let email = ((f["email"] as? [String: Any])?["stringValue"] as? String ?? "").lowercased()
                let partnerUid = (f["partnerUid"] as? [String: Any])?["stringValue"] as? String ?? ""

                if username == cleanUsername || email == cleaned || displayName.lowercased() == cleaned {
                    return ["uid": uid, "displayName": displayName, "username": username, "email": email, "hasPartner": !partnerUid.isEmpty]
                }
            }
        }

        return nil
    }
    
    public func addPartner(codeOrEmail: String, foundUserData: [String: Any]? = nil) async -> AddPartnerResult {
        guard let partnerData = foundUserData else { return .notFound }
        guard var user = AuthService.shared.currentUser else { return .error("Usuario no autenticado") }
        if user.isPaired { return .alreadyHasPartner }

        let partnerId = partnerData["uid"] as? String ?? ""
        guard !partnerId.isEmpty else { return .notFound }
        
        let myUid = FirebaseRESTService.shared.localId ?? user.id
        if partnerId == myUid {
            return .error("No puedes vincularte a ti mismo")
        }
        
        if partnerData["hasPartner"] as? Bool == true {
            return .targetHasPartner
        }
        
        let displayName = partnerData["displayName"] as? String ?? "Mi Pareja ❤️"
        let username = partnerData["username"] as? String ?? "pareja"
        let email = partnerData["email"] as? String ?? ""
        let coupleId = [myUid, partnerId].sorted().joined(separator: "_")

        do {
            try await FirebaseRESTService.shared.firestoreSet(path: "users/\(myUid)", fields: [
                "partnerUid": partnerId, "partnerName": displayName, "coupleId": coupleId,
                "displayName": user.displayName, "email": user.email, "username": user.username
            ])
            try await FirebaseRESTService.shared.firestoreSet(path: "users/\(partnerId)", fields: [
                "partnerUid": myUid, "partnerName": user.displayName, "coupleId": coupleId,
                "displayName": displayName, "email": email, "username": username
            ])
        } catch {
            return .error("Error al vincular en Firestore: \(error.localizedDescription)")
        }

        user.partnerUid = partnerId
        user.anniversaryDate = Date().addingTimeInterval(-86400 * 365)
        user.skippedPartner = false
        AuthService.shared.currentUser = user
        AuthService.shared.saveUser(user)

        let partner = UserModel(id: partnerId, email: email, displayName: displayName, username: username,
            pairCode: "", partnerUid: myUid, anniversaryDate: user.anniversaryDate,
            mood: "🥰", moodMessage: "Pensando en ti", batteryLevel: 0.88, isCharging: true)
        self.partnerUser = partner

        return .success
    }
    
    public func updateMood(emoji: String, message: String? = nil) {
        guard var user = AuthService.shared.currentUser else { return }
        user.mood = emoji
        user.moodMessage = message
        AuthService.shared.saveUser(user)
        AuthService.shared.currentUser = user
    }
    
    public func updateBattery(level: Double, isCharging: Bool) {
        guard var user = AuthService.shared.currentUser else { return }
        user.batteryLevel = level
        user.isCharging = isCharging
        AuthService.shared.saveUser(user)
        AuthService.shared.currentUser = user
    }
    
    public func didSkipPartner() {
        guard var user = AuthService.shared.currentUser else { return }
        user.skippedPartner = true
        AuthService.shared.saveUser(user)
        AuthService.shared.currentUser = user
    }
    
    public func simulatePartnerEvent(event: PartnerEventType) {
        guard var partner = partnerUser else { return }
        let name = partner.displayName
        switch event {
        case .lowBattery(let level):
            partner.batteryLevel = Double(level) / 100.0
            partner.isCharging = false; self.partnerUser = partner
        case .startedCharging:
            partner.isCharging = true; self.partnerUser = partner
        case .moodChanged(let emoji, let text):
            partner.mood = emoji; partner.moodMessage = text; self.partnerUser = partner
        case .proximityAlert(let distText):
            break
        }
    }
    
    private func loadMockPartnerIfNeeded() {
        if let user = AuthService.shared.currentUser, user.isPaired {
            self.partnerUser = UserModel(
                id: user.partnerUid ?? "", email: "", displayName: user.partnerUid ?? "Pareja",
                username: "", pairCode: "", partnerUid: user.id,
                anniversaryDate: user.anniversaryDate ?? Date().addingTimeInterval(-86400 * 200),
                mood: "🥰", batteryLevel: 0.85, isCharging: true)
        }
    }
}

public enum PartnerEventType {
    case lowBattery(Int)
    case startedCharging
    case moodChanged(String, String?)
    case proximityAlert(String)
}
