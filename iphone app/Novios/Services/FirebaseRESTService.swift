import Foundation

public class FirebaseRESTService {
    public static let shared = FirebaseRESTService()

    private let primaryAPIKey = "AIzaSyASvpCiEJzuuCg31pVw7qDxnp26LKrJhJA"
    private let secondaryAPIKey = "AIzaSyAgZLZSshhuHpUi62b9UZsLOchjM9G-xWc"
    private let primaryProjectID = "novios-everus"

    public private(set) var currentAPIKey: String
    public private(set) var currentProjectID: String
    public private(set) var idToken: String?
    public private(set) var localId: String?
    public private(set) var refreshToken: String?

    private let session = URLSession.shared

    private init() {
        currentAPIKey = primaryAPIKey
        currentProjectID = primaryProjectID
        loadSavedConfig()
    }

    public func loadSavedConfig() {
        idToken = UserDefaults.standard.string(forKey: "fb_id_token")
        localId = UserDefaults.standard.string(forKey: "fb_local_id")
        refreshToken = UserDefaults.standard.string(forKey: "fb_refresh_token")
    }

    // MARK: - Firebase Auth REST API

    public func signIn(email: String, password: String) async throws -> (localId: String, idToken: String, refreshToken: String) {
        do {
            return try await performSignIn(email: email, password: password, apiKey: primaryAPIKey)
        } catch {
            return try await performSignIn(email: email, password: password, apiKey: secondaryAPIKey)
        }
    }

    private func performSignIn(email: String, password: String, apiKey: String) async throws -> (localId: String, idToken: String, refreshToken: String) {
        let url = URL(string: "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=\(apiKey)")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "password": password,
            "returnSecureToken": true
        ])
        let data = try await performRequest(req)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let idToken = json["idToken"] as? String,
              let localId = json["localId"] as? String,
              let refreshTkn = json["refreshToken"] as? String else {
            throw FirebaseError.invalidResponse
        }
        self.currentAPIKey = apiKey
        self.idToken = idToken; self.localId = localId; self.refreshToken = refreshTkn
        saveTokens()
        return (localId, idToken, refreshTkn)
    }

    public func refreshIdToken() async throws -> String {
        guard let refreshToken = refreshToken, !refreshToken.isEmpty else { throw FirebaseError.notAuthenticated }
        let url = URL(string: "https://securetoken.googleapis.com/v1/token?key=\(currentAPIKey)")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken
        ])
        let data = try await performRequest(req)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let newIdToken = json["id_token"] as? String,
              let newRefreshToken = json["refresh_token"] as? String else {
            throw FirebaseError.invalidResponse
        }
        idToken = newIdToken; self.refreshToken = newRefreshToken
        saveTokens()
        return newIdToken
    }

    // MARK: - Firestore REST API

    private func getAuthHeader() async throws -> [String: String] {
        if idToken == nil { _ = try await refreshIdToken() }
        guard let token = idToken else { throw FirebaseError.notAuthenticated }
        if let exp = try? parseJWTExp(token), exp < Date().timeIntervalSince1970 {
            let refreshed = try await refreshIdToken()
            return ["Authorization": "Bearer \(refreshed)", "Content-Type": "application/json"]
        }
        return ["Authorization": "Bearer \(token)", "Content-Type": "application/json"]
    }

    private func firestoreURL(_ path: String) -> String {
        let encoded = path.split(separator: "/").map {
            $0.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String($0)
        }.joined(separator: "/")
        return "https://firestore.googleapis.com/v1/projects/\(currentProjectID)/databases/(default)/documents/\(encoded)"
    }

    private func ensureAuth() async throws {
        if idToken == nil { _ = try await refreshIdToken() }
        if let exp = try? parseJWTExp(idToken!), exp < Date().timeIntervalSince1970 {
            _ = try await refreshIdToken()
        }
    }

    public func firestoreGet(path: String) async throws -> [String: Any]? {
        try await ensureAuth()
        var headers = try await getAuthHeader()
        let url = URL(string: firestoreURL(path))!
        var req = URLRequest(url: url)
        req.allHTTPHeaderFields = headers
        do {
            let data = try await performRequest(req)
            return try JSONSerialization.jsonObject(with: data) as? [String: Any]
        } catch FirebaseError.serverError(let msg) where msg.contains("401") || msg.contains("403") || msg.contains("unauthenticated") || msg.contains("UNAUTHENTICATED") {
            _ = try await refreshIdToken()
            headers = try await getAuthHeader()
            req.allHTTPHeaderFields = headers
            let data = try await performRequest(req)
            return try JSONSerialization.jsonObject(with: data) as? [String: Any]
        }
    }

    public func firestoreSet(path: String, fields: [String: Any]) async throws {
        try await ensureAuth()
        var headers = try await getAuthHeader()
        
        var urlString = firestoreURL(path)
        if !fields.isEmpty {
            let masks = fields.keys.map { "updateMask.fieldPaths=\($0.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0)" }.joined(separator: "&")
            urlString += "?\(masks)"
        }
        
        let url = URL(string: urlString)!
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.allHTTPHeaderFields = headers
        req.httpBody = try JSONSerialization.data(withJSONObject: ["fields": encodeFields(fields)])
        do {
            _ = try await performRequest(req)
        } catch FirebaseError.serverError(let msg) where msg.contains("401") || msg.contains("403") || msg.contains("unauthenticated") || msg.contains("UNAUTHENTICATED") {
            _ = try await refreshIdToken()
            headers = try await getAuthHeader()
            req.allHTTPHeaderFields = headers
            _ = try await performRequest(req)
        }
    }

    public func firestoreList(path: String) async throws -> [[String: Any]] {
        try await ensureAuth()
        var headers = try await getAuthHeader()
        var urlStr = firestoreURL(path)
        if !urlStr.contains("?") {
            urlStr += "?pageSize=300"
        } else {
            urlStr += "&pageSize=300"
        }
        let url = URL(string: urlStr)!
        var req = URLRequest(url: url)
        req.allHTTPHeaderFields = headers
        do {
            let data = try await performRequest(req)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let documents = json["documents"] as? [[String: Any]] else { return [] }
            return documents
        } catch FirebaseError.serverError(let msg) where msg.contains("401") || msg.contains("403") || msg.contains("unauthenticated") || msg.contains("UNAUTHENTICATED") {
            _ = try await refreshIdToken()
            headers = try await getAuthHeader()
            req.allHTTPHeaderFields = headers
            let data = try await performRequest(req)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let documents = json["documents"] as? [[String: Any]] else { return [] }
            return documents
        }
    }

    public func firestoreDelete(path: String) async throws {
        try await ensureAuth()
        var headers = try await getAuthHeader()
        let url = URL(string: firestoreURL(path))!
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        req.allHTTPHeaderFields = headers
        do {
            _ = try await performRequest(req)
        } catch FirebaseError.serverError(let msg) where msg.contains("401") || msg.contains("403") || msg.contains("unauthenticated") || msg.contains("UNAUTHENTICATED") {
            _ = try await refreshIdToken()
            headers = try await getAuthHeader()
            req.allHTTPHeaderFields = headers
            _ = try await performRequest(req)
        }
    }

    // MARK: - Helpers

    private func performRequest(_ req: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: req)
        guard let httpResp = response as? HTTPURLResponse else { throw FirebaseError.networkError }
        if httpResp.statusCode == 200 || httpResp.statusCode == 201 { return data }
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            if message.contains("EMAIL_EXISTS") { throw FirebaseError.emailExists }
            if message.contains("INVALID_LOGIN") || message.contains("INVALID_PASSWORD") || message.contains("EMAIL_NOT_FOUND") {
                throw FirebaseError.invalidCredentials
            }
            throw FirebaseError.serverError(message)
        }
        throw FirebaseError.httpError(httpResp.statusCode)
    }

    private func saveTokens() {
        UserDefaults.standard.set(idToken, forKey: "fb_id_token")
        UserDefaults.standard.set(localId, forKey: "fb_local_id")
        UserDefaults.standard.set(refreshToken, forKey: "fb_refresh_token")
    }

    public func signOut() {
        idToken = nil; localId = nil; refreshToken = nil
        UserDefaults.standard.removeObject(forKey: "fb_id_token")
        UserDefaults.standard.removeObject(forKey: "fb_local_id")
        UserDefaults.standard.removeObject(forKey: "fb_refresh_token")
    }

    private func encodeFields(_ fields: [String: Any]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in fields {
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
        if let arr = value as? [Any] {
            return ["arrayValue": ["values": arr.map { firestoreValue($0) }]]
        }
        if let dict = value as? [String: Any] {
            return ["mapValue": ["fields": encodeFields(dict)]]
        }
        return ["stringValue": "\(value)"]
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
