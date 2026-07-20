import SwiftUI

private struct Question: Identifiable {
    let id = UUID()
    let text: String
    let answer: WhoAnswer
}

private enum WhoAnswer: String {
    case me = "Yo"
    case partner = "Mi pareja"
}

public struct WhoView: View {
    @State private var currentQuestion = 0
    @State private var score = 0
    @State private var showResult = false
    @State private var selectedAnswer: WhoAnswer? = nil
    @State private var questions: [Question] = []

    private let sampleQuestions: [(text: String, answer: WhoAnswer)] = [
        ("¿Quién dijo 'Te amo' primero?", .me),
        ("¿Quién cocina mejor?", .partner),
        ("¿Quién es más desordenado?", .me),
        ("¿Quién elige la película siempre?", .partner),
        ("¿Quién se despierta primero?", .me),
        ("¿Quién gasta más en ropa?", .partner),
        ("¿Quién conduce mejor?", .me),
        ("¿Quién tiene más paciencia?", .partner),
        ("¿Quién inició la primera conversación?", .me),
        ("¿Quién es más celoso?", .partner),
    ]

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()

                VStack(spacing: 20) {
                    scoreHeader
                    progressBar
                    Spacer()
                    questionCard
                    Spacer()
                    answerButtons
                }
                .padding()
            }
            .navigationTitle("¿Quién es quién?")
            .navigationBarTitleTextColor(.white)
            .ignoresSafeArea(edges: .bottom)
            .onAppear {
                questions = sampleQuestions.shuffled().map { Question(text: $0.text, answer: $0.answer) }
            }
        }
    }

    private var scoreHeader: some View {
        HStack {
            GlassCard {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("Puntuación: \(score)/\(questions.count)")
                        .foregroundColor(.primary)
                        .font(.headline)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 8)

                RoundedRectangle(cornerRadius: 8)
                    .fill(ThemeManager.shared.primaryPink)
                    .frame(width: questions.isEmpty ? 0 : geo.size.width * CGFloat(currentQuestion) / CGFloat(questions.count), height: 8)
                    .animation(.easeInOut, value: currentQuestion)
            }
        }
        .frame(height: 8)
        .padding(.horizontal)
    }

    private var questionCard: some View {
        VStack {
            if currentQuestion < questions.count {
                GlassCard {
                    VStack(spacing: 16) {
                        Text("Pregunta \(currentQuestion + 1) de \(questions.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(questions[currentQuestion].text)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary)

                        if showResult {
                            let isCorrect = selectedAnswer == questions[currentQuestion].answer
                            HStack {
                                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(isCorrect ? .green : .red)
                                Text(isCorrect ? "¡Correcto!" : "Incorrecto")
                                    .foregroundColor(isCorrect ? .green : .red)
                                    .fontWeight(.semibold)
                            }
                            .padding(.top, 8)

                            Text("Respuesta: \(questions[currentQuestion].answer.rawValue)")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                    }
                    .padding()
                }
            } else {
                GlassCard {
                    VStack(spacing: 16) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.yellow)
                        Text("¡Juego terminado!")
                            .font(.title2)
                            .foregroundColor(.primary)
                        Text("Puntuación final: \(score)/\(questions.count)")
                            .foregroundColor(.primary)

                        Button(action: resetGame) {
                            Text("Volver a jugar")
                                .foregroundColor(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                                .background(ThemeManager.shared.primaryPink)
                                .cornerRadius(12)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                }
            }
        }
        .padding(.horizontal)
    }

    private var answerButtons: some View {
        HStack(spacing: 24) {
            answerButton(title: "Yo", answer: .me, icon: "person.fill")
            answerButton(title: "Mi pareja", answer: .partner, icon: "heart.fill")
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 40)
    }

    private func answerButton(title: String, answer: WhoAnswer, icon: String) -> some View {
        Button(action: { handleAnswer(answer) }) {
            GlassCard {
                VStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.title)
                        .foregroundColor(ThemeManager.shared.primaryPink)
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
            }
        }
        .disabled(showResult && currentQuestion < questions.count)
        .opacity(showResult && currentQuestion < questions.count ? 0.5 : 1)
    }

    private func handleAnswer(_ answer: WhoAnswer) {
        guard currentQuestion < questions.count else { return }
        selectedAnswer = answer
        if answer == questions[currentQuestion].answer {
            score += 1
        }
        withAnimation { showResult = true }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showResult = false
                selectedAnswer = nil
                if currentQuestion < questions.count - 1 {
                    currentQuestion += 1
                } else {
                    currentQuestion = questions.count
                }
            }
        }
    }

    private func resetGame() {
        questions = sampleQuestions.shuffled().map { Question(text: $0.text, answer: $0.answer) }
        currentQuestion = 0
        score = 0
        showResult = false
        selectedAnswer = nil
    }
}
