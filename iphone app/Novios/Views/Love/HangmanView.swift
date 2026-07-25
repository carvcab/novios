import SwiftUI
import FirebaseFirestore

public struct HangmanView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss

    private let words = ["AMOR", "BESO", "ABRAZO", "CORAZON", "PAREJA", "ROMANTICO", "CARINO", "PASION", "SENTIMIENTO", "ALMA"]
    private let maxWrongGuesses = 6

    @State private var currentWord = ""
    @State private var guessedLetters: Set<Character> = []
    @State private var wrongGuesses = 0
    @State private var score = 0
    @State private var gamesPlayed = 0
    @State private var showResult = false
    @State private var resultMessage = ""
    @State private var gameOver = false

    private let letters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundGradient.ignoresSafeArea()
                VStack(spacing: 16) {
                    scoreHeader
                    hangmanArt
                    wordDisplay
                    keyboardGrid
                    newGameButton
                }
                .padding()
            }
            .navigationTitle("Ahorcado")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Cerrar") { dismiss() } } }
            .alert(resultMessage, isPresented: $showResult) {
                Button("Jugar otra") { resetGame() }
                Button("Cerrar", role: .cancel) { dismiss() }
            }
            .onAppear { resetGame() }
        }
    }

    private var scoreHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Puntaje: \(score)").appFont(size: 16, weight: .bold).foregroundColor(theme.textPrimary)
                Text("Jugados: \(gamesPlayed)").appFont(size: 12).foregroundColor(theme.textSecondary)
            }
            Spacer()
            Text("Errores: \(wrongGuesses)/\(maxWrongGuesses)").appFont(size: 14, weight: .semibold).foregroundColor(wrongGuesses > 3 ? .red : theme.textPrimary)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var hangmanArt: some View {
        Text(hangmanStages[wrongGuesses])
            .appFont(size: 14)
            .foregroundColor(theme.textPrimary)
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var wordDisplay: some View {
        let display = currentWord.map { guessedLetters.contains($0) ? String($0) : "_" }.joined(separator: " ")
        return Text(display)
            .appFont(size: 32, weight: .bold)
            .foregroundColor(theme.primary)
            .tracking(4)
            .padding()
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var keyboardGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
            ForEach(letters, id: \.self) { letter in
                let used = guessedLetters.contains(letter)
                let isCorrect = currentWord.contains(letter)
                Button {
                    guess(letter)
                } label: {
                    Text(String(letter))
                        .appFont(size: 16, weight: .semibold)
                        .frame(width: 36, height: 36)
                        .background(used ? (isCorrect ? Color.green.opacity(0.3) : Color.red.opacity(0.3)) : theme.primary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .foregroundColor(used ? (isCorrect ? .green : .red) : theme.textPrimary)
                }
                .disabled(used || gameOver)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var newGameButton: some View {
        Button {
            resetGame()
        } label: {
            Label("Nueva palabra", systemImage: "arrow.counterclockwise")
                .appFont(size: 14, weight: .semibold)
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(theme.primary.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .foregroundColor(theme.textPrimary)
    }

    private func guess(_ letter: Character) {
        guard !gameOver else { return }
        guessedLetters.insert(letter)
        if currentWord.contains(letter) {
            if currentWord.allSatisfy({ guessedLetters.contains($0) }) {
                endGame(won: true)
            }
        } else {
            wrongGuesses += 1
            if wrongGuesses >= maxWrongGuesses {
                endGame(won: false)
            }
        }
    }

    private func endGame(won: Bool) {
        gameOver = true
        gamesPlayed += 1
        if won {
            score += 1
            resultMessage = "Ganaste 🎉\nLa palabra era: \(currentWord)"
        } else {
            resultMessage = "Perdiste 😞\nLa palabra era: \(currentWord)"
        }
        showResult = true
    }

    private func resetGame() {
        currentWord = words.randomElement() ?? "AMOR"
        guessedLetters = []
        wrongGuesses = 0
        gameOver = false
        showResult = false
    }

    private let hangmanStages = [
        """
          +---+
              |
              |
              |
              |
              |
        =========
        """,
        """
          +---+
          O   |
              |
              |
              |
              |
        =========
        """,
        """
          +---+
          O   |
          |   |
              |
              |
              |
        =========
        """,
        """
          +---+
          O   |
         /|   |
              |
              |
              |
        =========
        """,
        """
          +---+
          O   |
         /|\\  |
              |
              |
              |
        =========
        """,
        """
          +---+
          O   |
         /|\\  |
         /    |
              |
              |
        =========
        """,
        """
          +---+
          O   |
         /|\\  |
         / \\  |
              |
              |
        =========
        """
    ]
}
