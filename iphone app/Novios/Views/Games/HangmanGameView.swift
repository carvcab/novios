import SwiftUI

public struct HangmanGameView: View {
    @State private var secretWord = ""
    @State private var guessedLetters: [String] = []
    @State private var wrongCount = 0
    @State private var gameState: GameState2 = .playing
    @State private var usedLetters: Set<String> = []

    private let words = ["TEAMO", "ANIVERSARIO", "COMPROMISO", "ABRAZO", "DULCE", "SIEMPRE", "BESO", "CARINO", "PAREJA", "CORAZON"]

    private enum GameState2 { case playing, won, lost }

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient.ignoresSafeArea()
                VStack(spacing: 20) {
                    Text("Ahorcado").font(.system(size: 26, weight: .bold)).foregroundColor(.primary)

                    // Lives
                    HStack(spacing: 6) {
                        ForEach(0..<6, id: \.self) { i in
                            Image(systemName: i < (6 - wrongCount) ? "heart.fill" : "heart")
                                .foregroundColor(Color(red: 1.0, green: 0.36, blue: 0.54)).font(.system(size: 22))
                        }
                    }

                    // Word display
                    Text(displayWord).font(.system(size: 28, weight: .bold, design: .monospaced)).tracking(6).foregroundColor(.primary)
                        .padding(20).background(.ultraThinMaterial).cornerRadius(16)

                    if gameState == .won {
                        Text("¡Ganaste! 🎉").font(.system(size: 20, weight: .bold)).foregroundColor(.green)
                    } else if gameState == .lost {
                        Text("Era: \(secretWord) 😢").font(.system(size: 16, weight: .bold)).foregroundColor(.red)
                    }

                    // Letter buttons
                    if gameState == .playing {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                            ForEach(Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").map(String.init), id: \.self) { letter in
                                let used = usedLetters.contains(letter)
                                Button {
                                    guess(letter)
                                } label: {
                                    Text(letter).font(.system(size: 16, weight: .medium)).foregroundColor(used ? .gray : .white)
                                        .frame(width: 36, height: 36)
                                        .background(used ? Color.gray.opacity(0.2) : ThemeManager.shared.primaryPink)
                                        .cornerRadius(8)
                                }
                                .disabled(used)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    Button {
                        resetGame()
                    } label: {
                        Text("Nueva palabra").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                            .padding(.horizontal, 30).padding(.vertical, 12)
                            .background(ThemeManager.shared.primaryPink).cornerRadius(14)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Ahorcado")
        }
        .onAppear { resetGame() }
    }

    private var displayWord: String {
        secretWord.map { guessedLetters.contains(String($0)) ? "\($0) " : "_ " }.joined()
    }

    private func guess(_ letter: String) {
        guard gameState == .playing else { return }
        usedLetters.insert(letter)
        guessedLetters.append(letter)
        if !secretWord.contains(letter) {
            wrongCount += 1
            if wrongCount >= 6 { gameState = .lost }
        } else if secretWord.allSatisfy({ guessedLetters.contains(String($0)) || usedLetters.contains(String($0)) }) {
            gameState = .won
        }
    }

    private func resetGame() {
        secretWord = words.randomElement() ?? "AMOR"
        guessedLetters = []
        wrongCount = 0
        usedLetters = []
        gameState = .playing
    }
}
