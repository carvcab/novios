import SwiftUI

public struct QuizGameView: View {
    @State private var currentQuestion = 0
    @State private var score = 0
    @State private var showResult = false

    private let questions: [(q: String, o: [String], a: Int)] = [
        ("¿Dónde fue nuestra primera cita oficial?", ["Restaurante italiano", "El cine", "Un café acogedor", "Un parque"], 2),
        ("¿Quién dijo 'te amo' primero?", ["Yo", "Mi pareja", "Ambos", "Nadie"], 0),
        ("¿Cuál es nuestra comida favorita?", ["Pizza", "Sushi", "Hamburguesas", "Tacos"], 0),
        ("¿Qué hacemos en un día lluvioso?", ["Ver películas", "Dormir", "Cocinar", "Juegos"], 0),
    ]

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient.ignoresSafeArea()
                VStack(spacing: 20) {
                    if showResult {
                        resultView
                    } else {
                        ProgressView(value: Double(currentQuestion + 1) / Double(questions.count))
                            .tint(ThemeManager.shared.primaryPink)
                        Text("Pregunta \(currentQuestion + 1) de \(questions.count)")
                            .font(.system(size: 12)).foregroundColor(.primary.opacity(0.5))
                        GlassCard {
                            Text(questions[currentQuestion].q)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                        VStack(spacing: 10) {
                            ForEach(Array(questions[currentQuestion].o.enumerated()), id: \.offset) { i, opt in
                                Button {
                                    if i == questions[currentQuestion].a { score += 1 }
                                    if currentQuestion < questions.count - 1 {
                                        currentQuestion += 1
                                    } else {
                                        showResult = true
                                    }
                                } label: {
                                    Text(opt)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(ThemeManager.shared.primaryPink.opacity(0.1))
                                        .cornerRadius(14)
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Quiz")
        }
    }

    private var resultView: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.fill").font(.system(size: 56)).foregroundColor(.yellow)
            Text("Tu puntuación: \(score) / \(questions.count)")
                .font(.system(size: 18, weight: .bold))
            Text(score == questions.count ? "¡Perfecto! Se conocen muy bien ❤️" :
                 score >= 3 ? "¡Muy bien! Casi perfecto 🌟" :
                 score >= 2 ? "Bien, pero pueden mejorar 💪" : "Sigan conociéndose 🥰")
                .font(.system(size: 14)).foregroundColor(.primary.opacity(0.7))
            GradientButton(title: "Jugar de nuevo", icon: "arrow.counterclockwise") {
                currentQuestion = 0; score = 0; showResult = false
            }
        }
    }
}
