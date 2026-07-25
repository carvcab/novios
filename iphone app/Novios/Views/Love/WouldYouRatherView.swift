import SwiftUI
import FirebaseFirestore

public struct WouldYouRatherView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var questions: [WouldYouRatherQuestion] = []
    @State private var currentIndex = 0
    @State private var diegoAnswers: [Int] = []
    @State private var yosmariAnswers: [Int] = []
    @State private var currentPlayer = 0
    @State private var gameOver = false
    @State private var showFinal = false

    private let allQuestions: [WouldYouRatherQuestion] = [
        WouldYouRatherQuestion(optionA: "Una cena romantica en casa", optionB: "Una cena elegante en un restaurante"),
        WouldYouRatherQuestion(optionA: "Un viaje a la playa", optionB: "Un viaje a la montaña"),
        WouldYouRatherQuestion(optionA: "Ver una pelicula juntos", optionB: "Ver una serie completa juntos"),
        WouldYouRatherQuestion(optionA: "Mensajes de texto todo el dia", optionB: "Una llamada larga antes de dormir"),
        WouldYouRatherQuestion(optionA: "Despertarme con un beso", optionB: "Dormirme abrazado de ti"),
        WouldYouRatherQuestion(optionA: "Que me cocines", optionB: "Cocinar juntos"),
        WouldYouRatherQuestion(optionA: "Una carta escrita a mano", optionB: "Un mensaje largo y bonito"),
        WouldYouRatherQuestion(optionA: "Bailar lento en la sala", optionB: "Bailar en una fiesta"),
        WouldYouRatherQuestion(optionA: "Ver el amanecer juntos", optionB: "Ver el atardecer juntos"),
        WouldYouRatherQuestion(optionA: "Un masaje de 30 minutos", optionB: "Un beso de 30 segundos"),
        WouldYouRatherQuestion(optionA: "Hacer un picnic en el parque", optionB: "Una cena en la azotea"),
        WouldYouRatherQuestion(optionA: "Reirnos hasta llorar", optionB: "Llorar de emocion juntos"),
        WouldYouRatherQuestion(optionA: "Un fin de semana de aventura", optionB: "Un fin de semana de solo relax"),
        WouldYouRatherQuestion(optionA: "Que me canten", optionB: "Que me escriban un poema"),
        WouldYouRatherQuestion(optionA: "Una sorpresa planeada por ti", optionB: "Una sorpresa improvisada"),
        WouldYouRatherQuestion(optionA: "Pasar el dia en la cama", optionB: "Salir todo el dia"),
        WouldYouRatherQuestion(optionA: "Fotos Polaroid juntos", optionB: "Un video de recuerdos"),
        WouldYouRatherQuestion(optionA: "Hacer ejercicio juntos", optionB: "Cocinar algo dulce juntos"),
        WouldYouRatherQuestion(optionA: "Una ducha juntos", optionB: "Un baño de tina juntos"),
        WouldYouRatherQuestion(optionA: "Leer el mismo libro", optionB: "Ver la misma serie"),
        WouldYouRatherQuestion(optionA: "Que me peines", optionB: "Que me vistas"),
        WouldYouRatherQuestion(optionA: "Un concierto de tu banda favorita", optionB: "Un festival contigo"),
        WouldYouRatherQuestion(optionA: "Hacer un viaje largo en carro", optionB: "Un vuelo corto a algun lado"),
        WouldYouRatherQuestion(optionA: "Una noche de juegos de mesa", optionB: "Una noche de videojuegos"),
        WouldYouRatherQuestion(optionA: "Que me cuentes un secreto", optionB: "Que me digas lo que piensas de mi"),
        WouldYouRatherQuestion(optionA: "Un beso en la lluvia", optionB: "Un abrazo en la nieve"),
        WouldYouRatherQuestion(optionA: "Decorar la casa juntos", optionB: "Armar muebles juntos"),
        WouldYouRatherQuestion(optionA: "Hacer un album de fotos", optionB: "Hacer un video collage"),
        WouldYouRatherQuestion(optionA: "Un dia sin telefonos", optionB: "Un dia sin reloj"),
        WouldYouRatherQuestion(optionA: "Planear nuestras vacaciones", optionB: "Planear nuestra boda"),
        WouldYouRatherQuestion(optionA: "Que me hagas reir", optionB: "Que me hagas sonrojar"),
        WouldYouRatherQuestion(optionA: "Caminar descalzos en la playa", optionB: "Caminar tomados de la mano en la ciudad"),
    ]

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundGradient.ignoresSafeArea()
                VStack(spacing: 20) {
                    if showFinal {
                        finalResultView
                    } else {
                        scoreHeader
                        progressBar
                        if gameOver {
                            summaryView
                        } else {
                            questionCard
                            pickerButtons
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Que prefieres?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Cerrar") { dismiss() } } }
            .onAppear { shuffleQuestions() }
        }
    }

    private var scoreHeader: some View {
        HStack {
            Spacer()
            VStack(spacing: 2) {
                Text("Coincidencias").appFont(size: 12).foregroundColor(theme.textSecondary)
                Text("\(matchingScore())").appFont(size: 28, weight: .bold).foregroundColor(theme.primary)
            }
            Spacer()
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var progressBar: some View {
        HStack(spacing: 8) {
            Text("\(currentIndex + 1)/\(questions.count)").appFont(size: 12).foregroundColor(theme.textSecondary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.gray.opacity(0.2)).frame(height: 6)
                    Capsule().fill(theme.primary).frame(width: geo.size.width * CGFloat(diegoAnswers.count + yosmariAnswers.count) / CGFloat(questions.count * 2), height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    private var questionCard: some View {
        VStack(spacing: 12) {
            Text("Que prefieres...").appFont(size: 13, weight: .semibold).foregroundColor(theme.textSecondary)
            Text(questions[currentIndex].optionA).appFont(size: 18, weight: .semibold).multilineTextAlignment(.center).foregroundColor(theme.primary)
            Text("o").appFont(size: 14).foregroundColor(theme.textSecondary)
            Text(questions[currentIndex].optionB).appFont(size: 18, weight: .semibold).multilineTextAlignment(.center).foregroundColor(theme.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
    }

    private var pickerButtons: some View {
        VStack(spacing: 10) {
            Text("Turno de: \(currentPlayer == 0 ? "Diego" : "Yosmari")")
                .appFont(size: 13, weight: .semibold).foregroundColor(theme.textSecondary)

            HStack(spacing: 12) {
                Button {
                    pickOption(0)
                } label: {
                    Text(questions[currentIndex].optionA)
                        .appFont(size: 13, weight: .semibold)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(theme.primary.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .foregroundColor(theme.textPrimary)

                Button {
                    pickOption(1)
                } label: {
                    Text(questions[currentIndex].optionB)
                        .appFont(size: 13, weight: .semibold)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(theme.secondary.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .foregroundColor(theme.textPrimary)
            }
        }
    }

    private var summaryView: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.circle.fill").font(.system(size: 50)).foregroundColor(theme.primary)
            Text("Ronda completada").appFont(size: 20, weight: .bold).foregroundColor(theme.textPrimary)
            Text("Coincidieron en \(matchingScore()) de \(questions.count) preguntas").appFont(size: 14).foregroundColor(theme.textSecondary)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(questions.enumerated()), id: \.offset) { index, q in
                        let d = diegoAnswers.indices.contains(index) ? diegoAnswers[index] : -1
                        let y = yosmariAnswers.indices.contains(index) ? yosmariAnswers[index] : -1
                        let match = d == y && d >= 0
                        HStack {
                            Text("\(index + 1).").appFont(size: 11).foregroundColor(.secondary)
                            Text(match ? "✅" : "❌").font(.system(size: 12))
                            Text(match ? "Coincidieron" : "No coincidieron").appFont(size: 11).foregroundColor(theme.textSecondary)
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                    }
                }
            }
            .frame(maxHeight: 200)

            Button {
                shuffleQuestions()
            } label: {
                Label("Jugar otra vez", systemImage: "arrow.counterclockwise")
                    .appFont(size: 14, weight: .semibold)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var finalResultView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles").font(.system(size: 60)).foregroundColor(theme.primary)
            Text("Se conocen bien!").appFont(size: 18, weight: .bold).foregroundColor(theme.textPrimary)
            Text("\(matchingScore()) de \(questions.count) coincidencias").appFont(size: 14).foregroundColor(theme.textSecondary)
            Button {
                showFinal = false
                shuffleQuestions()
            } label: {
                Label("Jugar de nuevo", systemImage: "arrow.counterclockwise")
                    .appFont(size: 14, weight: .semibold)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .foregroundColor(.white)
            }
        }
    }

    private func pickOption(_ option: Int) {
        if currentPlayer == 0 {
            diegoAnswers.append(option)
            currentPlayer = 1
        } else {
            yosmariAnswers.append(option)
            currentPlayer = 0
            if currentIndex + 1 < questions.count {
                withAnimation { currentIndex += 1 }
            } else {
                gameOver = true
            }
        }
    }

    private func shuffleQuestions() {
        questions = allQuestions.shuffled()
        currentIndex = 0
        diegoAnswers = []
        yosmariAnswers = []
        currentPlayer = 0
        gameOver = false
    }

    private func matchingScore() -> Int {
        zip(diegoAnswers, yosmariAnswers).filter { $0 == $1 }.count
    }
}

private struct WouldYouRatherQuestion {
    let optionA: String
    let optionB: String
}
