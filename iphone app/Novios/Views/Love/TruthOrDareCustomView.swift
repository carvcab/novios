import SwiftUI
import FirebaseFirestore

public struct TruthOrDareCustomView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab = 0
    @State private var currentCard: String?
    @State private var isRevealed = false
    @State private var customEntries: [String: [TDCustomEntry]] = [:]
    @State private var showAddSheet = false
    @State private var addCategory = "Verdad"
    @State private var revealCount = 0
    @State private var editMode = false
    @State private var editingEntry: TDCustomEntry? = nil
    @State private var collections: [String] = []
    @State private var selectedCollection: String? = nil

    private let categories = ["Verdad", "Reto", "Foto", "Video", "Picante", "Romanico", "Divertido", "Personalizado"]

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundGradient.ignoresSafeArea()
                if editMode {
                    editModeList
                } else {
                    VStack(spacing: 0) {
                        categoryTabs
                        cardArea
                        Spacer()
                        actionButtons
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Verdad o Reto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !collections.isEmpty {
                        Menu {
                            Button("Todas") { selectedCollection = nil }
                            ForEach(collections, id: \.self) { col in
                                Button(col) { selectedCollection = col }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                    .font(.system(size: 14))
                                Text(selectedCollection ?? "Coleccion")
                                    .appFont(size: 12, weight: .medium)
                            }
                            .foregroundColor(theme.primary)
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cerrar") { dismiss() }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        editMode.toggle()
                    } label: {
                        Image(systemName: editMode ? "play.fill" : "pencil")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.primary)
                    }
                    if !editMode {
                        Button {
                            addCategory = categories[selectedTab]
                            editingEntry = nil
                            showAddSheet = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(theme.primary)
                        }
                    }
                }
            }
            .onAppear {
                loadCustomEntries()
                loadCollections()
            }
            .sheet(isPresented: $showAddSheet) {
                AddDEView(category: $addCategory, entry: editingEntry, collections: collections, onSave: {
                    loadCustomEntries()
                })
            }
        }
    }

    // MARK: - Edit Mode List

    private var editModeList: some View {
        List {
            ForEach(categories, id: \.self) { category in
                let entries = customEntries[category] ?? []
                if !entries.isEmpty {
                    Section {
                        ForEach(entries) { entry in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.text)
                                        .appFont(size: 14)
                                        .lineLimit(3)
                                    if let col = entry.collection, !col.isEmpty {
                                        Text(col)
                                            .appFont(size: 11, weight: .medium)
                                            .foregroundColor(theme.primary.opacity(0.7))
                                    }
                                }
                                Spacer()
                                Button {
                                    duplicateEntry(entry)
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 14))
                                        .foregroundColor(theme.primary)
                                }
                                .buttonStyle(.borderless)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteEntry(entry)
                                } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }
                                Button {
                                    editingEntry = entry
                                    addCategory = entry.category
                                    showAddSheet = true
                                } label: {
                                    Label("Editar", systemImage: "pencil")
                                }
                                .tint(.orange)
                            }
                        }
                    } header: {
                        Text(category)
                            .appFont(size: 14, weight: .bold)
                            .foregroundColor(categoryColor(category))
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }

    // MARK: - Category Tabs

    private var categoryTabs: some View {
        TabView(selection: $selectedTab) {
            ForEach(categories.indices, id: \.self) { i in
                VStack {}.tabItem {
                    Image(systemName: tabIcon(for: categories[i]))
                    Text(categories[i])
                }.tag(i)
            }
        }
        .frame(height: 60)
        .onChange(of: selectedTab) { _ in
            withAnimation(.spring()) {
                currentCard = nil
                isRevealed = false
            }
        }
    }

    // MARK: - Card Area

    private var cardArea: some View {
        VStack(spacing: 16) {
            if let card = currentCard {
                VStack(spacing: 12) {
                    Text(isRevealed ? card : "? ? ?")
                        .appFont(size: 20, weight: .semibold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(isRevealed ? theme.textPrimary : categoryColor(categories[selectedTab]))
                        .padding(24)
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(categoryColor(categories[selectedTab]).opacity(0.3), lineWidth: 1)
                        )
                        .onTapGesture {
                            withAnimation(.spring()) { isRevealed = true }
                        }

                    if isRevealed {
                        HStack(spacing: 8) {
                            Text(categories[selectedTab])
                                .appFont(size: 12, weight: .bold)
                                .foregroundColor(categoryColor(categories[selectedTab]))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(categoryColor(categories[selectedTab]).opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: tabIcon(for: categories[selectedTab]))
                        .font(.system(size: 60))
                        .foregroundColor(categoryColor(categories[selectedTab]).opacity(0.5))
                    Text("Toca para generar")
                        .appFont(size: 16, weight: .semibold)
                        .foregroundColor(theme.textSecondary)
                    Text(categories[selectedTab])
                        .appFont(size: 13, weight: .regular)
                        .foregroundColor(theme.textSecondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
        .padding(.vertical, 16)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 20) {
            Button {
                generateCard()
            } label: {
                Label("Nueva carta", systemImage: "shuffle")
                    .appFont(size: 14, weight: .semibold)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(categoryColor(categories[selectedTab]).opacity(0.2))
                    .foregroundColor(theme.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if currentCard != nil && isRevealed {
                Button {
                    generateCard()
                } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(categoryColor(categories[selectedTab]))
                }
                .transition(.scale)
            }
        }
    }

    // MARK: - Core Logic

    private func generateCard() {
        let cat = categories[selectedTab]
        var entries = customEntries[cat] ?? []

        if let filter = selectedCollection {
            entries = entries.filter { $0.collection == filter || ($0.collection ?? "").isEmpty }
        } else {
            entries = entries.filter { ($0.collection ?? "").isEmpty }
        }

        let all = entries.map(\.text)

        guard !all.isEmpty else {
            currentCard = "No hay entradas en esta categoria"
            isRevealed = true
            return
        }

        var newCard: String
        repeat {
            newCard = all.randomElement() ?? ""
        } while newCard == currentCard && all.count > 1

        withAnimation(.spring()) {
            currentCard = newCard
            isRevealed = false
        }
    }

    private func loadCustomEntries() {
        for cat in categories {
            guard cat != "Personalizado" else { continue }
            Task {
                let query = GameService.shared.streamTD(category: cat)
                let snapshot = try? await query.getDocuments()
                let entries = snapshot?.documents.compactMap { doc -> TDCustomEntry? in
                    guard let text = doc.data()["text"] as? String else { return nil }
                    let collection = doc.data()["collection"] as? String
                    let authorId = doc.data()["authorId"] as? String
                    return TDCustomEntry(id: doc.documentID, text: text, category: cat, collection: collection, authorId: authorId)
                } ?? []
                await MainActor.run {
                    customEntries[cat] = entries
                }
            }
        }
    }

    private func loadCollections() {
        Task {
            let query = GameService.shared.streamCollections()
            let snapshot = try? await query.getDocuments()
            let names = snapshot?.documents.compactMap { $0.data()["name"] as? String } ?? []
            await MainActor.run {
                collections = names
            }
        }
    }

    private func deleteEntry(_ entry: TDCustomEntry) {
        GameService.shared.deleteTD(entry.id)
        loadCustomEntries()
        if currentCard == entry.text {
            currentCard = nil
        }
        revealCount += 1
        GameService.shared.saveGameStats("verdad_reto", [
            "action": "deleted",
            "category": entry.category,
            "totalRevealed": revealCount,
        ])
    }

    private func duplicateEntry(_ entry: TDCustomEntry) {
        GameService.shared.duplicateItem(gameType: "verdad_reto", itemId: entry.id)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            loadCustomEntries()
        }
    }

    // MARK: - Helpers

    private func tabIcon(for cat: String) -> String {
        switch cat {
        case "Verdad": return "text.bubble.fill"
        case "Reto": return "flame.fill"
        case "Foto": return "camera.fill"
        case "Video": return "video.fill"
        case "Picante": return "sparkles"
        case "Romanico": return "heart.fill"
        case "Divertido": return "face.smiling.fill"
        case "Personalizado": return "person.fill"
        default: return "questionmark"
        }
    }

    private func categoryColor(_ category: String) -> Color {
        switch category {
        case "Verdad": return Color.blue
        case "Reto": return Color.orange
        case "Foto": return Color.purple
        case "Video": return Color.pink
        case "Picante": return .red
        case "Romanico": return Color(red: 0.9, green: 0.2, blue: 0.4)
        case "Divertido": return Color.yellow
        case "Personalizado": return theme.primary
        default: return theme.primary
        }
    }
}

// MARK: - Model

private struct TDCustomEntry: Identifiable {
    let id: String
    let text: String
    let category: String
    let collection: String?
    let authorId: String?
}

// MARK: - Add/Edit View

private struct AddDEView: View {
    @Binding var category: String
    var entry: TDCustomEntry?
    let collections: [String]
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var selectedCollection: String = ""
    @State private var saving = false
    @ObservedObject private var theme = ThemeManager.shared

    private let categories = ["Verdad", "Reto", "Foto", "Video", "Picante", "Romanico", "Divertido"]

    private var isEditing: Bool { entry != nil }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Picker("Categoria", selection: $category) {
                    ForEach(categories, id: \.self) { cat in
                        Text(cat).tag(cat)
                    }
                }
                .pickerStyle(.menu)

                if !collections.isEmpty {
                    Picker("Coleccion", selection: $selectedCollection) {
                        Text("Ninguna").tag("")
                        ForEach(collections, id: \.self) { col in
                            Text(col).tag(col)
                        }
                    }
                    .pickerStyle(.menu)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Contenido:")
                        .appFont(size: 14, weight: .semibold)
                        .foregroundColor(theme.textSecondary)
                    TextEditor(text: $text)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                }

                Button {
                    saveEntry()
                } label: {
                    if saving {
                        ProgressView().tint(.white)
                    } else {
                        Label(isEditing ? "Actualizar" : "Guardar", systemImage: "checkmark")
                            .appFont(size: 14, weight: .semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(text.trimmingCharacters(in: .whitespaces).isEmpty || saving ? Color.gray : theme.primary)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty || saving)
            }
            .padding(20)
            .navigationTitle(isEditing ? "Editar entrada" : "Nueva entrada")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
            }
        }
        .onAppear {
            if let entry = entry {
                text = entry.text
                category = entry.category
                selectedCollection = entry.collection ?? ""
            }
        }
    }

    private func saveEntry() {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        saving = true

        var data: [String: Any] = [
            "text": trimmed,
            "category": category,
        ]
        if !selectedCollection.isEmpty {
            data["collection"] = selectedCollection
        }

        GameService.shared.saveTD(data, id: entry?.id)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            saving = false
            onSave()
            dismiss()
        }
    }
}
