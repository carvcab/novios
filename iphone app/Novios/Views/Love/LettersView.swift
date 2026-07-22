import SwiftUI

public struct LettersView: View {
    @StateObject private var coupleService = CoupleService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showNewLetter = false
    @State private var titleInput = ""
    @State private var contentInput = ""
    @State private var selectedLetter: LetterModel? = nil

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()

                if coupleService.cartas.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(coupleService.cartas) { carta in
                                Button {
                                    selectedLetter = carta
                                } label: {
                                    letterRow(carta)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Cartas de Amor 💌")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showNewLetter = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(ThemeManager.shared.primaryPink)
                    }
                }
            }
            .sheet(isPresented: $showNewLetter) {
                newLetterSheet
            }
            .sheet(item: $selectedLetter) { carta in
                letterDetailSheet(carta)
            }
            .task {
                await coupleService.fetchCartas()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "envelope.open.fill")
                .font(.system(size: 48))
                .foregroundColor(ThemeManager.shared.primaryPink.opacity(0.6))
            Text("No hay cartas aún")
                .appFont(size: 18, weight: .semibold)
            Text("Escríbele una hermosa carta a tu pareja 💖")
                .appFont(size: 13)
                .foregroundColor(.secondary)
        }
    }

    private func letterRow(_ carta: LetterModel) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(ThemeManager.shared.primaryPink.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "envelope.fill")
                    .foregroundColor(ThemeManager.shared.primaryPink)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(carta.titulo.isEmpty ? "Carta de Amor" : carta.titulo)
                    .appFont(size: 16, weight: .semibold)
                Text(carta.contenido)
                    .appFont(size: 13)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .appFont(size: 12)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(Color.white.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2), lineWidth: 0.8))
    }

    private var newLetterSheet: some View {
        NavigationStack {
            Form {
                Section("Título") {
                    TextField("Escribe un título especial...", text: $titleInput)
                }
                Section("Contenido de la Carta") {
                    TextEditor(text: $contentInput)
                        .frame(minHeight: 180)
                }
            }
            .navigationTitle("Nueva Carta 💌")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { showNewLetter = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enviar") {
                        Task {
                            await coupleService.addCarta(titulo: titleInput, contenido: contentInput)
                            titleInput = ""; contentInput = ""
                            showNewLetter = false
                        }
                    }
                    .disabled(contentInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func letterDetailSheet(_ carta: LetterModel) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(carta.titulo)
                        .appFont(size: 22, weight: .bold)
                        .foregroundColor(ThemeManager.shared.primaryPink)
                    Divider()
                    Text(carta.contenido)
                        .appFont(size: 16)
                        .lineSpacing(6)
                }
                .padding(20)
            }
            .navigationTitle("Carta de Amor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cerrar") { selectedLetter = nil }
                }
            }
        }
    }
}
