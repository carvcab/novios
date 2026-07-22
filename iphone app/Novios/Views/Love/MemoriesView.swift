import SwiftUI

public struct MemoriesView: View {
    @StateObject private var coupleService = CoupleService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showNewMemory = false
    @State private var titleInput = ""
    @State private var descInput = ""

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()

                if coupleService.recuerdos.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            ForEach(coupleService.recuerdos) { recuerdo in
                                memoryCard(recuerdo)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Recuerdos y Álbum 📸")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showNewMemory = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(ThemeManager.shared.primaryPink)
                    }
                }
            }
            .sheet(isPresented: $showNewMemory) {
                newMemorySheet
            }
            .task {
                await coupleService.fetchRecuerdos()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundColor(ThemeManager.shared.primaryPink.opacity(0.6))
            Text("Álbum Vacío")
                .appFont(size: 18, weight: .semibold)
            Text("Agrega momentos inolvidables juntos 💖")
                .appFont(size: 13)
                .foregroundColor(.secondary)
        }
    }

    private func memoryCard(_ recuerdo: MemoryModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.pink.opacity(0.1))
                    .frame(height: 120)
                Image(systemName: "heart.fill")
                    .font(.system(size: 32))
                    .foregroundColor(ThemeManager.shared.primaryPink.opacity(0.4))
            }
            Text(recuerdo.titulo)
                .appFont(size: 14, weight: .semibold)
                .lineLimit(1)
            if !recuerdo.descripcion.isEmpty {
                Text(recuerdo.descripcion)
                    .appFont(size: 12)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2), lineWidth: 0.8))
    }

    private var newMemorySheet: some View {
        NavigationStack {
            Form {
                Section("Título del Recuerdo") {
                    TextField("Lugar o momento...", text: $titleInput)
                }
                Section("Descripción") {
                    TextField("Detalles del recuerdo...", text: $descInput)
                }
            }
            .navigationTitle("Nuevo Recuerdo 📸")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { showNewMemory = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        Task {
                            await coupleService.addRecuerdo(titulo: titleInput, descripcion: descInput, fotoBase64: "")
                            titleInput = ""; descInput = ""
                            showNewMemory = false
                        }
                    }
                    .disabled(titleInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
