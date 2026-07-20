import Foundation
import Combine

public struct OnlineSession: Identifiable, Codable {
    public var id: String = UUID().uuidString
    public var gameType: String
    public var currentTurnUserId: String
    public var currentQuestion: String?
    public var isTruth: Bool?
    public var scores: [String: Int]
    public var updatedAt: Date = Date()
}

public class OnlineGameService: ObservableObject {
    public static let shared = OnlineGameService()
    
    @Published public var activeSession: OnlineSession?
    @Published public var isMyTurn: Bool = true
    
    private init() {
        startSampleSession()
    }
    
    public func startNewGame(gameType: String) {
        let myId = AuthService.shared.currentUser?.id ?? "user_me"
        self.activeSession = OnlineSession(
            gameType: gameType,
            currentTurnUserId: myId,
            currentQuestion: "¡Comenzó la partida en vivo!",
            scores: [myId: 0]
        )
        self.isMyTurn = true
    }
    
    public func nextTurn(questionText: String, isTruth: Bool) {
        guard var session = activeSession else { return }
        let myId = AuthService.shared.currentUser?.id ?? "user_me"
        let partnerId = UserService.shared.partnerUser?.id ?? "partner_123"
        
        session.currentTurnUserId = session.currentTurnUserId == myId ? partnerId : myId
        session.currentQuestion = questionText
        session.isTruth = isTruth
        session.updatedAt = Date()
        
        self.activeSession = session
        self.isMyTurn = session.currentTurnUserId == myId
    }
    
    private func startSampleSession() {
        let myId = AuthService.shared.currentUser?.id ?? "user_me"
        self.activeSession = OnlineSession(
            gameType: "truth_or_dare",
            currentTurnUserId: myId,
            currentQuestion: "¿Cuál es tu lugar favorito para tener una cita?",
            isTruth: true,
            scores: [myId: 2]
        )
    }
}
