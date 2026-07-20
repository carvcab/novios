import SwiftUI

public struct HigherCardView: View {
    let ranks = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
    let suits = ["heart", "diamond", "club", "spade"]

    @State private var myCard: (rank: String, suit: String)?
    @State private var partnerCard: (rank: String, suit: String)?
    @State private var myScore = 0
    @State private var partnerScore = 0
    @State private var round = 0
    @State private var isFlipped = false
    @State private var roundResult: String?
    @State private var gameOver = false
    @State private var finalMessage = ""

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    Spacer()

                    HStack(spacing: 24) {
                        VStack(spacing: 4) {
                            Text("Yo")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(ThemeManager.shared.primaryPink)
                            Text("\(myScore)")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        Text("vs")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                        VStack(spacing: 4) {
                            Text("Pareja")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(ThemeManager.shared.primaryPink)
                            Text("\(partnerScore)")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.primary)
                        }
                    }

                    Text("Ronda \(round + 1)/5")
                        .font(.system(size: 14))
                        .foregroundColor(ThemeManager.shared.primaryPink)

                    HStack(spacing: 30) {
                        if !isFlipped {
                            cardBack(label: "Yo")
                            cardBack(label: "Pareja")
                        } else {
                            if let myCard {
                                cardFront(rank: myCard.rank, suit: myCard.suit, label: "Yo")
                            }
                            if let partnerCard {
                                cardFront(rank: partnerCard.rank, suit: partnerCard.suit, label: "Pareja")
                            }
                        }
                    }

                    if let result = roundResult {
                        Text(result)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                            .transition(.scale.combined(with: .opacity))
                    }

                    if gameOver {
                        GlassCard {
                            Text(finalMessage)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 8)
                        }
                        .padding(.horizontal, 24)
                    }

                    Spacer()

                    Button {
                        if gameOver {
                            withAnimation {
                                resetGame()
                            }
                        } else {
                            withAnimation {
                                drawRound()
                            }
                        }
                    } label: {
                        Text(gameOver ? "Jugar de Nuevo" : "Nueva Ronda")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(ThemeManager.shared.primaryPink.opacity(0.8))
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Carta Mayor")
        }
    }

    func cardBack(label: String) -> some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.primary)
            RoundedRectangle(cornerRadius: 14)
                .fill(ThemeManager.shared.primaryPink.opacity(0.2))
                .frame(width: 100, height: 145)
                .overlay(
                    Image(systemName: "questionmark")
                        .font(.system(size: 42))
                        .foregroundColor(.primary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(ThemeManager.shared.primaryPink.opacity(0.4), lineWidth: 2)
                )
        }
    }

    func cardFront(rank: String, suit: String, label: String) -> some View {
        let isRed = suit == "heart" || suit == "diamond"
        return VStack(spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.primary)
            RoundedRectangle(cornerRadius: 14)
                .fill(.white)
                .frame(width: 100, height: 145)
                .overlay(
                    VStack(spacing: 4) {
                        Text(rank)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(isRed ? .red : .black)
                        Image(systemName: "suit.\(suit).fill")
                            .font(.system(size: 26))
                            .foregroundColor(isRed ? .red : .black)
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }

    func drawRound() {
        round += 1
        let mySuit = suits.randomElement()!
        let partnerSuit = suits.randomElement()!
        let myRank = ranks.randomElement()!
        let partnerRank = ranks.randomElement()!
        myCard = (myRank, mySuit)
        partnerCard = (partnerRank, partnerSuit)
        isFlipped = true

        let myVal = rankValue(myRank)
        let partnerVal = rankValue(partnerRank)

        if myVal > partnerVal {
            myScore += 1
            roundResult = "¡Ganaste esta ronda! 🎉"
        } else if partnerVal > myVal {
            partnerScore += 1
            roundResult = "Tu pareja ganó esta ronda 💕"
        } else {
            roundResult = "¡Empate! 🤝"
        }

        if round >= 5 {
            gameOver = true
            if myScore > partnerScore {
                finalMessage = "¡Felicidades! Ganaste \(myScore) - \(partnerScore) 🏆"
            } else if partnerScore > myScore {
                finalMessage = "Tu pareja ganó \(partnerScore) - \(myScore). ¡Sigue intentando! 💪"
            } else {
                finalMessage = "¡Empate \(myScore) - \(partnerScore)! 💞"
            }
        }
    }

    func rankValue(_ rank: String) -> Int {
        switch rank {
        case "J": return 11
        case "Q": return 12
        case "K": return 13
        default: return Int(rank) ?? 0
        }
    }

    func resetGame() {
        myCard = nil
        partnerCard = nil
        myScore = 0
        partnerScore = 0
        round = 0
        isFlipped = false
        roundResult = nil
        gameOver = false
        finalMessage = ""
    }
}
