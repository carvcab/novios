import Foundation

public struct GameSession: Identifiable {
    public let id: String
    public var type: GameType
    public var state: GameState
    public var myScore: Int
    public var partnerScore: Int
    public var currentTurn: String
    public var data: [String: Any]
}

public enum GameType: String, CaseIterable {
    case quiz, truthOrDare, memorama, tictactoe, rps, hangman,
         loveDice, higherCard, wouldYouRather, loveRoulette, neverHaveIEver, spicy
}

public enum GameState: String {
    case waiting, playing, finished
}

public struct SpicyChallenge: Identifiable {
    public let id: String
    public let level: SpicyLevel
    public let type: ChallengeType
    public let text: String
    public var status: ChallengeStatus
    public let fromPartner: Bool
}

public enum SpicyLevel: String, CaseIterable {
    case suave, picante, extremo, xxx
}

public enum ChallengeType: String {
    case truth, dare, photo
}

public enum ChallengeStatus: String {
    case pending, responded
}
