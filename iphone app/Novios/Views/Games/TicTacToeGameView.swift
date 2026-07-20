import SwiftUI

public struct TicTacToeGameView: View {
    @State private var board: [String] = Array(repeating: "", count: 9)
    @State private var currentPlayer = "X"
    @State private var winner: String? = nil
    @State private var gameOver = false

    private let winPatterns: [[Int]] = [
        [0,1,2], [3,4,5], [6,7,8],
        [0,3,6], [1,4,7], [2,5,8],
        [0,4,8], [2,4,6]
    ]

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient.ignoresSafeArea()
                VStack(spacing: 16) {
                    Text("TRES EN RAYA")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.top, 8)

                    if gameOver {
                        if let w = winner {
                            Text("¡Ganador: \(w)! 🎉")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(w == "X" ? ThemeManager.shared.primaryPink : ThemeManager.shared.primaryPurple)
                        } else {
                            Text("¡Empate! 🤝")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                        }
                    } else {
                        Text("Turno de: \(currentPlayer)")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(currentPlayer == "X" ? ThemeManager.shared.primaryPink : ThemeManager.shared.primaryPurple)
                    }

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        ForEach(0..<9) { i in
                            Button {
                                makeMove(at: i)
                            } label: {
                                Text(board[i])
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(board[i] == "X" ? ThemeManager.shared.primaryPink : ThemeManager.shared.primaryPurple)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 100)
                                    .background(ThemeManager.shared.cardBackground.opacity(0.6))
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(ThemeManager.shared.primaryPink.opacity(0.2), lineWidth: 1)
                                    )
                            }
                            .disabled(board[i] != "" || gameOver)
                        }
                    }
                    .padding(.horizontal, 24)

                    GradientButton(title: "Reiniciar", icon: "arrow.counterclockwise") {
                        resetGame()
                    }
                    .padding(.horizontal, 40)

                    Spacer()
                }
            }
            .navigationTitle("Tres en Raya")
        }
    }

    func makeMove(at index: Int) {
        if board[index] != "" || gameOver { return }
        board[index] = currentPlayer

        if checkWinner(for: currentPlayer) {
            winner = currentPlayer
            gameOver = true
        } else if board.allSatisfy({ $0 != "" }) {
            gameOver = true
        } else {
            currentPlayer = currentPlayer == "X" ? "O" : "X"
        }
    }

    func checkWinner(for player: String) -> Bool {
        for pattern in winPatterns {
            if pattern.allSatisfy({ board[$0] == player }) {
                return true
            }
        }
        return false
    }

    func resetGame() {
        board = Array(repeating: "", count: 9)
        currentPlayer = "X"
        winner = nil
        gameOver = false
    }
}
