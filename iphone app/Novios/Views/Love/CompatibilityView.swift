import SwiftUI
import FirebaseFirestore

private struct CompQuestion: Identifiable {
    let id: String
    let question: String
    let options: [String]
    let category: String
}

private let defaultQuestions: [CompQuestion] = [
    CompQuestion(id: "q1", question: "Cual es nuestro lugar favorito para ir juntos?", options: ["Playa", "Montana", "Ciudad", "Casa"], category: "Recuerdos"),
    CompQuestion(id: "q2", question: "Que momento recuerdo con mas carino?", options: ["Primer beso", "Primera cita", "Aniversario", "Viaje"], category: "Recuerdos"),
    CompQuestion(id: "q3", question: "Donde fue nuestra primera cita?", options: ["Cine", "Parque", "Restaurante", "Cafe"], category: "Recuerdos"),
    CompQuestion(id: "q4", question: "Que recuerdo de nuestra relacion me hace mas feliz?", options: ["Nuestro inicio", "Nuestros viajes", "Nuestros logros", "El dia a dia"], category: "Recuerdos"),

    CompQuestion(id: "q5", question: "Como prefieres que pasemos los fines de semana?", options: ["Salir a cenar", "Quedarnos en casa", "Ir de paseo", "Ver peliculas"], category: "Preferencias"),
    CompQuestion(id: "q6", question: "Como prefieres que resolvamos desacuerdos?", options: ["Hablando", "Escribiendo", "Con espacio", "Con abrazos"], category: "Preferencias"),
    CompQuestion(id: "q7", question: "Que plan es tu cita ideal?", options: ["Cena romantica", "Picnic", "Noche de peliculas", "Aventura"], category: "Preferencias"),
    CompQuestion(id: "q8", question: "Que prefieres hacer en nuestro aniversario?", options: ["Viaje sorpresa", "Cena especial", "Cartas de amor", "Dia de spa"], category: "Preferencias"),

    CompQuestion(id: "q9", question: "Donde nos gustaria viajar primero?", options: ["Europa", "Asia", "Caribe", "Nacional"], category: "Futuro"),
    CompQuestion(id: "q10", question: "Que nos gustaria aprender juntos?", options: ["Cocinar", "Bailar", "Un idioma", "Un deporte"], category: "Futuro"),
    CompQuestion(id: "q11", question: "Donde nos gustaria vivir en el futuro?", options: ["Ciudad", "Campo", "Playa", "Extranjero"], category: "Futuro"),
    CompQuestion(id: "q12", question: "Que mascota te gustaria tener?", options: ["Perro", "Gato", "Conejo", "Ninguna"], category: "Futuro"),

    CompQuestion(id: "q13", question: "Cual es mi color favorito?", options: ["Rojo", "Azul", "Verde", "Negro"], category: "Personalidad"),
    CompQuestion(id: "q14", question: "Que actividad disfruto hacer en mi tiempo libre?", options: ["Leer", "Ejercicio", "Series", "Cocinar"], category: "Personalidad"),
    CompQuestion(id: "q15", question: "Cual es mi estacion favorita?", options: ["Primavera", "Verano", "Otono", "Invierno"], category: "Personalidad"),
    CompQuestion(id: "q16", question: "Que es lo que mas valoro en una persona?", options: ["Honestidad", "Humor", "Lealtad", "Amabilidad"], category: "Personalidad"),

    CompQuestion(id: "q17", question: "Que pelicula describe mejor nuestra relacion?", options: ["Romance", "Comedia", "Aventura", "Drama"], category: "Gustos"),
    CompQuestion(id: "q18", question: "Cual es mi platillo favorito que cocinas?", options: ["Pasta", "Pizza", "Ensalada", "Postre"], category: "Gustos"),
    CompQuestion(id: "q19", question: "Que tipo de musica prefiero?", options: ["Pop", "Rock", "Bachata", "Regueton"], category: "Gustos"),
    CompQuestion(id: "q20", question: "Cual es mi bebida favorita?", options: ["Cafe", "Te", "Agua", "Refresco"], category: "Gustos"),
]

private let categoryColors: [String: Color] = [
    "Recuerdos": .blue,
    "Preferencias": .orange,
    "Futuro": .purple,
    "Personalidad": .green,
    "Gustos": .pink,
]

public struct CompatibilityView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var questions: [CompQuestion] = []
    @State private var currentIndex = 0
    @State private var currentPlayer = 1
    @State private var answers1: [Int] = []
    @State private var answers2: [Int] = []
    @State private var showResult = false
    @State private var listener: ListenerRegistration?
    @State private var isSaving = false

    private let totalQuestions = 20

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundGradient.ignoresSafeArea()
                VStack(spacing: 16) {
                    if showResult {
                        resultView
                    } else {
                        playerHeader
                        progressBar
                        if !questions.isEmpty, currentIndex < questions.count {
                            questionCard
                            optionButtons
                        } else {
                            Spacer()
                            Text("Cargando preguntas...").appFont(size: 16).foregroundColor(theme.textSecondary)
                            Spacer()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Compatibilidad")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Cerrar") { dismiss() } }
            }
            .onAppear {
                setupListener()
                loadDefaults()
            }
            .onDisappear { listener?.remove() }
        }
    }

    private var playerHeader: some View {
        HStack {
            Spacer()
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    playerDot(number: 1, label: "Jugador 1")
                    Image(systemName: "heart.fill").font(.system(size: 10)).foregroundColor(theme.primary)
                    playerDot(number: 2, label: "Jugador 2")
                }
                Text(currentPlayer == 1 ? "Turno del Jugador 1" : "Turno del Jugador 2")
                    .appFont(size: 13, weight: .semibold)
                    .foregroundColor(theme.primary)
            }
            Spacer()
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func playerDot(number: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Circle()
                .fill(currentPlayer == number ? theme.primary : Color.gray.opacity(0.3))
                .frame(width: 12, height: 12)
            Text(label).appFont(size: 10).foregroundColor(theme.textSecondary)
        }
    }

    private var progressBar: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Pregunta \(currentIndex + 1) de \(totalQuestions)").appFont(size: 12).foregroundColor(theme.textSecondary)
                Spacer()
                Text("\(answers1.count + answers2.count)/\(totalQuestions * 2)").appFont(size: 12).foregroundColor(theme.textSecondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.gray.opacity(0.2)).frame(height: 6)
                    Capsule().fill(theme.primary)
                        .frame(width: geo.size.width * CGFloat(answers1.count + answers2.count) / CGFloat(totalQuestions * 2), height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    private var questionCard: some View {
        let q = questions[currentIndex]
        return VStack(spacing: 12) {
            HStack {
                Text(q.category)
                    .appFont(size: 11, weight: .bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(categoryColor(q.category))
                    .clipShape(Capsule())
                Spacer()
            }

            Text(q.question)
                .appFont(size: 20, weight: .semibold)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.textPrimary)
                .padding(.vertical, 8)

            Text("Selecciona tu respuesta")
                .appFont(size: 12)
                .foregroundColor(theme.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 180)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        .id("\(currentIndex)-\(currentPlayer)")
    }

    private var optionButtons: some View {
        let q = questions[currentIndex]
        return VStack(spacing: 8) {
            ForEach(Array(q.options.enumerated()), id: \.offset) { index, option in
                Button {
                    selectOption(index)
                } label: {
                    HStack {
                        Text(option)
                            .appFont(size: 15, weight: .medium)
                            .foregroundColor(theme.textPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var resultView: some View {
        let matchCount = matchingScore()
        let pct = totalQuestions > 0 ? Int(Double(matchCount) / Double(totalQuestions) * 100) : 0

        return ScrollView {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(theme.primary.opacity(0.15), lineWidth: 12)
                        .frame(width: 140, height: 140)
                    Circle()
                        .trim(from: 0, to: CGFloat(pct) / 100)
                        .stroke(theme.primaryGradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 1), value: pct)
                    VStack(spacing: 2) {
                        Text("\(pct)%").appFont(size: 32, weight: .bold).foregroundColor(theme.primary)
                        Text("Compatibilidad").appFont(size: 11).foregroundColor(theme.textSecondary)
                    }
                }
                .padding(.top, 8)

                VStack(spacing: 4) {
                    Text("Resultado").appFont(size: 18, weight: .bold).foregroundColor(theme.textPrimary)
                    Text("Coincidieron en \(matchCount) de \(totalQuestions) respuestas")
                        .appFont(size: 14).foregroundColor(theme.textSecondary)
                }

                if matchCount == totalQuestions {
                    Text("Perfectamente compatibles! ❤️").appFont(size: 14, weight: .semibold).foregroundColor(theme.primary)
                } else if pct >= 70 {
                    Text("Muy compatibles! Sigan asi! 💖").appFont(size: 14, weight: .semibold).foregroundColor(theme.primary)
                } else if pct >= 40 {
                    Text("Todavia se conocen! 😊").appFont(size: 14, weight: .semibold).foregroundColor(theme.primary)
                } else {
                    Text("Hay mucho por descubrir! 💪").appFont(size: 14, weight: .semibold).foregroundColor(theme.primary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Desglose por pregunta").appFont(size: 14, weight: .bold).foregroundColor(theme.textPrimary)

                    ForEach(Array(questions.enumerated()), id: \.offset) { index, q in
                        let a1 = answers1.indices.contains(index) ? answers1[index] : -1
                        let a2 = answers2.indices.contains(index) ? answers2[index] : -1
                        let match = a1 == a2 && a1 >= 0

                        VStack(spacing: 4) {
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(index + 1).").appFont(size: 12, weight: .semibold).foregroundColor(theme.textSecondary)
                                    .frame(width: 24, alignment: .leading)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(q.question).appFont(size: 12, weight: .medium).foregroundColor(theme.textPrimary)
                                        .lineLimit(2)
                                    HStack(spacing: 8) {
                                        HStack(spacing: 2) {
                                            Image(systemName: "1.circle.fill").font(.system(size: 10)).foregroundColor(theme.primary)
                                            Text(a1 >= 0 && a1 < q.options.count ? q.options[a1] : "-")
                                                .appFont(size: 11).foregroundColor(theme.textSecondary)
                                        }
                                        HStack(spacing: 2) {
                                            Image(systemName: "2.circle.fill").font(.system(size: 10)).foregroundColor(theme.secondary)
                                            Text(a2 >= 0 && a2 < q.options.count ? q.options[a2] : "-")
                                                .appFont(size: 11).foregroundColor(theme.textSecondary)
                                        }
                                    }
                                }
                                Spacer()
                                Image(systemName: match ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(match ? .green : .red)
                            }
                        }
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }

                Button {
                    resetGame()
                } label: {
                    Label("Jugar de nuevo", systemImage: "arrow.counterclockwise")
                        .appFont(size: 15, weight: .semibold)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(theme.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .foregroundColor(.white)
                }
                .padding(.top, 8)
            }
        }
    }

    private func selectOption(_ index: Int) {
        if currentPlayer == 1 {
            answers1.append(index)
            if currentIndex + 1 < totalQuestions {
                withAnimation { currentIndex += 1 }
            } else {
                currentPlayer = 2
                currentIndex = 0
            }
        } else {
            answers2.append(index)
            if currentIndex + 1 < totalQuestions {
                withAnimation { currentIndex += 1 }
            } else {
                finishGame()
            }
        }
    }

    private func finishGame() {
        let matchCount = matchingScore()
        GameService.shared.saveGameStats("compatibility", ["percentage": matchCount * 100 / totalQuestions, "matched": matchCount, "total": totalQuestions])
        withAnimation { showResult = true }
    }

    private func matchingScore() -> Int {
        zip(answers1, answers2).filter { $0 == $1 }.count
    }

    private func resetGame() {
        currentIndex = 0
        currentPlayer = 1
        answers1 = []
        answers2 = []
        showResult = false
        loadDefaults()
    }

    private func setupListener() {
        listener = GameService.shared.streamLoveQuestions().addSnapshotListener { snapshot, error in
            guard let docs = snapshot?.documents, !docs.isEmpty else { return }
            let firestoreQuestions = docs.compactMap { doc -> CompQuestion? in
                let d = doc.data()
                guard let q = d["question"] as? String,
                      let opts = d["options"] as? [String],
                      let cat = d["category"] as? String else { return nil }
                return CompQuestion(id: doc.documentID, question: q, options: opts, category: cat)
            }
            if !firestoreQuestions.isEmpty {
                questions = firestoreQuestions.shuffled()
            }
        }
    }

    private func loadDefaults() {
        if questions.isEmpty {
            questions = defaultQuestions.shuffled()
        }
        if isSaving { return }
        isSaving = true
        for q in defaultQuestions {
            GameService.shared.saveLoveQuestion([
                "question": q.question,
                "options": q.options,
                "category": q.category,
            ])
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isSaving = false
        }
    }

    private func categoryColor(_ category: String) -> Color {
        categoryColors[category] ?? theme.primary
    }
}
