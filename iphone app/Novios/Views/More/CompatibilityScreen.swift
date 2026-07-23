import SwiftUI

public struct CompatibilityScreen: View {
    @ObservedObject private var theme = ThemeManager.shared
    @State private var q = 0
    @State private var score = 0
    @State private var showResult = false

    private let questions: [(q: String, a: String, b: String, c: String, d: String, correct: Int)] = [
        ("¿Dónde fue su primer beso?", "Cine", "Casa", "Parque", "Playa", 2),
        ("¿Quién dijo 'Te amo' primero?", "Yo", "Mi pareja", "Los dos", "Ninguno", 1),
        ("¿Cuál es el color favorito de tu pareja?", "Rojo", "Azul", "Negro", "Rosa", 1),
        ("¿Cuál es su comida favorita?", "Pizza", "Sushi", "Pasta", "Tacos", 0),
        ("¿Qué género de película prefiere?", "Comedia", "Romance", "Terror", "Acción", 1),
    ]

    public init() {}

    public var body: some View {
        ZStack {
            LiquidBackgroundView()
            if showResult {
                resultView
            } else {
                questionView
            }
        }
        .navigationTitle("Compatibilidad")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var questionView: some View {
        VStack(spacing: 20) {
            Text("Pregunta \(q + 1) de \(questions.count)")
                .appFont(size: 14, weight: .medium).foregroundColor(theme.textSecondary)
            Text(questions[q].q)
                .appFont(size: 20, weight: .bold).foregroundColor(theme.textPrimary)
                .multilineTextAlignment(.center).padding(.horizontal)
            Spacer()
            VStack(spacing: 12) {
                answerButton(0, questions[q].a)
                answerButton(1, questions[q].b)
                answerButton(2, questions[q].c)
                answerButton(3, questions[q].d)
            }
            .padding(.horizontal, 24)
            Spacer()
            Button("Reiniciar") { q = 0; score = 0; showResult = false }
                .appFont(size: 13).foregroundColor(theme.textSecondary)
        }
        .padding(.vertical, 24)
    }

    private func answerButton(_ idx: Int, _ text: String) -> some View {
        Button {
            if idx == questions[q].correct { score += 1 }
            if q + 1 < questions.count { q += 1 }
            else { showResult = true }
        } label: {
            Text(text).appFont(size: 16, weight: .medium).foregroundColor(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 14)
                .background(theme.primaryGradient).cornerRadius(12)
        }
    }

    private var resultView: some View {
        let pct = Double(score) / Double(questions.count) * 100
        return VStack(spacing: 20) {
            Spacer()
            Text("\(Int(pct))%").appFont(size: 64, weight: .bold).foregroundColor(theme.primary)
            Text(score == questions.count ? "¡Almas gemelas! 💕" :
                 score >= questions.count - 1 ? "¡Se conocen muy bien! 💑" :
                 "Sigan conociéndose 💪")
                .appFont(size: 18, weight: .semibold).foregroundColor(theme.textPrimary)
            Text("Acertaron \(score) de \(questions.count)")
                .appFont(size: 14).foregroundColor(theme.textSecondary)
            Button("Volver a intentar") { q = 0; score = 0; showResult = false }
                .appFont(size: 16, weight: .semibold).foregroundColor(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 14)
                .background(theme.primaryGradient).cornerRadius(12)
                .padding(.horizontal, 24)
            Spacer()
        }
    }
}
