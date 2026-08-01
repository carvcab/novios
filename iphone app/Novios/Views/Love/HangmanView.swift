import SwiftUI
import FirebaseFirestore

private let letters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZÑ")

private struct HangmanWordModel: Identifiable {
    let id: String
    let word: String
    let hint: String
    let category: String
}

public struct HangmanView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var customWords: [HangmanWordModel] = []
    @State private var currentWord = ""
    @State private var currentHint = ""
    @State private var guessedLetters: Set<Character> = []
    @State private var wrongGuesses = 0
    @State private var score = 0
    @State private var gamesPlayed = 0
    @State private var gameOver = false
    @State private var showResult = false
    @State private var won = false
    @State private var selectedCategory = ""
    @State private var showAddSheet = false
    @State private var newWord = ""
    @State private var newHint = ""
    @State private var newCategory = ""
    @State private var editingWordId: String?
    @State private var listener: ListenerRegistration?
    @State private var editMode = false

    private let maxWrong = 6

    private var categories: [String] {
        let fromData = Set(customWords.map(\.category))
        return fromData.sorted()
    }

    private var availableWords: [HangmanWordModel] {
        customWords.filter { $0.category == selectedCategory }
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundGradient.ignoresSafeArea()
                if editMode {
                    wordList
                } else {
                    VStack(spacing: 10) {
                        scoreHeader
                        categoryPicker
                        if currentWord.isEmpty {
                            Text("No hay palabras para esta categoria")
                                .appFont(size: 14)
                                .foregroundColor(theme.textSecondary)
                                .frame(maxHeight: .infinity)
                        } else {
                            hangmanCanvas
                            hintText
                            wordDisplay
                            keyboardGrid
                        }
                        newGameButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Ahorcado")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Cerrar") { dismiss() } }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundColor(theme.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(editMode ? "Listo" : "Editar") { editMode.toggle() }
                        .foregroundColor(theme.primary)
                }
            }
            .alert(won ? "Ganaste!" : "Perdiste", isPresented: $showResult) {
                Text(won ? "Palabra: \(currentWord)" : "Era: \(currentWord)")
                Button("Siguiente") { pickWord() }
                Button("Cerrar", role: .cancel) { dismiss() }
            }
            .sheet(isPresented: $showAddSheet) { addWordSheet }
            .onAppear {
                setupListener()
                if !customWords.isEmpty, selectedCategory.isEmpty {
                    selectedCategory = categories.first ?? ""
                }
                if !currentWord.isEmpty || (!availableWords.isEmpty && currentWord.isEmpty) {
                    pickWord()
                }
            }
            .onDisappear { listener?.remove() }
        }
    }

    private var scoreHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Puntaje: \(score)").appFont(size: 16, weight: .bold).foregroundColor(theme.textPrimary)
                Text("Jugados: \(gamesPlayed)").appFont(size: 12).foregroundColor(theme.textSecondary)
            }
            Spacer()
            Text("Errores: \(wrongGuesses)/\(maxWrong)").appFont(size: 14, weight: .semibold).foregroundColor(wrongGuesses > 3 ? .red : theme.textPrimary)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { cat in
                    Button {
                        selectedCategory = cat
                        pickWord()
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

    private var hangmanCanvas: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let baseY = h * 0.9
            context.stroke(Path { p in
                p.move(to: CGPoint(x: w * 0.1, y: baseY))
                p.addLine(to: CGPoint(x: w * 0.9, y: baseY))
            }, with: .color(theme.textPrimary.opacity(0.4)), lineWidth: 3)
            context.stroke(Path { p in
                p.move(to: CGPoint(x: w * 0.2, y: baseY))
                p.addLine(to: CGPoint(x: w * 0.2, y: h * 0.1))
                p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.1))
                p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.2))
            }, with: .color(theme.textPrimary.opacity(0.4)), lineWidth: 3)
            context.stroke(Path { p in
                p.move(to: CGPoint(x: w * 0.5, y: h * 0.1))
                p.addLine(to: CGPoint(x: w * 0.8, y: h * 0.1))
            }, with: .color(theme.textPrimary.opacity(0.3)), lineWidth: 2)
            if wrongGuesses > 0 {
                let head = CGPoint(x: w * 0.5, y: h * 0.26)
                context.stroke(Path { p in
                    p.addArc(center: head, radius: w * 0.05, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
                }, with: .color(theme.primary), lineWidth: 3)
            }
            if wrongGuesses > 1 {
                let neck = CGPoint(x: w * 0.5, y: h * 0.35)
                context.stroke(Path { p in
                    p.move(to: CGPoint(x: w * 0.5, y: h * 0.31))
                    p.addLine(to: neck)
                }, with: .color(theme.primary), lineWidth: 3)
            }
            if wrongGuesses > 2 {
                context.stroke(Path { p in
                    p.move(to: CGPoint(x: w * 0.5, y: h * 0.35))
                    p.addLine(to: CGPoint(x: w * 0.35, y: h * 0.55))
                }, with: .color(theme.primary), lineWidth: 3)
            }
            if wrongGuesses > 3 {
                context.stroke(Path { p in
                    p.move(to: CGPoint(x: w * 0.5, y: h * 0.35))
                    p.addLine(to: CGPoint(x: w * 0.65, y: h * 0.55))
                }, with: .color(theme.primary), lineWidth: 3)
            }
            if wrongGuesses > 4 {
                context.stroke(Path { p in
                    p.move(to: CGPoint(x: w * 0.5, y: h * 0.45))
                    p.addLine(to: CGPoint(x: w * 0.35, y: h * 0.75))
                }, with: .color(theme.primary), lineWidth: 3)
            }
            if wrongGuesses > 5 {
                context.stroke(Path { p in
                    p.move(to: CGPoint(x: w * 0.5, y: h * 0.45))
                    p.addLine(to: CGPoint(x: w * 0.65, y: h * 0.75))
                }, with: .color(theme.primary), lineWidth: 3)
            }
        }
        .frame(height: 140)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var hintText: some View {
        Group {
            if !currentHint.isEmpty {
                Text("Pista: \(currentHint)")
                    .appFont(size: 13, weight: .medium)
                    .foregroundColor(theme.textSecondary)
                    .padding(.horizontal)
            }
        }
    }

    private var wordDisplay: some View {
        let display = currentWord.map { guessedLetters.contains($0) ? String($0) : "_" }.joined(separator: " ")
        return Text(display)
            .appFont(size: 28, weight: .bold)
            .foregroundColor(theme.primary)
            .tracking(4)
            .padding()
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var keyboardGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
            ForEach(letters, id: \.self) { letter in
                let used = guessedLetters.contains(letter)
                let isCorrect = currentWord.contains(letter)
                Button {
                    guess(letter)
                } label: {
                    Text(String(letter))
                        .appFont(size: 15, weight: .semibold)
                        .frame(width: 34, height: 34)
                        .background(used ? (isCorrect ? Color.green.opacity(0.3) : Color.red.opacity(0.3)) : theme.primary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .foregroundColor(used ? (isCorrect ? .green : .red) : theme.textPrimary)
                }
                .disabled(used || gameOver || currentWord.isEmpty)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var newGameButton: some View {
        Button {
            pickWord()
        } label: {
            Label("Nueva palabra", systemImage: "arrow.counterclockwise")
                .appFont(size: 14, weight: .semibold)
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(theme.primary.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .foregroundColor(theme.textPrimary)
        .disabled(availableWords.isEmpty)
    }

    private var wordList: some View {
        List {
            ForEach(customWords) { w in
                Button {
                    newWord = w.word
                    newHint = w.hint
                    newCategory = w.category
                    editingWordId = w.id
                    showAddSheet = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(w.word).appFont(size: 14, weight: .bold).foregroundColor(theme.textPrimary)
                            HStack(spacing: 4) {
                                Text(w.category).appFont(size: 11).foregroundColor(theme.primary)
                                if !w.hint.isEmpty {
                                    Text("- \(w.hint)").appFont(size: 11).foregroundColor(theme.textSecondary)
                                }
                            }
                        }
                        Spacer()
                        Image(systemName: "pencil.circle.fill").foregroundColor(theme.primary)
                    }
                }
            }
            .onDelete(perform: deleteCustomWord)
        }
        .scrollContentBackground(.hidden)
    }

    private var addWordSheet: some View {
        NavigationStack {
            Form {
                Section(editingWordId != nil ? "Editar palabra" : "Nueva palabra") {
                    TextField("Palabra", text: $newWord)
                        .autocapitalization(.allCharacters)
                    TextField("Pista (opcional)", text: $newHint)
                    TextField("Categoria", text: $newCategory)
                }
            }
            .navigationTitle(editingWordId != nil ? "Editar" : "Agregar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { saveCustomWord() }.disabled(newWord.trimmingCharacters(in: .whitespaces).isEmpty || newCategory.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        resetWordFields()
                        showAddSheet = false
                    }
                }
            }
        }
    }

    private func guess(_ letter: Character) {
        guard !gameOver else { return }
        guessedLetters.insert(letter)
        if currentWord.contains(letter) {
            if currentWord.allSatisfy({ guessedLetters.contains($0) }) {
                endGame(won: true)
            }
        } else {
            wrongGuesses += 1
            if wrongGuesses >= maxWrong {
                endGame(won: false)
            }
        }
    }

    private func endGame(won: Bool) {
        gameOver = true
        gamesPlayed += 1
        self.won = won
        if won {
            score += 1
        }
        showResult = true
        GameService.shared.saveGameStats("hangman", ["score": score, "word": currentWord, "won": won])
    }

    private func pickWord() {
        let pool = availableWords
        if pool.isEmpty {
            currentWord = ""
            currentHint = ""
            guessedLetters = []
            wrongGuesses = 0
            gameOver = false
            showResult = false
            return
        }
        let chosen = pool.randomElement()!
        currentWord = chosen.word
        currentHint = chosen.hint
        guessedLetters = []
        wrongGuesses = 0
        gameOver = false
        showResult = false
    }

    private func setupListener() {
        listener = GameService.shared.streamHangman().addSnapshotListener { snapshot, error in
            guard let docs = snapshot?.documents else { return }
            customWords = docs.compactMap { doc in
                let d = doc.data()
                guard let word = d["word"] as? String else { return nil }
                return HangmanWordModel(id: doc.documentID, word: word.uppercased(), hint: d["hint"] as? String ?? "", category: d["category"] as? String ?? "Personalizado")
            }
            if selectedCategory.isEmpty, let first = categories.first {
                selectedCategory = first
            }
            if !categories.contains(selectedCategory) {
                selectedCategory = categories.first ?? ""
            }
            if currentWord.isEmpty || !availableWords.contains(where: { $0.word == currentWord }) {
                pickWord()
            }
        }
    }

    private func saveCustomWord() {
        let word = newWord.trimmingCharacters(in: .whitespaces).uppercased()
        let category = newCategory.trimmingCharacters(in: .whitespaces)
        guard !word.isEmpty, !category.isEmpty else { return }
        if let id = editingWordId {
            GameService.shared.saveHangmanWord(["word": word, "hint": newHint, "category": category], id: id)
        } else {
            GameService.shared.saveHangmanWord(["word": word, "hint": newHint, "category": category])
        }
        resetWordFields()
        showAddSheet = false
    }

    private func deleteCustomWord(at offsets: IndexSet) {
        for idx in offsets {
            GameService.shared.deleteHangmanWord(customWords[idx].id)
        }
    }

    private func resetWordFields() {
        newWord = ""
        newHint = ""
        newCategory = ""
        editingWordId = nil
    }
}
