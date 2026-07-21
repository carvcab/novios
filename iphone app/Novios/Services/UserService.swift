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
    @Published public var isSearching = false

    private init() {}

    // MARK: - Search User (matches Android exactly)

    public func searchUser(query: String) async -> [String: Any]? {
        let clean = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !clean.isEmpty else { return nil }
        let myUid = FirebaseRESTService.shared.localId ?? AuthService.shared.currentUser?.id

        if let unDoc = try? await FirebaseRESTService.shared.firestoreGet(path: "usernames/\(clean)"),
           let uf = unDoc["fields"] as? [String: Any],
           let uid = (uf["uid"] as? [String: Any])?["stringValue"] as? String,
           uid != myUid {
            if let userDoc = try? await FirebaseRESTService.shared.firestoreGet(path: "users/\(uid)"),
               let userFields = userDoc["fields"] as? [String: Any] {
                return extractUserData(uid: uid, fields: userFields)
            }
            return ["uid": uid, "username": clean, "displayName": clean, "name": clean]
        }
        return nil
    }

    private func extractUserData(uid: String, fields: [String: Any]) -> [String: Any] {
        let extract = { (key: String) -> String? in
            (fields[key] as? [String: Any])?["stringValue"] as? String
        }
        var result: [String: Any] = [:]
        result["uid"] = uid
        result["username"] = extract("username") ?? ""
        result["displayName"] = extract("displayName") ?? extract("name") ?? ""
        result["name"] = extract("name") ?? extract("displayName") ?? ""
        result["email"] = extract("email") ?? ""
        for (k, v) in fields {
            if let sv = (v as? [String: Any])?["stringValue"] as? String {
                result[k] = sv
            }
        }
        return result
    }

    // MARK: - Add Partner (matches Android exactly)

    public func addPartner(query: String) async -> AddPartnerResult {
        guard let myUid = FirebaseRESTService.shared.localId ?? AuthService.shared.currentUser?.id else {
            return .error("Usuario no autenticado")
        }

        guard let targetData = await searchUser(query: query) else {
            return .notFound
        }

        let targetUid = targetData["uid"] as? String ?? ""
        guard !targetUid.isEmpty, targetUid != myUid else {
            return .notFound
        }

        let targetUsername = targetData["username"] as? String ?? ""
        let targetEmail = targetData["email"] as? String ?? ""
        var targetName = targetData["displayName"] as? String ?? ""
        if targetName.isEmpty { targetName = targetUsername }
        if targetName.isEmpty { targetName = targetEmail }

        let coupleId = [myUid, targetUid].sorted().joined(separator: "_")

        // Check both users don't already have partners
        if let myDoc = try? await FirebaseRESTService.shared.firestoreGet(path: "users/\(myUid)"),
           let myFields = myDoc["fields"] as? [String: Any] {
            let myPartner = (myFields["partnerUid"] as? [String: Any])?["stringValue"] as? String ?? ""
            if !myPartner.isEmpty && myPartner != targetUid {
                return .alreadyHasPartner
            }
        }

        if let targetDoc = try? await FirebaseRESTService.shared.firestoreGet(path: "users/\(targetUid)"),
           let targetFields = targetDoc["fields"] as? [String: Any] {
            let tPartner = (targetFields["partnerUid"] as? [String: Any])?["stringValue"] as? String ?? ""
            if !tPartner.isEmpty && tPartner != myUid {
                return .targetHasPartner
            }
        }

        let myName = AuthService.shared.currentUser?.displayName ?? "Mi Pareja"
        let myUsername = AuthService.shared.currentUser?.username ?? ""

        // Write all three documents
        do {
            try await FirebaseRESTService.shared.firestoreSet(path: "users/\(myUid)", fields: [
                "partnerUid": targetUid,
                "partnerUsername": targetUsername,
                "partnerDisplayName": targetName,
                "coupleId": coupleId,
            ])

            try await FirebaseRESTService.shared.firestoreSet(path: "users/\(targetUid)", fields: [
                "partnerUid": myUid,
                "partnerUsername": myUsername,
                "partnerDisplayName": myName,
                "coupleId": coupleId,
            ])

            try await FirebaseRESTService.shared.firestoreSet(path: "couples/\(coupleId)", fields: [
                "active": true,
                "members": [myUid, targetUid],
                "createdAt": Date(),
                "updatedAt": Date(),
                "userNames": [myUid: myName, targetUid: targetName],
            ])
        } catch {
            return .error("Error al vincular: \(error.localizedDescription)")
        }

        // Save to UserDefaults
        let defaults = UserDefaults.standard
        defaults.set(targetUid, forKey: "partner_uid")
        defaults.set(targetUsername, forKey: "partner_username")
        defaults.set(targetName, forKey: "partner_name")
        defaults.set(coupleId, forKey: "couple_id")
        defaults.set(coupleId, forKey: "pair_id")
        defaults.removeObject(forKey: "partner_skipped")

        await MainActor.run {
            self.partnerUser = UserModel(
                id: targetUid, email: "", displayName: targetName,
                username: targetUsername, partnerUid: myUid,
                mood: "🥰", batteryLevel: 0.88, isCharging: true
            )
        }

        return .success
    }

    public func loadPartnerFromDefaults() {
        let defaults = UserDefaults.standard
        guard let puid = defaults.string(forKey: "partner_uid"), !puid.isEmpty else {
            partnerUser = nil
            return
        }
        var pname = defaults.string(forKey: "partner_name") ?? ""
        if pname.count > 20 || pname == puid { pname = "" }
        let pusername = defaults.string(forKey: "partner_username") ?? ""
        let display = !pname.isEmpty ? pname : (!pusername.isEmpty ? pusername : "Pareja")
        partnerUser = UserModel(id: puid, email: "", displayName: display, username: pusername, partnerUid: AuthService.shared.currentUser?.id, mood: "🥰", batteryLevel: 0.88, isCharging: true)
    }

    public func fetchPartnerFromFirestore() async {
        let defaults = UserDefaults.standard
        guard let puid = defaults.string(forKey: "partner_uid"), !puid.isEmpty else { return }
        if let doc = try? await FirebaseRESTService.shared.firestoreGet(path: "users/\(puid)"),
           let fields = doc["fields"] as? [String: Any] {
            let extract = { (key: String) -> String? in (fields[key] as? [String: Any])?["stringValue"] as? String }
            let displayName = extract("displayName") ?? extract("name") ?? ""
            let username = extract("username") ?? ""
            let email = extract("email") ?? ""
            let finalName = !displayName.isEmpty ? displayName : (!username.isEmpty ? username : (!email.isEmpty ? email : "Pareja"))
            await MainActor.run {
                self.partnerUser = UserModel(id: puid, email: email, displayName: finalName, username: username, partnerUid: AuthService.shared.currentUser?.id, mood: "🥰", batteryLevel: 0.88, isCharging: true)
            }
        }
    }
}
