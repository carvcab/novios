import SwiftUI

public struct CompatibilityView: View {
    @State private var currentQuestion = 0
    @State private var answers: [Int] = []
    @State private var showResult = false

    private let questions: [(question: String, options: [String])] = [
        ("¿Cómo nos conocimos?", ["Amigos en común", "Redes sociales", "Trabajo/Estudio", "Casualidad"]),
        ("¿Comida favorita juntos?", ["Italiana", "Mexicana", "Japonesa", "No tenemos"]),
        ("¿Lugar especial?", ["La playa", "La montaña", "Un café", "Nuestra casa"]),
        ("¿Película que vimos juntos?", ["Romance", "Comedia", "Terror", "Acción"]),
        ("¿Canción especial?", ["Bachata", "Pop", "Reggaetón", "Balada"])
    ]

    private var progress: Double {
        Double(currentQuestion) / Double(questions.count)
    }

    private var compatibilityScore: Int {
        guard !answers.isEmpty else { return 0 }
        let match = answers.filter { $0 == 0 }.count
        return Int((Double(match) / Double(questions.count)) * 100)
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient.ignoresSafeArea()

                if showResult {
                    resultView
                } else {
                    questionView
                }
            }
            .navigationTitle("Test de Compatibilidad")
        }
    }

    private var questionView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Paso \(currentQuestion + 1)/\(questions.count)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(ThemeManager.shared.primaryPink)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(ThemeManager.shared.neonGlowGradient)
                            .frame(width: geo.size.width * progress, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: progress)
                    }
                }
                .frame(height: 8)
                .padding(.horizontal, 20)
            }
            .padding(.top, 16)

            Text(questions[currentQuestion].question)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 14) {
                ForEach(Array(questions[currentQuestion].options.enumerated()), id: \.offset) { index, option in
                    Button {
                        answers.append(index)
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        if currentQuestion < questions.count - 1 {
                            withAnimation { currentQuestion += 1 }
                        } else {
                            withAnimation { showResult = true }
                        }
                    } label: {
                        GlassCard {
                            HStack {
                                Text(option)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(ThemeManager.shared.textSecondary)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private var resultView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(ThemeManager.shared.primaryPink.opacity(0.15), lineWidth: 12)
                    .frame(width: 180, height: 180)

                Circle()
                    .trim(from: 0, to: CGFloat(compatibilityScore) / 100)
                    .stroke(ThemeManager.shared.neonGlowGradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 1.5), value: compatibilityScore)

                Text("\(compatibilityScore)%")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.primary)
            }

            Text(compatibilityScore >= 70 ? "¡Alma gemela!" : "Sigan conociéndose")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(ThemeManager.shared.primaryPink)

            Text(compatibilityScore >= 70
                 ? "Tienen una conexión increíble. ¡Sigan así!"
                 : "Cada día es una oportunidad para conocerse más.")
                .font(.system(size: 15))
                .foregroundColor(ThemeManager.shared.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            GradientButton(title: "Reintentar", icon: "arrow.counterclockwise") {
                withAnimation {
                    currentQuestion = 0
                    answers.removeAll()
                    showResult = false
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}
