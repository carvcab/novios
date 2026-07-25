import SwiftUI
import FirebaseFirestore

public struct TruthOrDareCustomView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory = "Verdad"
    @State private var currentCard: String?
    @State private var isRevealed = false
    @State private var customEntries: [String: [String]] = [:]
    @State private var showAddSheet = false
    @State private var addCategory = "Verdad"

    private let categories = ["Verdad", "Reto", "Video Reto", "Picante"]

    private let defaults: [String: [String]] = [
        "Verdad": [
            "Que fue lo primero que pensaste cuando me viste?",
            "Cual es tu recuerdo favorito conmigo?",
            "Que es lo que mas te gusta de nuestra relacion?",
            "Cuando supiste que me amabas?",
            "Que es lo que mas extranas cuando no estamos juntos?",
            "Cual fue tu cita favorita?",
            "Que pelicula te recuerda a nosotros?",
            "Cual es tu mayor miedo en la relacion?",
            "Que promesa quieres que te haga?",
            "Que es lo que mas te gusta de mi personalidad?",
        ],
        "Reto": [
            "Dame un abrazo de 10 segundos sin soltar",
            "Bailame una cancion lenta",
            "Cantame tu cancion favorita",
            "Hazme reir con una cara graciosa",
            "Escribe algo bonito en mi brazo",
            "Preparame tu bebida favorita",
            "Hazme un cumplido sincero",
            "Cuentame un chiste malo",
            "Dibuja algo en un papel para mi",
            "Inventa un apodo nuevo para nosotros",
        ],
        "Video Reto": [
            "Graba un video bailando nuestra cancion",
            "Haz un video diciendo 3 cosas que amas de mi",
            "Graba un saludo vergonzoso para mi",
            "Haz un lip sync de nuestra cancion",
            "Graba un mini tutorial de algo que sepas hacer",
            "Haz un video imitando mi voz",
            "Graba un mensaje sorpresa para mi futuro yo",
            "Haz un time-lapse haciendo algo divertido",
            "Graba un video cocinando algo rapido",
            "Haz un video contando un secreto en camara lenta",
        ],
        "Picante": [
            "Besa el lugar que mas te guste de mi",
            "Susurrame algo sexy al oido",
            "Quitame una prenda con los dientes",
            "Bailame una cancion sensual",
            "Pasame tu mano por debajo de mi ropa",
            "Lame mi cuello lentamente",
            "Haz el sonido que haces cuando sientes placer",
            "Ponte detras de mi y abrazame por la cintura",
            "Dime lo que me hari-as esta noche en detalle",
            "Muerdeme el labio inferior suavemente",
        ],
    ]

    private let db = Firestore.firestore()
    private var coupleId: String { [CoupleService.diegoUid, CoupleService.yosmariUid].sorted().joined(separator: "_") }

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundGradient.ignoresSafeArea()
                VStack(spacing: 20) {
                    categoryPicker
                    cardArea
                    Spacer()
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("Verdad o Reto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Cerrar") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        addCategory = selectedCategory
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear { loadCustomEntries() }
            .sheet(isPresented: $showAddSheet) {
                AddEntryView(category: $addCategory, coupleId: coupleId, onSave: { loadCustomEntries() })
            }
        }
    }

    private var categoryPicker: some View {
        HStack(spacing: 0) {
            ForEach(categories, id: \.self) { cat in
                let sel = cat == selectedCategory
                Button {
                    withAnimation { selectedCategory = cat; currentCard = nil; isRevealed = false }
                } label: {
                    Text(cat)
                        .appFont(size: 11, weight: .semibold)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(sel ? categoryColor(cat) : Color.clear)
                        .foregroundColor(sel ? .white : theme.textPrimary)
                }
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 4)
    }

    private var cardArea: some View {
        VStack(spacing: 16) {
            if let card = currentCard {
                Text(isRevealed ? card : "?")
                    .appFont(size: 20, weight: .semibold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(isRevealed ? theme.textPrimary : categoryColor(selectedCategory))
                    .padding(24)
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(categoryColor(selectedCategory).opacity(0.3), lineWidth: 1)
                    )
                    .onTapGesture {
                        withAnimation(.spring()) { isRevealed = true }
                    }

                if isRevealed {
                    Text(selectedCategory)
                        .appFont(size: 12, weight: .bold)
                        .foregroundColor(categoryColor(selectedCategory))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(categoryColor(selectedCategory).opacity(0.12))
                        .clipShape(Capsule())
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(categoryColor(selectedCategory).opacity(0.5))
                    Text("Toca para generar")
                        .appFont(size: 16, weight: .semibold)
                        .foregroundColor(theme.textSecondary)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 20) {
            Button {
                generateCard()
            } label: {
                Label("Nueva carta", systemImage: "shuffle")
                    .appFont(size: 14, weight: .semibold)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(categoryColor(selectedCategory).opacity(0.2))
                    .foregroundColor(theme.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if currentCard != nil && isRevealed {
                Button {
                    generateCard()
                } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(categoryColor(selectedCategory))
                }
                .transition(.scale)
            }
        }
    }

    private func generateCard() {
        let defaults = self.defaults[selectedCategory] ?? []
        let customs = customEntries[selectedCategory] ?? []
        let all = defaults + customs

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
            Task {
                let path = "couples/\(coupleId)/customTD/\(cat)"
                guard let snapshot = try? await Firestore.firestore().collection(path).getDocuments() else { return }
                let entries = snapshot.documents.compactMap { $0.data()["text"] as? String }
                await MainActor.run {
                    customEntries[cat] = entries
                }
            }
        }
    }

    private func categoryColor(_ category: String) -> Color {
        switch category {
        case "Verdad": return Color.blue
        case "Reto": return Color.orange
        case "Video Reto": return Color.purple
        case "Picante": return .red
        default: return theme.primary
        }
    }
}

// MARK: - Add Entry View

private struct AddEntryView: View {
    @Binding var category: String
    let coupleId: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var saving = false

    private let db = Firestore.firestore()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Agregar a: \(category)")
                    .appFont(size: 18, weight: .semibold)

                TextEditor(text: $text)
                    .frame(minHeight: 120)
                    .padding(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.3)))

                Button {
                    saveEntry()
                } label: {
                    if saving {
                        ProgressView().tint(.white)
                    } else {
                        Label("Guardar", systemImage: "checkmark")
                            .appFont(size: 14, weight: .semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(text.trimmingCharacters(in: .whitespaces).isEmpty || saving ? Color.gray : ThemeManager.shared.primary)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty || saving)
            }
            .padding(20)
            .navigationTitle("Nueva entrada")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
            }
        }
    }

    private func saveEntry() {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        saving = true
        let path = "couples/\(coupleId)/customTD/\(category)"
        Task {
            try? await Firestore.firestore().collection(path).addDocument(data: [
                "text": trimmed,
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
