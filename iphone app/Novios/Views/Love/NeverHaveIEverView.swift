import SwiftUI
import FirebaseFirestore

private struct NeverModel: Identifiable {
    let id: String
    var text: String
    var category: String
    var collection: String
}

private let categories = ["Romantico", "Divertido", "Parejas", "Viajes", "Universidad", "Infancia", "Picante"]
private let collections = ["Pareja", "Amigos", "Fiesta", "Personal"]

public struct NeverHaveIEverView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var customStatements: [NeverModel] = []
    @State private var currentStatements: [NeverModel] = []
    @State private var currentIndex = 0
    @State private var score1 = 0
    @State private var score2 = 0
    @State private var currentPlayer = 0
    @State private var gameOver = false
    @State private var selectedCategory = "Romantico"
    @State private var showAddSheet = false
    @State private var newText = ""
    @State private var newCategory = "Romantico"
    @State private var newCollection = "Pareja"
    @State private var listener: ListenerRegistration?
    @State private var editMode = false
    @State private var editingStatement: NeverModel?

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundGradient.ignoresSafeArea()
                if editMode {
                    editListView
                } else {
                    VStack(spacing: 16) {
                        if gameOver {
                            resultView
                        } else {
                            scoreBoard
                            categoryPicker
                            progressBar
                            statementCard
                            actionButtons
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Nunca He Hecho")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Cerrar") { dismiss() } }
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 8) {
                        Button { editMode.toggle() } label: {
                            Image(systemName: editMode ? "play.fill" : "pencil")
                                .font(.system(size: 18))
                                .foregroundColor(theme.primary)
                        }
                        if !editMode {
                            Button { showAddSheet = true } label: {
                                Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundColor(theme.primary)
                            }
                        }
                    }
                }
                if editMode {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button { showAddSheet = true } label: {
                            Image(systemName: "plus").foregroundColor(theme.primary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) { addStatementSheet }
            .onAppear {
                setupListener()
                shuffleAndStart()
            }
            .onDisappear { listener?.remove() }
        }
    }

    private var editListView: some View {
        List {
            ForEach(customStatements) { stmt in
                VStack(alignment: .leading, spacing: 2) {
                    Text(stmt.text).appFont(size: 14).foregroundColor(theme.textPrimary)
                    HStack(spacing: 4) {
                        Text(stmt.category).appFont(size: 11).foregroundColor(theme.textSecondary)
                        Text("\u{00B7}")
                        Text(stmt.collection).appFont(size: 11).foregroundColor(theme.textSecondary)
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        GameService.shared.deleteNever(stmt.id)
                    } label: {
                        Label("Eliminar", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading) {
                    Button {
                        editingStatement = stmt
                        newText = stmt.text
                        newCategory = stmt.category
                        newCollection = stmt.collection
                        showAddSheet = true
                    } label: {
                        Label("Editar", systemImage: "pencil")
                    }
                    .tint(.orange)
                }
            }
        }
        .scrollContentBackground(.hidden)
    }

    private var scoreBoard: some View {
        HStack {
            playerScore(name: "Jugador 1", score: score1, color: Color.blue.opacity(0.7))
            Spacer()
            playerScore(name: "Jugador 2", score: score2, color: Color.pink.opacity(0.7))
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func playerScore(name: String, score: Int, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(name).appFont(size: 12, weight: .semibold).foregroundColor(theme.textSecondary)
            Text("\(score)").appFont(size: 24, weight: .bold).foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { cat in
                    Button {
                        selectedCategory = cat
                        shuffleAndStart()
                    } label: {
                        Text(cat)
                            .appFont(size: 12, weight: .semibold)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background {
                                if selectedCategory == cat {
                                    theme.primary
                                }
                            }
                            .background {
                                if selectedCategory != cat {
                                    Rectangle().fill(.ultraThinMaterial)
                                }
                            }
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
            Text("\(currentIndex + 1)/\(currentStatements.count)").appFont(size: 12).foregroundColor(theme.textSecondary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.gray.opacity(0.2)).frame(height: 6)
                    Capsule().fill(theme.primary).frame(width: geo.size.width * CGFloat(currentIndex + 1) / CGFloat(max(currentStatements.count, 1)), height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    private var statementCard: some View {
        VStack(spacing: 16) {
            if currentStatements.isEmpty {
                Text("Sin preguntas para esta categoria")
                    .appFont(size: 16, weight: .medium)
                    .foregroundColor(theme.textSecondary)
                    .padding()
            } else {
                Text(currentStatements[currentIndex].text)
                    .appFont(size: 20, weight: .semibold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(theme.textPrimary)
                    .padding()
            }
        }
        .frame(maxWidth: .infinity, minHeight: 160)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        .id(currentIndex)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Text("Turno: \(currentPlayer == 0 ? "Jugador 1" : "Jugador 2")")
                .appFont(size: 13, weight: .semibold)
                .foregroundColor(theme.textSecondary)
            HStack(spacing: 16) {
                Button {
                    tapHeHecho()
                } label: {
                    Label("He hecho", systemImage: "hand.raised.fill")
                        .appFont(size: 15, weight: .semibold)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.green.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .foregroundColor(.green)
                Button {
                    tapNunca()
                } label: {
                    Label("Nunca", systemImage: "xmark.circle.fill")
                        .appFont(size: 15, weight: .semibold)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.red.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .foregroundColor(.red)
            }
        }
    }

    private var resultView: some View {
        VStack(spacing: 20) {
            Image(systemName: score1 > score2 ? "person.fill" : score2 > score1 ? "person.fill" : "heart.fill")
                .font(.system(size: 60))
                .foregroundColor(theme.primary)
            Text("Juego terminado").appFont(size: 22, weight: .bold).foregroundColor(theme.textPrimary)
            HStack(spacing: 30) {
                VStack {
                    Text("Jugador 1").appFont(size: 14).foregroundColor(theme.textSecondary)
                    Text("\(score1)").appFont(size: 36, weight: .bold).foregroundColor(.blue)
                }
                VStack {
                    Text("Jugador 2").appFont(size: 14).foregroundColor(theme.textSecondary)
                    Text("\(score2)").appFont(size: 36, weight: .bold).foregroundColor(.pink)
                }
            }
            Text(winnerText()).appFont(size: 16, weight: .semibold).foregroundColor(theme.textPrimary)
            Button {
                shuffleAndStart()
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
    }

    private var addStatementSheet: some View {
        NavigationStack {
            Form {
                Section(editingStatement != nil ? "Editar afirmacion" : "Nueva afirmacion") {
                    TextField("Texto", text: $newText)
                    Picker("Categoria", selection: $newCategory) {
                        ForEach(categories, id: \.self) { Text($0) }
                    }
                    Picker("Coleccion", selection: $newCollection) {
                        ForEach(collections, id: \.self) { Text($0) }
                    }
                }
            }
            .navigationTitle(editingStatement != nil ? "Editar afirmacion" : "Anadir afirmacion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { saveStatement() }.disabled(newText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        editingStatement = nil
                        showAddSheet = false
                    }
                }
            }
        }
    }

    private func tapHeHecho() {
        if currentPlayer == 0 { score1 += 1 } else { score2 += 1 }
        nextStatement()
    }

    private func tapNunca() {
        nextStatement()
    }

    private func nextStatement() {
        withAnimation {
            if currentIndex + 1 >= currentStatements.count {
                gameOver = true
                GameService.shared.saveGameStats("nunca", ["score1": score1, "score2": score2, "category": selectedCategory])
            } else {
                currentIndex += 1
                currentPlayer = currentPlayer == 0 ? 1 : 0
            }
        }
    }

    private func shuffleAndStart() {
        let filtered = customStatements.filter { $0.category == selectedCategory }.shuffled()
        currentStatements = filtered
        currentIndex = 0
        score1 = 0
        score2 = 0
        currentPlayer = 0
        gameOver = false
    }

    private func winnerText() -> String {
        if score1 > score2 { return "Gana Jugador 1!" }
        if score2 > score1 { return "Gana Jugador 2!" }
        return "Empate!"
    }

    private func setupListener() {
        listener = GameService.shared.streamNever().addSnapshotListener { snapshot, error in
            guard let docs = snapshot?.documents else { return }
            customStatements = docs.compactMap { doc in
                let d = doc.data()
                guard let text = d["text"] as? String else { return nil }
                return NeverModel(
                    id: doc.documentID,
                    text: text,
                    category: d["category"] as? String ?? "Romantico",
                    collection: d["collection"] as? String ?? "Pareja"
                )
            }
            if !currentStatements.isEmpty {
                shuffleAndStart()
            }
        }
    }

    private func saveStatement() {
        let text = newText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        if let editing = editingStatement {
            GameService.shared.saveNever(["text": text, "category": newCategory, "collection": newCollection], id: editing.id)
        } else {
            GameService.shared.saveNever(["text": text, "category": newCategory, "collection": newCollection])
        }
        newText = ""
        newCategory = "Romantico"
        newCollection = "Pareja"
        editingStatement = nil
        showAddSheet = false
    }
}
