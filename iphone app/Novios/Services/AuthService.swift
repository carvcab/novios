import Foundation
import Combine

public class AuthService: ObservableObject {
    public static let shared = AuthService()

    @Published public var currentUser: UserModel?
    @Published public var isLoggedIn = false
    @Published public var hasProfile = false
    @Published public var hasPartner = false
    @Published public var partnerSkipped = false
    @Published public var isLoading = false
    @Published public var isRestoringSession = true

    private let defaults = UserDefaults.standard

    private init() {
        FirebaseRESTService.shared.loadSavedConfig()
        loadSession()
    }

    // Google sign-in removed - use email/password auth instead

    public func signInWithEmail(email: String, password: String) async throws {
        await MainActor.run { isLoading = true }
        do {
            let result = try await FirebaseRESTService.shared.signIn(email: email, password: password)
            
            // Sync profile & partner from Firestore synchronously before unlocking UI
            try? await syncUserFromFirestore(uid: result.localId, email: email)
            
            let data = try? await FirebaseRESTService.shared.getUserData()
            let name = data?["displayName"] as? String ?? email.components(separatedBy: "@").first?.capitalized ?? "Usuario"
            let uname = defaults.string(forKey: "profile_username") ?? email.components(separatedBy: "@").first ?? "usuario"
            let user = UserModel(id: result.localId, email: email, displayName: name, username: uname)
            
            await MainActor.run {
                self.currentUser = user
                self.saveSession(user: user)
                self.checkProfileAndPartner()
                self.isLoggedIn = true
                self.isLoading = false
            }
        } catch {
            await MainActor.run { self.isLoading = false }
            throw error
        }
    }

    public func signUpWithEmail(email: String, password: String, name: String) async throws {
        await MainActor.run { isLoading = true }
        do {
            let result = try await FirebaseRESTService.shared.signUp(email: email, password: password, displayName: name)
            let user = UserModel(id: result.localId, email: email, displayName: name, username: email.components(separatedBy: "@").first ?? name.lowercased())
            await MainActor.run {
                self.currentUser = user; self.isLoggedIn = true; self.isLoading = false
                saveSession(user: user)
            }
        } catch {
            await MainActor.run { self.isLoading = false }
            throw error
        }
    }

    public func signOut() {
        FirebaseRESTService.shared.signOut()
        currentUser = nil; isLoggedIn = false; hasProfile = false; hasPartner = false; partnerSkipped = false
        clearUserDefaults()
    }

    private func clearUserDefaults() {
        let defaults = UserDefaults.standard
        ["auth_user_id","auth_user_email","auth_user_name","auth_logged_in","profile_dob","profile_username",
         "partner_uid","partner_name","partner_skipped","fb_id_token","fb_local_id","fb_refresh_token","onboarding_complete"].forEach {
            defaults.removeObject(forKey: $0)
        }
    }

    private func syncUserFromFirestore(uid: String, email: String) async throws {
        let defaults = UserDefaults.standard
        let defaultUsername = email.components(separatedBy: "@").first?.lowercased() ?? "usuario"
        let defaultName = email.components(separatedBy: "@").first?.capitalized ?? "Usuario"

        if let doc = try? await FirebaseRESTService.shared.firestoreGet(path: "users/\(uid)"),
           let fields = doc["fields"] as? [String: Any] {
            
            let extract = { (key: String) -> String? in
                guard let map = fields[key] as? [String: Any] else { return nil }
                return map["stringValue"] as? String ?? map["timestampValue"] as? String ?? map["integerValue"] as? String
            }
            
            let username = extract("username") ?? defaultUsername
            let dob = extract("dob") ?? extract("birthdayDate") ?? extract("birthday_date") ?? "2000-01-01"
            let partnerUid = extract("partnerUid") ?? ""
            let partnerName = extract("partnerName") ?? "Pareja"
            let displayName = extract("displayName") ?? extract("name") ?? defaultName
            
            // Sync important dates
            let dateFields = ["anniversaryDate": "anniversary_date", "metDate": "met_date", "datingDate": "dating_date", "weddingDate": "wedding_date"]
            for (firestoreKey, defaultsKey) in dateFields {
                if let val = extract(firestoreKey), !val.isEmpty {
                    defaults.set(val, forKey: defaultsKey)
                }
            }
            
            defaults.set(dob, forKey: "profile_dob")
            defaults.set(username, forKey: "profile_username")
            defaults.set(displayName, forKey: "auth_user_name")
            defaults.set(true, forKey: "onboarding_complete")
            
            if !partnerUid.isEmpty {
                defaults.set(partnerUid, forKey: "partner_uid")
                defaults.set(partnerName, forKey: "partner_name")
                await MainActor.run {
                    self.hasPartner = true
                }
            }
            
            await MainActor.run {
                self.hasProfile = true
            }
        } else {
            // If user document is absent or temporary network drop, set default profile for existing auth account
            defaults.set("2000-01-01", forKey: "profile_dob")
            defaults.set(defaultUsername, forKey: "profile_username")
            defaults.set(defaultName, forKey: "auth_user_name")
            defaults.set(true, forKey: "onboarding_complete")
            
            await MainActor.run {
                self.hasProfile = true
            }
            
            // Create user document in Firestore asynchronously
            Task {
                try? await FirebaseRESTService.shared.firestoreSet(path: "users/\(uid)", fields: [
                    "username": defaultUsername,
                    "dob": "2000-01-01",
                    "birthdayDate": "2000-01-01",
                    "displayName": defaultName,
                    "name": defaultName,
                    "email": email
                ])
                try? await FirebaseRESTService.shared.firestoreSet(path: "usernames/\(defaultUsername)", fields: [
                    "uid": uid,
                    "email": email
                ])
            }
        }
    }

    public func checkProfileAndPartner() {
        hasProfile = defaults.bool(forKey: "onboarding_complete") ||
            (isLoggedIn && currentUser != nil) ||
            ((defaults.string(forKey: "profile_dob") != nil || defaults.string(forKey: "profile_username") != nil) &&
             !(defaults.string(forKey: "profile_username")?.isEmpty ?? true))
        hasPartner = defaults.string(forKey: "partner_uid") != nil &&
                     !(defaults.string(forKey: "partner_uid")?.isEmpty ?? true)
        partnerSkipped = defaults.bool(forKey: "partner_skipped")
    }

    private func loadSession() {
        isRestoringSession = true
        FirebaseRESTService.shared.loadSavedConfig()
        
        if defaults.bool(forKey: "auth_logged_in"),
           let uid = defaults.string(forKey: "auth_user_id") {
            let email = defaults.string(forKey: "auth_user_email") ?? ""
            let name = defaults.string(forKey: "auth_user_name") ?? "Usuario"
            let username = defaults.string(forKey: "profile_username") ?? ""
            currentUser = UserModel(id: uid, email: email, displayName: name, username: username)
            isLoggedIn = true
            checkProfileAndPartner()
            
            // Sync from Firestore in background
            Task {
                if let doc = try? await FirebaseRESTService.shared.firestoreGet(path: "users/\(uid)"),
                   let fields = doc["fields"] as? [String: Any] {
                    await self.syncFromFirestore(fields)
                } else {
                    // Firestore unavailable, try to refresh token and retry
                    if let newToken = try? await FirebaseRESTService.shared.refreshIdToken() {
                        _ = newToken
                        if let doc = try? await FirebaseRESTService.shared.firestoreGet(path: "users/\(uid)"),
                           let fields = doc["fields"] as? [String: Any] {
                            await self.syncFromFirestore(fields)
                        }
                    }
                }
                await MainActor.run {
                    self.checkProfileAndPartner()
                    self.isRestoringSession = false
                }
            }
        } else {
            isRestoringSession = false
        }
    }

    private func syncFromFirestore(_ fields: [String: Any]) async {
        let extract = { (key: String) -> String? in
            (fields[key] as? [String: Any])?["stringValue"] as? String
        }
        let extractDate = { (key: String) -> Date? in
            if let str = (fields[key] as? [String: Any])?["stringValue"] as? String {
                return ISO8601DateFormatter().date(from: str)
            }
            if let ts = (fields[key] as? [String: Any])?["timestampValue"] as? String {
                return ISO8601DateFormatter().date(from: ts)
            }
            return nil
        }
        let username = extract("username") ?? ""
        let dob = extract("dob") ?? extract("birthdayDate") ?? extract("birthday_date") ?? ""
        let partnerUid = extract("partnerUid") ?? ""
        let partnerName = extract("partnerName") ?? ""
        let displayName = extract("displayName") ?? extract("name") ?? ""

        let defaults = UserDefaults.standard

        // Sync important dates from Firestore
        let dateFields = [
            "anniversaryDate": "anniversary_date",
            "metDate": "met_date",
            "datingDate": "dating_date",
            "weddingDate": "wedding_date"
        ]
        for (firestoreKey, defaultsKey) in dateFields {
            if let date = extractDate(firestoreKey) {
                defaults.set(ISO8601DateFormatter().string(from: date), forKey: defaultsKey)
            }
        }

        // Always save what we got from Firestore
        if !username.isEmpty || !displayName.isEmpty {
            defaults.set(dob, forKey: "profile_dob")
            defaults.set(username.isEmpty ? displayName.lowercased() : username, forKey: "profile_username")
            defaults.set(true, forKey: "onboarding_complete")
            if !displayName.isEmpty { defaults.set(displayName, forKey: "auth_user_name") }
            await MainActor.run { self.hasProfile = true }
        }
        if !partnerUid.isEmpty {
            defaults.set(partnerUid, forKey: "partner_uid")
            defaults.set(partnerName.isEmpty ? "Pareja" : partnerName, forKey: "partner_name")
            defaults.set(true, forKey: "onboarding_complete")
            await MainActor.run { self.hasPartner = true }
        }
        // If Firestore has data, also set FirebaseRESTService tokens if missing
        if FirebaseRESTService.shared.localId == nil {
            FirebaseRESTService.shared.loadSavedConfig()
        }
    }

    private func saveSession(user: UserModel) {
        defaults.set(user.id, forKey: "auth_user_id")
        defaults.set(user.email, forKey: "auth_user_email")
        defaults.set(user.displayName, forKey: "auth_user_name")
        defaults.set(true, forKey: "auth_logged_in")
    }

    public func saveProfile(dob: Date, username: String, partnerName: String?) {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let dobStr = df.string(from: dob)
        defaults.set(dobStr, forKey: "profile_dob")
        defaults.set(username, forKey: "profile_username")
        if let name = partnerName { defaults.set(name, forKey: "profile_partner_name") }
        defaults.set(true, forKey: "onboarding_complete")
        hasProfile = true
        // Sync to Firestore
        Task {
            guard let uid = localUserId else { return }
            let email = currentUser?.email ?? ""
            let displayName = currentUser?.displayName ?? username
            try? await FirebaseRESTService.shared.firestoreSet(path: "users/\(uid)", fields: [
                "username": username,
                "dob": dobStr,
                "birthdayDate": dobStr,
                "displayName": displayName,
                "name": displayName,
                "email": email
            ])
            try? await FirebaseRESTService.shared.firestoreSet(path: "usernames/\(username)", fields: [
                "uid": uid,
                "email": email
            ])
        }
    }

    public func savePartner(uid: String, name: String) {
        defaults.set(uid, forKey: "partner_uid")
        defaults.set(name, forKey: "partner_name")
        defaults.set(true, forKey: "onboarding_complete")
        hasPartner = true
        partnerSkipped = false
        // Sync to Firestore
        Task {
            guard let myUid = localUserId else { return }
            let coupleId = [myUid, uid].sorted().joined(separator: "_")
            try? await FirebaseRESTService.shared.firestoreSet(path: "users/\(myUid)", fields: [
                "partnerUid": uid, "partnerName": name, "coupleId": coupleId
            ])
            try? await FirebaseRESTService.shared.firestoreSet(path: "users/\(uid)", fields: [
                "partnerUid": myUid, "partnerName": currentUser?.displayName ?? "Pareja", "coupleId": coupleId
            ])
        }
    }

    public func didSkipPartner() {
        partnerSkipped = true
        defaults.set(true, forKey: "partner_skipped")
    }

    private var localUserId: String? {
        FirebaseRESTService.shared.localId ?? currentUser?.id
    }

    public func saveUser(_ user: UserModel) {
        currentUser = user
        defaults.set(user.id, forKey: "auth_user_id")
        defaults.set(user.email, forKey: "auth_user_email")
        defaults.set(user.displayName, forKey: "auth_user_name")
        defaults.set(user.pairCode, forKey: "auth_pair_code")
        if let partnerUid = user.partnerUid { defaults.set(partnerUid, forKey: "partner_uid") }
    }

    public var currentUserName: String {
        currentUser?.displayName ?? "Usuario"
    }

    public var currentUserEmail: String {
        currentUser?.email ?? ""
    }

    public var currentUserId: String {
        currentUser?.id ?? ""
    }
}

public enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case networkError

    public var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "Correo o contraseña inválidos"
        case .networkError: return "Error de conexión. Intenta de nuevo."
        }
    }
}
