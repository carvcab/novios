import Foundation

public class FirebaseRESTService {
    public static let shared = FirebaseRESTService()

    private let primaryAPIKey = "AIzaSyCG9W2qU4SH2RkjNRJHI96fJzt3hHqLzys"
    private let primaryProjectID = "novios-49289"
    private let backupAPIKey = "AIzaSyCSgxk_uEtVFmJHTqCMmlaKmnc8Fvf_rnQ"
    private let backupProjectID = "novios-8beb7"

    public private(set) var currentAPIKey: String
    public private(set) var currentProjectID: String
    public private(set) var isUsingBackup = false
    public private(set) var idToken: String?
    public private(set) var localId: String?
    public private(set) var refreshToken: String?

    private let session = URLSession.shared

    private init() {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: "firebase_use_backup") {
            currentAPIKey = backupAPIKey
            currentProjectID = backupProjectID
            isUsingBackup = true
        } else {
            currentAPIKey = primaryAPIKey
            currentProjectID = primaryProjectID
        }
    }

    public func switchToBackup() {
        currentAPIKey = backupAPIKey
        currentProjectID = backupProjectID
        isUsingBackup = true
        UserDefaults.standard.set(true, forKey: "firebase_use_backup")
    }

    public func switchToPrimary() {
        currentAPIKey = primaryAPIKey
        currentProjectID = primaryProjectID
        isUsingBackup = false
        UserDefaults.standard.removeObject(forKey: "firebase_use_backup")
    }

    public func loadSavedConfig() {
        switchToPrimary()
        idToken = UserDefaults.standard.string(forKey: "fb_id_token")
        localId = UserDefaults.standard.string(forKey: "fb_local_id")
        refreshToken = UserDefaults.standard.string(forKey: "fb_refresh_token")
    }

    // MARK: - Firebase Auth REST API

    public func signUp(email: String, password: String, displayName: String) async throws -> (localId: String, idToken: String, refreshToken: String) {
        let url = URL(string: "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=\(currentAPIKey)")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "password": password,
            "displayName": displayName,
            "returnSecureToken": true
        ])
        let data = try await performRequest(req)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let idToken = json["idToken"] as? String,
              let localId = json["localId"] as? String,
              let refreshTkn = json["refreshToken"] as? String else {
            throw FirebaseError.invalidResponse
        }
        self.idToken = idToken; self.localId = localId; self.refreshToken = refreshTkn
        saveTokens()
        return (localId, idToken, refreshTkn)
    }

    public func signIn(email: String, password: String) async throws -> (localId: String, idToken: String, refreshToken: String) {
        let url = URL(string: "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=\(currentAPIKey)")!
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
        self.idToken = idToken; self.localId = localId; self.refreshToken = refreshTkn
        saveTokens()
        return (localId, idToken, refreshTkn)
    }

    public func refreshIdToken() async throws -> String {
        let url = URL(string: "https://securetoken.googleapis.com/v1/token?key=\(currentAPIKey)")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken ?? ""
        ])
        let data = try await performRequest(req)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let newIdToken = json["id_token"] as? String,
              let newRefreshToken = json["refresh_token"] as? String else {
            throw FirebaseError.invalidResponse
        }
        idToken = newIdToken; refreshToken = newRefreshToken
        saveTokens()
        return newIdToken
    }

    public func getUserData() async throws -> [String: Any]? {
        guard let idToken = idToken else { return nil }
        let url = URL(string: "https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=\(currentAPIKey)")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["idToken": idToken])
        let data = try await performRequest(req)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let users = json["users"] as? [[String: Any]],
              let user = users.first else { return nil }
        return user
    }

    // MARK: - Firestore REST API

    private func getAuthHeader() async throws -> [String: String] {
        if idToken == nil { throw FirebaseError.notAuthenticated }
        var token = idToken!
        if let exp = try? parseJWTExp(token), exp < Date().timeIntervalSince1970 {
            token = try await refreshIdToken()
        }
        return ["Authorization": "Bearer \(token)", "Content-Type": "application/json"]
    }

    private func firestoreURL(_ path: String) -> String {
        let encoded = path.split(separator: "/").map {
            $0.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String($0)
        }.joined(separator: "/")
        return "https://firestore.googleapis.com/v1/projects/\(currentProjectID)/databases/(default)/documents/\(encoded)"
    }

    public func firestoreGet(path: String) async throws -> [String: Any]? {
        var headers = try await getAuthHeader()
        let url = URL(string: firestoreURL(path))!
        var req = URLRequest(url: url)
        req.allHTTPHeaderFields = headers
        do {
            let data = try await performRequest(req)
            return try JSONSerialization.jsonObject(with: data) as? [String: Any]
        } catch FirebaseError.serverError(let msg) where msg.contains("401") || msg.contains("403") || msg.contains("unauthenticated") || msg.contains("UNAUTHENTICATED") {
            // Token expired, refresh and retry
            try await refreshIdToken()
            headers = try await getAuthHeader()
            req.allHTTPHeaderFields = headers
            let data = try await performRequest(req)
            return try JSONSerialization.jsonObject(with: data) as? [String: Any]
        }
    }

    public func firestoreSet(path: String, fields: [String: Any]) async throws {
        var headers = try await getAuthHeader()
        let url = URL(string: firestoreURL(path))!
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.allHTTPHeaderFields = headers
        req.httpBody = try JSONSerialization.data(withJSONObject: ["fields": encodeFields(fields)])
        do {
            _ = try await performRequest(req)
        } catch FirebaseError.serverError(let msg) where msg.contains("401") || msg.contains("403") || msg.contains("unauthenticated") || msg.contains("UNAUTHENTICATED") {
            try await refreshIdToken()
            headers = try await getAuthHeader()
            req.allHTTPHeaderFields = headers
            _ = try await performRequest(req)
        }
    }

    public func firestoreCreate(path: String, fields: [String: Any]) async throws -> String? {
        let headers = try await getAuthHeader()
        let url = URL(string: firestoreURL(path))!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = headers
        req.httpBody = try JSONSerialization.data(withJSONObject: ["fields": encodeFields(fields)])
        let data = try await performRequest(req)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["name"] as? String
    }

    public func firestoreQuery(path: String, field: String, op: String, value: Any) async throws -> [[String: Any]] {
        let headers = try await getAuthHeader()
        let url = URL(string: "https://firestore.googleapis.com/v1/projects/\(currentProjectID)/databases/(default)/documents:runQuery")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = headers
        let filter: [String: Any] = [
            "fieldFilter": [
                "field": ["fieldPath": field],
                "op": op,
                "value": firestoreValue(value)
            ]
        ]
        let structuredQuery: [String: Any] = [
            "structuredQuery": [
                "from": [["collectionId": path]],
                "where": filter,
                "limit": 10
            ]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: structuredQuery)
        let data = try await performRequest(req)
        let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
        return json.compactMap { $0["document"] as? [String: Any] }
    }

    public func firestoreList(path: String) async throws -> [[String: Any]] {
        let headers = try await getAuthHeader()
        let url = URL(string: firestoreURL(path))!
        var req = URLRequest(url: url)
        req.allHTTPHeaderFields = headers
        let data = try await performRequest(req)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let documents = json["documents"] as? [[String: Any]] else { return [] }
        return documents
    }

    public func firestoreDelete(path: String) async throws {
        let headers = try await getAuthHeader()
        let url = URL(string: firestoreURL(path))!
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        req.allHTTPHeaderFields = headers
        _ = try await performRequest(req)
    }

    // Polling-based real-time updates (Firestore REST doesn't support streaming without gRPC)
    public func startPolling(path: String, interval: TimeInterval = 2, onChange: @escaping ([String: Any]?) -> Void) -> Timer {
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            Task {
                guard let data = try? await self.firestoreGet(path: path) else { return }
                await MainActor.run { onChange(data) }
            }
        }
        return timer
    }

    // MARK: - Helpers

    private func performRequest(_ req: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: req)
        guard let httpResp = response as? HTTPURLResponse else { throw FirebaseError.networkError }
        if httpResp.statusCode == 200 || httpResp.statusCode == 201 { return data }
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            if message.contains("QUOTA") || message.contains("quota") || message.contains("RESOURCE_EXHAUSTED") {
                handleQuotaExceeded()
            }
            if message.contains("EMAIL_EXISTS") { throw FirebaseError.emailExists }
            if message.contains("INVALID_LOGIN") || message.contains("INVALID_PASSWORD") || message.contains("EMAIL_NOT_FOUND") {
                throw FirebaseError.invalidCredentials
            }
            throw FirebaseError.serverError(message)
        }
        throw FirebaseError.httpError(httpResp.statusCode)
    }

    private func handleQuotaExceeded() {
        print("Firebase REST quota warning")
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
