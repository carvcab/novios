import SwiftUI

public struct WouldYouRatherView: View {
    struct Question {
        let optionA: String
        let optionB: String
    }

    let questions = [
        Question(optionA: "una cena romántica en casa", optionB: "un picnic en la playa"),
        Question(optionA: "recibir un masaje", optionB: "dar un masaje"),
        Question(optionA: "ver una película", optionB: "una serie juntos"),
        Question(optionA: "viajar a la playa", optionB: "a la montaña"),
        Question(optionA: "cocinar juntos", optionB: "pedir delivery"),
        Question(optionA: "bailar en la sala", optionB: "cantar en el coche"),
        Question(optionA: "amanecer juntos", optionB: "trasnochar conversando"),
        Question(optionA: "escribir cartas", optionB: "grabar audios"),
        Question(optionA: "regalar flores", optionB: "un detalle hecho a mano"),
        Question(optionA: "una cita sorpresa", optionB: "planear todo juntos")
    ]

    @State private var questionIndex = 0
    @State private var selectedAnswer: String?
    @State private var showResult = false

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("¿Qué Prefieres? 🤔")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.top, 8)

                    Text("Pregunta \(questionIndex + 1)/\(questions.count)")
                        .font(.system(size: 14))
                        .foregroundColor(ThemeManager.shared.primaryPink)

                    if questionIndex < questions.count {
                        let q = questions[questionIndex]

                        Text("¿Prefieres...")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)

                        Button {
                            selectAnswer(q.optionA)
                        } label: {
                            GlassCard {
                                HStack {
                                    Text("A")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 24, height: 24)
                                        .background(ThemeManager.shared.primaryPink)
                                        .clipShape(Circle())

                                    Text(q.optionA)
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.vertical, 8)
                            }
                            .overlay(
                                selectedAnswer == q.optionA && showResult
                                    ? RoundedRectangle(cornerRadius: 24).stroke(Color.green, lineWidth: 3)
                                    : nil
                            )
                        }
                        .disabled(showResult)
                        .padding(.horizontal, 24)

                        Text("O")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(ThemeManager.shared.primaryPink)

                        Button {
                            selectAnswer(q.optionB)
                        } label: {
                            GlassCard {
                                HStack {
                                    Text("B")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 24, height: 24)
                                        .background(ThemeManager.shared.primaryPurple)
                                        .clipShape(Circle())

                                    Text(q.optionB)
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.vertical, 8)
                            }
                            .overlay(
                                selectedAnswer == q.optionB && showResult
                                    ? RoundedRectangle(cornerRadius: 24).stroke(Color.green, lineWidth: 3)
                                    : nil
                            )
                        }
                        .disabled(showResult)
                        .padding(.horizontal, 24)
                    }

                    if showResult {
                        GlassCard {
                            VStack(spacing: 8) {
                                Text("¡Elección popular!")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.primary)

                                HStack(spacing: 30) {
                                    VStack {
                                        Text("60%")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(ThemeManager.shared.primaryPink)
                                        Text("eligió esta opción")
                                            .font(.system(size: 11))
                                            .foregroundColor(.primary)
                                    }
                                    VStack {
                                        Text("40%")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(ThemeManager.shared.primaryPurple)
                                        Text("eligió la otra")
                                            .font(.system(size: 11))
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .padding(.horizontal, 24)

                        Button {
                            withAnimation {
                                nextQuestion()
                            }
                        } label: {
                            Text(questionIndex < questions.count - 1 ? "Siguiente" : "Finalizar")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(ThemeManager.shared.primaryPink.opacity(0.8))
                                .cornerRadius(16)
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 20)
                    }

                    Spacer()
                }
            }
            .navigationTitle("¿Qué Prefieres?")
        }
    }

    func selectAnswer(_ answer: String) {
        selectedAnswer = answer
        withAnimation {
            showResult = true
        }
    }

    func nextQuestion() {
        if questionIndex < questions.count - 1 {
            questionIndex += 1
            selectedAnswer = nil
            showResult = false
        }
    }
}
