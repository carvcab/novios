import SwiftUI

public struct NeverHaveIEverView: View {
    let statements = [
        "Yo nunca he hecho una locura por amor",
        "Yo nunca he espiado el celular de mi pareja",
        "Yo nunca he tenido una cita a ciegas",
        "Yo nunca he dicho 'te amo' sin sentirlo",
        "Yo nunca he besado a alguien en un juego de verdad o reto",
        "Yo nunca he tenido un crush antes de mi pareja",
        "Yo nunca he hecho una broma pesada a mi pareja",
        "Yo nunca he cocinado algo que quedó terrible",
        "Yo nunca me he quedado dormido en una cita",
        "Yo nunca he cantado una canción de amor a mi pareja"
    ]

    @State private var currentQuestion = 0
    @State private var myAnswer: Bool?
    @State private var showResult = false
    @State private var score = 0
    @State private var isFinished = false

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient
                    .ignoresSafeArea()

                if isFinished {
                    finishedView
                } else {
                    gameView
                }
            }
            .navigationTitle("Yo Nunca Nunca")
        }
    }

    var gameView: some View {
        VStack(spacing: 20) {
            Text("Yo Nunca Nunca 🫣")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
                .padding(.top, 8)

            HStack {
                Text("Pregunta \(currentQuestion + 1)/\(statements.count)")
                    .font(.system(size: 14))
                    .foregroundColor(ThemeManager.shared.primaryPink)

                Spacer()

                Text("Puntos: \(score)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 24)

            GlassCard {
                Text(statements[currentQuestion])
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)

            if !showResult {
                VStack(spacing: 16) {
                    Button {
                        answerQuestion(true)
                    } label: {
                        Text("Yo sí 😳")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(ThemeManager.shared.primaryPink.opacity(0.8))
                            .cornerRadius(16)
                    }

                    Button {
                        answerQuestion(false)
                    } label: {
                        Text("Yo nunca 😇")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.blue.opacity(0.4))
                            .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 40)
            }

            if showResult {
                GlassCard {
                    VStack(spacing: 8) {
                        Text(myAnswer == true ? "Dijiste: Yo sí 😳" : "Dijiste: Yo nunca 😇")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)

                        Text("El 65% de las parejas dijo lo mismo")
                            .font(.system(size: 13))
                            .foregroundColor(ThemeManager.shared.primaryPink)

                        Text(myAnswer == true
                             ? "¡Eres honest@! 🤭"
                             : "¡Qué sant@! 😇")
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 8)
                }
                .padding(.horizontal, 24)

                Button {
                    withAnimation {
                        nextQuestion()
                    }
                } label: {
                    Text(currentQuestion < statements.count - 1 ? "Siguiente" : "Ver Resultados")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(ThemeManager.shared.primaryPink.opacity(0.8))
                        .cornerRadius(16)
                }
                .padding(.horizontal, 40)
            }

            Spacer()
        }
    }

    var finishedView: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("🎉")
                .font(.system(size: 80))

            Text("¡Juego Completado!")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)

            GlassCard {
                VStack(spacing: 12) {
                    Text("Puntuación final")
                        .font(.system(size: 16))
                        .foregroundColor(ThemeManager.shared.primaryPink)

                    Text("\(score)/10")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.primary)

                    Text(scoreMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 12)
            }
            .padding(.horizontal, 40)

            Button {
                withAnimation {
                    resetGame()
                }
            } label: {
                Text("Jugar de Nuevo")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(ThemeManager.shared.primaryPink.opacity(0.8))
                    .cornerRadius(16)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
    }

    var scoreMessage: String {
        switch score {
        case 8...10: return "¡Se conocen muy bien! 💞"
        case 5...7: return "Se conocen bastante bien 💕"
        default: return "Sigan jugando para conocerse más 💗"
        }
    }

    func answerQuestion(_ answer: Bool) {
        myAnswer = answer
        withAnimation {
            showResult = true
        }

        let expectedCorrect = currentQuestion % 2 == 0
        if answer == expectedCorrect {
            score += 1
        }
    }

    func nextQuestion() {
        if currentQuestion < statements.count - 1 {
            currentQuestion += 1
            myAnswer = nil
            showResult = false
        } else {
            withAnimation {
                isFinished = true
            }
        }
    }

    func resetGame() {
        currentQuestion = 0
        myAnswer = nil
        showResult = false
        score = 0
        isFinished = false
    }
}
