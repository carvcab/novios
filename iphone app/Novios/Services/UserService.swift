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

        // 1. Direct read from usernames/{username}
        if let doc = try? await FirebaseRESTService.shared.firestoreGet(path: "usernames/\(cleanUsername)"),
           let fields = doc["fields"] as? [String: Any],
           let uid = (fields["uid"] as? [String: Any])?["stringValue"] as? String {
            if let uDoc = try? await FirebaseRESTService.shared.firestoreGet(path: "users/\(uid)"),
               let uf = uDoc["fields"] as? [String: Any] {
                let displayName = (uf["displayName"] as? [String: Any])?["stringValue"] as? String ?? 
                                  (uf["name"] as? [String: Any])?["stringValue"] as? String ?? cleanUsername
                let uname = (uf["username"] as? [String: Any])?["stringValue"] as? String ?? cleanUsername
                let email = (uf["email"] as? [String: Any])?["stringValue"] as? String ?? ""
                let partnerUid = (uf["partnerUid"] as? [String: Any])?["stringValue"] as? String ?? ""
                return ["uid": uid, "displayName": displayName, "username": uname, "email": email, "hasPartner": !partnerUid.isEmpty]
            }
            return ["uid": uid, "displayName": cleanUsername, "username": cleanUsername, "email": "", "hasPartner": false]
        }

        // 2. Search by Pair Code (e.g. LOVE-8492 or 8492)
        let upperCode = cleaned.uppercased()
        let formattedCode = upperCode.hasPrefix("LOVE-") ? upperCode : "LOVE-\(upperCode)"
        if let codeDoc = try? await FirebaseRESTService.shared.firestoreGet(path: "pair_codes/\(formattedCode)"),
           let cf = codeDoc["fields"] as? [String: Any],
           let uid = (cf["uid"] as? [String: Any])?["stringValue"] as? String {
            if let uDoc = try? await FirebaseRESTService.shared.firestoreGet(path: "users/\(uid)"),
               let uf = uDoc["fields"] as? [String: Any] {
                let displayName = (uf["displayName"] as? [String: Any])?["stringValue"] as? String ?? "Usuario"
                let uname = (uf["username"] as? [String: Any])?["stringValue"] as? String ?? ""
                let email = (uf["email"] as? [String: Any])?["stringValue"] as? String ?? ""
                let partnerUid = (uf["partnerUid"] as? [String: Any])?["stringValue"] as? String ?? ""
                return ["uid": uid, "displayName": displayName, "username": uname, "email": email, "hasPartner": !partnerUid.isEmpty]
            }
        }

        // 3. Try Firestore query on users collection by username
        if let docs = try? await FirebaseRESTService.shared.firestoreQuery(path: "users", field: "username", op: "EQUAL", value: cleanUsername),
           let first = docs.first,
           let f = first["fields"] as? [String: Any] {
            let uid = (first["name"] as? String)?.split(separator: "/").last.map(String.init) ?? ""
            let displayName = (f["displayName"] as? [String: Any])?["stringValue"] as? String ?? 
                              (f["name"] as? [String: Any])?["stringValue"] as? String ?? cleanUsername
            let email = (f["email"] as? [String: Any])?["stringValue"] as? String ?? ""
            let partnerUid = (f["partnerUid"] as? [String: Any])?["stringValue"] as? String ?? ""
            return ["uid": uid, "displayName": displayName, "username": cleanUsername, "email": email, "hasPartner": !partnerUid.isEmpty]
        }

        // 4. Try by email
        if cleaned.contains("@") {
            if let docs = try? await FirebaseRESTService.shared.firestoreQuery(path: "users", field: "email", op: "EQUAL", value: cleaned),
               let first = docs.first,
               let f = first["fields"] as? [String: Any] {
                let uid = (first["name"] as? String)?.split(separator: "/").last.map(String.init) ?? ""
                let displayName = (f["displayName"] as? [String: Any])?["stringValue"] as? String ?? ""
                let uname = (f["username"] as? [String: Any])?["stringValue"] as? String ?? cleanUsername
                let email = (f["email"] as? [String: Any])?["stringValue"] as? String ?? cleaned
                let partnerUid = (f["partnerUid"] as? [String: Any])?["stringValue"] as? String ?? ""
                return ["uid": uid, "displayName": displayName, "username": uname, "email": email, "hasPartner": !partnerUid.isEmpty]
            }
            // Also try email search by reading usernames collection
            if let docs = try? await FirebaseRESTService.shared.firestoreGet(path: "usernames?pageSize=100"),
               let documents = docs["documents"] as? [[String: Any]] {
                for doc in documents {
                    if let f = doc["fields"] as? [String: Any],
                       let emailVal = (f["email"] as? [String: Any])?["stringValue"] as? String,
                       emailVal.lowercased() == cleaned {
                        let uid = (f["uid"] as? [String: Any])?["stringValue"] as? String ?? ""
                        if !uid.isEmpty {
                            if let uDoc = try? await FirebaseRESTService.shared.firestoreGet(path: "users/\(uid)"),
                               let uf = uDoc["fields"] as? [String: Any] {
                                let displayName = (uf["displayName"] as? [String: Any])?["stringValue"] as? String ?? ""
                                let uname = (uf["username"] as? [String: Any])?["stringValue"] as? String ?? cleanUsername
                                let partnerUid = (uf["partnerUid"] as? [String: Any])?["stringValue"] as? String ?? ""
                                return ["uid": uid, "displayName": displayName, "username": uname, "email": emailVal, "hasPartner": !partnerUid.isEmpty]
                            }
                        }
                    }
                }
            }
        }

        // 5. Fallback: list all users and find by username locally (no index needed)
        if let docs = try? await FirebaseRESTService.shared.firestoreGet(path: "users?pageSize=100"),
           let documents = docs["documents"] as? [[String: Any]] {
            for doc in documents {
                guard let f = doc["fields"] as? [String: Any],
                      let name = doc["name"] as? String else { continue }
                let uid = name.split(separator: "/").last.map(String.init) ?? ""
                let username = (f["username"] as? [String: Any])?["stringValue"] as? String ?? ""
                let displayName = (f["displayName"] as? [String: Any])?["stringValue"] as? String ?? username
                let email = (f["email"] as? [String: Any])?["stringValue"] as? String ?? ""
                let partnerUid = (f["partnerUid"] as? [String: Any])?["stringValue"] as? String ?? ""
                if username.lowercased() == cleanUsername {
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
