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
        let myUid = FirebaseRESTService.shared.localId

        // 1. Search by Pair Code (e.g. LOVE-8492)
        let upper = clean.uppercased()
        let formattedCode = upper.contains("LOVE-") ? upper : "LOVE-\(upper)"
        if let codeDoc = try? await FirebaseRESTService.shared.firestoreGet(path: "pair_codes/\(formattedCode)"),
           let codeFields = codeDoc["fields"] as? [String: Any],
           let uid = (codeFields["uid"] as? [String: Any])?["stringValue"] as? String,
           uid != myUid {
            if let userDoc = try? await FirebaseRESTService.shared.firestoreGet(path: "users/\(uid)"),
               let userFields = userDoc["fields"] as? [String: Any] {
                var result = extractUserData(uid: uid, fields: userFields)
                result["_source"] = "pair_code"
                return result
            }
        }

        // 2. Search by Username
        if let usernameDoc = try? await FirebaseRESTService.shared.firestoreGet(path: "usernames/\(clean)"),
           let unFields = usernameDoc["fields"] as? [String: Any],
           let uid = (unFields["uid"] as? [String: Any])?["stringValue"] as? String,
           uid != myUid {
            if let userDoc = try? await FirebaseRESTService.shared.firestoreGet(path: "users/\(uid)"),
               let userFields = userDoc["fields"] as? [String: Any] {
                var result = extractUserData(uid: uid, fields: userFields)
                result["_source"] = "username"
                return result
            }
            var result: [String: Any] = ["uid": uid, "username": clean, "displayName": clean]
            result["_source"] = "username_only"
            return result
        }

        // 3. Search by Email (iterate usernames collection)
        if clean.contains("@") {
            if let allDocs = try? await FirebaseRESTService.shared.firestoreGet(path: "usernames?pageSize=200"),
               let docs = allDocs["documents"] as? [[String: Any]] {
                for doc in docs {
                    guard let f = doc["fields"] as? [String: Any] else { continue }
                    let emailVal = ((f["email"] as? [String: Any])?["stringValue"] as? String ?? "").lowercased()
                    guard emailVal == clean else { continue }
                    let uid = (f["uid"] as? [String: Any])?["stringValue"] as? String ?? ""
                    guard !uid.isEmpty, uid != myUid else { continue }
                    if let userDoc = try? await FirebaseRESTService.shared.firestoreGet(path: "users/\(uid)"),
                       let userFields = userDoc["fields"] as? [String: Any] {
                        var result = extractUserData(uid: uid, fields: userFields)
                        result["_source"] = "email"
                        return result
                    }
                }
            }
        }

        // 4. Fallback: iterate all users
        if let usersList = try? await FirebaseRESTService.shared.firestoreGet(path: "users?pageSize=200"),
           let docs = usersList["documents"] as? [[String: Any]] {
            for doc in docs {
                guard let f = doc["fields"] as? [String: Any],
                      let name = doc["name"] as? String else { continue }
                let uid = name.split(separator: "/").last.map(String.init) ?? ""
                guard uid != myUid else { continue }
                let username = ((f["username"] as? [String: Any])?["stringValue"] as? String ?? "").lowercased()
                let displayName = (f["displayName"] as? [String: Any])?["stringValue"] as? String
                    ?? (f["name"] as? [String: Any])?["stringValue"] as? String ?? ""
                let email = ((f["email"] as? [String: Any])?["stringValue"] as? String ?? "").lowercased()

                if username == clean || displayName.lowercased() == clean || email == clean {
                    var result = extractUserData(uid: uid, fields: f)
                    result["_source"] = "fallback"
                    return result
                }
            }
        }

        return nil
    }

    private func extractUserData(uid: String, fields: [String: Any]) -> [String: Any] {
        let extract = { (key: String) -> String? in
            (fields[key] as? [String: Any])?["stringValue"] as? String
        }
        return [
            "uid": uid,
            "displayName": extract("displayName") ?? extract("name") ?? uid,
            "username": extract("username") ?? "",
            "email": extract("email") ?? "",
            "hasPartner": (extract("partnerUid") ?? "").isEmpty == false
        ]
    }

    // MARK: - Add Partner (matches Android exactly)

    public func addPartner(query: String) async -> AddPartnerResult {
        guard let myUid = FirebaseRESTService.shared.localId else {
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
        let targetName = targetData["displayName"] as? String ?? targetUsername

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
}
