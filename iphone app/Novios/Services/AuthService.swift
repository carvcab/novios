import Foundation
import Combine

public class AuthService: ObservableObject {
    public static let shared = AuthService()
    
    @Published public var currentUser: UserModel?
    @Published public var isAuthenticated: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var authError: String?
    
    private init() {
        // Load saved session locally if exists
        loadSavedUserSession()
    }
    
    public func loadSavedUserSession() {
        if let data = UserDefaults.standard.data(forKey: "novios_saved_user"),
           let user = try? JSONDecoder().decode(UserModel.self, from: data) {
            self.currentUser = user
            self.isAuthenticated = true
        }
    }
    
    public func signIn(email: String, pass: String) async -> Bool {
        await MainActor.run { self.isLoading = true; self.authError = nil }
        try? await Task.sleep(nanoseconds: 500_000_000) // Simulate network
        
        let uid = "user_" + UUID().uuidString.prefix(6)
        let pairCode = String((0..<6).map { _ in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()! })
        let newUser = UserModel(
            id: uid,
            email: email,
            displayName: email.components(separatedBy: "@").first ?? "Usuario",
            username: email.components(separatedBy: "@").first?.lowercased() ?? "usuario",
            pairCode: pairCode
        )
        
        saveUser(newUser)
        await MainActor.run {
            self.currentUser = newUser
            self.isAuthenticated = true
            self.isLoading = false
        }
        return true
    }
    
    public func signUp(email: String, pass: String, name: String) async -> Bool {
        await MainActor.run { self.isLoading = true; self.authError = nil }
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        let uid = "user_" + UUID().uuidString.prefix(6)
        let pairCode = String((0..<6).map { _ in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()! })
        let newUser = UserModel(
            id: uid,
            email: email,
            displayName: name,
            username: name.lowercased().replacingOccurrences(of: " ", with: ""),
            pairCode: pairCode
        )
        
        saveUser(newUser)
        await MainActor.run {
            self.currentUser = newUser
            self.isAuthenticated = true
            self.isLoading = false
        }
        return true
    }

    public func saveUser(_ user: UserModel) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "novios_saved_user")
        }
    }
    
    public func signOut() {
        UserDefaults.standard.removeObject(forKey: "novios_saved_user")
        self.currentUser = nil
        self.isAuthenticated = false
    }
}
