import Foundation

public struct GameHistoryEntry: Identifiable {
    public let id: String
    public let gameType: String
    public let icon: String
    public let color: String
    public let date: Date
    public let myScore: Int
    public let partnerScore: Int
    public let result: GameResult

    public var winner: String {
        switch result {
        case .win: return "Ganaste 🎉"
        case .lose: return "Perdiste 😢"
        case .tie: return "Empate 🤝"
        }
    }
}

public enum GameResult: String {
    case win, lose, tie
}
