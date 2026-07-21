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
    private let df = ISO8601DateFormatter()

    private init() {
        FirebaseRESTService.shared.loadSavedConfig()
        loadSession()
    }

    // MARK: - Sign In

    public func signInWithEmail(email: String, password: String) async throws {
        await MainActor.run { isLoading = true }
        do {
            let result = try await FirebaseRESTService.shared.signIn(email: email, password: password)

            try? await syncFromFirestore(uid: result.localId, email: email)

            let name = defaults.string(forKey: "auth_user_name") ?? email.components(separatedBy: "@").first?.capitalized ?? "Usuario"
            let uname = defaults.string(forKey: "profile_username") ?? email.components(separatedBy: "@").first ?? "usuario"
            let user = UserModel(id: result.localId, email: email, displayName: name, username: uname)

            await MainActor.run {
                self.currentUser = user
                self.saveSession(user: user)
                self.isLoggedIn = true
                self.isLoading = false
            }
        } catch {
            await MainActor.run { self.isLoading = false }
            throw error
        }
    }

    // MARK: - Sign Up

    public func signUpWithEmail(email: String, password: String, name: String) async throws {
        await MainActor.run { isLoading = true }
        do {
            let result = try await FirebaseRESTService.shared.signUp(email: email, password: password, displayName: name)
            let username = email.components(separatedBy: "@").first?.lowercased() ?? name.lowercased()

            let user = UserModel(id: result.localId, email: email, displayName: name, username: username)
            await MainActor.run {
                self.currentUser = user; self.isLoggedIn = true; self.isLoading = false
                saveSession(user: user)
            }

            defaults.set(name, forKey: "auth_user_name")
            defaults.set(username, forKey: "profile_username")

            try? await FirebaseRESTService.shared.firestoreSet(path: "users/\(result.localId)", fields: [
                "username": username,
                "displayName": name,
                "name": name,
                "email": email,
                "createdAt": df.string(from: Date())
            ])
            try? await FirebaseRESTService.shared.firestoreSet(path: "usernames/\(username)", fields: [
                "uid": result.localId,
                "email": email
            ])
        } catch {
            await MainActor.run { self.isLoading = false }
            throw error
        }
    }

    // MARK: - Sign Out

    public func signOut() {
        FirebaseRESTService.shared.signOut()
        currentUser = nil; isLoggedIn = false; hasProfile = false; hasPartner = false; partnerSkipped = false
        clearUserDefaults()
    }

    private func clearUserDefaults() {
        ["auth_user_id","auth_user_email","auth_user_name","auth_logged_in","profile_dob","profile_username",
         "partner_uid","partner_name","partner_skipped","fb_id_token","fb_local_id","fb_refresh_token","onboarding_complete"].forEach {
            defaults.removeObject(forKey: $0)
        }
    }

    // MARK: - Firestore Sync

    private func syncFromFirestore(uid: String, email: String) async throws {
        guard let doc = try? await FirebaseRESTService.shared.firestoreGet(path: "users/\(uid)"),
              let fields = doc["fields"] as? [String: Any] else {
            await MainActor.run { self.hasProfile = false; self.hasPartner = false }
            return
        }

        let extract = { (key: String) -> String? in
            guard let map = fields[key] as? [String: Any] else { return nil }
            return map["stringValue"] as? String ?? map["timestampValue"] as? String ?? map["integerValue"] as? String
        }

        let username = extract("username") ?? ""
        let displayName = extract("displayName") ?? extract("name") ?? ""
        let dob = extract("dob") ?? extract("birthdayDate") ?? extract("birthday_date") ?? ""
        let partnerUid = extract("partnerUid") ?? ""
        let partnerName = extract("partnerName") ?? ""

        if !username.isEmpty || !displayName.isEmpty {
            defaults.set(dob, forKey: "profile_dob")
            defaults.set(username.isEmpty ? displayName.lowercased() : username, forKey: "profile_username")
            if !displayName.isEmpty { defaults.set(displayName, forKey: "auth_user_name") }
        }

        let dateFields = ["anniversaryDate": "anniversary_date", "metDate": "met_date", "datingDate": "dating_date", "weddingDate": "wedding_date", "invitationDate": "invitation_date"]
        for (firestoreKey, defaultsKey) in dateFields {
            if let val = extract(firestoreKey), !val.isEmpty {
                defaults.set(val, forKey: defaultsKey)
            }
        }

        await MainActor.run {
            self.hasProfile = !username.isEmpty || !displayName.isEmpty
            if !partnerUid.isEmpty {
                defaults.set(partnerUid, forKey: "partner_uid")
                defaults.set(partnerName.isEmpty ? "Pareja" : partnerName, forKey: "partner_name")
                self.hasPartner = true
            } else {
                defaults.removeObject(forKey: "partner_uid")
                defaults.removeObject(forKey: "partner_name")
                self.hasPartner = false
            }
        }
    }

    // MARK: - Session Restore

    private func loadSession() {
        FirebaseRESTService.shared.loadSavedConfig()

        guard defaults.bool(forKey: "auth_logged_in"),
              let uid = defaults.string(forKey: "auth_user_id") else {
            isRestoringSession = false
            return
        }

        let email = defaults.string(forKey: "auth_user_email") ?? ""
        let name = defaults.string(forKey: "auth_user_name") ?? "Usuario"
        let username = defaults.string(forKey: "profile_username") ?? ""
        currentUser = UserModel(id: uid, email: email, displayName: name, username: username)
        isLoggedIn = true

        checkProfileAndPartner()

        Task {
            if let doc = try? await FirebaseRESTService.shared.firestoreGet(path: "users/\(uid)"),
               let fields = doc["fields"] as? [String: Any] {
                await syncFromFirestore(fields)
            }
            await MainActor.run {
                self.checkProfileAndPartner()
                self.isRestoringSession = false
            }
        }
        // If Firestore fetch takes too long, show UI anyway after 3s
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run {
                if self.isRestoringSession {
                    self.isRestoringSession = false
                }
            }
        }
    }

    private func syncFromFirestore(_ fields: [String: Any]) async {
        let extract = { (key: String) -> String? in
            (fields[key] as? [String: Any])?["stringValue"] as? String
        }
        let username = extract("username") ?? ""
        let displayName = extract("displayName") ?? extract("name") ?? ""
        let dob = extract("dob") ?? extract("birthdayDate") ?? extract("birthday_date") ?? ""
        let partnerUid = extract("partnerUid") ?? ""
        let partnerName = extract("partnerName") ?? ""

        if !username.isEmpty || !displayName.isEmpty {
            defaults.set(dob.isEmpty ? "2000-01-01" : dob, forKey: "profile_dob")
            defaults.set(username.isEmpty ? displayName.lowercased() : username, forKey: "profile_username")
            if !displayName.isEmpty { defaults.set(displayName, forKey: "auth_user_name") }
            await MainActor.run { self.hasProfile = true }
            let dateKeys = ["anniversaryDate", "metDate", "datingDate", "weddingDate", "invitationDate"]
            let defaultsKeys = ["anniversary_date", "met_date", "dating_date", "wedding_date", "invitation_date"]
            for (fk, dk) in zip(dateKeys, defaultsKeys) {
                if let val = extract(fk), !val.isEmpty { defaults.set(val, forKey: dk) }
            }
            // Ensure usernames/{username} document exists (Android always creates it)
            let finalUsername = username.isEmpty ? displayName.lowercased() : username
            if !finalUsername.isEmpty, let uid = FirebaseRESTService.shared.localId {
                Task {
                    if (try? await FirebaseRESTService.shared.firestoreGet(path: "usernames/\(finalUsername)")) == nil {
                        try? await FirebaseRESTService.shared.firestoreSet(path: "usernames/\(finalUsername)", fields: [
                            "uid": uid, "email": currentUser?.email ?? ""
                        ])
                    }
                }
            }
        }
        if !partnerUid.isEmpty {
            defaults.set(partnerUid, forKey: "partner_uid")
            defaults.set(partnerName, forKey: "partner_name")
            defaults.set(true, forKey: "onboarding_complete")
            await MainActor.run { self.hasPartner = true }
        }
        if FirebaseRESTService.shared.localId == nil {
            FirebaseRESTService.shared.loadSavedConfig()
        }
    }

    public func checkProfileAndPartner() {
        hasProfile = defaults.bool(forKey: "onboarding_complete") ||
            ((defaults.string(forKey: "profile_username") ?? "").isEmpty == false &&
             (defaults.string(forKey: "auth_user_name") ?? "").isEmpty == false)
        hasPartner = (defaults.string(forKey: "partner_uid") ?? "").isEmpty == false
        partnerSkipped = defaults.bool(forKey: "partner_skipped")
    }

    // MARK: - Session Save

    private func saveSession(user: UserModel) {
        defaults.set(user.id, forKey: "auth_user_id")
        defaults.set(user.email, forKey: "auth_user_email")
        defaults.set(user.displayName, forKey: "auth_user_name")
        defaults.set(true, forKey: "auth_logged_in")
    }

    // MARK: - Partner

    public func savePartner(uid: String, name: String) {
        defaults.set(uid, forKey: "partner_uid")
        defaults.set(name, forKey: "partner_name")
        defaults.set(true, forKey: "onboarding_complete")
        hasPartner = true
        partnerSkipped = false

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

    // MARK: - Profile

    public func saveProfile(dob: Date, username: String, partnerName: String?) {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let dobStr = df.string(from: dob)
        defaults.set(dobStr, forKey: "profile_dob")
        defaults.set(username, forKey: "profile_username")
        if let name = partnerName { defaults.set(name, forKey: "profile_partner_name") }
        defaults.set(true, forKey: "onboarding_complete")
        hasProfile = true

        Task {
            guard let uid = localUserId else { return }
            let email = currentUser?.email ?? ""
            let displayName = currentUser?.displayName ?? username
            try? await FirebaseRESTService.shared.firestoreSet(path: "users/\(uid)", fields: [
                "username": username, "dob": dobStr, "birthdayDate": dobStr,
                "displayName": displayName, "name": displayName, "email": email
            ])
            try? await FirebaseRESTService.shared.firestoreSet(path: "usernames/\(username)", fields: [
                "uid": uid, "email": email
            ])
        }
    }

    public func saveUser(_ user: UserModel) {
        currentUser = user
        defaults.set(user.id, forKey: "auth_user_id")
        defaults.set(user.email, forKey: "auth_user_email")
        defaults.set(user.displayName, forKey: "auth_user_name")
        if let partnerUid = user.partnerUid { defaults.set(partnerUid, forKey: "partner_uid") }
    }

    // MARK: - Computed

    public var currentUserName: String { currentUser?.displayName ?? "Usuario" }
    public var currentUserEmail: String { currentUser?.email ?? "" }
    public var currentUserId: String { currentUser?.id ?? "" }
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
