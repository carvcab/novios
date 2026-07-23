import Foundation
import Combine
import FirebaseAuth

public class AuthService: ObservableObject {
    public static let shared = AuthService()

    @Published public var currentUser: UserModel?
    @Published public var isLoggedIn = false
    @Published public var isLoading = false
    @Published public var isRestoringSession = true
    @Published public var isLocked = false
    @Published public var authError: String?

    private let defaults = UserDefaults.standard

    public static let diegoUid = "joeBcVn2o1hfXfU68rWNOyAZIqt2"
    public static let yosmariUid = "Dd1X94n3gxg7leWtMtnLlxDVHcm2"

    private init() {
        FirebaseRESTService.shared.loadSavedConfig()
        loadSession()
    }

    // MARK: - Sign In (Diego or Yosmari)

    public func signIn(email: String, password: String) async -> Bool {
        await MainActor.run { isLoading = true; authError = nil }
        do {
            let result = try await FirebaseRESTService.shared.signIn(email: email, password: password)
            let uid = result.localId
            guard uid == Self.diegoUid || uid == Self.yosmariUid else {
                await MainActor.run { isLoading = false; authError = "Esta cuenta no está autorizada."; isLoggedIn = false }
                return false
            }
            
            let name = uid == Self.diegoUid ? "Diego" : "Yosmari"
            let user = UserModel(
                id: uid,
                nombre: name,
                correo: email,
                foto: "",
                PIN: "",
                ultimaConexion: Date(),
                ultimoAcceso: Date(),
                tokenFCM: "",
                configuracionPersonal: "{}",
                parejaId: CoupleService.coupleId
            )

            await MainActor.run {
                self.currentUser = user
                self.isLoggedIn = true
                self.isLoading = false
                saveSession(user: user)
            }

            try await ensureUserAndCoupleCreated(uid: uid, name: name, email: email)
            await CoupleService.shared.loadCouple()
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

    // MARK: - Session Restore & Initialization

    private func loadSession() {
        if let user = Auth.auth().currentUser {
            let uid = user.uid
            guard uid == Self.diegoUid || uid == Self.yosmariUid else {
                try? Auth.auth().signOut()
                clearUserDefaults()
                isRestoringSession = false
                return
            }
            let email = user.email ?? ""
            let name = uid == Self.diegoUid ? "Diego" : "Yosmari"
            currentUser = UserModel(id: uid, nombre: name, correo: email, parejaId: CoupleService.coupleId)
            isLoggedIn = true
            saveSession(user: currentUser!)
            Task {
                try? await ensureUserAndCoupleCreated(uid: uid, name: name, email: email)
                await CoupleService.shared.loadCouple()
                await MainActor.run { self.isRestoringSession = false }
            }
        } else if defaults.bool(forKey: "auth_logged_in") {
            clearUserDefaults()
            isRestoringSession = false
        } else {
            isRestoringSession = false
        }
    }

    public func ensureUserAndCoupleCreated(uid: String, name: String, email: String) async throws {
        let df = ISO8601DateFormatter()
        let now = df.string(from: Date())
        let coupleId = [Self.diegoUid, Self.yosmariUid].sorted().joined(separator: "_")

        // 1. Create/Update user document in users/{uid} (matches Flutter)
        try await FirebaseRESTService.shared.firestoreSet(path: "users/\(uid)", fields: [
            "id": uid,
            "name": name,
            "email": email,
            "coupleId": coupleId,
            "updatedAt": now
        ])

        // 2. Create/Update couple document in couples/{coupleId} (matches Flutter)
        try await FirebaseRESTService.shared.firestoreSet(path: "couples/\(coupleId)", fields: [
            "names": [name, name == "Diego" ? "Yosmari" : "Diego"],
            "members": [Self.diegoUid, Self.yosmariUid],
            "createdAt": now
        ])
    }

    private func saveSession(user: UserModel) {
        defaults.set(user.id, forKey: "auth_user_id")
        defaults.set(user.correo, forKey: "auth_user_email")
        defaults.set(user.nombre, forKey: "auth_user_name")
        defaults.set(true, forKey: "auth_logged_in")
    }
}
