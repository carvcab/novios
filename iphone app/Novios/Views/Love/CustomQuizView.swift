import SwiftUI
import FirebaseFirestore

public struct CustomQuizView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var quizzes: [Quiz] = []
    @State private var showCreate = false
    @State private var playingQuiz: Quiz?
    @State private var currentQuestionIndex = 0
    @State private var score = 0
    @State private var showResult = false
    @State private var selectedAnswer: Int?
    @State private var showAnswerFeedback = false

    private let db = Firestore.firestore()
    private var coupleId: String { [CoupleService.diegoUid, CoupleService.yosmariUid].sorted().joined(separator: "_") }
    private var quizzesRef: CollectionReference { db.collection("couples").document(coupleId).collection("customQuizzes") }

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundGradient.ignoresSafeArea()
                if let quiz = playingQuiz {
                    playView(quiz: quiz)
                } else {
                    VStack(spacing: 0) {
                        if quizzes.isEmpty {
                            emptyState
                        } else {
                            quizList
                        }
                    }
                }
            }
            .navigationTitle("Quizzes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if playingQuiz == nil {
                        Button("Cerrar") { dismiss() }
                    } else {
                        Button("Salir") {
                            withAnimation { playingQuiz = nil }
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if playingQuiz == nil {
                        Button {
                            showCreate = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .onAppear { loadQuizzes() }
            .sheet(isPresented: $showCreate) {
                CreateQuizView(quizzesRef: quizzesRef, onSave: { loadQuizzes() })
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.stack.3d.up.slash").font(.system(size: 50)).foregroundColor(theme.textSecondary.opacity(0.4))
            Text("No hay quizzes aun").appFont(size: 16, weight: .semibold).foregroundColor(theme.textPrimary)
            Text("Crea tu primer quiz").appFont(size: 13).foregroundColor(theme.textSecondary)
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
                    Button {
                        withAnimation { playingQuiz = quiz; currentQuestionIndex = 0; score = 0; selectedAnswer = nil }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(quiz.name).appFont(size: 16, weight: .semibold).foregroundColor(theme.textPrimary)
                                Text("\(quiz.questions.count) preguntas").appFont(size: 12).foregroundColor(theme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "play.circle.fill").font(.system(size: 28)).foregroundColor(theme.primary)
                        }
                        .padding(14)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteQuiz(quiz)
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    private func playView(quiz: Quiz) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text(quiz.name).appFont(size: 18, weight: .bold).foregroundColor(theme.textPrimary)
                Spacer()
                Text("\(score)/\(quiz.questions.count)").appFont(size: 14, weight: .semibold).foregroundColor(theme.primary)
            }
            .padding(.horizontal)

            if showResult {
                resultView(quiz: quiz)
            } else if currentQuestionIndex < quiz.questions.count {
                questionView(quiz: quiz)
            }
        }
        .padding(.top)
    }

    private func questionView(quiz: Quiz) -> some View {
        let question = quiz.questions[currentQuestionIndex]
        return VStack(spacing: 16) {
            ProgressView(value: Double(currentQuestionIndex + 1), total: Double(quiz.questions.count))
                .tint(theme.primary)
                .padding(.horizontal)

            Text("Pregunta \(currentQuestionIndex + 1) de \(quiz.questions.count)")
                .appFont(size: 12)
                .foregroundColor(theme.textSecondary)

            Text(question.text)
                .appFont(size: 18, weight: .semibold)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.textPrimary)
                .padding()
                .frame(maxWidth: .infinity, minHeight: 100)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(spacing: 10) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                    Button {
                        selectAnswer(index, question: question)
                    } label: {
                        HStack {
                            Text(option)
                                .appFont(size: 14, weight: .semibold)
                                .foregroundColor(answerColor(index: index, question: question))
                            Spacer()
                            if let sel = selectedAnswer, sel == index {
                                Image(systemName: index == question.correctIndex ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(index == question.correctIndex ? .green : .red)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(answerBgColor(index: index, question: question))
                        )
                    }
                    .disabled(selectedAnswer != nil)
                }
            }

            if selectedAnswer != nil {
                Button {
                    if currentQuestionIndex + 1 < quiz.questions.count {
                        withAnimation {
                            currentQuestionIndex += 1
                            selectedAnswer = nil
                        }
                    } else {
                        showResult = true
                    }
                } label: {
                    Text(currentQuestionIndex + 1 < quiz.questions.count ? "Siguiente" : "Ver resultado")
                        .appFont(size: 14, weight: .semibold)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(theme.primary)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(.horizontal)
    }

    private func resultView(quiz: Quiz) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "star.fill").font(.system(size: 60)).foregroundColor(theme.primary)
            Text("Completaste \(quiz.name)").appFont(size: 20, weight: .bold).foregroundColor(theme.textPrimary)
            Text("Puntaje: \(score)/\(quiz.questions.count)").appFont(size: 28, weight: .bold).foregroundColor(theme.primary)
            Text(score == quiz.questions.count ? "Perfecto! 🎉" : score > quiz.questions.count / 2 ? "Buen trabajo! 👏" : "Sigue intentando! 💪")
                .appFont(size: 16)
                .foregroundColor(theme.textSecondary)
            Button {
                withAnimation { playingQuiz = nil }
            } label: {
                Label("Volver a quizzes", systemImage: "arrow.left")
                    .appFont(size: 14, weight: .semibold)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(theme.primary)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }

    private func selectAnswer(_ index: Int, question: QuizQuestion) {
        selectedAnswer = index
        if index == question.correctIndex {
            score += 1
        }
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

    private func loadQuizzes() {
        Task {
            guard let snapshot = try? await quizzesRef.getDocuments() else { return }
            let items: [Quiz] = snapshot.documents.compactMap { doc in
                let data = doc.data()
                guard let name = data["name"] as? String,
                      let questionsData = data["questions"] as? [[String: Any]] else { return nil }
                let questions = questionsData.compactMap { q -> QuizQuestion? in
                    guard let text = q["text"] as? String,
                          let options = q["options"] as? [String],
                          let correctIndex = q["correctIndex"] as? Int else { return nil }
                    return QuizQuestion(text: text, options: options, correctIndex: correctIndex)
                }
                return Quiz(id: doc.documentID, name: name, questions: questions)
            }
            await MainActor.run { quizzes = items }
        }
    }

    private func deleteQuiz(_ quiz: Quiz) {
        Task {
            try? await quizzesRef.document(quiz.id).delete()
            loadQuizzes()
        }
    }
}

// MARK: - Create Quiz

private struct CreateQuizView: View {
    let quizzesRef: CollectionReference
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var questions: [EditableQuestion] = [EditableQuestion(text: "", options: ["", "", "", ""], correctIndex: 0)]
    @State private var saving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Nombre del Quiz") {
                    TextField("Ej: Cuanto me conoces", text: $name)
                }

                Section("Preguntas") {
                    ForEach(questions.indices, id: \.self) { qIndex in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Pregunta \(qIndex + 1)").appFont(size: 13, weight: .semibold)
                                Spacer()
                                if questions.count > 1 {
                                    Button(role: .destructive) {
                                        questions.remove(at: qIndex)
                                    } label: {
                                        Image(systemName: "trash").font(.system(size: 12))
                                    }
                                }
                            }

                            TextField("Pregunta", text: $questions[qIndex].text)
                                .textFieldStyle(.roundedBorder)

                            ForEach(questions[qIndex].options.indices, id: \.self) { oIndex in
                                HStack {
                                    TextField("Opcion \(oIndex + 1)", text: $questions[qIndex].options[oIndex])
                                        .textFieldStyle(.roundedBorder)

                                    Button {
                                        questions[qIndex].correctIndex = oIndex
                                    } label: {
                                        Image(systemName: questions[qIndex].correctIndex == oIndex ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(questions[qIndex].correctIndex == oIndex ? .green : .secondary)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Button {
                        questions.append(EditableQuestion(text: "", options: ["", "", "", ""], correctIndex: 0))
                    } label: {
                        Label("Agregar pregunta", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle("Crear Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { saveQuiz() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || questions.isEmpty || saving)
                }
            }
        }
    }

    private func saveQuiz() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        saving = true
        let validQuestions = questions.filter { !$0.text.trimmingCharacters(in: .whitespaces).isEmpty && $0.options.allSatisfy { !$0.trimmingCharacters(in: .whitespaces).isEmpty } }
        let questionsData = validQuestions.map { q in
            [
                "text": q.text.trimmingCharacters(in: .whitespaces),
                "options": q.options.map { $0.trimmingCharacters(in: .whitespaces) },
                "correctIndex": q.correctIndex
            ] as [String: Any]
        }
        Task {
            try? await quizzesRef.addDocument(data: [
                "name": name.trimmingCharacters(in: .whitespaces),
                "questions": questionsData,
                "createdAt": FieldValue.serverTimestamp(),
                "createdBy": AuthService.shared.currentUser?.id ?? ""
            ])
            await MainActor.run {
                saving = false
                onSave()
                dismiss()
            }
        }
    }
}

private struct EditableQuestion {
    var text: String
    var options: [String]
    var correctIndex: Int
}

// MARK: - Models

private struct Quiz: Identifiable {
    let id: String
    let name: String
    let questions: [QuizQuestion]
}

private struct QuizQuestion {
    let text: String
    let options: [String]
    let correctIndex: Int
}
