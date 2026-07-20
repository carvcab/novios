import SwiftUI

public struct MemoramaGameView: View {
    struct Card: Identifiable {
        let id = UUID()
        let emoji: String
        var isFlipped = false
        var isMatched = false
    }

    @State private var cards: [Card] = []
    @State private var firstFlipped: Int? = nil
    @State private var secondFlipped: Int? = nil
    @State private var moves = 0
    @State private var isProcessing = false

    private let emojis = ["❤️", "💍", "🌸", "🍫", "🧸", "🍷"]

    public init() {
        _cards = State(initialValue: Self.shuffledCards(emojis: emojis))
    }

    static func shuffledCards(emojis: [String]) -> [Card] {
        let pairs = (emojis + emojis).shuffled()
        return pairs.map { Card(emoji: $0) }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient.ignoresSafeArea()
                VStack(spacing: 16) {
                    Text("MEMORAMA")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.top, 8)

                    HStack {
                        Text("Movimientos: \(moves)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary.opacity(0.7))
                        Spacer()
                        Text("Pares: \(cards.filter(\.isMatched).count / 2)/\(emojis.count)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary.opacity(0.7))
                    }
                    .padding(.horizontal, 24)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                        ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                            cardView(for: index)
                        }
                    }
                    .padding(.horizontal, 16)

                    if cards.allSatisfy(\.isMatched) {
                        VStack(spacing: 12) {
                            Image(systemName: "hand.wave.fill").font(.system(size: 48)).foregroundColor(.yellow)
                            Text("¡Felicidades! 🎉")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.primary)
                            Text("Completaste el juego en \(moves) movimientos")
                                .font(.system(size: 14))
                                .foregroundColor(.primary.opacity(0.7))
                            GradientButton(title: "Jugar de nuevo", icon: "arrow.counterclockwise") {
                                resetGame()
                            }
                        }
                        .padding(.top, 8)
                    }

                    Spacer()
                }
            }
            .navigationTitle("Memorama")
        }
    }

    @ViewBuilder
    func cardView(for index: Int) -> some View {
        let card = cards[index]
        Button {
            flipCard(at: index)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(card.isMatched ? ThemeManager.shared.primaryPink.opacity(0.3) :
                          card.isFlipped ? Color.white : ThemeManager.shared.primaryPink.opacity(0.7))
                    .frame(height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(ThemeManager.shared.primaryPink.opacity(0.3), lineWidth: 1)
                    )

                if card.isFlipped || card.isMatched {
                    Text(card.emoji)
                        .font(.system(size: 32))
                }
            }
        }
        .disabled(card.isFlipped || card.isMatched || isProcessing)
        .rotation3DEffect(.degrees(card.isFlipped || card.isMatched ? 0 : 180), axis: (x: 0, y: 1, z: 0))
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: card.isFlipped)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: card.isMatched)
    }

    func flipCard(at index: Int) {
        if isProcessing { return }
        if cards[index].isFlipped || cards[index].isMatched { return }

        cards[index].isFlipped = true

        if firstFlipped == nil {
            firstFlipped = index
        } else if secondFlipped == nil, index != firstFlipped {
            secondFlipped = index
            moves += 1
            checkMatch()
        }
    }

    func checkMatch() {
        isProcessing = true
        let first = firstFlipped!
        let second = secondFlipped!

        if cards[first].emoji == cards[second].emoji {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                cards[first].isMatched = true
                cards[second].isMatched = true
            }
            firstFlipped = nil
            secondFlipped = nil
            isProcessing = false
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    cards[first].isFlipped = false
                    cards[second].isFlipped = false
                }
                firstFlipped = nil
                secondFlipped = nil
                isProcessing = false
            }
        }
    }

    func resetGame() {
        cards = Self.shuffledCards(emojis: emojis)
        firstFlipped = nil
        secondFlipped = nil
        moves = 0
        isProcessing = false
    }
}
