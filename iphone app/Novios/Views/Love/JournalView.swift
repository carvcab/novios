import SwiftUI

public struct JournalView: View {
    @StateObject private var couple = CoupleService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showNew = false
    @State private var titleInput = ""
    @State private var contentInput = ""
    @State private var emotionInput = "❤️"

    private let emotions = ["❤️", "😊", "😢", "😡", "🤗", "💕", "🥰", "😎", "🙏", "🎉"]

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                if couple.diarioEntries.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(couple.diarioEntries) { entry in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("\(entry.emocion) \(entry.titulo)")
                                            .appFont(size: 16, weight: .bold)
                                        Spacer()
                                        Text(entry.autorUid == CoupleService.diegoUid ? "Diego" : "Yosmari")
                                            .appFont(size: 11).foregroundColor(ThemeManager.shared.primary)
                                            .padding(.horizontal, 8).padding(.vertical, 4)
                                            .background(ThemeManager.shared.primary.opacity(0.1)).cornerRadius(8)
                                    }
                                    Text(entry.contenido).appFont(size: 14).foregroundColor(.secondary).lineLimit(4)
                                }
                                .padding(14)
                                .background(Color.white.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.15)))
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Diario Compartido 📖")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cerrar") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showNew = true } label: {
                        Image(systemName: "plus.circle.fill").foregroundColor(ThemeManager.shared.primary)
                    }
                }
            }
            .sheet(isPresented: $showNew) { newEntrySheet }
            .task { await couple.fetchDiario() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.closed.fill").font(.system(size: 48)).foregroundColor(ThemeManager.shared.primary.opacity(0.5))
            Text("Diario Vacío").appFont(size: 18, weight: .semibold)
            Text("Escribe tus pensamientos y sentimientos 💭").appFont(size: 13).foregroundColor(.secondary)
        }
    }

    private var newEntrySheet: some View {
        NavigationStack {
            Form {
                Section("Estado de ánimo") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 36))], spacing: 8) {
                        ForEach(emotions, id: \.self) { e in
                            Button { emotionInput = e } label: {
                                Text(e).appFont(size: 24).padding(6)
                                    .background(emotionInput == e ? ThemeManager.shared.primary.opacity(0.2) : Color.clear)
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
                Section("Título") { TextField("¿Qué pasó hoy?", text: $titleInput) }
                Section("Contenido") { TextEditor(text: $contentInput).frame(minHeight: 120) }
            }
            .navigationTitle("Nueva Entrada 📝")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { showNew = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        Task {
                            await couple.addDiarioEntry(titulo: titleInput, contenido: contentInput, emocion: emotionInput)
                            titleInput = ""; contentInput = ""; showNew = false
                        }
                    }
                    .disabled(titleInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
