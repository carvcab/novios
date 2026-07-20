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
    @Published public var myPairCode: String = ""
    @Published public var isSearching: Bool = false
    
    private var partnerObserverCancellable: AnyCancellable?
    
    private init() {
        loadMockPartnerIfNeeded()
    }
    
    public func getOrGeneratePairCode() async -> String {
        if let current = AuthService.shared.currentUser, !current.pairCode.isEmpty {
            self.myPairCode = current.pairCode
            return current.pairCode
        }
        let code = String((0..<6).map { _ in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()! })
        self.myPairCode = code
        if var user = AuthService.shared.currentUser {
            user.pairCode = code
            AuthService.shared.saveUser(user)
            AuthService.shared.currentUser = user
        }
        return code
    }
    
    public func searchUser(query: String) async -> [String: Any]? {
        await MainActor.run { self.isSearching = true }
        try? await Task.sleep(nanoseconds: 400_000_000)
        await MainActor.run { self.isSearching = false }
        
        let cleaned = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if cleaned.isEmpty { return nil }
        
        return [
            "uid": "partner_sample_123",
            "displayName": "Mi Amor ❤️",
            "username": cleaned.contains("@") ? cleaned.components(separatedBy: "@").first! : cleaned,
            "email": cleaned.contains("@") ? cleaned : "\(cleaned)@love.com",
            "pairCode": "LOVE88"
        ]
    }
    
    public func addPartner(codeOrEmail: String) async -> AddPartnerResult {
        try? await Task.sleep(nanoseconds: 600_000_000)
        guard var user = AuthService.shared.currentUser else { return .error("Usuario no autenticado") }
        
        if user.isPaired { return .alreadyHasPartner }
        
        let partnerId = "partner_sample_123"
        user.partnerUid = partnerId
        user.anniversaryDate = Date().addingTimeInterval(-86400 * 365)
        user.skippedPartner = false
        
        AuthService.shared.saveUser(user)
        AuthService.shared.currentUser = user
        
        let partner = UserModel(
            id: partnerId,
            email: "amor@love.com",
            displayName: "Mi Pareja ❤️",
            username: "mi_pareja",
            pairCode: "LOVE88",
            partnerUid: user.id,
            anniversaryDate: user.anniversaryDate,
            mood: "🥰",
            moodMessage: "Pensando en ti",
            batteryLevel: 0.88,
            isCharging: true,
            latitude: 4.6097,
            longitude: -74.0817
        )
        self.partnerUser = partner
        
        // Disparar notificación de vinculación exitosa
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
