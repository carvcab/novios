import SwiftUI
import FirebaseFirestore

private struct PreferModel: Identifiable {
    let id: String
    let optionA: String
    let optionB: String
    let category: String
}

private let categories = ["Romantico", "Divertido", "Viajes", "Comida", "Futuro", "Personalizado"]

private let defaultDilemmas: [String: [(String, String)]] = [
    "Romantico": [
        ("Una cena romantica en casa", "Una cena elegante en un restaurante"),
        ("Un viaje a la playa", "Un viaje a la montana"),
        ("Ver una pelicula juntos", "Ver una serie completa juntos"),
        ("Mensajes de texto todo el dia", "Una llamada larga antes de dormir"),
        ("Despertarme con un beso", "Dormirme abrazado de ti"),
    ],
    "Divertido": [
        ("Una carta escrita a mano", "Un mensaje largo y bonito"),
        ("Bailar lento en la sala", "Bailar en una fiesta"),
        ("Reirnos hasta llorar", "Llorar de emocion juntos"),
        ("Una noche de juegos de mesa", "Una noche de videojuegos"),
        ("Un dia sin telefonos", "Un dia sin reloj"),
    ],
    "Viajes": [
        ("Un fin de semana de aventura", "Un fin de semana de solo relax"),
        ("Un viaje largo en carro", "Un vuelo corto a algun lado"),
        ("Ver el amanecer juntos", "Ver el atardecer juntos"),
        ("Caminar descalzos en la playa", "Caminar tomados de la mano en la ciudad"),
        ("Un concierto de tu banda favorita", "Un festival contigo"),
    ],
    "Comida": [
        ("Que me cocines", "Cocinar juntos"),
        ("Hacer un picnic en el parque", "Una cena en la azotea"),
        ("Cocinar algo dulce juntos", "Pedir comida a domicilio"),
        ("Desayuno en la cama", "Cena a la luz de las velas"),
        ("Comer en un food truck", "Comer en un restaurante con estrellas"),
    ],
    "Futuro": [
        ("Planear nuestras vacaciones", "Planear nuestra boda"),
        ("Comprar una casa juntos", "Viajar por el mundo juntos"),
        ("Tener hijos", "Tener mascotas"),
        ("Vivir en la ciudad", "Vivir en el campo"),
        ("Trabajar juntos", "Trabajar desde casa juntos"),
    ],
]

public struct WouldYouRatherView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var customDilemmas: [PreferModel] = []
    @State private var currentDilemmas: [PreferModel] = []
    @State private var currentIndex = 0
    @State private var answers1: [Int] = []
    @State private var answers2: [Int] = []
    @State private var currentPlayer = 0
    @State private var gameOver = false
    @State private var showFinal = false
    @State private var selectedCategory = "Romantico"
    @State private var showAddSheet = false
    @State private var newOptionA = ""
    @State private var newOptionB = ""
    @State private var newCategory = "Romantico"
    @State private var listener: ListenerRegistration?

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundGradient.ignoresSafeArea()
                VStack(spacing: 16) {
                    if showFinal {
                        finalResultView
                    } else {
                        scoreHeader
                        categoryPicker
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
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Cerrar") { dismiss() } }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundColor(theme.primary)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) { addDilemmaSheet }
            .onAppear {
                setupListener()
                shuffleQuestions()
            }
            .onDisappear { listener?.remove() }
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

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { cat in
                    Button {
                        selectedCategory = cat
                        shuffleQuestions()
                    } label: {
                        Text(cat)
                            .appFont(size: 12, weight: .semibold)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(selectedCategory == cat ? theme.primary : .ultraThinMaterial)
                            .clipShape(Capsule())
                            .foregroundColor(selectedCategory == cat ? .white : theme.textPrimary)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private var progressBar: some View {
        HStack(spacing: 8) {
            Text("\(currentIndex + 1)/\(currentDilemmas.count)").appFont(size: 12).foregroundColor(theme.textSecondary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.gray.opacity(0.2)).frame(height: 6)
                    Capsule().fill(theme.primary).frame(width: geo.size.width * CGFloat(answers1.count + answers2.count) / CGFloat(max(currentDilemmas.count * 2, 1)), height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    private var questionCard: some View {
        VStack(spacing: 12) {
            if currentDilemmas.isEmpty {
                Text("Sin dilemas para esta categoria")
                    .appFont(size: 16, weight: .medium)
                    .foregroundColor(theme.textSecondary)
                    .padding()
            } else {
                Text("Que prefieres...").appFont(size: 13, weight: .semibold).foregroundColor(theme.textSecondary)
                Text(currentDilemmas[currentIndex].optionA).appFont(size: 18, weight: .semibold).multilineTextAlignment(.center).foregroundColor(theme.primary)
                Text("o").appFont(size: 14).foregroundColor(theme.textSecondary)
                Text(currentDilemmas[currentIndex].optionB).appFont(size: 18, weight: .semibold).multilineTextAlignment(.center).foregroundColor(theme.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        .id(currentIndex)
    }

    private var pickerButtons: some View {
        VStack(spacing: 10) {
            Text("Turno: \(currentPlayer == 0 ? "Jugador 1" : "Jugador 2")")
                .appFont(size: 13, weight: .semibold).foregroundColor(theme.textSecondary)
            HStack(spacing: 12) {
                Button {
                    pickOption(0)
                } label: {
                    Text(currentDilemmas.isEmpty ? "A" : currentDilemmas[currentIndex].optionA)
                        .appFont(size: 13, weight: .semibold)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(theme.primary.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .foregroundColor(theme.textPrimary)
                .disabled(currentDilemmas.isEmpty)
                Button {
                    pickOption(1)
                } label: {
                    Text(currentDilemmas.isEmpty ? "B" : currentDilemmas[currentIndex].optionB)
                        .appFont(size: 13, weight: .semibold)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(theme.secondary.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .foregroundColor(theme.textPrimary)
                .disabled(currentDilemmas.isEmpty)
            }
        }
    }

    private var summaryView: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.circle.fill").font(.system(size: 50)).foregroundColor(theme.primary)
            Text("Ronda completada").appFont(size: 20, weight: .bold).foregroundColor(theme.textPrimary)
            Text("Coincidieron en \(matchingScore()) de \(currentDilemmas.count) preguntas").appFont(size: 14).foregroundColor(theme.textSecondary)
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(currentDilemmas.enumerated()), id: \.offset) { index, q in
                        let a1 = answers1.indices.contains(index) ? answers1[index] : -1
                        let a2 = answers2.indices.contains(index) ? answers2[index] : -1
                        let match = a1 == a2 && a1 >= 0
                        HStack {
                            Text("\(index + 1).").appFont(size: 11).foregroundColor(.secondary)
                            Text(match ? "Coincidieron" : "No coincidieron").appFont(size: 11).foregroundColor(theme.textSecondary)
                            Spacer()
                            Text(match ? "✅" : "❌").font(.system(size: 12))
                        }
                        .padding(.horizontal, 8)
                    }
                }
            }
            .frame(maxHeight: 200)
            Button {
                showFinal = true
            } label: {
                Label("Ver resultado final", systemImage: "sparkles")
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
            Text("Resultado final").appFont(size: 18, weight: .bold).foregroundColor(theme.textPrimary)
            let matchCount = matchingScore()
            let pct = currentDilemmas.isEmpty ? 0 : Int(Double(matchCount) / Double(currentDilemmas.count) * 100)
            Text("\(matchCount) de \(currentDilemmas.count) coincidencias").appFont(size: 14).foregroundColor(theme.textSecondary)
            Text("\(pct)% de compatibilidad").appFont(size: 32, weight: .bold).foregroundColor(theme.primary)
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

    private var addDilemmaSheet: some View {
        NavigationStack {
            Form {
                Section("Nuevo dilema") {
                    TextField("Opcion A", text: $newOptionA)
                    TextField("Opcion B", text: $newOptionB)
                    Picker("Categoria", selection: $newCategory) {
                        ForEach(categories, id: \.self) { Text($0) }
                    }
                }
                Section("Tus dilemas") {
                    if customDilemmas.isEmpty {
                        Text("Sin dilemas personalizados").foregroundColor(theme.textSecondary)
                    }
                    ForEach(customDilemmas) { d in
                        VStack(alignment: .leading, spacing: 2) {
                            Text("A: \(d.optionA)").appFont(size: 13).foregroundColor(theme.textPrimary)
                            Text("B: \(d.optionB)").appFont(size: 13).foregroundColor(theme.textPrimary)
                            Text(d.category).appFont(size: 11).foregroundColor(theme.textSecondary)
                        }
                    }
                    .onDelete(perform: deleteDilemma)
                }
            }
            .navigationTitle("Anadir dilema")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { saveDilemma() }.disabled(newOptionA.trimmingCharacters(in: .whitespaces).isEmpty || newOptionB.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { showAddSheet = false }
                }
            }
        }
    }

    private func pickOption(_ option: Int) {
        if currentPlayer == 0 {
            answers1.append(option)
            currentPlayer = 1
        } else {
            answers2.append(option)
            currentPlayer = 0
            if currentIndex + 1 < currentDilemmas.count {
                withAnimation { currentIndex += 1 }
            } else {
                gameOver = true
                GameService.shared.saveGameStats("prefieres", ["matches": matchingScore(), "total": currentDilemmas.count])
            }
        }
    }

    private func shuffleQuestions() {
        let defaults = defaultDilemmas[selectedCategory] ?? []
        let customs = customDilemmas.filter { $0.category == selectedCategory }
        let all = defaults.map { PreferModel(id: UUID().uuidString, optionA: $0.0, optionB: $0.1, category: selectedCategory) } + customs
        currentDilemmas = all.shuffled()
        currentIndex = 0
        answers1 = []
        answers2 = []
        currentPlayer = 0
        gameOver = false
        showFinal = false
    }

    private func matchingScore() -> Int {
        zip(answers1, answers2).filter { $0 == $1 }.count
    }

    private func setupListener() {
        listener = GameService.shared.streamPrefer().addSnapshotListener { snapshot, error in
            guard let docs = snapshot?.documents else { return }
            customDilemmas = docs.compactMap { doc in
                let d = doc.data()
                guard let a = d["optionA"] as? String, let b = d["optionB"] as? String else { return nil }
                return PreferModel(id: doc.documentID, optionA: a, optionB: b, category: d["category"] as? String ?? "Personalizado")
            }
            if !currentDilemmas.isEmpty {
                shuffleQuestions()
            }
        }
    }

    private func saveDilemma() {
        let a = newOptionA.trimmingCharacters(in: .whitespaces)
        let b = newOptionB.trimmingCharacters(in: .whitespaces)
        guard !a.isEmpty, !b.isEmpty else { return }
        GameService.shared.savePrefer(["optionA": a, "optionB": b, "category": newCategory])
        newOptionA = ""
        newOptionB = ""
        showAddSheet = false
    }

    private func deleteDilemma(at offsets: IndexSet) {
        for idx in offsets {
            GameService.shared.deletePrefer(customDilemmas[idx].id)
        }
    }
}
