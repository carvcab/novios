import Foundation
import Combine

public class AuthService: ObservableObject {
    public static let shared = AuthService()

    @Published public var currentUser: UserModel?
    @Published public var isLoggedIn = false
    @Published public var isLoading = false
    @Published public var isRestoringSession = true
    @Published public var isLocked = false
    @Published public var authError: String?

    private let defaults = UserDefaults.standard

    public let fixedAccounts: [(uid: String, email: String, name: String)] = [
        ("joeBcVn2o1hfXfU68rWNOyAZIqt2", "diego@novios.app", "Diego"),
        ("Dd1X94n3gxg7leWtMtnLlxDVHcm2", "yosmari@novios.app", "Yosmari")
    ]

    private init() {
        FirebaseRESTService.shared.loadSavedConfig()
        loadSession()
    }

    // MARK: - Sign In (only fixed accounts)

    public func signIn(email: String, password: String) async -> Bool {
        await MainActor.run { isLoading = true; authError = nil }
        do {
            let result = try await FirebaseRESTService.shared.signIn(email: email, password: password)
            guard let account = fixedAccounts.first(where: { $0.uid == result.localId }) else {
                await MainActor.run { isLoading = false; authError = "Esta cuenta no está autorizada."; isLoggedIn = false }
                return false
            }
            let user = UserModel(id: result.localId, email: email, displayName: account.name, username: account.name.lowercased())
            await MainActor.run {
                self.currentUser = user
                self.isLoggedIn = true
                self.isLoading = false
                saveSession(user: user)
            }
            let df = ISO8601DateFormatter()
            let now = df.string(from: Date())
            try? await FirebaseRESTService.shared.firestoreSet(path: "usuarios/\(result.localId)", fields: [
                "nombre": account.name,
                "correo": email,
                "foto": "",
                "PIN": "",
                "ultimaConexion": now,
                "ultimoAcceso": now,
                "tokenFCM": "",
                "configuracionPersonal": "",
                "parejaId": "pareja_001",
            ])
            try? await CoupleService.shared.ensureParejaDocExists()
            return true
        } catch {
            await MainActor.run { isLoading = false; authError = "Correo o contraseña incorrectos." }
            return false
        }
    }

    // MARK: - Sign Out

    public func signOut() {
        FirebaseRESTService.shared.signOut()
        currentUser = nil; isLoggedIn = false; isLocked = false
        clearUserDefaults()
    }

    private func clearUserDefaults() {
        ["auth_user_id","auth_user_email","auth_user_name","auth_logged_in","fb_id_token","fb_local_id","fb_refresh_token"].forEach {
            defaults.removeObject(forKey: $0)
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
        currentUser = UserModel(id: uid, email: email, displayName: name, username: name.lowercased())
        isLoggedIn = true
        isRestoringSession = false
    }

    private func saveSession(user: UserModel) {
        defaults.set(user.id, forKey: "auth_user_id")
        defaults.set(user.email, forKey: "auth_user_email")
        defaults.set(user.displayName, forKey: "auth_user_name")
        defaults.set(true, forKey: "auth_logged_in")
    }
}
