import SwiftUI

public struct RPSGameView: View {
    @State private var myChoice: String? = nil
    @State private var partnerChoice: String? = nil
    @State private var result: String? = nil
    @State private var showResult = false

    private let choices = ["Piedra 🪨", "Papel 📄", "Tijera ✂️"]
    private let choiceEmojis = ["Piedra 🪨", "Papel 📄", "Tijera ✂️"]

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient.ignoresSafeArea()
                VStack(spacing: 20) {
                    Text("PIEDRA, PAPEL O TIJERA")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.top, 8)
                        .multilineTextAlignment(.center)

                    if showResult {
                        resultContent
                    } else {
                        Text("Elige tu jugada:")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)

                        ForEach(choices, id: \.self) { choice in
                            Button {
                                play(choice)
                            } label: {
                                Text(choice)
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(ThemeManager.shared.primaryPink.opacity(0.1))
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(ThemeManager.shared.primaryPink.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal, 32)
                    }

                    Spacer()
                }
            }
            .navigationTitle("Piedra Papel Tijera")
        }
    }

    var resultContent: some View {
        VStack(spacing: 20) {
            GlassCard {
                VStack(spacing: 12) {
                    HStack {
                        VStack {
                            Text("Tú")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.primary.opacity(0.6))
                            Text(myChoice ?? "")
                                .font(.system(size: 28))
                        }
                        Spacer()
                        Text("VS")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(ThemeManager.shared.primaryPink)
                        Spacer()
                        VStack {
                            Text("Pareja")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.primary.opacity(0.6))
                            Text(partnerChoice ?? "")
                                .font(.system(size: 28))
                        }
                    }
                    .padding(.horizontal, 8)

                    Divider()

                    Text(result ?? "")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 8)
            }
            .padding(.horizontal, 24)
            .transition(.scale.combined(with: .opacity))

            GradientButton(title: "Jugar de nuevo", icon: "arrow.counterclockwise") {
                resetGame()
            }
            .padding(.horizontal, 40)
        }
    }

    func play(_ choice: String) {
        myChoice = choice
        partnerChoice = choices.randomElement()!
        result = determineWinner(mine: choice, partner: partnerChoice!)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showResult = true
        }
    }

    func determineWinner(mine: String, partner: String) -> String {
        if mine == partner { return "¡Empate! 🤝" }
        if mine == "Piedra 🪨" && partner == "Tijera ✂️" { return "¡Ganaste! 🎉" }
        if mine == "Papel 📄" && partner == "Piedra 🪨" { return "¡Ganaste! 🎉" }
        if mine == "Tijera ✂️" && partner == "Papel 📄" { return "¡Ganaste! 🎉" }
        return "Perdiste 😅"
    }

    func resetGame() {
        myChoice = nil
        partnerChoice = nil
        result = nil
        showResult = false
    }
}
