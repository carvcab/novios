import Foundation
import Combine

public enum AddPartnerResult {
    case success
    case alreadyHasPartner
    case targetHasPartner
    case notFound
    case error(String)
}

public class UserService: ObservableObject {
    public static let shared = UserService()
    
    @Published public var partnerUser: UserModel?
    @Published public var isSearching: Bool = false
    
    private var partnerObserverCancellable: AnyCancellable?
    
    private init() {
        loadMockPartnerIfNeeded()
    }
    
    public func searchUser(query: String) async -> [String: Any]? {
        await MainActor.run { self.isSearching = true }
        defer { Task { await MainActor.run { self.isSearching = false } } }

        let cleaned = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanUsername = cleaned.hasPrefix("@") ? String(cleaned.dropFirst()) : cleaned
        if cleanUsername.isEmpty { return nil }

        // 1. Search in usernames/{username} collection
        if let usernameDoc = try? await FirebaseRESTService.shared.firestoreGet(path: "usernames/\(cleanUsername)"),
           let fields = usernameDoc["fields"] as? [String: Any],
           let uid = (fields["uid"] as? [String: Any])?["stringValue"] as? String {
            if let userDoc = try? await FirebaseRESTService.shared.firestoreGet(path: "users/\(uid)"),
               let uf = userDoc["fields"] as? [String: Any] {
                let displayName = (uf["displayName"] as? [String: Any])?["stringValue"] as? String ?? (uf["name"] as? [String: Any])?["stringValue"] as? String ?? cleanUsername
                let uname = (uf["username"] as? [String: Any])?["stringValue"] as? String ?? cleanUsername
                let email = (uf["email"] as? [String: Any])?["stringValue"] as? String ?? ""
                return ["uid": uid, "displayName": displayName, "username": uname, "email": email]
            }
        }

        // 2. Search by username or email field in users collection
        let searchFields = ["username": cleanUsername, "email": cleaned]
        for (field, value) in searchFields {
            if let docs = try? await FirebaseRESTService.shared.firestoreQuery(path: "users", field: field, op: "EQUAL", value: value),
               let first = docs.first,
               let f = first["fields"] as? [String: Any] {
                let uid = (first["name"] as? String)?.split(separator: "/").last.map(String.init) ?? ""
                let displayName = (f["displayName"] as? [String: Any])?["stringValue"] as? String ?? (f["name"] as? [String: Any])?["stringValue"] as? String ?? value
                let uname = (f["username"] as? [String: Any])?["stringValue"] as? String ?? value
                let email = (f["email"] as? [String: Any])?["stringValue"] as? String ?? ""
                return ["uid": uid, "displayName": displayName, "username": uname, "email": email]
            }
        }

        return nil
    }
    
    public func addPartner(codeOrEmail: String, foundUserData: [String: Any]? = nil) async -> AddPartnerResult {
        guard let partnerData = foundUserData else { return .notFound }
        guard var user = AuthService.shared.currentUser else { return .error("Usuario no autenticado") }
        if user.isPaired { return .alreadyHasPartner }

        let partnerId = partnerData["uid"] as? String ?? ""
        let displayName = partnerData["displayName"] as? String ?? "Mi Pareja ❤️"
        let username = partnerData["username"] as? String ?? "pareja"
        let email = partnerData["email"] as? String ?? ""
        let myUid = FirebaseRESTService.shared.localId ?? user.id
        let coupleId = [myUid, partnerId].sorted().joined(separator: "_")

        // Write to Firestore
        do {
            try await FirebaseRESTService.shared.firestoreSet(path: "users/\(myUid)", fields: [
                "partnerUid": partnerId, "partnerName": displayName, "coupleId": coupleId,
                "displayName": user.displayName, "email": user.email, "username": user.username
            ])
            try await FirebaseRESTService.shared.firestoreSet(path: "users/\(partnerId)", fields: [
                "partnerUid": myUid, "partnerName": user.displayName, "coupleId": coupleId,
                "displayName": displayName, "email": email, "username": username
            ])
        } catch {
            return .error("Error al vincular en Firestore")
        }

        user.partnerUid = partnerId
        user.anniversaryDate = Date().addingTimeInterval(-86400 * 365)
        user.skippedPartner = false
        AuthService.shared.currentUser = user
        AuthService.shared.saveUser(user)

        let partner = UserModel(id: partnerId, email: email, displayName: displayName, username: username,
            pairCode: "", partnerUid: myUid, anniversaryDate: user.anniversaryDate,
            mood: "🥰", moodMessage: "Pensando en ti", batteryLevel: 0.88, isCharging: true)
        self.partnerUser = partner

        ChatNotificationService.shared.sendLocalNotification(
            title: "¡Pareja Vinculada! 🎉",
            body: "❤️ Te has vinculado exitosamente con \(partner.displayName). ¡Disfruten su espacio juntos!"
        )
        return .success
    }
    
    public func updateMood(emoji: String, message: String? = nil) {
        guard var user = AuthService.shared.currentUser else { return }
        user.mood = emoji
        user.moodMessage = message
        AuthService.shared.saveUser(user)
        AuthService.shared.currentUser = user
    }
    
    public func updateBattery(level: Double, isCharging: Bool) {
        guard var user = AuthService.shared.currentUser else { return }
        user.batteryLevel = level
        user.isCharging = isCharging
        AuthService.shared.saveUser(user)
        AuthService.shared.currentUser = user
    }
    
    public func didSkipPartner() {
        guard var user = AuthService.shared.currentUser else { return }
        user.skippedPartner = true
        AuthService.shared.saveUser(user)
        AuthService.shared.currentUser = user
    }
    
    // Método para simular actualización en tiempo real de la pareja y disparar notificaciones
    public func simulatePartnerEvent(event: PartnerEventType) {
        guard var partner = partnerUser else { return }
        let name = partner.displayName
        
        switch event {
        case .lowBattery(let level):
            partner.batteryLevel = Double(level) / 100.0
            partner.isCharging = false
            self.partnerUser = partner
            ChatNotificationService.shared.notifyPartnerLowBattery(partnerName: name, level: level)
            
        case .startedCharging:
            partner.isCharging = true
            self.partnerUser = partner
            ChatNotificationService.shared.notifyPartnerCharging(partnerName: name)
            
        case .moodChanged(let emoji, let text):
            partner.mood = emoji
            partner.moodMessage = text
            self.partnerUser = partner
            ChatNotificationService.shared.notifyPartnerMoodChange(partnerName: name, moodEmoji: emoji, message: text)
            
        case .proximityAlert(let distText):
            ChatNotificationService.shared.notifyPartnerProximity(partnerName: name, distanceText: distText)
        }
    }
    
    private func loadMockPartnerIfNeeded() {
        if let user = AuthService.shared.currentUser, user.isPaired {
            self.partnerUser = UserModel(
                id: user.partnerUid ?? "partner_sample_123",
                email: "amor@love.com",
                displayName: "Mi Pareja ❤️",
                username: "mi_pareja",
                pairCode: "LOVE88",
                partnerUid: user.id,
                anniversaryDate: user.anniversaryDate ?? Date().addingTimeInterval(-86400 * 200),
                mood: "🥰",
                moodMessage: "¡Te amo mucho!",
                batteryLevel: 0.85,
                isCharging: true,
                latitude: 4.6097,
                longitude: -74.0817
            )
        }
    }
}

public enum PartnerEventType {
    case lowBattery(Int)
    case startedCharging
    case moodChanged(String, String?)
    case proximityAlert(String)
}
