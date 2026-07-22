import Foundation
import FirebaseAuth
import FirebaseFirestore

public class FirebaseRESTService {
    public static let shared = FirebaseRESTService()

    public var localId: String? { Auth.auth().currentUser?.uid }
    public private(set) var idToken: String?

    private let db = Firestore.firestore()
    private var tokenListener: NSObjectProtocol?

    private init() {
        loadSavedConfig()
        listenForAuthChanges()
    }

    private func listenForAuthChanges() {
        tokenListener = Auth.auth().addIDTokenDidChangeListener { [weak self] _, user in
            Task {
                if let user = user {
                    self?.idToken = try? await user.getIDToken()
                } else {
                    self?.idToken = nil
                }
            }
        }
    }

    public func loadSavedConfig() {
        if let user = Auth.auth().currentUser {
            Task {
                idToken = try? await user.getIDToken()
            }
        }
    }

    // MARK: - Auth

    public func signIn(email: String, password: String) async throws -> (localId: String, idToken: String, refreshToken: String) {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        let token = try await result.user.getIDToken()
        self.idToken = token
        saveTokens()
        return (result.user.uid, token, "")
    }

    public func refreshIdToken() async throws -> String {
        guard let user = Auth.auth().currentUser else { throw FirebaseError.notAuthenticated }
        let token = try await user.getIDToken()
        idToken = token
        return token
    }

    public func signOut() {
        idToken = nil
        try? Auth.auth().signOut()
        UserDefaults.standard.removeObject(forKey: "fb_id_token")
        UserDefaults.standard.removeObject(forKey: "fb_local_id")
        UserDefaults.standard.removeObject(forKey: "fb_refresh_token")
    }

    // MARK: - Firestore Read

    public func firestoreGet(path: String) async throws -> [String: Any]? {
        let doc = try await db.document(path).getDocument()
        guard doc.exists, let data = doc.data() else { return nil }
        return ["fields": encodeRESTFields(data), "name": "\(doc.reference.path)"]
    }

    public func firestoreList(path: String) async throws -> [[String: Any]] {
        let snapshot = try await db.collection(path).getDocuments()
        return snapshot.documents.map { doc in
            let data = doc.data()
            return [
                "fields": encodeRESTFields(data),
                "name": "\(doc.reference.path)"
            ]
        }
    }

    public func firestoreQuery(parent: String, collectionId: String, limit: Int = 150) async throws -> [[String: Any]] {
        let snapshot = try await db.collection(parent).document(collectionId).collection(collectionId)
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()
        return snapshot.documents.map { doc in
            ["document": [
                "fields": encodeRESTFields(doc.data()),
                "name": "\(doc.reference.path)"
            ]]
        }
    }

    // MARK: - Firestore Write

    public func firestoreSet(path: String, fields: [String: Any]) async throws {
        try await db.document(path).setData(fields, merge: true)
    }

    public func firestoreDelete(path: String) async throws {
        try await db.document(path).delete()
    }

    // MARK: - Helpers

    private func saveTokens() {
        UserDefaults.standard.set(idToken, forKey: "fb_id_token")
        if let uid = localId {
            UserDefaults.standard.set(uid, forKey: "fb_local_id")
        }
    }

    private func encodeRESTFields(_ data: [String: Any]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in data {
            result[key] = firestoreValue(value)
        }
        return result
    }

    private func firestoreValue(_ value: Any) -> [String: Any] {
        if let s = value as? String { return ["stringValue": s] }
        if let n = value as? Int { return ["integerValue": "\(n)"] }
        if let n = value as? Double { return ["doubleValue": n] }
        if let b = value as? Bool { return ["booleanValue": b] }
        if let d = value as? Date {
            let df = ISO8601DateFormatter()
            return ["timestampValue": df.string(from: d)]
        }
        if let ts = value as? Timestamp {
            let df = ISO8601DateFormatter()
            return ["timestampValue": df.string(from: ts.dateValue())]
        }
        if let arr = value as? [Any] {
            return ["arrayValue": ["values": arr.map { firestoreValue($0) }]]
        }
        if let dict = value as? [String: Any] {
            return ["mapValue": ["fields": encodeRESTFields(dict)]]
        }
        if let ref = value as? DocumentReference {
            return ["referenceValue": ref.path]
        }
        return ["stringValue": "\(value)"]
    }

    deinit {
        if let listener = tokenListener {
            Auth.auth().removeIDTokenDidChangeListener(listener)
        }
    }
}

public enum FirebaseError: Error, LocalizedError {
    case invalidResponse
    case networkError
    case notAuthenticated
    case emailExists
    case invalidCredentials
    case httpError(Int)
    case serverError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Respuesta inválida del servidor"
        case .networkError: return "Error de conexión"
        case .notAuthenticated: return "No autenticado"
        case .emailExists: return "El correo ya está registrado"
        case .invalidCredentials: return "Correo o contraseña incorrectos"
        case .httpError(let code): return "Error HTTP \(code)"
        case .serverError(let msg): return msg
        }
    }
}
