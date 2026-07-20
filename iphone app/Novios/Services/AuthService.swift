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

    private let defaults = UserDefaults.standard

    private init() {
        loadSession()
    }

    public func signInWithGoogle() async -> UserModel? {
        await MainActor.run { isLoading = true }
        do {
            let result = try await FirebaseRESTService.shared.signUp(email: "\(UUID().uuidString)@google.com", password: "google_\(UUID().uuidString)", displayName: "Usuario")
            let user = UserModel(id: result.localId, email: "", displayName: "Usuario", username: "usuario_\(Int.random(in: 100...999))")
            await MainActor.run {
                self.currentUser = user; self.isLoggedIn = true; self.isLoading = false
                saveSession(user: user)
            }
            return user
        } catch {
            await MainActor.run { self.isLoading = false }
            return nil
        }
    }

    public func signInWithEmail(email: String, password: String) async throws {
        await MainActor.run { isLoading = true }
        do {
            let result = try await FirebaseRESTService.shared.signIn(email: email, password: password)
            let data = try? await FirebaseRESTService.shared.getUserData()
            let name = data?["displayName"] as? String ?? email.components(separatedBy: "@").first?.capitalized ?? "Usuario"
            let user = UserModel(id: result.localId, email: email, displayName: name, username: email.components(separatedBy: "@").first ?? "usuario")
            await MainActor.run {
                self.currentUser = user; self.isLoggedIn = true; self.isLoading = false
                saveSession(user: user); checkProfileAndPartner()
                // Try to sync profile from Firestore
                Task { try? await syncUserFromFirestore(uid: result.localId) }
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
         "partner_uid","partner_name","partner_skipped","fb_id_token","fb_local_id","fb_refresh_token"].forEach {
            defaults.removeObject(forKey: $0)
        }
    }

    private func syncUserFromFirestore(uid: String) async throws {
        guard let doc = try? await FirebaseRESTService.shared.firestoreGet(path: "users/\(uid)"),
              let fields = doc["fields"] as? [String: Any] else { return }
        let username = (fields["username"] as? [String: Any])?["stringValue"] as? String
        let dob = (fields["dob"] as? [String: Any])?["stringValue"] as? String
        let partnerUid = (fields["partnerUid"] as? [String: Any])?["stringValue"] as? String
        if let u = username, let d = dob, !u.isEmpty, !d.isEmpty {
            let defaults = UserDefaults.standard
            defaults.set(d, forKey: "profile_dob")
            defaults.set(u, forKey: "profile_username")
            hasProfile = true
        }
        if let puid = partnerUid, !puid.isEmpty {
            let pname = (fields["partnerName"] as? [String: Any])?["stringValue"] as? String ?? "Pareja"
            let defaults = UserDefaults.standard
            defaults.set(puid, forKey: "partner_uid")
            defaults.set(pname, forKey: "partner_name")
            hasPartner = true
        }
    }

    public func checkProfileAndPartner() {
        hasProfile = defaults.string(forKey: "profile_dob") != nil &&
                     defaults.string(forKey: "profile_username") != nil &&
                     !(defaults.string(forKey: "profile_username")?.isEmpty ?? true)
        hasPartner = defaults.string(forKey: "partner_uid") != nil &&
                     !(defaults.string(forKey: "partner_uid")?.isEmpty ?? true)
        partnerSkipped = defaults.bool(forKey: "partner_skipped")
    }

    private func loadSession() {
        if defaults.bool(forKey: "auth_logged_in"),
           let uid = defaults.string(forKey: "auth_user_id") {
            let email = defaults.string(forKey: "auth_user_email") ?? ""
            let name = defaults.string(forKey: "auth_user_name") ?? "Usuario"
            currentUser = UserModel(id: uid, email: email, displayName: name, username: "")
            isLoggedIn = true
            checkProfileAndPartner()
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
        hasProfile = true
        // Sync to Firestore
        Task {
            guard let uid = localUserId else { return }
            try? await FirebaseRESTService.shared.firestoreSet(path: "users/\(uid)", fields: [
                "username": username,
                "dob": dobStr,
                "displayName": currentUser?.displayName ?? username
            ])
        }
    }

    public func savePartner(uid: String, name: String) {
        defaults.set(uid, forKey: "partner_uid")
        defaults.set(name, forKey: "partner_name")
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
