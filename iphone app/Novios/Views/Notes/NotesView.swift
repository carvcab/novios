import SwiftUI

public struct NotesView: View {
    @State private var notes: [(String, String, String, String, String)] = []
    @State private var showAddAlert = false
    @State private var newTitle = ""
    @State private var newContent = ""

    private func timeAgo(from date: Any?) -> String {
        guard let d = date as? Date else { return "" }
        let interval = Date().timeIntervalSince(d)
        if interval < 60 { return "Ahora" }
        if interval < 3600 { return "Hace \(Int(interval / 60))m" }
        if interval < 86400 { return "Hace \(Int(interval / 3600))h" }
        if interval < 172800 { return "Ayer" }
        return "Hace \(Int(interval / 86400)) días"
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Notas Compartidas")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.primary)

                            Spacer()

                            Button(action: { showAddAlert = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(ThemeManager.shared.primaryPink)
                            }
                        }
                        .padding(.horizontal, 20)

                        ForEach(Array(notes.enumerated()), id: \.offset) { index, note in
                            GlassCard {
                                HStack(spacing: 14) {
                                    Text(note.1)
                                        .font(.system(size: 32))

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(note.2)
                                            .font(.system(size: 17, weight: .bold))
                                            .foregroundColor(.primary)

                                        Text(note.3)
                                            .font(.system(size: 13))
                                            .foregroundColor(ThemeManager.shared.textSecondary)
                                            .lineLimit(2)

                                        Text(note.4)
                                            .font(.system(size: 11))
                                            .foregroundColor(ThemeManager.shared.textSecondary.opacity(0.6))
                                    }

                                    Spacer()
                                }
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    deleteNote(at: index)
                                } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteNote(at: index)
                                } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Notas")
            .task {
                await loadNotes()
            }
            .alert("Nueva nota", isPresented: $showAddAlert) {
                TextField("Título", text: $newTitle)
                TextField("Contenido", text: $newContent)
                Button("Cancelar", role: .cancel) {
                    newTitle = ""
                    newContent = ""
                }
                Button("Agregar") {
                    let title = newTitle.trimmingCharacters(in: .whitespaces)
                    let content = newContent.trimmingCharacters(in: .whitespaces)
                    guard !title.isEmpty else { return }
                    Task {
                        await FirestoreSyncService.shared.saveNote(title: title, content: content, emoji: "\u{1F4DD}")
                        await loadNotes()
                    }
                    newTitle = ""
                    newContent = ""
                }
            }
        }
    }

    private func loadNotes() async {
        let items = await FirestoreSyncService.shared.loadNotes()
        notes = items.map { item in
            let id = item["id"] as? String ?? ""
            let emoji = item["emoji"] as? String ?? "\u{1F4DD}"
            let title = item["title"] as? String ?? ""
            let content = item["content"] as? String ?? ""
            let timestamp = timeAgo(from: item["createdAt"])
            return (id, emoji, title, content, timestamp)
        }
    }

    private func deleteNote(at index: Int) {
        let id = notes[index].0
        guard !id.isEmpty else { return }
        notes.remove(at: index)
        Task {
            await FirestoreSyncService.shared.deleteNote(id: id)
        }
    }
}
