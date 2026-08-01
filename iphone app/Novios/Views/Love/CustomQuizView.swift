import SwiftUI
import FirebaseFirestore

// MARK: - Models

private struct QuizItem: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let category: String
    let difficulty: String
    let color: String
    let icon: String
    let questions: [QuizQuestion]
    let author: String
    let authorId: String

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: QuizItem, rhs: QuizItem) -> Bool { lhs.id == rhs.id }
}

private struct QuizQuestion: Hashable {
    let text: String
    let options: [String]
    let correctIndex: Int
    let explanation: String
}

private struct EditableQuestion {
    var text: String
    var options: [String]
    var correctIndex: Int
    var explanation: String
}

// MARK: - Category Colors

private func categoryGradient(_ category: String) -> [Color] {
    switch category {
    case "Romantico": return [.red, Color(red: 0.9, green: 0.2, blue: 0.3)]
    case "Divertido": return [.orange, Color(red: 1, green: 0.7, blue: 0.2)]
    case "Viajes": return [.blue, Color(red: 0.2, green: 0.6, blue: 1)]
    case "Picante": return [.purple, Color(red: 0.7, green: 0.2, blue: 0.8)]
    case "Personalizado": return [.green, Color(red: 0.3, green: 0.8, blue: 0.4)]
    default: return [ThemeManager.shared.primary, ThemeManager.shared.secondary]
    }
}

private let colorOptions: [(name: String, color: Color)] = [
    ("red", .red), ("pink", .pink), ("purple", .purple),
    ("blue", .blue), ("mint", .mint), ("orange", .orange),
    ("yellow", .yellow), ("white", .white), ("black", .black)
]

private let iconOptions = [
    "heart.fill", "star.fill", "sparkle", "flame.fill",
    "moon.fill", "sun.max.fill", "gift.fill", "crown.fill",
    "bolt.fill", "leaf.fill", "music.note", "book.fill"
]

private let categoryOptions = ["Romantico", "Divertido", "Viajes", "Picante", "Personalizado"]
private let difficultyOptions = ["Facil", "Medio", "Dificil"]

private func colorFromName(_ name: String) -> Color {
    colorOptions.first(where: { $0.name == name.lowercased() })?.color ?? ThemeManager.shared.primary
}

// MARK: - CustomQuizView

public struct CustomQuizView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var quizzes: [QuizItem] = []
    @State private var listener: ListenerRegistration?
    @State private var showCreate = false

    private let currentUserId = UserDefaults.standard.string(forKey: "user_id") ?? ""

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundGradient.ignoresSafeArea()
                if quizzes.isEmpty {
                    emptyState
                } else {
                    quizList
                }
            }
            .navigationTitle("Quizzes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cerrar") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showCreate = true } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
            .onAppear { startListening() }
            .onDisappear { listener?.remove() }
            .sheet(isPresented: $showCreate) {
                CreateEditQuizView(quiz: nil) { }
            }
            .navigationDestination(for: QuizItem.self) { quiz in
                QuizDetailView(quiz: quiz)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 50))
                .foregroundColor(theme.textSecondary.opacity(0.4))
            Text("No hay quizzes aun")
                .appFont(size: 16, weight: .semibold)
                .foregroundColor(theme.textPrimary)
            Text("Crea tu primer quiz personalizado")
                .appFont(size: 13)
                .foregroundColor(theme.textSecondary)
            Button {
                showCreate = true
            } label: {
                Label("Crear Quiz", systemImage: "plus.circle.fill")
                    .appFont(size: 14, weight: .semibold)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(theme.primary)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var quizList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(quizzes) { quiz in
                    NavigationLink(value: quiz) {
                        QuizCardView(quiz: quiz)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        if quiz.authorId == currentUserId {
                            Button(role: .destructive) {
                                GameService.shared.deleteQuiz(quiz.id)
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    private func startListening() {
        listener?.remove()
        listener = GameService.shared.streamQuizzes().addSnapshotListener { snapshot, error in
            guard let docs = snapshot?.documents else { return }
            quizzes = docs.compactMap { doc in
                let data = doc.data()
                guard let title = data["title"] as? String,
                      let questionsData = data["questions"] as? [[String: Any]] else { return nil }
                let questions = questionsData.compactMap { q -> QuizQuestion? in
                    guard let text = q["text"] as? String,
                          let options = q["options"] as? [String],
                          let correctIndex = q["correctIndex"] as? Int else { return nil }
                    return QuizQuestion(
                        text: text,
                        options: options,
                        correctIndex: correctIndex,
                        explanation: q["explanation"] as? String ?? ""
                    )
                }
                return QuizItem(
                    id: doc.documentID,
                    title: title,
                    description: data["description"] as? String ?? "",
                    category: data["category"] as? String ?? "Romantico",
                    difficulty: data["difficulty"] as? String ?? "Facil",
                    color: data["color"] as? String ?? "pink",
                    icon: data["icon"] as? String ?? "heart.fill",
                    questions: questions,
                    author: data["author"] as? String ?? "",
                    authorId: data["authorId"] as? String ?? ""
                )
            }
        }
    }
}

// MARK: - QuizCardView

private struct QuizCardView: View {
    @ObservedObject private var theme = ThemeManager.shared
    let quiz: QuizItem

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: quiz.icon)
                .font(.system(size: 28))
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(colorFromName(quiz.color).opacity(0.3))
                        .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1))
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(quiz.title)
                    .appFont(size: 16, weight: .semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(quiz.description)
                    .appFont(size: 12)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Label(quiz.category, systemImage: "tag.fill")
                        .appFont(size: 10)
                    Text("·")
                        .appFont(size: 10)
                    Text("\(quiz.questions.count) preguntas")
                        .appFont(size: 10)
                    Text("·")
                        .appFont(size: 10)
                    Text(quiz.difficulty)
                        .appFont(size: 10)
                }
                .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.8))
                Text(quiz.author)
                    .appFont(size: 10)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: categoryGradient(quiz.category),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: categoryGradient(quiz.category)[0].opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// MARK: - QuizDetailView

private struct QuizDetailView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    let quiz: QuizItem

    @State private var showPlay = false
    @State private var showEdit = false
    @State private var showDeleteConfirm = false
    @State private var stats: [[String: Any]] = []
    @State private var statsListener: ListenerRegistration?

    private let currentUserId = UserDefaults.standard.string(forKey: "user_id") ?? ""
    private var isOwner: Bool { quiz.authorId == currentUserId }

    var body: some View {
        ZStack {
            theme.backgroundGradient.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    headerCard
                    statsSection
                    actionButtons
                }
                .padding(16)
            }
        }
        .navigationTitle("Detalle")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { startStatsListener() }
        .onDisappear { statsListener?.remove() }
        .fullScreenCover(isPresented: $showPlay) {
            PlayQuizView(quiz: quiz)
        }
        .sheet(isPresented: $showEdit) {
            CreateEditQuizView(quiz: quiz) { }
        }
        .alert("Eliminar quiz", isPresented: $showDeleteConfirm) {
            Button("Cancelar", role: .cancel) { }
            Button("Eliminar", role: .destructive) {
                GameService.shared.deleteQuiz(quiz.id)
                dismiss()
            }
        } message: {
            Text("Esta accion no se puede deshacer.")
        }
    }

    private var headerCard: some View {
        VStack(spacing: 14) {
            Image(systemName: quiz.icon)
                .font(.system(size: 44))
                .foregroundColor(colorFromName(quiz.color))
                .frame(width: 72, height: 72)
                .background(
                    Circle()
                        .fill(colorFromName(quiz.color).opacity(0.15))
                        .overlay(Circle().stroke(colorFromName(quiz.color).opacity(0.3), lineWidth: 1))
                )

            Text(quiz.title)
                .appFont(size: 22, weight: .bold)
                .foregroundColor(theme.textPrimary)
                .multilineTextAlignment(.center)

            if !quiz.description.isEmpty {
                Text(quiz.description)
                    .appFont(size: 14)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 16) {
                Label(quiz.category, systemImage: "tag.fill")
                Label(quiz.difficulty, systemImage: "chart.bar.fill")
                Label("\(quiz.questions.count) preguntas", systemImage: "list.bullet")
            }
            .appFont(size: 12)
            .foregroundColor(theme.textSecondary)

            Text("Creado por \(quiz.author)")
                .appFont(size: 12)
                .foregroundColor(theme.textSecondary.opacity(0.7))
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Estadisticas")
                .appFont(size: 16, weight: .semibold)
                .foregroundColor(theme.textPrimary)

            if stats.isEmpty {
                Text("Aun no hay estadisticas")
                    .appFont(size: 13)
                    .foregroundColor(theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(stats.prefix(5).enumerated()), id: \.offset) { _, stat in
                    HStack {
                        Text(stat["playerName"] as? String ?? "")
                            .appFont(size: 13)
                            .foregroundColor(theme.textPrimary)
                        Spacer()
                        Text("\(stat["score"] as? Int ?? 0)/\(stat["total"] as? Int ?? 0)")
                            .appFont(size: 13, weight: .semibold)
                            .foregroundColor(theme.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                showPlay = true
            } label: {
                Label("Jugar", systemImage: "play.fill")
                    .appFont(size: 16, weight: .semibold)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(theme.primary)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            if isOwner {
                HStack(spacing: 12) {
                    Button {
                        showEdit = true
                    } label: {
                        Label("Editar", systemImage: "pencil")
                            .appFont(size: 14, weight: .semibold)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .foregroundColor(theme.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Eliminar", systemImage: "trash")
                            .appFont(size: 14, weight: .semibold)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .foregroundColor(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }

    private func startStatsListener() {
        statsListener = GameService.shared.streamGameStats("quizzes").addSnapshotListener { snapshot, _ in
            guard let docs = snapshot?.documents else { return }
            stats = docs.compactMap { doc in
                let data = doc.data()
                guard data["quizId"] as? String == quiz.id else { return nil }
                return data
            }
        }
    }
}

// MARK: - PlayQuizView

private struct PlayQuizView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    let quiz: QuizItem

    @State private var currentQuestionIndex = 0
    @State private var score = 0
    @State private var selectedAnswer: Int?
    @State private var showResult = false
    @State private var isAdvancing = false

    private var questions: [QuizQuestion] { quiz.questions }

    var body: some View {
        ZStack {
            theme.backgroundGradient.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                if showResult {
                    resultView
                } else if currentQuestionIndex < questions.count {
                    questionArea
                }
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(theme.textSecondary)
            }

            Spacer()

            Text(quiz.title)
                .appFont(size: 16, weight: .semibold)
                .foregroundColor(theme.textPrimary)
                .lineLimit(1)

            Spacer()

            Text("\(score)/\(questions.count)")
                .appFont(size: 14, weight: .bold)
                .foregroundColor(theme.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var questionArea: some View {
        let question = questions[currentQuestionIndex]
        return VStack(spacing: 16) {
            ProgressView(value: Double(currentQuestionIndex + 1), total: Double(questions.count))
                .tint(theme.primary)
                .padding(.horizontal, 16)
                .padding(.top, 8)

            Text("Pregunta \(currentQuestionIndex + 1) de \(questions.count)")
                .appFont(size: 12)
                .foregroundColor(theme.textSecondary)

            Text(question.text)
                .appFont(size: 20, weight: .semibold)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.textPrimary)
                .padding()
                .frame(maxWidth: .infinity, minHeight: 100)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 16)

            VStack(spacing: 10) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                    Button {
                        selectAnswer(index, question: question)
                    } label: {
                        HStack {
                            Text(option)
                                .appFont(size: 15, weight: .semibold)
                                .foregroundColor(answerColor(index: index, question: question))
                                .multilineTextAlignment(.leading)
                            Spacer()
                            if let sel = selectedAnswer, sel == index {
                                Image(systemName: index == question.correctIndex ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(index == question.correctIndex ? .green : .red)
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(answerBgColor(index: index, question: question))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(answerBorderColor(index: index, question: question), lineWidth: selectedAnswer != nil && index == question.correctIndex ? 2 : 0)
                        )
                    }
                    .disabled(selectedAnswer != nil)
                }
            }
            .padding(.horizontal, 16)

            if selectedAnswer != nil {
                Button {
                    advanceToNext()
                } label: {
                    Text(currentQuestionIndex + 1 < questions.count ? "Siguiente" : "Ver resultado")
                        .appFont(size: 15, weight: .semibold)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(theme.primary)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 16)
            }
        }
        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
    }

    private var resultView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: score == questions.count ? "star.fill" : score > questions.count / 2 ? "hand.thumbsup.fill" : "heart.fill")
                .font(.system(size: 60))
                .foregroundColor(theme.primary)

            Text("Completaste \(quiz.title)")
                .appFont(size: 22, weight: .bold)
                .foregroundColor(theme.textPrimary)

            Text("Puntaje: \(score)/\(questions.count)")
                .appFont(size: 36, weight: .bold)
                .foregroundColor(theme.primary)

            Text(resultMessage)
                .appFont(size: 16)
                .foregroundColor(theme.textSecondary)

            Spacer()

            Button {
                resetGame()
            } label: {
                Label("Jugar de nuevo", systemImage: "arrow.counterclockwise")
                    .appFont(size: 16, weight: .semibold)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(theme.primary)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 16)

            Button {
                dismiss()
            } label: {
                Text("Salir")
                    .appFont(size: 14, weight: .semibold)
                    .padding(12)
                    .foregroundColor(theme.textSecondary)
            }
        }
        .padding()
    }

    private var resultMessage: String {
        if score == questions.count { return "Perfecto! 🎉"}
        if score > questions.count / 2 { return "Buen trabajo! 👏"}
        return "Sigue intentando! 💪"
    }

    private func selectAnswer(_ index: Int, question: QuizQuestion) {
        guard !isAdvancing else { return }
        selectedAnswer = index
        if index == question.correctIndex {
            score += 1
        }
        isAdvancing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
            advanceToNext()
        }
    }

    private func advanceToNext() {
        guard !showResult else { return }
        if currentQuestionIndex + 1 < questions.count {
            withAnimation {
                currentQuestionIndex += 1
                selectedAnswer = nil
                isAdvancing = false
            }
        } else {
            showResult = true
            saveStats()
        }
    }

    private func saveStats() {
        GameService.shared.saveGameStats("quizzes", [
            "score": score,
            "total": questions.count,
            "quizId": quiz.id
        ])
    }

    private func resetGame() {
        currentQuestionIndex = 0
        score = 0
        selectedAnswer = nil
        showResult = false
    }

    private func answerColor(index: Int, question: QuizQuestion) -> Color {
        guard let sel = selectedAnswer else { return theme.textPrimary }
        if index == question.correctIndex { return .green }
        if index == sel { return .red }
        return theme.textPrimary.opacity(0.4)
    }

    private func answerBgColor(index: Int, question: QuizQuestion) -> Color {
        guard let sel = selectedAnswer else { return Color.clear }
        if index == question.correctIndex { return Color.green.opacity(0.12) }
        if index == sel { return Color.red.opacity(0.12) }
        return Color.clear
    }

    private func answerBorderColor(index: Int, question: QuizQuestion) -> Color {
        guard let sel = selectedAnswer else { return Color.clear }
        if index == question.correctIndex { return .green.opacity(0.5) }
        if index == sel { return .red.opacity(0.5) }
        return Color.clear
    }
}

// MARK: - CreateEditQuizView

private struct CreateEditQuizView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    let quiz: QuizItem?

    var body: some View {
        NavigationStack {
            Form {
                infoSection
                appearanceSection
                questionsSection
            }
            .navigationTitle(quiz == nil ? "Crear Quiz" : "Editar Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { save() }
                        .disabled(!isValid)
                }
            }
        }
    }

    // MARK: - Form State

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var category: String = "Romantico"
    @State private var difficulty: String = "Facil"
    @State private var selectedColor: String = "pink"
    @State private var selectedIcon: String = "heart.fill"
    @State private var questions: [EditableQuestion] = []
    @State private var saving = false

    init(quiz: QuizItem?, onSave: @escaping () -> Void = {}) {
        self.quiz = quiz
        _title = State(initialValue: quiz?.title ?? "")
        _description = State(initialValue: quiz?.description ?? "")
        _category = State(initialValue: quiz?.category ?? "Romantico")
        _difficulty = State(initialValue: quiz?.difficulty ?? "Facil")
        _selectedColor = State(initialValue: quiz?.color ?? "pink")
        _selectedIcon = State(initialValue: quiz?.icon ?? "heart.fill")
        if let q = quiz {
            _questions = State(initialValue: q.questions.map {
                EditableQuestion(text: $0.text, options: $0.options, correctIndex: $0.correctIndex, explanation: $0.explanation)
            })
        } else {
            _questions = State(initialValue: [EditableQuestion(text: "", options: ["", "", "", ""], correctIndex: 0, explanation: "")])
        }
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !questions.isEmpty &&
        questions.allSatisfy { !$0.text.trimmingCharacters(in: .whitespaces).isEmpty } &&
        !saving
    }

    // MARK: - Info Section

    private var infoSection: some View {
        Section("Informacion") {
            TextField("Titulo del quiz", text: $title)
            TextField("Descripcion (opcional)", text: $description)

            Picker("Categoria", selection: $category) {
                ForEach(categoryOptions, id: \.self) { cat in
                    HStack {
                        Circle()
                            .fill(categoryGradient(cat)[0])
                            .frame(width: 12, height: 12)
                        Text(cat)
                    }.tag(cat)
                }
            }

            Picker("Dificultad", selection: $difficulty) {
                ForEach(difficultyOptions, id: \.self) { diff in
                    Text(diff).tag(diff)
                }
            }
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        Section("Apariencia") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Color").appFont(size: 12, weight: .semibold).foregroundColor(theme.textSecondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(colorOptions, id: \.name) { option in
                            Circle()
                                .fill(option.color)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == option.name ? Color.white : Color.clear, lineWidth: 3)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(option.color.opacity(0.4), lineWidth: selectedColor == option.name ? 5 : 0)
                                )
                                .shadow(color: option.color.opacity(0.4), radius: selectedColor == option.name ? 6 : 0)
                                .onTapGesture { selectedColor = option.name }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Icono").appFont(size: 12, weight: .semibold).foregroundColor(theme.textSecondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.system(size: 20))
                                .foregroundColor(selectedIcon == icon ? .white : theme.textPrimary)
                                .frame(width: 42, height: 42)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedIcon == icon ? theme.primary : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedIcon == icon ? Color.clear : theme.textSecondary.opacity(0.3), lineWidth: 1)
                                )
                                .onTapGesture { selectedIcon = icon }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Questions Section

    private var questionsSection: some View {
        Section("Preguntas") {
            ForEach(questions.indices, id: \.self) { qIndex in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Pregunta \(qIndex + 1)")
                            .appFont(size: 13, weight: .semibold)
                            .foregroundColor(theme.textPrimary)
                        Spacer()
                        if questions.count > 1 {
                            Button(role: .destructive) {
                                questions.remove(at: qIndex)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                            }
                        }
                    }

                    TextField("Escribe la pregunta", text: $questions[qIndex].text)

                    ForEach(questions[qIndex].options.indices, id: \.self) { oIndex in
                        HStack {
                            TextField("Opcion \(oIndex + 1)", text: $questions[qIndex].options[oIndex])

                            Button {
                                questions[qIndex].correctIndex = oIndex
                            } label: {
                                Image(systemName: questions[qIndex].correctIndex == oIndex ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(questions[qIndex].correctIndex == oIndex ? .green : theme.textSecondary)
                                    .font(.system(size: 18))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    TextField("Explicacion (opcional)", text: $questions[qIndex].explanation)
                }
                .padding(.vertical, 6)
            }

            Button {
                questions.append(EditableQuestion(text: "", options: ["", "", "", ""], correctIndex: 0, explanation: ""))
            } label: {
                Label("Agregar pregunta", systemImage: "plus.circle")
                    .appFont(size: 13, weight: .semibold)
            }
        }
    }

    // MARK: - Save

    private func save() {
        guard isValid else { return }
        saving = true
        let validQuestions = questions.filter {
            !$0.text.trimmingCharacters(in: .whitespaces).isEmpty &&
            $0.options.allSatisfy { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        }
        let questionsData = validQuestions.map { q in
            [
                "text": q.text.trimmingCharacters(in: .whitespaces),
                "options": q.options.map { $0.trimmingCharacters(in: .whitespaces) },
                "correctIndex": q.correctIndex,
                "explanation": q.explanation.trimmingCharacters(in: .whitespaces)
            ] as [String: Any]
        }
        let data: [String: Any] = [
            "title": title.trimmingCharacters(in: .whitespaces),
            "description": description.trimmingCharacters(in: .whitespaces),
            "category": category,
            "difficulty": difficulty,
            "color": selectedColor,
            "icon": selectedIcon,
            "questions": questionsData
        ]
        GameService.shared.saveQuiz(data, id: quiz?.id)
        dismiss()
    }
}
