import SwiftUI
import FirebaseFirestore

private struct LoveCard: Identifiable {
    let id: String
    let content: String
    let category: String
    let points: Int
}

public struct LoveGameView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var allCards: [LoveCard] = []
    @State private var displayCards: [LoveCard] = []
    @State private var currentIndex = 0
    @State private var isRevealed = false
    @State private var intimacyScore = 0
    @State private var cardsPlayed = 0
    @State private var offset: CGSize = .zero
    @State private var selectedCategory = "Todas"
    @State private var hasSavedStats = false
    @State private var editMode = false
    @State private var showAddSheet = false
    @State private var editContent = ""
    @State private var editCategory = "Romanticas"
    @State private var editPoints = 1
    @State private var editingCardId: String?
    @State private var listener: ListenerRegistration?

    private var categories: [String] {
        ["Todas"] + Array(Set(allCards.map(\.category))).sorted()
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundGradient.ignoresSafeArea()
                if editMode {
                    cardList
                } else {
                    VStack(spacing: 16) {
                        categoryPicker
                        Spacer()
                        cardStack
                        Spacer()
                        actionButtons
                    }
                    .padding()
                }
            }
            .navigationTitle("Love Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Cerrar") { saveAndDismiss() } }
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill").font(.system(size: 12)).foregroundColor(theme.primary)
                        Text("\(intimacyScore)").appFont(size: 14, weight: .bold).foregroundColor(theme.primary)
                    }
                }
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
            .sheet(isPresented: $showAddSheet) { addCardSheet }
            .onAppear {
                setupListener()
                filterCards()
            }
            .onDisappear { listener?.remove() }
        }
    }

    private var cardList: some View {
        List {
            ForEach(allCards) { card in
                Button {
                    editContent = card.content
                    editCategory = card.category
                    editPoints = card.points
                    editingCardId = card.id
                    showAddSheet = true
                } label: {
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(card.content)
                                .appFont(size: 13, weight: .medium)
                                .foregroundColor(theme.textPrimary)
                                .lineLimit(2)
                            HStack(spacing: 6) {
                                Text(card.category)
                                    .appFont(size: 10, weight: .bold)
                                    .foregroundColor(categoryColor(card.category))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(categoryColor(card.category).opacity(0.12))
                                    .clipShape(Capsule())
                                Text("\(card.points) pts")
                                    .appFont(size: 10)
                                    .foregroundColor(theme.textSecondary)
                            }
                        }
                        Spacer()
                        Image(systemName: "pencil.circle.fill").foregroundColor(theme.primary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .onDelete(perform: deleteCard)
        }
        .scrollContentBackground(.hidden)
    }

    private var addCardSheet: some View {
        NavigationStack {
            Form {
                Section(editingCardId != nil ? "Editar carta" : "Nueva carta") {
                    TextField("Pregunta / contenido", text: $editContent)
                    TextField("Categoria", text: $editCategory)
                    Stepper("Puntos: \(editPoints)", value: $editPoints, in: 1...10)
                }
            }
            .navigationTitle(editingCardId != nil ? "Editar" : "Agregar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { saveCard() }.disabled(editContent.trimmingCharacters(in: .whitespaces).isEmpty || editCategory.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        resetCardFields()
                        showAddSheet = false
                    }
                }
            }
        }
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { cat in
                    Button {
                        selectedCategory = cat
                        filterCards()
                    } label: {
                        Text(cat)
                            .appFont(size: 12, weight: .semibold)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(cat == selectedCategory ? theme.primary : Color.clear)
                            .foregroundColor(cat == selectedCategory ? .white : theme.textPrimary)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(cat == selectedCategory ? Color.clear : theme.primary.opacity(0.3), lineWidth: 1))
                    }
                }
            }
        }
    }

    private var cardStack: some View {
        ZStack {
            if displayCards.isEmpty {
                Text("No hay cartas en esta categoria")
                    .appFont(size: 16)
                    .foregroundColor(theme.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 300)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            } else if currentIndex < displayCards.count {
                let card = displayCards[currentIndex]
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .shadow(color: theme.primary.opacity(0.1), radius: 16)

                    VStack(spacing: 16) {
                        if isRevealed {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 36))
                                .foregroundColor(categoryColor(card.category))

                            Text(card.content)
                                .appFont(size: 20, weight: .semibold)
                                .multilineTextAlignment(.center)
                                .foregroundColor(theme.textPrimary)
                                .padding(.horizontal)

                            Text(card.category)
                                .appFont(size: 11, weight: .bold)
                                .foregroundColor(categoryColor(card.category))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(categoryColor(card.category).opacity(0.12))
                                .clipShape(Capsule())

                            Text("+\(card.points) pts")
                                .appFont(size: 12, weight: .semibold)
                                .foregroundColor(theme.primary)
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "questionmark.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(theme.primary)
                                Text("Toca para revelar")
                                    .appFont(size: 16, weight: .semibold)
                                    .foregroundColor(theme.textSecondary)
                            }
                        }
                    }
                    .padding(24)
                }
                .frame(maxWidth: .infinity, minHeight: 320)
                .offset(x: offset.width, y: offset.height * 0.1)
                .rotationEffect(.degrees(Double(offset.width / 40)))
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            if isRevealed {
                                offset = gesture.translation
                            }
                        }
                        .onEnded { gesture in
                            if abs(gesture.translation.width) > 100 && isRevealed {
                                swipeCard()
                            }
                            withAnimation(.spring()) {
                                offset = .zero
                            }
                        }
                )
                .onTapGesture {
                    withAnimation(.spring()) {
                        isRevealed = true
                    }
                }
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 20) {
            Button {
                if currentIndex > 0 {
                    withAnimation {
                        currentIndex -= 1
                        isRevealed = false
                    }
                }
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18))
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .disabled(currentIndex == 0)
            .foregroundColor(theme.textPrimary)

            if isRevealed {
                Button {
                    intimacyScore += displayCards[safe: currentIndex]?.points ?? 1
                    withAnimation { swipeCard() }
                } label: {
                    Text("Completado")
                        .appFont(size: 14, weight: .semibold)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.green.opacity(0.3))
                        .foregroundColor(.green)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .transition(.scale)
            }

            Button {
                if currentIndex < displayCards.count - 1 {
                    withAnimation {
                        currentIndex += 1
                        isRevealed = false
                    }
                }
            } label: {
                Image(systemName: "arrow.right")
                    .font(.system(size: 18))
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .disabled(currentIndex >= displayCards.count - 1)
            .foregroundColor(theme.textPrimary)
        }
    }

    private func swipeCard() {
        if currentIndex < displayCards.count - 1 {
            withAnimation(.spring()) {
                currentIndex += 1
                isRevealed = false
                cardsPlayed += 1
            }
        }
    }

    private func filterCards() {
        if !categories.contains(selectedCategory) {
            selectedCategory = "Todas"
        }
        if selectedCategory == "Todas" {
            displayCards = allCards.shuffled()
        } else {
            displayCards = allCards.filter { $0.category == selectedCategory }.shuffled()
        }
        currentIndex = 0
        isRevealed = false
        cardsPlayed = 0
        intimacyScore = 0
        hasSavedStats = false
    }

    private func saveAndDismiss() {
        if !hasSavedStats {
            GameService.shared.saveGameStats("love", ["score": intimacyScore])
            hasSavedStats = true
        }
        dismiss()
    }

    private func categoryColor(_ category: String) -> Color {
        switch category {
        case "Romanticas": return .red
        case "Atrevidas": return Color.orange
        case "Curiosas": return Color.purple
        case "Acciones": return Color.green
        default: return theme.primary
        }
    }

    private func setupListener() {
        listener = GameService.shared.streamLoveQuestions().addSnapshotListener { snapshot, error in
            guard let docs = snapshot?.documents else { return }
            allCards = docs.compactMap { doc in
                let d = doc.data()
                return LoveCard(
                    id: doc.documentID,
                    content: d["content"] as? String ?? d["question"] as? String ?? "",
                    category: d["category"] as? String ?? "Romanticas",
                    points: d["points"] as? Int ?? 1
                )
            }
            filterCards()
        }
    }

    private func saveCard() {
        let content = editContent.trimmingCharacters(in: .whitespaces)
        let category = editCategory.trimmingCharacters(in: .whitespaces)
        guard !content.isEmpty, !category.isEmpty else { return }
        let data: [String: Any] = ["content": content, "category": category, "points": editPoints]
        if let id = editingCardId {
            GameService.shared.saveLoveQuestion(data, id: id)
        } else {
            GameService.shared.saveLoveQuestion(data)
        }
        resetCardFields()
        showAddSheet = false
    }

    private func deleteCard(at offsets: IndexSet) {
        for idx in offsets {
            GameService.shared.deleteItem(gameType: "amor", id: allCards[idx].id)
        }
    }

    private func resetCardFields() {
        editContent = ""
        editCategory = "Romanticas"
        editPoints = 1
        editingCardId = nil
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
