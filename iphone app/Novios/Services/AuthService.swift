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
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        let user = UserModel(
            id: UUID().uuidString,
            email: "usuario@gmail.com",
            displayName: "Usuario",
            username: "usuario_\(Int.random(in: 100...999))"
        )
        await MainActor.run {
            self.currentUser = user
            self.isLoggedIn = true
            self.isLoading = false
            saveSession(user: user)
        }
        return user
    }

    public func signInWithEmail(email: String, password: String) async throws {
        await MainActor.run { isLoading = true }
        try? await Task.sleep(nanoseconds: 800_000_000)
        guard email.contains("@"), password.count >= 6 else {
            await MainActor.run { isLoading = false }
            throw AuthError.invalidCredentials
        }
        let user = UserModel(
            id: UUID().uuidString,
            email: email,
            displayName: email.components(separatedBy: "@").first?.capitalized ?? "Usuario",
            username: email.components(separatedBy: "@").first ?? "usuario"
        )
        await MainActor.run {
            self.currentUser = user
            self.isLoggedIn = true
            self.isLoading = false
            saveSession(user: user)
            checkProfileAndPartner()
        }
    }

    public func signUpWithEmail(email: String, password: String, name: String) async throws {
        await MainActor.run { isLoading = true }
        try? await Task.sleep(nanoseconds: 800_000_000)
        guard email.contains("@"), password.count >= 6, !name.isEmpty else {
            await MainActor.run { isLoading = false }
            throw AuthError.invalidCredentials
        }
        let user = UserModel(
            id: UUID().uuidString,
            email: email,
            displayName: name,
            username: email.components(separatedBy: "@").first ?? name.lowercased()
        )
        await MainActor.run {
            self.currentUser = user
            self.isLoggedIn = true
            self.isLoading = false
            saveSession(user: user)
        }
    }

    public func signOut() {
        currentUser = nil
        isLoggedIn = false
        hasProfile = false
        hasPartner = false
        partnerSkipped = false
        defaults.removeObject(forKey: "auth_user_id")
        defaults.removeObject(forKey: "auth_user_email")
        defaults.removeObject(forKey: "auth_user_name")
        defaults.removeObject(forKey: "auth_logged_in")
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
        defaults.set(df.string(from: dob), forKey: "profile_dob")
        defaults.set(username, forKey: "profile_username")
        if let name = partnerName { defaults.set(name, forKey: "profile_partner_name") }
        hasProfile = true
    }

    public func savePartner(uid: String, name: String) {
        defaults.set(uid, forKey: "partner_uid")
        defaults.set(name, forKey: "partner_name")
        hasPartner = true
        partnerSkipped = false
    }

    public func didSkipPartner() {
        partnerSkipped = true
        defaults.set(true, forKey: "partner_skipped")
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
