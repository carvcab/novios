import SwiftUI

public struct DreamsView: View {
    @State private var dreams: [(String, String, String, Bool)] = []
    @State private var selectedFilter: DreamFilter = .todos
    @State private var showAddAlert = false
    @State private var newTitle = ""
    @State private var newEmoji = ""

    private var filteredDreams: [(String, String, String, Bool)] {
        switch selectedFilter {
        case .todos:
            return dreams
        case .pendientes:
            return dreams.filter { !$0.3 }
        case .cumplidos:
            return dreams.filter { $0.3 }
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Sue\u{00F1}os Compartidos")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.primary)

                            Spacer()

                            Button(action: { showAddAlert = true }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus")
                                    Text("Agregar sue\u{00F1}o")
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(ThemeManager.shared.primaryPink)
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 20)

                        HStack(spacing: 8) {
                            ForEach(DreamFilter.allCases, id: \.self) { filter in
                                Button(action: { selectedFilter = filter }) {
                                    Text(filter.rawValue)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(selectedFilter == filter ? .white : ThemeManager.shared.textSecondary)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 8)
                                        .background(selectedFilter == filter ? ThemeManager.shared.primaryPink : Color.white.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            ForEach(Array(filteredDreams.enumerated()), id: \.offset) { _, dream in
                                GlassCard(cornerRadius: 20) {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text(dream.2)
                                            .font(.system(size: 36))

                                        Text(dream.1)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.primary)

                                        Button {
                                            toggleDream(dream)
                                        } label: {
                                            HStack(spacing: 4) {
                                                Text(dream.3 ? "\u{2705}" : "\u{23F3}")
                                                    .font(.system(size: 12))
                                                Text(dream.3 ? "Cumplido" : "Pendiente")
                                                    .font(.system(size: 11, weight: .semibold))
                                                    .foregroundColor(dream.3 ? .green : .orange)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Sue\u{00F1}os")
            .task {
                await loadDreams()
            }
            .alert("Nuevo sue\u{00F1}o", isPresented: $showAddAlert) {
                TextField("T\u{00ED}tulo", text: $newTitle)
                TextField("Emoji", text: $newEmoji)
                Button("Cancelar", role: .cancel) {
                    newTitle = ""
                    newEmoji = ""
                }
                Button("Agregar") {
                    let title = newTitle.trimmingCharacters(in: .whitespaces)
                    let emoji = newEmoji.trimmingCharacters(in: .whitespaces).isEmpty ? "\u{2B50}" : newEmoji.trimmingCharacters(in: .whitespaces)
                    guard !title.isEmpty else { return }
                    Task {
                        await FirestoreSyncService.shared.saveDream(title: title, emoji: emoji, isCompleted: false)
                        await loadDreams()
                    }
                    newTitle = ""
                    newEmoji = ""
                }
            }
        }
    }

    private func loadDreams() async {
        let items = await FirestoreSyncService.shared.loadDreams()
        dreams = items.map { item in
            let id = item["id"] as? String ?? UUID().uuidString
            let title = item["title"] as? String ?? ""
            let emoji = item["emoji"] as? String ?? "\u{2B50}"
            let isCompleted = item["isCompleted"] as? Bool ?? false
            return (id, title, emoji, isCompleted)
        }
    }

    private func toggleDream(_ dream: (String, String, String, Bool)) {
        let newValue = !dream.3
        if let idx = dreams.firstIndex(where: { $0.0 == dream.0 }) {
            dreams[idx].3 = newValue
        }
        Task {
            await FirestoreSyncService.shared.toggleDream(id: dream.0, isCompleted: newValue)
        }
    }
}

private enum DreamFilter: String, CaseIterable {
    case todos = "Todos"
    case pendientes = "Pendientes"
    case cumplidos = "Cumplidos"
}
