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

        // Force refresh token first
        if let token = FirebaseRESTService.shared.idToken {
            if let exp = try? parseJWTExp(token), exp < Date().timeIntervalSince1970 {
                _ = try? await FirebaseRESTService.shared.refreshIdToken()
            }
        }

        let myUid = FirebaseRESTService.shared.localId ?? AuthService.shared.currentUser?.id
        guard let myUid = myUid else { return nil }

        // Verify auth works by fetching own user doc
        let ownDoc = try? await FirebaseRESTService.shared.firestoreGet(path: "users/\(myUid)")
        if ownDoc == nil {
            if (try? await FirebaseRESTService.shared.refreshIdToken()) == nil {
                return nil
            }
            guard (try? await FirebaseRESTService.shared.firestoreGet(path: "users/\(myUid)")) != nil else {
                return nil
            }
        }

        // 1. Try direct usernames/{clean} lookup
        if let usernameDoc = try? await FirebaseRESTService.shared.firestoreGet(path: "usernames/\(clean)"),
           let unFields = usernameDoc["fields"] as? [String: Any],
           let uid = (unFields["uid"] as? [String: Any])?["stringValue"] as? String,
           uid != myUid {
            if let userDoc = try? await FirebaseRESTService.shared.firestoreGet(path: "users/\(uid)"),
               let userFields = userDoc["fields"] as? [String: Any] {
                var result = self.extractUserData(uid: uid, fields: userFields)
                result["_source"] = "username"
                return result
            }
            var result: [String: Any] = ["uid": uid, "username": clean, "displayName": clean]
            result["_source"] = "username_only"
            return result
        }

        // 2. List ALL users and find by any matching field (most reliable)
        if let usersList = try? await FirebaseRESTService.shared.firestoreList(path: "users") {
            for doc in usersList {
                guard let f = doc["fields"] as? [String: Any],
                      let docName = doc["name"] as? String else { continue }
                let uid = docName.split(separator: "/").last.map(String.init) ?? ""
                guard !uid.isEmpty, uid != myUid else { continue }

                let extractStr = { (key: String) -> String in
                    ((f[key] as? [String: Any])?["stringValue"] as? String ?? "").lowercased()
                }

                let fieldsToCheck = ["username", "displayName", "name", "email"]
                for field in fieldsToCheck {
                    if extractStr(field) == clean {
                        var result = self.extractUserData(uid: uid, fields: f)
                        result["_source"] = "field_\(field)"
                        return result
                    }
                }
            }
        }

        // 3. Try listing usernames collection (fallback)
        if let allDocs = try? await FirebaseRESTService.shared.firestoreList(path: "usernames") {
            for doc in allDocs {
                guard let f = doc["fields"] as? [String: Any] else { continue }
                let docId = (doc["name"] as? String)?.split(separator: "/").last.map(String.init)?.lowercased() ?? ""
                let emailVal = ((f["email"] as? [String: Any])?["stringValue"] as? String ?? "").lowercased()
                let match = docId == clean || emailVal == clean
                guard match else { continue }
                let uid = (f["uid"] as? [String: Any])?["stringValue"] as? String ?? ""
                guard !uid.isEmpty, uid != myUid else { continue }
                if let userDoc = try? await FirebaseRESTService.shared.firestoreGet(path: "users/\(uid)"),
                   let userFields = userDoc["fields"] as? [String: Any] {
                    var result = self.extractUserData(uid: uid, fields: userFields)
                    result["_source"] = docId == clean ? "username_iter" : "email"
                    return result
                }
                var result: [String: Any] = ["uid": uid, "username": docId, "displayName": docId]
                result["_source"] = "username_iter_only"
                return result
            }
        }

        return nil
    }

    private func parseJWTExp(_ token: String) -> TimeInterval? {
        let parts = token.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        var padded = String(parts[1])
        while padded.count % 4 != 0 { padded += "=" }
        guard let data = Data(base64Encoded: padded),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let exp = json["exp"] as? TimeInterval else { return nil }
        return exp
    }

    private func extractUserData(uid: String, fields: [String: Any]) -> [String: Any] {
        let extract = { (key: String) -> String? in
            (fields[key] as? [String: Any])?["stringValue"] as? String
        }
        return [
            "uid": uid,
            "displayName": extract("displayName") ?? extract("name") ?? "",
            "username": extract("username") ?? "",
            "email": extract("email") ?? "",
            "hasPartner": (extract("partnerUid") ?? "").isEmpty == false
        ]
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
